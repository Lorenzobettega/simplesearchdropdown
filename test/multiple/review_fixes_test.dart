// Exercises 7.x API on purpose (compat findings).
// ignore_for_file: deprecated_member_use, deprecated_member_use_from_same_package, cascade_invocations
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:simple_search_dropdown/simple_search_dropdown.dart';

import '../support/harness.dart';

/// Legacy multiple dropdown whose parent rebuilds on every selection and
/// passes non-const settings (a new identity each build).
class _Host extends StatefulWidget {
  const _Host({required this.items});

  final List<ValueItem<int>> items;

  @override
  State<_Host> createState() => _HostState();
}

class _HostState extends State<_Host> {
  final List<ValueItem<int>> selected = <ValueItem<int>>[];
  final GlobalKey<MultipleSearchDropDownState<int>> key = GlobalKey();

  void rebuild() => setState(() {});

  @override
  Widget build(BuildContext context) => MultipleSearchDropDown<int>(
    key: key,
    listItems: widget.items,
    selectedItems: selected,
    updateSelectedItems: (_) => setState(() {}),
    newValueItem: (s) => ValueItem<int>(label: s, value: 99),
    onAddItem: (item) async {
      await Future<void>.delayed(const Duration(milliseconds: 100));
    },
    deleteMode: false,
    // ignore: prefer_const_constructors
    verifyDialogSettings: DialogSettings(title: Text('t')),
  );
}

