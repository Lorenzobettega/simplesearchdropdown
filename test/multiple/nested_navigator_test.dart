import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:simple_search_dropdown/simple_search_dropdown.dart';

import '../support/harness.dart';

/// [dropdown] on the second page of a nested Navigator (like a go_router
/// ShellRoute); the dialogs go on the root navigator.
Widget _nested(Widget dropdown) => MaterialApp(
  home: Navigator(
    onGenerateInitialRoutes: (_, _) => <Route<void>>[
      MaterialPageRoute<void>(
        builder: (_) => const Scaffold(body: Text('base page')),
      ),
      MaterialPageRoute<void>(
        builder: (_) => Scaffold(body: Center(child: dropdown)),
      ),
    ],
  ),
);

/// Lets a dialog open or close while a row spinner animates.
Future<void> _settle(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 500));
}

MultipleSearchDropDownController<int> _multiple({
  bool addMode = false,
  bool deleteMode = false,
  bool editMode = false,
  bool confirmDelete = false,
  Function(ValueItem<int>)? onDeleteItem,
  bool Function(ValueItem<int>)? verifyInputItem,
}) => MultipleSearchDropDownController<int>(
  listItems: fruitItems(),
  addMode: addMode,
  deleteMode: deleteMode,
  editMode: editMode,
  confirmDelete: confirmDelete,
  onAddItem: (_) {},
  onDeleteItem: onDeleteItem ?? (_) {},
  onEditItem: (_, _) {},
  verifyInputItem: verifyInputItem,
  newValueItem: (s) => ValueItem<int>(label: s, value: 99),
);

SearchDropDownController<int> _single({
  bool addMode = false,
  bool deleteMode = false,
  bool editMode = false,
  bool confirmDelete = false,
  bool Function(ValueItem<int>)? verifyInputItem,
}) => SearchDropDownController<int>(
  listItems: fruitItems(),
  addMode: addMode,
  deleteMode: deleteMode,
  editMode: editMode,
  confirmDelete: confirmDelete,
  onAddItem: (_) {},
  onDeleteItem: (_) {},
  onEditItem: (_, _) {},
  verifyInputItem: verifyInputItem,
  newValueItem: (s) => ValueItem<int>(label: s, value: 99),
);

void _expectDialogClosedOnPage<W>() {
  expect(find.byType(AlertDialog), findsNothing);
  expect(find.text('base page'), findsNothing);
  expect(find.byType(W), findsOneWidget);
}

