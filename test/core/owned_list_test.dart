// The 8.0 list contract, for both controllers: the controller keeps its own
// copy of the items (and, multiple, of the selection), never writes to the
// caller's lists, applies add/edit/delete only when the callback completes
// without throwing, and takes outside changes through updateListItems.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:simple_search_dropdown/simple_search_dropdown.dart';

import '../support/harness.dart';

const List<String> _fruitOrder = <String>[
  'Maçã',
  'Banana',
  'Uva',
  'abacaxi',
  'Pêra',
];

/// A caller list and the identities it held, to prove it never changed.
class _Caller {
  _Caller() : list = fruitItems() {
    snapshot = List<ValueItem<int>>.of(list);
  }

  final List<ValueItem<int>> list;
  late final List<ValueItem<int>> snapshot;

  void expectUntouched() {
    expect(list, hasLength(snapshot.length));
    for (int i = 0; i < list.length; i++) {
      expect(identical(list[i], snapshot[i]), isTrue, reason: 'index $i');
    }
  }
}

/// Starts [edit] (which opens the edit dialog), types [text] and confirms.
Future<void> _confirmEdit(
  WidgetTester tester,
  Future<void> edit,
  String text,
) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 400));
  await tester.enterText(
    find.descendant(
      of: find.byType(EditDialog),
      matching: find.byType(TextField),
    ),
    text,
  );
  await tester.tap(find.text('Editar'));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 400));
  await edit;
}

Future<BuildContext> _context(WidgetTester tester) async {
  await tester.pumpWidget(host(const SizedBox()));
  return tester.element(find.byType(SizedBox));
}

SearchDropDownController<int> _single(
  List<ValueItem<int>> items, {
  Function(ValueItem<int>)? onAddItem,
  Function(ValueItem<int>)? onDeleteItem,
  Function(ValueItem<int>, ValueItem<int>)? onEditItem,
  ValueItem<int>? initial,
}) {
  final c = SearchDropDownController<int>(
    items: items,
    newValueItem: (s) => ValueItem<int>(label: s, value: 10 + s.length),
    onAddItem: onAddItem ?? (_) {},
    onDeleteItem: onDeleteItem ?? (_) {},
    editMode: true,
    onEditItem: onEditItem ?? (_, _) {},
    initialSelectedItem: initial,
  );
  addTearDown(c.dispose);
  return c;
}

MultipleSearchDropDownController<int> _multiple(
  List<ValueItem<int>> items, {
  List<ValueItem<int>>? selected,
  Function(ValueItem<int>)? onAddItem,
  Function(ValueItem<int>)? onDeleteItem,
  Function(ValueItem<int>, ValueItem<int>)? onEditItem,
  SortType sort = SortType.none,
}) {
  final c = MultipleSearchDropDownController<int>(
    items: items,
    selectedItems: selected,
    newValueItem: (s) => ValueItem<int>(label: s, value: 10 + s.length),
    onAddItem: onAddItem ?? (_) {},
    onDeleteItem: onDeleteItem ?? (_) {},
    editMode: true,
    onEditItem: onEditItem ?? (_, _) {},
    sort: sort,
  );
  addTearDown(c.dispose);
  return c;
}

Never _offline([Object? _, Object? _]) => throw StateError('offline');