void main() {
  group('review fixes: multiple', () {
    testWidgets('a parent rebuild keeps the active search (R4/R10)', (
      tester,
    ) async {
      await tester.pumpWidget(host(_Host(items: fruitItems())));
      await openMultiple(tester);
      await tester.enterText(find.byType(TextField).last, 'ma');
      await tester.pump();
      await tester.tap(find.widgetWithText(DefaultListTile<int>, 'Maçã'));
      await tester.pump();
      final List<String> rows = tester
          .widgetList<DefaultListTile<int>>(find.byType(DefaultListTile<int>))
          .map((t) => t.item.label)
          .toList();
      expect(rows, <String>['Maçã']);
    });

    testWidgets('an add still selects after a parent rebuild (R17)', (
      tester,
    ) async {
      final List<ValueItem<int>> items = fruitItems();
      await tester.pumpWidget(host(_Host(items: items)));
      final _HostState hostState = tester.state(find.byType(_Host));
      await openMultiple(tester);
      await tester.enterText(find.byType(TextField).last, 'Kiwi');
      await tester.pump();
      await tester.tap(find.text('Criar'));
      await tester.pump();
      hostState.rebuild();
      await tester.pump(const Duration(milliseconds: 200));
      expect(hostState.selected.map((e) => e.label), contains('Kiwi'));
      expect(items.map((e) => e.label), contains('Kiwi'));
    });

    testWidgets('onFilterUpdated may call setState when the list opens (R6)', (
      tester,
    ) async {
      late StateSetter rebuild;
      final c = MultipleSearchDropDownController<int>(
        items: fruitItems(),
        addMode: false,
        deleteMode: false,
        onFilterUpdated: () => rebuild(() {}),
      );
      addTearDown(c.dispose);
      await tester.pumpWidget(
        host(
          StatefulBuilder(
            builder: (context, setState) {
              rebuild = setState;
              return MultipleSearchDropDown<int>(controller: c);
            },
          ),
        ),
      );
      c.search('ma');
      await openMultiple(tester);
      expect(tester.takeException(), isNull);
    });

    testWidgets('7.x State setters aberto / enabled still work (R8/R14)', (
      tester,
    ) async {
      await tester.pumpWidget(host(_Host(items: fruitItems())));
      final MultipleSearchDropDownState<int> state = tester
          .state<_HostState>(find.byType(_Host))
          .key
          .currentState!;
      state.aberto = true;
      await tester.pump();
      expect(find.byType(MultipleListView<int>), findsOneWidget);
      state.enabled = false;
      await tester.pump();
      expect(state.enabled, isFalse);
      expect(state.overlayScreen, isA<OverlayScreen>());
    });

    testWidgets('7.x overlayScreen is one stable instance that closes the '
        'list (F10)', (tester) async {
      await tester.pumpWidget(host(_Host(items: fruitItems())));
      final MultipleSearchDropDownState<int> state = tester
          .state<_HostState>(find.byType(_Host))
          .key
          .currentState!;
      expect(identical(state.overlayScreen, state.overlayScreen), isTrue);

      // A caller's own entry survives between accesses.
      final OverlayEntry entry = OverlayEntry(
        builder: (_) => const Text('custom-entry'),
      );
      state.overlayScreen.show(entry);
      await tester.pump();
      expect(find.text('custom-entry'), findsOneWidget);
      expect(state.overlayScreen.overlayEntrys, hasLength(1));
      state.overlayScreen.updateLast();
      state.overlayScreen.closeLast();
      await tester.pump();
      expect(find.text('custom-entry'), findsNothing);
      expect(state.overlayScreen.overlayEntrys, isEmpty);

      // 7.x closeLast()/closeAll() closed the list (its entry was on top).
      state.aberto = true;
      await tester.pump();
      expect(find.byType(MultipleListView<int>), findsOneWidget);
      state.overlayScreen
        ..updateLast()
        ..closeLast();
      await tester.pump();
      expect(state.aberto, isFalse);
      expect(find.byType(MultipleListView<int>), findsNothing);

      state.aberto = true;
      await tester.pump();
      state.overlayScreen.show(entry);
      await tester.pump();
      state.overlayScreen.closeAll();
      await tester.pump();
      expect(state.aberto, isFalse);
      expect(find.byType(MultipleListView<int>), findsNothing);
      expect(find.text('custom-entry'), findsNothing);

      // Nothing open: no StateError.
      state.overlayScreen
        ..closeLast()
        ..closeAll()
        ..updateLast();
      await tester.pump();
      expect(tester.takeException(), isNull);
    });
  });

  group('final review fixes', () {
    testWidgets('multiple: confirming an unchanged edit keeps the item', (
      tester,
    ) async {
      final List<ValueItem<String>> items = <ValueItem<String>>[
        const ValueItem(label: 'Apple', value: 'Apple'),
        const ValueItem(label: 'Banana', value: 'Banana'),
      ];
      final c = MultipleSearchDropDownController<String>(
        listItems: items,
        selectedItems: <ValueItem<String>>[items.first],
        addMode: false,
        deleteMode: false,
        editMode: true,
        onEditItem: (_, _) {},
        newValueItem: (s) => ValueItem(label: s, value: s),
      );
      addTearDown(c.dispose);
      await tester.pumpWidget(
        host(MultipleSearchDropDown<String>(controller: c)),
      );
      await openMultiple(tester);
      await tester.tap(find.byIcon(Icons.edit).first);
      await tester.pump(const Duration(milliseconds: 500));
      await tester.tap(find.text('Editar'));
      await tester.pump(const Duration(milliseconds: 500));
      expect(items.map((e) => e.label), <String>['Apple', 'Banana']);
      expect(c.selectedItems.map((e) => e.label), <String>['Apple']);
    });

    testWidgets('single: a swapped-out controller is not disposed (7.x)', (
      tester,
    ) async {
      final a = SearchDropDownController<int>(
        listItems: fruitItems(),
        addMode: false,
        deleteMode: false,
      );
      final b = SearchDropDownController<int>(
        listItems: fruitItems(),
        addMode: false,
        deleteMode: false,
      );
      addTearDown(a.dispose);
      await tester.pumpWidget(host(SearchDropDown<int>(controller: a)));
      await tester.pumpWidget(host(SearchDropDown<int>(controller: b)));
      await tester.pumpWidget(const SizedBox());
      expect(a.isDisposed, isFalse);
      expect(b.isDisposed, isTrue);
    });
  });

  group('review fixes: 7.x public members keep their types (R11/R13)', () {
    test('settings texts read as non-null defaults', () {
      const SimpleSearchbarSettings bar = SimpleSearchbarSettings();
      const SimpleOverlaySettings list = SimpleOverlaySettings();
      const DialogSettings dialog = DialogSettings();
      final String hint = bar.hint;
      final String add = list.addItemHint;
      final String edit = dialog.editHint;
      final DialogButtonSettings delete = dialog.customDeleteButtonSettings;
      expect(
        <String>[hint, add, edit, delete.text],
        <String>['Pesquisar', 'Criar', 'Novo valor', 'Apagar'],
      );
    });

    testWidgets('tiles accept the 7.x misspelled parameters', (tester) async {
      await tester.pumpWidget(
        host(
          Column(
            children: <Widget>[
              DefaultListTile<int>(
                deleteMode: false,
                editMode: false,
                item: const ValueItem(label: 'A', value: 1),
                onDelete: (_) {},
                onEdit: (_) {},
                onPressed: (_) {},
                overlayListSettings: defaultOverlaySettings,
                selected: false,
                defaultAditionalWidget: const Text('extra-row'),
              ),
              DefaultAddListItem(
                text: 'x',
                overlayListSettings: defaultOverlaySettings,
                itemAdded: (_) {},
                addAditionalWidget: const Text('extra-add'),
              ),
            ],
          ),
        ),
      );
      expect(find.text('extra-row'), findsOneWidget);
      expect(find.text('extra-add'), findsOneWidget);
    });
  });
}
