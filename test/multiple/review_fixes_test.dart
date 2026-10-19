// ignore_for_file: cascade_invocations
import 'dart:async';

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
  void rebuild() => setState(() {});

  @override
  Widget build(BuildContext context) => MultipleSearchDropDown<int>(
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

/// Legacy parent whose async callbacks flip a shape parameter one way
/// (deleteMode/onDeleteItem while adding, sort while deleting) and then wait
/// for `gate`.
class _FlipHost extends StatefulWidget {
  const _FlipHost({this.addMode = true});

  final bool addMode;

  @override
  State<_FlipHost> createState() => _FlipHostState();
}

class _FlipHostState extends State<_FlipHost> {
  final List<ValueItem<int>> items = <ValueItem<int>>[
    const ValueItem(label: 'Apple', value: 1),
    const ValueItem(label: 'Banana', value: 2),
  ];
  final List<ValueItem<int>> selected = <ValueItem<int>>[];
  final Completer<void> gate = Completer<void>();
  bool saving = false;
  SortType sort = SortType.none;

  @override
  Widget build(BuildContext context) => MultipleSearchDropDown<int>(
    listItems: items,
    selectedItems: selected,
    // No setState, like example/lib/main.dart.
    updateSelectedItems: (_) {},
    addMode: widget.addMode,
    newValueItem: (s) => ValueItem<int>(label: s, value: 99),
    onAddItem: (_) async {
      setState(() => saving = true);
      await gate.future;
    },
    deleteMode: !saving,
    onDeleteItem: saving
        ? null
        : (_) async {
            setState(() => sort = SortType.alphabetical);
            await gate.future;
          },
    sort: sort,
  );
}

/// A value whose `==` only compares [id].
class _Tag {
  _Tag(this.id, this.name);

  final int id;
  final String name;

  @override
  bool operator ==(Object other) => other is _Tag && other.id == id;

  @override
  int get hashCode => id.hashCode;
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

    testWidgets('the State reports the list open; disabling closes it '
        '(R8/R14, N58)', (tester) async {
      final GlobalKey<MultipleSearchDropDownState<int>> key = GlobalKey();
      final c = MultipleSearchDropDownController<int>(
        listItems: fruitItems(),
        addMode: false,
        deleteMode: false,
      );
      addTearDown(c.dispose);
      await tester.pumpWidget(
        host(MultipleSearchDropDown<int>(key: key, controller: c)),
      );
      final MultipleSearchDropDownState<int> state = key.currentState!;
      await openMultiple(tester);
      expect(state.aberto, isTrue);
      expect(find.byType(MultipleListView<int>), findsOneWidget);
      c.enabled = false;
      await tester.pump();
      // Disabling closes the list (N58).
      expect(state.aberto, isFalse);
      expect(find.byType(MultipleListView<int>), findsNothing);
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

    testWidgets('tiles render their additional widgets', (tester) async {
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
                defaultAdditionalWidget: const Text('extra-row'),
              ),
              DefaultAddListItem(
                text: 'x',
                overlayListSettings: defaultOverlaySettings,
                itemAdded: (_) {},
                addAdditionalWidget: const Text('extra-add'),
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

  group('multiple controller and widget (C12)', () {
    Finder box() => find
        .descendant(
          of: find.byType(MultipleSearchDropDown<int>),
          matching: find.byType(Opacity),
        )
        .first;
    List<String> rows(WidgetTester tester) => tester
        .widgetList<DefaultListTile<int>>(find.byType(DefaultListTile<int>))
        .map((t) => t.item.label)
        .toList();
    String field(WidgetTester tester) => tester
        .widget<TextField>(
          find.descendant(
            of: find.byType(MultipleListView<int>),
            matching: find.byType(TextField),
          ),
        )
        .controller!
        .text;

    testWidgets('an add finishing after a shape-changing rebuild updates the '
        'list and the chips (N46)', (tester) async {
      await tester.pumpWidget(host(const _FlipHost()));
      final _FlipHostState state = tester.state(find.byType(_FlipHost));
      await openMultiple(tester);
      await tester.enterText(find.byType(TextField).last, 'Kiwi');
      await tester.pump();
      await tester.tap(find.text('Criar'));
      await tester.pump();
      state.gate.complete();
      await tester.pump();
      await tester.pump();
      expect(state.items.map((e) => e.label), contains('Kiwi'));
      expect(rows(tester), <String>['Apple', 'Banana', 'Kiwi']);
      expect(find.text('Criar'), findsNothing);
      expect(find.descendant(of: box(), matching: find.text('Kiwi')), findsOne);
      expect(field(tester), '');
    });

    testWidgets('a delete finishing after a sort-changing rebuild removes '
        'the row (N46)', (tester) async {
      await tester.pumpWidget(host(const _FlipHost(addMode: false)));
      final _FlipHostState state = tester.state(find.byType(_FlipHost));
      await openMultiple(tester);
      await tester.tap(
        find.descendant(
          of: find.widgetWithText(DefaultListTile<int>, 'Banana'),
          matching: find.byTooltip('Apagar item'),
        ),
      );
      await tester.pump();
      state.gate.complete();
      await tester.pump();
      await tester.pump();
      expect(state.items.map((e) => e.label), <String>['Apple']);
      expect(rows(tester), <String>['Apple']);
    });

    testWidgets('legacy mode flags, callbacks and sort apply in place (N46)', (
      tester,
    ) async {
      final List<ValueItem<int>> items = <ValueItem<int>>[
        const ValueItem(label: 'b', value: 2),
        const ValueItem(label: 'a', value: 1),
      ];
      final List<ValueItem<int>> selected = <ValueItem<int>>[];
      bool flags = false;
      late StateSetter rebuild;
      await tester.pumpWidget(
        host(
          StatefulBuilder(
            builder: (context, setState) {
              rebuild = setState;
              return MultipleSearchDropDown<int>(
                listItems: items,
                selectedItems: selected,
                updateSelectedItems: (_) {},
                addMode: flags,
                newValueItem: flags
                    ? (s) => ValueItem<int>(label: s, value: 9)
                    : null,
                onAddItem: flags ? (_) {} : null,
                deleteMode: flags,
                onDeleteItem: flags ? (_) {} : null,
                editMode: flags,
                onEditItem: flags ? (_) {} : null,
                confirmDelete: flags,
                sort: flags ? SortType.alphabetical : SortType.none,
              );
            },
          ),
        ),
      );
      await openMultiple(tester);
      expect(rows(tester), <String>['b', 'a']);
      expect(find.byTooltip('Apagar item'), findsNothing);
      await tester.enterText(find.byType(TextField).last, 'zz');
      await tester.pump();
      expect(find.text('Criar'), findsNothing);

      rebuild(() => flags = true);
      await tester.pumpAndSettle();
      expect(find.byType(MultipleListView<int>), findsOne);
      expect(field(tester), 'zz');
      expect(find.text('Criar'), findsOne);
      await tester.enterText(find.byType(TextField).last, '');
      await tester.pumpAndSettle();
      expect(rows(tester), <String>['a', 'b']);
      expect(find.byTooltip('Apagar item'), findsNWidgets(2));
      expect(find.byTooltip('Editar item'), findsNWidgets(2));
      // The caller's list is never reordered.
      expect(items.map((e) => e.label), <String>['b', 'a']);
      // confirmDelete now asks first.
      await tester.tap(find.byTooltip('Apagar item').first);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.byType(WarningDialog), findsOne);
    });

    testWidgets('legacy enabled: false closes an open list (N58)', (
      tester,
    ) async {
      bool enabled = true;
      late StateSetter rebuild;
      final List<ValueItem<int>> items = fruitItems();
      final List<ValueItem<int>> selected = <ValueItem<int>>[];
      await tester.pumpWidget(
        host(
          StatefulBuilder(
            builder: (context, setState) {
              rebuild = setState;
              return MultipleSearchDropDown<int>(
                listItems: items,
                selectedItems: selected,
                updateSelectedItems: (_) {},
                addMode: false,
                deleteMode: false,
                enabled: enabled,
              );
            },
          ),
        ),
      );
      await openMultiple(tester);
      rebuild(() => enabled = false);
      await tester.pumpAndSettle();
      expect(find.byType(MultipleListView<int>), findsNothing);
      expect(tester.widget<Opacity>(box()).opacity, 0.38);
      expect(tester.takeException(), isNull);
    });

    testWidgets('swapping the controller while open keeps the search (F22)', (
      tester,
    ) async {
      final a = MultipleSearchDropDownController<int>(
        items: fruitItems(),
        addMode: false,
        deleteMode: false,
      );
      final b = MultipleSearchDropDownController<int>(
        items: fruitItems(),
        addMode: false,
        deleteMode: false,
      );
      addTearDown(a.dispose);
      addTearDown(b.dispose);
      MultipleSearchDropDownController<int> current = a;
      late StateSetter swap;
      await tester.pumpWidget(
        host(
          StatefulBuilder(
            builder: (context, setState) {
              swap = setState;
              return MultipleSearchDropDown<int>(controller: current);
            },
          ),
        ),
      );
      await openMultiple(tester);
      await tester.enterText(find.byType(TextField).last, 'ma');
      await tester.pump();
      swap(() => current = b);
      await tester.pumpAndSettle();
      expect(find.byType(MultipleListView<int>), findsOne);
      expect(field(tester), 'ma');
      expect(b.query, 'ma');
      expect(rows(tester), <String>['Maçã']);
      // The swapped-out controller no longer drives the field.
      a.search('uva');
      await tester.pump();
      expect(field(tester), 'ma');
      b.search('uva');
      await tester.pump();
      expect(field(tester), 'uva');
      // The caret goes to the end of the synced text.
      expect(
        tester
            .widget<TextField>(find.byType(TextField).last)
            .controller!
            .selection,
        const TextSelection.collapsed(offset: 3),
      );
      // Nothing of the list still listens to the swapped-out controller.
      // ignore: invalid_use_of_protected_member
      expect(a.hasListeners, isFalse);
      expect(tester.takeException(), isNull);
    });

    testWidgets('a swapped-in controller opens fresh and scrolled to its '
        'selection (F22)', (tester) async {
      final a = MultipleSearchDropDownController<int>(
        items: fruitItems(),
        addMode: false,
        deleteMode: false,
      );
      final List<ValueItem<int>> many = numberedItems(60);
      final b = MultipleSearchDropDownController<int>(
        listItems: many,
        selectedItems: <ValueItem<int>>[many[40]],
        addMode: false,
        deleteMode: false,
      )..search('Item 5');
      addTearDown(a.dispose);
      addTearDown(b.dispose);
      MultipleSearchDropDownController<int> current = a;
      late StateSetter swap;
      await tester.pumpWidget(
        host(
          StatefulBuilder(
            builder: (context, setState) {
              swap = setState;
              return MultipleSearchDropDown<int>(controller: current);
            },
          ),
        ),
      );
      await openMultiple(tester);
      swap(() => current = b);
      await tester.pumpAndSettle();
      expect(b.query, '');
      expect(field(tester), '');
      expect(b.filteredItems, hasLength(60));
      expect(find.widgetWithText(DefaultListTile<int>, 'Item 40'), findsOne);
    });

    testWidgets('a closed list stops following the controller (N30)', (
      tester,
    ) async {
      final c = MultipleSearchDropDownController<int>(
        items: fruitItems(),
        addMode: false,
        deleteMode: false,
      );
      addTearDown(c.dispose);
      await tester.pumpWidget(host(MultipleSearchDropDown<int>(controller: c)));
      await openMultiple(tester);
      await tester.enterText(find.byType(TextField).last, 'ma');
      await tester.pump();
      await tester.tapAt(const Offset(5, 5));
      await tester.pumpAndSettle();
      expect(find.byType(MultipleListView<int>), findsNothing);
      c.search('uva');
      await tester.pump();
      expect(tester.takeException(), isNull);
    });

    testWidgets('legacy edit mode without newValueItem shows no edit button', (
      tester,
    ) async {
      final List<ValueItem<int>> items = fruitItems();
      await tester.pumpWidget(
        host(
          MultipleSearchDropDown<int>(
            listItems: items,
            selectedItems: const <ValueItem<int>>[],
            updateSelectedItems: (_) {},
            addMode: false,
            deleteMode: false,
            editMode: true,
            onEditItem: (_) {},
          ),
        ),
      );
      await openMultiple(tester);
      expect(find.byType(DefaultListTile<int>), findsWidgets);
      expect(find.byTooltip('Editar item'), findsNothing);
    });

    testWidgets('legacy to controller while open keeps the search (F22)', (
      tester,
    ) async {
      final b = MultipleSearchDropDownController<int>(
        items: fruitItems(),
        addMode: false,
        deleteMode: false,
      );
      addTearDown(b.dispose);
      final List<ValueItem<int>> items = fruitItems();
      final List<ValueItem<int>> selected = <ValueItem<int>>[];
      bool useController = false;
      late StateSetter swap;
      await tester.pumpWidget(
        host(
          StatefulBuilder(
            builder: (context, setState) {
              swap = setState;
              return useController
                  ? MultipleSearchDropDown<int>(controller: b)
                  : MultipleSearchDropDown<int>(
                      listItems: items,
                      selectedItems: selected,
                      updateSelectedItems: (_) {},
                      addMode: false,
                      deleteMode: false,
                    );
            },
          ),
        ),
      );
      await openMultiple(tester);
      await tester.enterText(find.byType(TextField).last, 'ma');
      await tester.pump();
      swap(() => useController = true);
      await tester.pumpAndSettle();
      expect(field(tester), 'ma');
      expect(b.query, 'ma');
      expect(rows(tester), <String>['Maçã']);
      expect(tester.takeException(), isNull);
    });

    group('the search field follows the controller query (N30)', () {
      late Completer<void> done;
      late MultipleSearchDropDownController<int> c;

      Future<void> open(WidgetTester tester, {bool slow = true}) async {
        done = Completer<void>();
        c = MultipleSearchDropDownController<int>(
          items: fruitItems(),
          deleteMode: false,
          newValueItem: (s) => ValueItem<int>(label: s, value: 99),
          onAddItem: (_) => slow ? done.future : null,
        );
        addTearDown(c.dispose);
        await tester.pumpWidget(
          host(MultipleSearchDropDown<int>(controller: c)),
        );
        await openMultiple(tester);
      }

      testWidgets('slow add: field and filter agree while awaiting and after '
          'typing', (tester) async {
        await open(tester);
        await tester.enterText(find.byType(TextField).last, 'Kiwi');
        await tester.pump();
        await tester.tap(find.text('Criar'));
        await tester.pump();
        expect(field(tester), 'Kiwi');
        expect(c.query, 'Kiwi');
        await tester.enterText(find.byType(TextField).last, 'Mango');
        await tester.pump();
        done.complete();
        await tester.pumpAndSettle();
        expect(c.query, '');
        expect(field(tester), '');
        expect(c.selectedItems.map((e) => e.label), contains('Kiwi'));
      });

      testWidgets('failed add: the field keeps the text the filter uses', (
        tester,
      ) async {
        await open(tester);
        await tester.enterText(find.byType(TextField).last, 'Kiwi');
        await tester.pump();
        await tester.tap(find.text('Criar'));
        await tester.pump();
        done.completeError(StateError('server'));
        await tester.pump();
        expect(tester.takeException(), isA<StateError>());
        expect(field(tester), 'Kiwi');
        expect(c.query, 'Kiwi');
        expect(
          tester
              .widget<DefaultAddListItem>(find.byType(DefaultAddListItem))
              .text,
          'Kiwi',
        );
      });

      testWidgets('programmatic addValue while open clears the field', (
        tester,
      ) async {
        await open(tester, slow: false);
        await tester.enterText(find.byType(TextField).last, 'Kiw');
        await tester.pump();
        await c.addValue(
          const ValueItem<int>(label: 'Kiwi', value: 99),
          tester.element(find.byType(MultipleListView<int>)),
        );
        await tester.pump();
        expect(c.query, '');
        expect(field(tester), '');
        expect(c.filteredItems, hasLength(6));
      });

      testWidgets('the add row label tracks the query when the filter stays '
          'empty', (tester) async {
        await open(tester, slow: false);
        await tester.enterText(find.byType(TextField).last, 'Kiwi');
        await tester.pump();
        await tester.enterText(find.byType(TextField).last, 'Kiwix');
        await tester.pump();
        expect(
          tester
              .widget<DefaultAddListItem>(find.byType(DefaultAddListItem))
              .text,
          'Kiwix',
        );
        await tester.tap(find.text('Criar'));
        await tester.pumpAndSettle();
        expect(c.selectedItems.single.label, 'Kiwix');
        expect(field(tester), '');
      });

      testWidgets('a rejected item clears the field before the warning', (
        tester,
      ) async {
        c = MultipleSearchDropDownController<int>(
          items: <ValueItem<int>>[],
          deleteMode: false,
          newValueItem: (s) => ValueItem<int>(label: s, value: 99),
          onAddItem: (_) {},
          verifyInputItem: (_) => false,
        );
        addTearDown(c.dispose);
        await tester.pumpWidget(
          host(MultipleSearchDropDown<int>(controller: c)),
        );
        await openMultiple(tester);
        await tester.enterText(find.byType(TextField).last, 'Kiwi');
        await tester.pump();
        await tester.tap(find.text('Criar'));
        await tester.pump();
        expect(field(tester), '');
        expect(c.query, '');
        await tester.pumpAndSettle();
        expect(find.byType(WarningDialog), findsOne);
      });
    });

    testWidgets('a fresh equal selection is drawn again (N51)', (tester) async {
      final _Tag old = _Tag(1, 'old');
      final List<ValueItem<_Tag>> items = <ValueItem<_Tag>>[
        ValueItem<_Tag>(label: 'Tag', value: old),
      ];
      final c = MultipleSearchDropDownController<_Tag>(
        listItems: items,
        selectedItems: <ValueItem<_Tag>>[items[0]],
        addMode: false,
        deleteMode: false,
      );
      addTearDown(c.dispose);
      await tester.pumpWidget(
        host(
          MultipleSearchDropDown<_Tag>(
            controller: c,
            searchBarSettings: SimpleSearchbarSettings(
              boxMultiItemWidgetBuilder: (item) =>
                  Text((item.value! as _Tag).name),
            ),
          ),
        ),
      );
      expect(find.text('old'), findsOne);
      // Equal by id, so == holds, but the chip shows another name.
      items[0] = ValueItem<_Tag>(label: 'Tag', value: _Tag(1, 'new'));
      c.forceMultipleSelection(<ValueItem<_Tag>>[items[0]]);
      await tester.pump();
      expect(find.text('new'), findsOne);
    });

    group('typing does not rebuild the box (N51)', () {
      late int chipBuilds;
      late MultipleSearchDropDownController<int> c;

      Future<void> pumpBox(WidgetTester tester) async {
        chipBuilds = 0;
        final List<ValueItem<int>> items = numberedItems(1000);
        c = MultipleSearchDropDownController<int>(
          listItems: items,
          selectedItems: <ValueItem<int>>[items[0], items[1]],
          addMode: false,
          deleteMode: false,
        );
        addTearDown(c.dispose);
        await tester.pumpWidget(
          host(
            MultipleSearchDropDown<int>(
              controller: c,
              searchBarSettings: SimpleSearchbarSettings(
                boxMultiItemWidgetBuilder: (item) {
                  chipBuilds++;
                  return Text('#${item.value}');
                },
              ),
            ),
          ),
        );
        expect(find.text('#0'), findsOne);
        await openMultiple(tester);
      }

      Future<void> type(WidgetTester tester, String text) async {
        for (int i = 1; i <= text.length; i++) {
          await tester.enterText(
            find.byType(TextField).last,
            text.substring(0, i),
          );
          await tester.pumpAndSettle();
        }
      }

      testWidgets('selected chips are not rebuilt while typing', (
        tester,
      ) async {
        await pumpBox(tester);
        final int before = chipBuilds;
        await type(tester, 'Item 99');
        expect(c.filteredItems, hasLength(11));
        expect(chipBuilds - before, 0);
      });

      testWidgets('the box still follows selection and enabled', (
        tester,
      ) async {
        await pumpBox(tester);
        await type(tester, 'Item 99');
        final int before = chipBuilds;
        await tester.tap(find.widgetWithText(DefaultListTile<int>, 'Item 99'));
        await tester.pump();
        expect(find.text('#99'), findsOne);
        expect(chipBuilds, greaterThan(before));
        c.forceMultipleSelection(<ValueItem<int>>[c.listItems[0]]);
        await tester.pump();
        expect(find.text('#99'), findsNothing);
        expect(find.text('#1'), findsNothing);
        c.enabled = false;
        await tester.pump();
        expect(tester.widget<Opacity>(box()).opacity, 0.38);
      });
    });
  });
}
