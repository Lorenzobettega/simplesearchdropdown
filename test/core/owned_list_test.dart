// The 8.0 list contract, for both controllers: the controller keeps its own
// copy of the items (and, multiple, of the selection), never writes to the
// caller's lists, applies add/edit/delete only when the callback completes
// without throwing, and takes outside changes through updateListItems.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:simple_search_dropdown/simple_search_dropdown.dart';

import '../support/harness.dart';

List<String> _labels(Iterable<ValueItem<dynamic>> items) =>
    items.map((e) => e.label).toList();

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

      expect(_labels(c.items), <String>[
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
      expect(_labels(c.items).first, 'Uva');
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
      expect(_labels(c.items), _fruitOrder);
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
      expect(_labels(c.items), _fruitOrder);
      expect(c.selectedItem, same(items[1]));
    });

    testWidgets('delete', (tester) async {
      final BuildContext ctx = await _context(tester);
      final List<ValueItem<int>> items = fruitItems();
      final c = _single(items, onDeleteItem: _offline, initial: items[1]);
      await expectLater(c.deleteItem(items[1], ctx), throwsStateError);
      expect(_labels(c.items), _fruitOrder);
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

      expect(_labels(c.items), <String>['Item 0', 'Item 1', 'Item 2']);
      expect(_labels(c.filteredItems), <String>['Item 0', 'Item 1', 'Item 2']);
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

        expect(_labels(c.items), <String>[
          'Banana2',
          'Uva',
          'abacaxi',
          'Pêra',
          'Kiwi',
        ]);
        expect(_labels(c.selectedItems), <String>['abacaxi']);
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
      expect(_labels(c.items), _fruitOrder);
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
      expect(_labels(c.items), _fruitOrder);
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
      expect(_labels(c.items), _fruitOrder);
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

      expect(_labels(c.items), <String>['Banana', 'Kiwi']);
      expect(_labels(c.filteredItems), <String>['Banana', 'Kiwi']);
      expect(_labels(c.selectedItems), <String>['Banana']);
      expect(updates, hasLength(1));
      expect(_labels(updates.single), <String>['Banana']);
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
}
