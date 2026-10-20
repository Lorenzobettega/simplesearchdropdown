import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:simple_search_dropdown/simple_search_dropdown.dart';
import 'package:simple_search_dropdown/src/multiple/multiple_listview.dart';

import '../support/harness.dart';

/// [child] under an app-wide English scope, as in the README.
Widget _scoped(Widget child) => MaterialApp(
  builder: (context, c) => SearchDropDownStringsScope(
    strings: const SearchDropDownStrings.en(),
    child: c!,
  ),
  home: Scaffold(body: Center(child: child)),
);

/// A button that runs [action] with its own context.
Widget _button(void Function(BuildContext context) action) => Builder(
  builder: (context) =>
      TextButton(onPressed: () => action(context), child: const Text('run')),
);

Future<void> _run(WidgetTester tester) async {
  await tester.tap(find.text('run'));
  await tester.pumpAndSettle();
}

SearchDropDownController<int> _controller() => SearchDropDownController<int>(
  items: fruitItems(),
  addMode: false,
  deleteMode: false,
);

void main() {
  group('strings: defaults stay Portuguese', () {
    testWidgets('hint comes from SearchDropDownStrings', (tester) async {
      await tester.pumpWidget(
        host(SearchDropDown<int>(controller: _controller())),
      );
      expect(find.text('Pesquisar'), findsOneWidget);
    });

    test('dialog buttons resolve to the PT texts', () {
      const settings = DialogSettings();
      const strings = SearchDropDownStrings();
      expect(settings.deleteButton(strings).text, 'Apagar');
      expect(settings.cancelButton(strings).text, 'Cancelar');
      expect(settings.okButton(strings).text, 'OK');
      expect(settings.editButton(strings).text, 'Editar');
    });
  });

  group('strings: per widget, app scope and explicit settings', () {
    testWidgets('widget strings win over the defaults', (tester) async {
      await tester.pumpWidget(
        host(
          SearchDropDown<int>(
            controller: _controller(),
            strings: const SearchDropDownStrings.en(),
          ),
        ),
      );
      expect(find.text('Search'), findsOneWidget);
    });

    testWidgets('SearchDropDownStringsScope applies below it', (tester) async {
      await tester.pumpWidget(
        host(
          SearchDropDownStringsScope(
            strings: const SearchDropDownStrings(searchHint: 'Buscar'),
            child: SearchDropDown<int>(controller: _controller()),
          ),
        ),
      );
      expect(find.text('Buscar'), findsOneWidget);
    });

    testWidgets('an explicit settings text wins over strings', (tester) async {
      await tester.pumpWidget(
        host(
          SearchDropDown<int>(
            controller: _controller(),
            strings: const SearchDropDownStrings.en(),
            searchBarSettings: const SimpleSearchbarSettings(hint: 'Custom'),
          ),
        ),
      );
      expect(find.text('Custom'), findsOneWidget);
    });

    test('custom dialog button settings win over strings', () {
      const settings = DialogSettings(
        customDeleteButtonSettings: DialogButtonSettings('Remover'),
      );
      expect(
        settings.deleteButton(const SearchDropDownStrings.en()).text,
        'Remover',
      );
    });

    testWidgets('dialogs use the given strings', (tester) async {
      await tester.pumpWidget(
        host(
          WarningDialog(
            returnFunction: (_) {},
            strings: const SearchDropDownStrings.en(),
          ),
        ),
      );
      expect(find.text('Are you sure?'), findsOneWidget);
      expect(find.text('Delete'), findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);
    });
  });
  group('strings: the app scope reaches controller calls and exported '
      'widgets (N60)', () {
    testWidgets('single deleteItem confirm dialog', (tester) async {
      final c = SearchDropDownController<int>(
        items: fruitItems(),
        addMode: false,
        onDeleteItem: (_) {},
        confirmDelete: true,
      );
      addTearDown(c.dispose);
      await tester.pumpWidget(
        _scoped(_button((ctx) => c.deleteItem(c.items[1], ctx))),
      );
      await _run(tester);
      expect(find.text('Are you sure?'), findsOneWidget);
      expect(find.text('This action cannot be undone.'), findsOneWidget);
      expect(find.text('Delete'), findsOneWidget);
      expect(find.text('Tem certeza?'), findsNothing);
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
    });

    testWidgets('single addItem rejected dialog', (tester) async {
      final c = SearchDropDownController<int>(
        items: fruitItems(),
        deleteMode: false,
        newValueItem: (t) => ValueItem(label: t, value: 0),
        onAddItem: (_) {},
        verifyInputItem: (_) => false,
      );
      addTearDown(c.dispose);
      await tester.pumpWidget(_scoped(_button((ctx) => c.addItem('x', ctx))));
      await _run(tester);
      expect(find.text('Error!'), findsOneWidget);
      expect(find.text('The value is not valid.'), findsOneWidget);
      expect(find.text('Erro!'), findsNothing);
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();
    });

    testWidgets('single editItem dialog', (tester) async {
      final c = SearchDropDownController<int>(
        items: fruitItems(),
        addMode: false,
        deleteMode: false,
        editMode: true,
        onEditItem: (_, _) {},
        newValueItem: (t) => ValueItem(label: t, value: 0),
      );
      addTearDown(c.dispose);
      await tester.pumpWidget(
        _scoped(_button((ctx) => c.editItem(c.items[1], ctx))),
      );
      await _run(tester);
      expect(find.text('Edit item:'), findsOneWidget);
      expect(
        tester.widget<InputField>(find.byType(InputField)).hint,
        'New value',
      );
      expect(find.text('Edit'), findsOneWidget);
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
    });

    testWidgets('multiple deleteItem, addItem and editItem dialogs', (
      tester,
    ) async {
      final c = MultipleSearchDropDownController<int>(
        items: fruitItems(),
        confirmDelete: true,
        editMode: true,
        onAddItem: (_) {},
        onDeleteItem: (_) {},
        onEditItem: (_, _) {},
        verifyInputItem: (_) => false,
        newValueItem: (t) => ValueItem(label: t, value: 0),
      );
      addTearDown(c.dispose);
      late BuildContext ctx;
      await tester.pumpWidget(
        _scoped(
          Builder(
            builder: (context) {
              ctx = context;
              return const SizedBox();
            },
          ),
        ),
      );
      c.deleteItem(c.items[1], ctx).ignore();
      await tester.pumpAndSettle();
      expect(find.text('Are you sure?'), findsOneWidget);
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      c.addItem('x', ctx).ignore();
      await tester.pumpAndSettle();
      expect(find.text('Error!'), findsOneWidget);
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();

      c.editItem(c.items[1], ctx).ignore();
      await tester.pumpAndSettle();
      expect(find.text('Edit item:'), findsOneWidget);
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
    });

    testWidgets('exported dialogs default to the scope', (tester) async {
      await tester.pumpWidget(_scoped(WarningDialog(returnFunction: (_) {})));
      expect(find.text('Are you sure?'), findsOneWidget);
      expect(find.text('Delete'), findsOneWidget);
      await tester.pumpWidget(
        _scoped(EditDialog(label: 'A', returnFunction: (_, _) {})),
      );
      expect(find.text('Edit item:'), findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);
      await tester.pumpWidget(
        _scoped(
          const Column(
            children: <Widget>[
              DefaultDialogTitle(confirmDialog: false),
              DefaultDialogContent(confirmDialog: true),
            ],
          ),
        ),
      );
      expect(find.text('Error!'), findsOneWidget);
      expect(find.text('This action cannot be undone.'), findsOneWidget);
    });

    testWidgets('exported rows and list default to the scope', (tester) async {
      await tester.pumpWidget(
        _scoped(
          Column(
            children: <Widget>[
              DefaultListTile<int>(
                deleteMode: true,
                editMode: true,
                item: const ValueItem(label: 'A', value: 1),
                onDelete: (_) {},
                onEdit: (_) {},
                onPressed: (_) {},
                overlayListSettings: defaultOverlaySettings,
                selected: false,
              ),
              DefaultAddListItem(
                text: 'x',
                overlayListSettings: defaultOverlaySettings,
                itemAdded: (_) {},
              ),
            ],
          ),
        ),
      );
      expect(find.byTooltip('Delete item'), findsOneWidget);
      expect(find.byTooltip('Edit item'), findsOneWidget);
      expect(find.text('Create'), findsOneWidget);

      final c = MultipleSearchDropDownController<int>(
        items: fruitItems(),
        addMode: false,
        deleteMode: false,
      );
      addTearDown(c.dispose);
      await tester.pumpWidget(
        _scoped(
          MultipleListView<int>(
            controller: c,
            overlayListSettings: defaultOverlaySettings,
            searchBarSettings: defaultSearchBarSettings,
          ),
        ),
      );
      expect(find.text('Search'), findsOneWidget);
    });

    testWidgets('without a scope controller dialogs stay Portuguese', (
      tester,
    ) async {
      final c = SearchDropDownController<int>(
        items: fruitItems(),
        addMode: false,
        onDeleteItem: (_) {},
        confirmDelete: true,
      );
      addTearDown(c.dispose);
      await tester.pumpWidget(
        host(_button((ctx) => c.deleteItem(c.items[1], ctx))),
      );
      await _run(tester);
      expect(find.text('Tem certeza?'), findsOneWidget);
      expect(find.text('Apagar'), findsOneWidget);
      await tester.tap(find.text('Cancelar'));
      await tester.pumpAndSettle();
    });

    testWidgets('explicit strings on a controller call win over the scope', (
      tester,
    ) async {
      final c = SearchDropDownController<int>(
        items: fruitItems(),
        addMode: false,
        onDeleteItem: (_) {},
        confirmDelete: true,
      );
      addTearDown(c.dispose);
      await tester.pumpWidget(
        _scoped(
          _button(
            (ctx) => c.deleteItem(
              c.items[1],
              ctx,
              strings: const SearchDropDownStrings(
                confirmDeleteTitle: 'Certeza?',
              ),
            ),
          ),
        ),
      );
      await _run(tester);
      expect(find.text('Certeza?'), findsOneWidget);
      expect(find.text('Apagar'), findsOneWidget);
      await tester.tap(find.text('Cancelar'));
      await tester.pumpAndSettle();
    });
  });
}