void main() {
  group('single: the caller list is never changed', () {
    testWidgets('add, edit, delete and sort change only the copy', (
      tester,
    ) async {
      final BuildContext ctx = await _context(tester);
      final _Caller caller = _Caller();
      final c = _single(caller.list);

      await c.addItem('Kiwi', ctx);
      await _confirmEdit(tester, c.editItem(c.items[1], ctx), 'Banana2');
      await c.deleteItem(c.items[0], ctx);
      c.sortBy(SortType.alphabetical);

      expect(labelsOf(c.items), <String>[
        'abacaxi',
        'Banana2',
        'Kiwi',
        'Pêra',
        'Uva',
      ]);
      caller.expectUntouched();
    });

    test('sorting at creation orders only the copy', () {
      final _Caller caller = _Caller();
      final c = SearchDropDownController<int>(
        items: caller.list,
        addMode: false,
        deleteMode: false,
        sort: SortType.reverseAlphabetical,
      );
      addTearDown(c.dispose);
      expect(labelsOf(c.items).first, 'Uva');
      caller.expectUntouched();
    });

    test('items is read-only', () {
      final c = _single(fruitItems());
      expect(() => c.items.add(fruitItems()[0]), throwsUnsupportedError);
    });
  });

  group('single: a throwing callback leaves the list as it was', () {
    testWidgets('add', (tester) async {
      final BuildContext ctx = await _context(tester);
      final c = _single(fruitItems(), onAddItem: _offline);
      await expectLater(c.addItem('Kiwi', ctx), throwsStateError);
      expect(labelsOf(c.items), _fruitOrder);
      expect(c.selectedItem, isNull);
    });

    testWidgets('edit', (tester) async {
      final BuildContext ctx = await _context(tester);
      final List<ValueItem<int>> items = fruitItems();
      final c = _single(items, onEditItem: _offline, initial: items[1]);
      final Future<void> edit = expectLater(
        c.editItem(items[1], ctx),
        throwsStateError,
      );
      await _confirmEdit(tester, edit, 'Banana2');
      expect(labelsOf(c.items), _fruitOrder);
      expect(c.selectedItem, same(items[1]));
    });

    testWidgets('delete', (tester) async {
      final BuildContext ctx = await _context(tester);
      final List<ValueItem<int>> items = fruitItems();
      final c = _single(items, onDeleteItem: _offline, initial: items[1]);
      await expectLater(c.deleteItem(items[1], ctx), throwsStateError);
      expect(labelsOf(c.items), _fruitOrder);
      expect(c.selectedItem, same(items[1]));
    });
  });

  group('single: updateListItems', () {
    test('replaces the data with a copy of the new list', () {
      final _Caller first = _Caller();
      final c = _single(first.list);
      final List<ValueItem<int>> next = numberedItems(3);

      c.updateListItems(next, false);
      next.add(const ValueItem(label: 'Late', value: 9));

      expect(labelsOf(c.items), <String>['Item 0', 'Item 1', 'Item 2']);
      expect(labelsOf(c.filteredItems), <String>['Item 0', 'Item 1', 'Item 2']);
      first.expectUntouched();
    });
  });

  group('multiple: the caller lists are never changed', () {
    testWidgets(
      'add, edit, delete, sort and selection change only the copies',
      (tester) async {
        final BuildContext ctx = await _context(tester);
        final _Caller caller = _Caller();
        final List<ValueItem<int>> selected = <ValueItem<int>>[caller.list[1]];
        final c = _multiple(caller.list, selected: selected);

        await c.addItem('Kiwi', ctx);
        await _confirmEdit(tester, c.editItem(c.items[1], ctx), 'Banana2');
        await c.deleteItem(c.items[0], ctx);
        c
          ..sort = SortType.alphabetical
          ..toggle(c.items[1])
          ..forceMultipleSelection(<ValueItem<int>>[c.items[2]]);

        expect(labelsOf(c.items), <String>[
          'Banana2',
          'Uva',
          'abacaxi',
          'Pêra',
          'Kiwi',
        ]);
        expect(labelsOf(c.selectedItems), <String>['abacaxi']);
        caller.expectUntouched();
        expect(selected, <ValueItem<int>>[caller.list[1]]);
      },
    );

    test('items and selectedItems are read-only', () {
      final c = _multiple(fruitItems());
      expect(() => c.items.add(fruitItems()[0]), throwsUnsupportedError);
      expect(
        () => c.selectedItems.add(fruitItems()[0]),
        throwsUnsupportedError,
      );
    });
  });

  group('multiple: a throwing callback leaves the lists as they were', () {
    testWidgets('add', (tester) async {
      final BuildContext ctx = await _context(tester);
      final c = _multiple(fruitItems(), onAddItem: _offline);
      await expectLater(c.addItem('Kiwi', ctx), throwsStateError);
      expect(labelsOf(c.items), _fruitOrder);
      expect(c.selectedItems, isEmpty);
    });

    testWidgets('edit', (tester) async {
      final BuildContext ctx = await _context(tester);
      final List<ValueItem<int>> items = fruitItems();
      final c = _multiple(
        items,
        selected: <ValueItem<int>>[items[1]],
        onEditItem: _offline,
      );
      final Future<void> edit = expectLater(
        c.editItem(items[1], ctx),
        throwsStateError,
      );
      await _confirmEdit(tester, edit, 'Banana2');
      expect(labelsOf(c.items), _fruitOrder);
      expect(c.selectedItems, <ValueItem<int>>[items[1]]);
    });

    testWidgets('delete', (tester) async {
      final BuildContext ctx = await _context(tester);
      final List<ValueItem<int>> items = fruitItems();
      final c = _multiple(
        items,
        selected: <ValueItem<int>>[items[1]],
        onDeleteItem: _offline,
      );
      await expectLater(c.deleteItem(items[1], ctx), throwsStateError);
      expect(labelsOf(c.items), _fruitOrder);
      expect(c.selectedItems, <ValueItem<int>>[items[1]]);
    });
  });

  group('multiple: updateListItems', () {
    test('replaces the data with a copy; selected items that are gone leave '
        'the selection', () {
      final _Caller first = _Caller();
      final List<List<ValueItem<int>>> updates = <List<ValueItem<int>>>[];
      final c = MultipleSearchDropDownController<int>(
        items: first.list,
        selectedItems: <ValueItem<int>>[first.list[0], first.list[1]],
        updateSelectedItems: updates.add,
        addMode: false,
        deleteMode: false,
      );
      addTearDown(c.dispose);
      final List<ValueItem<int>> next = <ValueItem<int>>[
        first.list[1],
        const ValueItem(label: 'Kiwi', value: 9),
      ];

      c.updateListItems(next, false);
      next.add(const ValueItem(label: 'Late', value: 10));

      expect(labelsOf(c.items), <String>['Banana', 'Kiwi']);
      expect(labelsOf(c.filteredItems), <String>['Banana', 'Kiwi']);
      expect(labelsOf(c.selectedItems), <String>['Banana']);
      expect(updates, hasLength(1));
      expect(labelsOf(updates.single), <String>['Banana']);
      first.expectUntouched();

      c.updateListItems(next, false);
      expect(updates, hasLength(1), reason: 'the selection did not change');
      c.updateListItems(next, true);
      expect(c.selectedItems, isEmpty);
      expect(updates, hasLength(2));
    });

    test('a kept selection takes the new instance without a callback', () {
      final List<List<ValueItem<int>>> updates = <List<ValueItem<int>>>[];
      // ignore: prefer_const_constructors
      final ValueItem<int> old = ValueItem<int>(label: 'A', value: 1);
      // ignore: prefer_const_constructors
      final ValueItem<int> fresh = ValueItem<int>(label: 'A', value: 1);
      final c = MultipleSearchDropDownController<int>(
        items: <ValueItem<int>>[old],
        selectedItems: <ValueItem<int>>[old],
        updateSelectedItems: updates.add,
        addMode: false,
        deleteMode: false,
      );
      addTearDown(c.dispose);

      c.updateListItems(<ValueItem<int>>[fresh], false);

      expect(c.selectedItems.single, same(fresh));
      expect(updates, isEmpty);
    });

    test('notifies listeners once', () {
      final c = _multiple(fruitItems());
      int n = 0;
      c
        ..addListener(() => n++)
        ..updateListItems(numberedItems(2), false);
      expect(n, 1);
    });
  });

  group("updateListItems with the controller's own items", () {
    test('single keeps the items', () {
      final c = _single(fruitItems());
      c.updateListItems(c.items, false);
      expect(labelsOf(c.items), _fruitOrder);
      expect(labelsOf(c.filteredItems), _fruitOrder);
    });

    test('multiple keeps the items and the selection', () {
      final List<ValueItem<int>> items = fruitItems();
      final c = _multiple(items, selected: <ValueItem<int>>[items[1]]);
      c.updateListItems(c.items, false);
      expect(labelsOf(c.items), _fruitOrder);
      expect(labelsOf(c.filteredItems), _fruitOrder);
      expect(c.selectedItems, <ValueItem<int>>[items[1]]);
    });
  });

  // A callback may apply a server copy with updateListItems; the controller
  // then keeps the app's list instead of applying the change a second time.
  group('single: a callback that refreshes the list itself', () {
    const ValueItem<int> a = ValueItem(label: 'a', value: 1);

    SearchDropDownController<int> server({
      Function(ValueItem<int>)? onAddItem,
      Function(ValueItem<int>)? onDeleteItem,
      Function(ValueItem<int>, ValueItem<int>)? onEditItem,
      ValueItem<int>? initial,
      List<ValueItem<int>> items = const <ValueItem<int>>[a],
    }) {
      final c = SearchDropDownController<int>(
        items: items,
        newValueItem: (s) => ValueItem<int>(label: s, value: -1),
        onAddItem: onAddItem ?? (_) {},
        onDeleteItem: onDeleteItem ?? (_) {},
        editMode: true,
        onEditItem: onEditItem ?? (_, _) {},
        initialSelectedItem: initial,
      );
      addTearDown(c.dispose);
      return c;
    }

    testWidgets('add selects the server copy instead of appending', (
      tester,
    ) async {
      final BuildContext ctx = await _context(tester);
      late final SearchDropDownController<int> c;
      // ignore: prefer_const_constructors
      final ValueItem<int> serverB = ValueItem<int>(label: 'b', value: 2);
      c = server(
        onAddItem: (i) async =>
            c.updateListItems(<ValueItem<int>>[...c.items, serverB], false),
      );

      await c.addItem('b', ctx);

      expect(c.items, <ValueItem<int>>[a, serverB]);
      expect(c.selectedItem, same(serverB));
    });

    testWidgets('add selects the equal server item', (tester) async {
      final BuildContext ctx = await _context(tester);
      late final SearchDropDownController<int> c;
      // ignore: prefer_const_constructors
      final ValueItem<int> serverB = ValueItem<int>(label: 'b', value: -1);
      c = server(
        onAddItem: (i) async =>
            c.updateListItems(<ValueItem<int>>[serverB, ...c.items], false),
      );

      await c.addItem('b', ctx);

      expect(c.items, <ValueItem<int>>[serverB, a]);
      expect(c.selectedItem, same(serverB));
    });

    testWidgets('add without the item in the new list adds nothing', (
      tester,
    ) async {
      final BuildContext ctx = await _context(tester);
      late final SearchDropDownController<int> c;
      c = server(
        onAddItem: (i) async => c.updateListItems(numberedItems(2), false),
      );

      await c.addItem('b', ctx);

      expect(labelsOf(c.items), <String>['Item 0', 'Item 1']);
      expect(c.selectedItem, isNull);
    });

    testWidgets('edit keeps the server list and selects its edited item', (
      tester,
    ) async {
      final BuildContext ctx = await _context(tester);
      const ValueItem<int> b = ValueItem(label: 'b', value: 2);
      // ignore: prefer_const_constructors
      final ValueItem<int> serverA2 = ValueItem<int>(label: 'a2', value: 1);
      late final SearchDropDownController<int> c;
      c = server(
        items: const <ValueItem<int>>[a, b],
        initial: a,
        onEditItem: (from, to) async =>
            c.updateListItems(<ValueItem<int>>[serverA2, b], false),
      );

      await _confirmEdit(tester, c.editItem(a, ctx), 'a2');

      expect(c.items, <ValueItem<int>>[serverA2, b]);
      expect(c.selectedItem, same(serverA2));
    });

    testWidgets('edit does not resurrect an item the server removed', (
      tester,
    ) async {
      final BuildContext ctx = await _context(tester);
      const ValueItem<int> b = ValueItem(label: 'b', value: 2);
      late final SearchDropDownController<int> c;
      c = server(
        items: const <ValueItem<int>>[a, b],
        initial: a,
        onEditItem: (from, to) async =>
            c.updateListItems(<ValueItem<int>>[b], false),
      );

      await _confirmEdit(tester, c.editItem(a, ctx), 'a2');

      expect(c.items, <ValueItem<int>>[b]);
      expect(c.selectedItem, isNull);
    });

    testWidgets('delete leaves the server list as it is', (tester) async {
      final BuildContext ctx = await _context(tester);
      const ValueItem<int> b = ValueItem(label: 'b', value: 2);
      const ValueItem<int> c3 = ValueItem(label: 'c', value: 3);
      late final SearchDropDownController<int> c;
      c = server(
        items: const <ValueItem<int>>[a, b],
        onDeleteItem: (i) async =>
            c.updateListItems(<ValueItem<int>>[b, c3], false),
      );

      await c.deleteItem(a, ctx);

      expect(c.items, <ValueItem<int>>[b, c3]);
    });
  });

  group('multiple: a callback that refreshes the list itself', () {
    const ValueItem<int> a = ValueItem(label: 'a', value: 1);
    const ValueItem<int> b = ValueItem(label: 'b', value: 2);

    MultipleSearchDropDownController<int> server({
      List<ValueItem<int>> items = const <ValueItem<int>>[a],
      List<ValueItem<int>>? selected,
      Function(ValueItem<int>)? onAddItem,
      Function(ValueItem<int>)? onDeleteItem,
      Function(ValueItem<int>, ValueItem<int>)? onEditItem,
      void Function(List<ValueItem<int>>)? updateSelectedItems,
    }) {
      final c = MultipleSearchDropDownController<int>(
        items: items,
        selectedItems: selected,
        updateSelectedItems: updateSelectedItems,
        newValueItem: (s) => ValueItem<int>(label: s, value: -1),
        onAddItem: onAddItem ?? (_) {},
        onDeleteItem: onDeleteItem ?? (_) {},
        editMode: true,
        onEditItem: onEditItem ?? (_, _) {},
      );
      addTearDown(c.dispose);
      return c;
    }

    testWidgets('add selects the server copy instead of appending', (
      tester,
    ) async {
      final BuildContext ctx = await _context(tester);
      // ignore: prefer_const_constructors
      final ValueItem<int> serverB = ValueItem<int>(label: 'B', value: 2);
      late final MultipleSearchDropDownController<int> c;
      c = server(
        onAddItem: (i) async =>
            c.updateListItems(<ValueItem<int>>[...c.items, serverB], false),
      );

      await c.addItem('b', ctx);

      expect(c.items, <ValueItem<int>>[a, serverB]);
      expect(c.selectedItems.single, same(serverB));
    });

    testWidgets('add without the item in the new list adds nothing', (
      tester,
    ) async {
      final BuildContext ctx = await _context(tester);
      late final MultipleSearchDropDownController<int> c;
      c = server(
        onAddItem: (i) async => c.updateListItems(<ValueItem<int>>[b], false),
      );

      await c.addItem('x', ctx);

      expect(c.items, <ValueItem<int>>[b]);
      expect(c.selectedItems, isEmpty);
    });

    testWidgets('edit does not resurrect an item the server removed', (
      tester,
    ) async {
      final BuildContext ctx = await _context(tester);
      late final MultipleSearchDropDownController<int> c;
      c = server(
        items: const <ValueItem<int>>[a, b],
        selected: const <ValueItem<int>>[a],
        onEditItem: (from, to) async =>
            c.updateListItems(<ValueItem<int>>[b], false),
      );

      await _confirmEdit(tester, c.editItem(a, ctx), 'a2');

      expect(c.items, <ValueItem<int>>[b]);
      expect(c.selectedItems, isEmpty);
    });

    testWidgets('edit keeps the server list and selects its edited item', (
      tester,
    ) async {
      final BuildContext ctx = await _context(tester);
      // ignore: prefer_const_constructors
      final ValueItem<int> serverA2 = ValueItem<int>(label: 'a2', value: 1);
      final List<List<ValueItem<int>>> updates = <List<ValueItem<int>>>[];
      late final MultipleSearchDropDownController<int> c;
      c = server(
        items: const <ValueItem<int>>[a, b],
        selected: const <ValueItem<int>>[a, b],
        updateSelectedItems: updates.add,
        onEditItem: (from, to) async =>
            c.updateListItems(<ValueItem<int>>[serverA2, b], false),
      );

      await _confirmEdit(tester, c.editItem(a, ctx), 'a2');
      await tester.pump();

      expect(c.items, <ValueItem<int>>[serverA2, b]);
      expect(c.selectedItems, <ValueItem<int>>[serverA2, b]);
      expect(c.selectedItems.first, same(serverA2));
      expect(updates.last, <ValueItem<int>>[serverA2, b]);
    });

    testWidgets('delete leaves the server list as it is', (tester) async {
      final BuildContext ctx = await _context(tester);
      const ValueItem<int> c3 = ValueItem(label: 'c', value: 3);
      late final MultipleSearchDropDownController<int> c;
      c = server(
        items: const <ValueItem<int>>[a, b],
        selected: const <ValueItem<int>>[a],
        onDeleteItem: (i) async =>
            c.updateListItems(<ValueItem<int>>[b, c3], false),
      );

      await c.deleteItem(a, ctx);

      expect(c.items, <ValueItem<int>>[b, c3]);
      expect(c.selectedItems, isEmpty);
    });
  });
}