void main() {
  group('dialogs close their own route in a nested navigator (N32)', () {
    for (final String button in <String>['Cancelar', 'Apagar']) {
      testWidgets('multiple: confirm-delete $button', (tester) async {
        final List<ValueItem<int>> deleted = <ValueItem<int>>[];
        final c = _multiple(
          deleteMode: true,
          confirmDelete: true,
          onDeleteItem: deleted.add,
        );
        addTearDown(c.dispose);
        await tester.pumpWidget(
          _nested(MultipleSearchDropDown<int>(controller: c)),
        );
        await openMultiple(tester);
        await tester.tap(find.byIcon(Icons.delete).first);
        await _settle(tester);
        expect(find.byType(WarningDialog), findsOneWidget);

        await tester.tap(find.text(button));
        await tester.pumpAndSettle();
        _expectDialogClosedOnPage<MultipleSearchDropDown<int>>();
        expect(deleted, hasLength(button == 'Apagar' ? 1 : 0));
      });
    }

    testWidgets('multiple: verify warning OK', (tester) async {
      final c = _multiple(addMode: true, verifyInputItem: (_) => false);
      addTearDown(c.dispose);
      await tester.pumpWidget(
        _nested(MultipleSearchDropDown<int>(controller: c)),
      );
      await openMultiple(tester);
      await tester.enterText(find.byType(TextField).last, 'Kiwi');
      await tester.pump();
      await tester.tap(find.text('Criar'));
      await _settle(tester);
      expect(find.byType(WarningDialog), findsOneWidget);

      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();
      _expectDialogClosedOnPage<MultipleSearchDropDown<int>>();
    });

    testWidgets('multiple: edit Cancelar', (tester) async {
      final c = _multiple(editMode: true);
      addTearDown(c.dispose);
      await tester.pumpWidget(
        _nested(MultipleSearchDropDown<int>(controller: c)),
      );
      await openMultiple(tester);
      await tester.tap(find.byIcon(Icons.edit).first);
      await _settle(tester);
      expect(find.byType(EditDialog), findsOneWidget);

      await tester.tap(find.text('Cancelar'));
      await tester.pumpAndSettle();
      _expectDialogClosedOnPage<MultipleSearchDropDown<int>>();
    });

    testWidgets('single: confirm-delete Cancelar keeps the view open', (
      tester,
    ) async {
      final c = _single(deleteMode: true, confirmDelete: true);
      addTearDown(c.dispose);
      await tester.pumpWidget(_nested(SearchDropDown<int>(controller: c)));
      await openSingle(tester);
      await tester.tap(find.byIcon(Icons.delete).first);
      await _settle(tester);
      expect(find.byType(WarningDialog), findsOneWidget);

      await tester.tap(find.text('Cancelar'));
      await tester.pumpAndSettle();
      _expectDialogClosedOnPage<SearchDropDown<int>>();
      expect(c.localSearchController.isOpen, isTrue);
    });

    testWidgets('single: verify warning OK keeps the view open', (
      tester,
    ) async {
      final c = _single(addMode: true, verifyInputItem: (_) => false);
      addTearDown(c.dispose);
      await tester.pumpWidget(_nested(SearchDropDown<int>(controller: c)));
      await openSingle(tester);
      await typeInSingle(tester, 'Kiwi');
      await tester.tap(find.text('Criar'));
      await _settle(tester);
      expect(find.byType(WarningDialog), findsOneWidget);

      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();
      _expectDialogClosedOnPage<SearchDropDown<int>>();
      expect(c.localSearchController.isOpen, isTrue);
    });

    testWidgets('single: edit Cancelar keeps the view open', (tester) async {
      final c = _single(editMode: true);
      addTearDown(c.dispose);
      await tester.pumpWidget(_nested(SearchDropDown<int>(controller: c)));
      await openSingle(tester);
      await tester.tap(find.byIcon(Icons.edit).first);
      await _settle(tester);
      expect(find.byType(EditDialog), findsOneWidget);

      await tester.tap(find.text('Cancelar'));
      await tester.pumpAndSettle();
      _expectDialogClosedOnPage<SearchDropDown<int>>();
      expect(c.localSearchController.isOpen, isTrue);
    });
  });

  testWidgets(
    'a double press on a dialog button closes only the dialog (N32)',
    (tester) async {
      final c = _single(deleteMode: true, confirmDelete: true);
      addTearDown(c.dispose);
      await tester.pumpWidget(
        host(
          Builder(
            builder: (context) => TextButton(
              onPressed: () => c.deleteItem(c.listItems.first, context),
              child: const Text('run'),
            ),
          ),
        ),
      );
      await tester.tap(find.text('run'));
      await tester.pumpAndSettle();
      // Two presses land before the dialog starts closing.
      final DialogButton cancel = tester.widget<DialogButton>(
        find.widgetWithText(DialogButton, 'Cancelar'),
      );
      cancel.function();
      cancel.function();
      await tester.pumpAndSettle();
      expect(find.byType(AlertDialog), findsNothing);
      expect(find.text('run'), findsOneWidget);
    },
  );

  group('a dialog closes when the caller context unmounts (N32)', () {
    Future<void> run(
      WidgetTester tester,
      Future<void> Function(BuildContext context) open,
      String button,
    ) async {
      bool show = true;
      late StateSetter setShow;
      late BuildContext rowContext;
      await tester.pumpWidget(
        host(
          StatefulBuilder(
            builder: (_, set) {
              setShow = set;
              return show
                  ? Builder(
                      builder: (context) {
                        rowContext = context;
                        return const SizedBox();
                      },
                    )
                  : const SizedBox();
            },
          ),
        ),
      );
      bool done = false;
      open(rowContext).then((_) => done = true).ignore();
      await tester.pumpAndSettle();
      expect(find.byType(AlertDialog), findsOneWidget);
      setShow(() => show = false);
      await tester.pump();
      await tester.tap(find.text(button));
      await tester.pumpAndSettle();
      expect(find.byType(AlertDialog), findsNothing);
      expect(done, isTrue);
    }

    testWidgets('multiple deleteItem', (tester) async {
      final c = _multiple(deleteMode: true, confirmDelete: true);
      addTearDown(c.dispose);
      await run(
        tester,
        (ctx) => c.deleteItem(c.listItems.first, ctx),
        'Cancelar',
      );
    });

    testWidgets('multiple addValue rejected', (tester) async {
      final c = _multiple(addMode: true, verifyInputItem: (_) => false);
      addTearDown(c.dispose);
      await run(tester, (ctx) => c.addItem('Kiwi', ctx), 'OK');
    });

    testWidgets('multiple editItem', (tester) async {
      final c = _multiple(editMode: true);
      addTearDown(c.dispose);
      await run(tester, (ctx) => c.editItem(c.listItems.first, ctx), 'Editar');
    });

    testWidgets('single deleteItem', (tester) async {
      final c = _single(deleteMode: true, confirmDelete: true);
      addTearDown(c.dispose);
      await run(
        tester,
        (ctx) => c.deleteItem(c.listItems.first, ctx),
        'Apagar',
      );
    });

    testWidgets('single addItem rejected', (tester) async {
      final c = _single(addMode: true, verifyInputItem: (_) => false);
      addTearDown(c.dispose);
      await run(tester, (ctx) => c.addItem('Kiwi', ctx), 'OK');
    });

    testWidgets('single editItem', (tester) async {
      final c = _single(editMode: true);
      addTearDown(c.dispose);
      await run(
        tester,
        (ctx) => c.editItem(c.listItems.first, ctx),
        'Cancelar',
      );
    });
  });
}
