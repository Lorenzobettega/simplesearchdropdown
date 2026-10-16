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

/// A BLoC/freezed-style parent: every change emits a new unmodifiable list.
class _FrozenHost extends StatefulWidget {
  const _FrozenHost();

  @override
  State<_FrozenHost> createState() => _FrozenHostState();
}

class _FrozenHostState extends State<_FrozenHost> {
  List<ValueItem<int>> items = List<ValueItem<int>>.unmodifiable(fruitItems());
  final List<ValueItem<int>> selected = <ValueItem<int>>[fruitItems()[1]];

  @override
  Widget build(BuildContext context) => MultipleSearchDropDown<int>(
    listItems: items,
    selectedItems: selected,
    updateSelectedItems: (_) => setState(() {}),
    newValueItem: (s) => ValueItem<int>(label: s, value: 99),
    onAddItem: (item) => setState(
      () => items = List<ValueItem<int>>.unmodifiable(<ValueItem<int>>[
        ...items,
        item,
      ]),
    ),
    onDeleteItem: (item) => setState(
      () => items = List<ValueItem<int>>.unmodifiable(
        items.where((e) => e != item),
      ),
    ),
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

    testWidgets('an unchanged edit keeps the original instance and skips '
        'onEditItem (N45)', (tester) async {
      const ValueItem<int> apple = ValueItem(label: 'Apple', value: 1);
      const ValueItem<int> banana = ValueItem(label: 'Banana', value: 2);
      final List<ValueItem<int>> items = <ValueItem<int>>[apple, banana];
      int fresh = 100;
      final List<List<ValueItem<int>>> edits = <List<ValueItem<int>>>[];
      int updates = 0;
      final c = MultipleSearchDropDownController<int>(
        listItems: items,
        selectedItems: <ValueItem<int>>[apple],
        addMode: false,
        deleteMode: false,
        editMode: true,
        onEditItem: (o, n) => edits.add(<ValueItem<int>>[o, n]),
        updateSelectedItems: (_) => updates++,
        newValueItem: (s) => ValueItem(label: s, value: fresh++),
      );
      addTearDown(c.dispose);
      await tester.pumpWidget(host(MultipleSearchDropDown<int>(controller: c)));
      await openMultiple(tester);
      await tester.tap(find.byIcon(Icons.edit).first);
      await tester.pump(const Duration(milliseconds: 500));
      await tester.tap(find.text('Editar'));
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.byType(EditDialog), findsNothing);
      expect(edits, isEmpty);
      expect(updates, 0);
      expect(fresh, 100);
      expect(identical(items.first, apple), isTrue);
      expect(items, <ValueItem<int>>[apple, banana]);
      expect(identical(c.selectedItems.single, apple), isTrue);
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

  group('legacy listItems write-back: multiple (F1/F2)', () {
    MultipleSearchDropDownController<int> legacy(
      List<ValueItem<int>> list, {
      List<ValueItem<int>>? selected,
      bool addMode = true,
      bool editMode = false,
      Function(ValueItem<int>)? onAddItem,
      Function(ValueItem<int>)? onDeleteItem,
      Function(ValueItem<int>, ValueItem<int>)? onEditItem,
      ValueItem<int> Function(String)? newValueItem,
    }) => MultipleSearchDropDownController<int>(
      listItems: list,
      selectedItems: selected,
      addMode: addMode,
      newValueItem: newValueItem ?? (s) => ValueItem<int>(label: s, value: 99),
      onAddItem: onAddItem ?? (_) {},
      deleteMode: onDeleteItem != null,
      onDeleteItem: onDeleteItem,
      editMode: editMode,
      onEditItem: onEditItem,
    );

    Future<void> submitEdit(
      WidgetTester tester,
      String label,
      String text,
    ) async {
      await tester.tap(
        find.descendant(
          of: find.widgetWithText(DefaultListTile<int>, label),
          matching: find.byIcon(Icons.edit),
        ),
      );
      await tester.pump(const Duration(milliseconds: 500));
      await tester.enterText(
        find.descendant(
          of: find.byType(EditDialog),
          matching: find.byType(TextField),
        ),
        text,
      );
      await tester.tap(find.text('Editar'));
      await tester.pumpAndSettle();
    }

    testWidgets('F1: delete and add with an unmodifiable list from state', (
      tester,
    ) async {
      await tester.pumpWidget(host(const _FrozenHost()));
      final _FrozenHostState state = tester.state(find.byType(_FrozenHost));
      await openMultiple(tester);
      await tester.tap(
        find.descendant(
          of: find.widgetWithText(DefaultListTile<int>, 'Banana'),
          matching: find.byIcon(Icons.delete),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(state.selected.map((e) => e.label), isNot(contains('Banana')));
      expect(find.widgetWithText(DefaultListTile<int>, 'Banana'), findsNothing);
      expect(state.items, hasLength(4));

      await tester.enterText(find.byType(TextField).last, 'Kiwi');
      await tester.pump();
      await tester.tap(find.text('Criar'));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(state.selected.map((e) => e.label), contains('Kiwi'));
      expect(state.items.map((e) => e.label), contains('Kiwi'));
    });

    testWidgets('F1: edit finishes with an unmodifiable list', (tester) async {
      final List<ValueItem<int>> selected = <ValueItem<int>>[fruitItems()[1]];
      final c = legacy(
        List<ValueItem<int>>.unmodifiable(fruitItems()),
        selected: selected,
        addMode: false,
        editMode: true,
        onEditItem: (_, _) {},
      );
      addTearDown(c.dispose);
      await tester.pumpWidget(host(MultipleSearchDropDown<int>(controller: c)));
      await openMultiple(tester);
      await submitEdit(tester, 'Banana', 'Kiwi');

      expect(tester.takeException(), isNull);
      expect(c.listItems[1].label, 'Banana');
      expect(selected, <ValueItem<int>>[
        const ValueItem<int>(label: 'Kiwi', value: 99),
      ]);
    });

    testWidgets('F2: an add whose callback stores its own copy is not '
        'duplicated and the copy is selected', (tester) async {
      final List<ValueItem<int>> items = fruitItems();
      final c = legacy(
        items,
        onAddItem: (i) => items.add(ValueItem<int>(label: i.label, value: 42)),
      );
      addTearDown(c.dispose);
      await tester.pumpWidget(host(MultipleSearchDropDown<int>(controller: c)));
      await openMultiple(tester);
      await tester.enterText(find.byType(TextField).last, 'Kiwi');
      await tester.pump();
      await tester.tap(find.text('Criar'));
      await tester.pumpAndSettle();

      expect(items.where((e) => e.label == 'Kiwi'), hasLength(1));
      expect(c.selectedItems, <ValueItem<int>>[
        const ValueItem<int>(label: 'Kiwi', value: 42),
      ]);
      expect(c.selectedItems.single, same(items.last));
    });

    testWidgets('F2: an edit whose callback swaps in its own copy is not '
        'duplicated and the copy stays selected', (tester) async {
      final List<ValueItem<int>> items = fruitItems();
      final List<ValueItem<int>> selected = <ValueItem<int>>[items[1]];
      final c = legacy(
        items,
        selected: selected,
        addMode: false,
        editMode: true,
        onEditItem: (old, nw) {
          items[items.indexOf(old)] = ValueItem<int>(
            label: nw.label,
            value: 42,
          );
        },
      );
      addTearDown(c.dispose);
      await tester.pumpWidget(host(MultipleSearchDropDown<int>(controller: c)));
      await openMultiple(tester);
      await submitEdit(tester, 'Banana', 'Banana2');

      expect(items.where((e) => e.label == 'Banana2'), hasLength(1));
      expect(items[1], const ValueItem<int>(label: 'Banana2', value: 42));
      expect(selected.single, same(items[1]));
    });

    testWidgets('F2: an edit that recreates an equal item selects the '
        'instance now in the list', (tester) async {
      final List<ValueItem<int>> items = <ValueItem<int>>[
        // Distinct instances on purpose.
        // ignore: prefer_const_constructors
        ValueItem<int>(label: 'Banana', value: 99),
      ];
      final ValueItem<int> old = items.single;
      final List<ValueItem<int>> selected = <ValueItem<int>>[old];
      final c = legacy(
        items,
        selected: selected,
        addMode: false,
        editMode: true,
        onEditItem: (_, _) {},
        // A new label that newValueItem turns back into the old item.
        newValueItem: (s) => ValueItem<int>(label: s.trim(), value: 99),
      );
      addTearDown(c.dispose);
      await tester.pumpWidget(host(MultipleSearchDropDown<int>(controller: c)));
      await openMultiple(tester);
      await submitEdit(tester, 'Banana', 'Banana ');

      expect(items, hasLength(1));
      expect(items.single, isNot(same(old)));
      expect(selected.single, same(items.single));
    });

    testWidgets('F1: only listItems is spared; an unmodifiable selectedItems '
        'still reports the write, as 7.x toggling did', (tester) async {
      final List<ValueItem<int>> items = fruitItems();
      final c = legacy(
        items,
        selected: List<ValueItem<int>>.unmodifiable(<ValueItem<int>>[items[1]]),
        addMode: false,
        editMode: true,
        onEditItem: (_, _) {},
      );
      addTearDown(c.dispose);
      await tester.pumpWidget(host(MultipleSearchDropDown<int>(controller: c)));
      final Future<void> edit = expectLater(
        c.editItem(
          items[1],
          tester.element(find.byType(MultipleSearchDropDown<int>)),
        ),
        throwsUnsupportedError,
      );
      await tester.pump(const Duration(milliseconds: 500));
      await tester.enterText(
        find.descendant(
          of: find.byType(EditDialog),
          matching: find.byType(TextField),
        ),
        'Kiwi',
      );
      await tester.tap(find.text('Editar'));
      await tester.pump(const Duration(milliseconds: 500));

      await edit;
      expect(items[1].label, 'Kiwi');
    });
  });
}
