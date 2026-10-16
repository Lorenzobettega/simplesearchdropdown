// ignore_for_file: cascade_invocations
import 'package:flutter_test/flutter_test.dart';
import 'package:simple_search_dropdown/simple_search_dropdown.dart';

import '../support/harness.dart';

List<String> _labels(Iterable<ValueItem<dynamic>> items) =>
    items.map((e) => e.label).toList();

int _labelReads = 0;

/// Counts label reads, so a full re-normalization shows up.
class _CountingItem extends ValueItem<int> {
  _CountingItem(this._text, int value) : super(label: '', value: value);
  final String _text;

  @override
  String get label {
    _labelReads++;
    return _text;
  }
}

/// A model whose `==` only looks at the id (like Equatable with props [id]).
class _Product {
  _Product(this.id, this.price);
  final int id;
  final int price;

  @override
  bool operator ==(Object other) => other is _Product && other.id == id;

  @override
  int get hashCode => id.hashCode;
}

MultipleSearchDropDownController<int> _shared(
  List<ValueItem<int>> items, {
  List<ValueItem<int>>? selected,
  SortType sort = SortType.none,
  void Function(List<ValueItem<int>>)? onChanged,
  void Function()? onFilterUpdated,
}) => MultipleSearchDropDownController<int>(
  listItems: items,
  selectedItems: selected,
  updateSelectedItems: onChanged,
  addMode: false,
  deleteMode: false,
  sort: sort,
  onFilterUpdated: onFilterUpdated,
);

void main() {
  group('a new selection list alone does not re-normalize labels (N56)', () {
    for (final SortType sort in <SortType>[
      SortType.alphabetical,
      SortType.none,
    ]) {
      test('sort: $sort', () {
        final List<ValueItem<int>> items = List<ValueItem<int>>.generate(
          500,
          (i) => _CountingItem('Item $i', i),
        );
        List<ValueItem<int>> selected = <ValueItem<int>>[];
        final c = _shared(
          items,
          selected: selected,
          sort: sort,
          onChanged: (l) => selected = List<ValueItem<int>>.of(l),
        );
        addTearDown(c.dispose);
        c.search('item 1');
        final List<ValueItem<int>> before = List<ValueItem<int>>.of(
          c.filteredItems,
        );

        _labelReads = 0;
        c.toggle(c.filteredItems.first);
        c.replaceSources(listItems: items, selectedItems: selected);

        expect(_labelReads, lessThan(items.length));
        expect(c.filteredItems, before);
        expect(c.selectedItems, same(selected));
        expect(c.listItems, same(items));
      });
    }

    test('a new selection list keeps the label cache', () {
      final List<ValueItem<int>> items = List<ValueItem<int>>.generate(
        500,
        (i) => _CountingItem('Item $i', i),
      );
      final c = _shared(items, selected: <ValueItem<int>>[]);
      addTearDown(c.dispose);
      c
        ..search('item 2')
        ..search('item 1');
      _labelReads = 0;
      c.search('item 2');
      final int warm = _labelReads;

      c.replaceSources(listItems: items, selectedItems: <ValueItem<int>>[]);
      _labelReads = 0;
      c.search('item 1');
      c.search('item 2');
      expect(_labelReads, lessThanOrEqualTo(2 * warm));
    });

    testWidgets('a new selection list alone still notifies listeners', (
      tester,
    ) async {
      final List<ValueItem<int>> items = fruitItems();
      final c = _shared(items, selected: <ValueItem<int>>[]);
      addTearDown(c.dispose);
      int n = 0;
      c.addListener(() => n++);

      c.replaceSources(listItems: items, selectedItems: [items[1]]);
      expect(n, 1);
      expect(c.isSelected(items[1]), isTrue);
      c.replaceSources(listItems: items, selectedItems: c.selectedItems);
      expect(n, 1);
    });

    test('selectedFirst still re-pins on a selection-only change', () {
      final List<ValueItem<int>> items = numberedItems(5);
      final c = _shared(items, sort: SortType.selectedFirst);
      addTearDown(c.dispose);

      c.replaceSources(listItems: items, selectedItems: [items[3]]);
      expect(c.filteredItems.first, same(items[3]));
      expect(_labels(items), _labels(numberedItems(5)));
    });

    test('a new listItems instance with new items still refreshes', () {
      final c = _shared(fruitItems(), sort: SortType.alphabetical);
      addTearDown(c.dispose);
      c.search('a');

      c.replaceSources(
        listItems: fruitItems()..add(const ValueItem(label: 'Amora', value: 9)),
        selectedItems: c.selectedItems,
      );
      expect(_labels(c.filteredItems), <String>[
        'abacaxi',
        'Amora',
        'Banana',
        'Maçã',
        'Pêra',
        'Uva',
      ]);
    });

    test('an in-place change with the same instances refreshes', () {
      final List<ValueItem<int>> items = fruitItems();
      final c = _shared(items);
      addTearDown(c.dispose);

      items.add(const ValueItem(label: 'Kiwi', value: 9));
      c.replaceSources(listItems: items, selectedItems: c.selectedItems);
      expect(_labels(c.filteredItems).last, 'Kiwi');
    });
  });

  group('selectedFirst re-pins after reset, clear and force (F12)', () {
    testWidgets('resetSelection, clear and forceMultipleSelection', (
      tester,
    ) async {
      const List<String> original = <String>[
        'Maçã',
        'Banana',
        'Uva',
        'abacaxi',
        'Pêra',
      ];
      final List<ValueItem<int>> mine = fruitItems();
      int updates = 0;
      final c = _shared(
        mine,
        sort: SortType.selectedFirst,
        onFilterUpdated: () => updates++,
      );
      addTearDown(c.dispose);

      c.toggle(mine[2]);
      expect(_labels(c.filteredItems), <String>[
        'Uva',
        'Maçã',
        'Banana',
        'abacaxi',
        'Pêra',
      ]);
      final int before = updates;
      c.resetSelection();
      expect(_labels(c.filteredItems), original);
      expect(updates, greaterThan(before));

      c
        ..toggle(mine[2])
        ..clear();
      expect(_labels(c.filteredItems), original);

      c.forceMultipleSelection(<ValueItem<int>>[mine[4]]);
      expect(_labels(c.filteredItems).first, 'Pêra');
      c.search('a');
      expect(_labels(c.filteredItems).first, 'Pêra');
      expect(_labels(mine), original);
    });
  });

  group('fresh instances replace stale ones (N42, multiple)', () {
    testWidgets('refresh hands back the fresh instances', (tester) async {
      int updates = 0;
      final List<ValueItem<_Product>> items = <ValueItem<_Product>>[
        ValueItem(label: 'Café', value: _Product(1, 10)),
        ValueItem(label: 'Chá', value: _Product(2, 10)),
      ];
      final c = MultipleSearchDropDownController<_Product>(
        listItems: items,
        addMode: false,
        deleteMode: false,
        onFilterUpdated: () => updates++,
      );
      addTearDown(c.dispose);
      int notified = 0;
      c.addListener(() => notified++);

      items[0] = ValueItem(label: 'Café', value: _Product(1, 12));
      c.refresh();
      expect(identical(c.filteredItems.first, items.first), isTrue);
      expect(updates, 0);
      expect(notified, 1);
      c.search('caf');
      expect(c.filteredItems.single.value!.price, 12);
    });
  });

  group('the query notifies even when the results stay equal (N29)', () {
    testWidgets('search on an empty list', (tester) async {
      final c = MultipleSearchDropDownController<int>(
        items: <ValueItem<int>>[],
        newValueItem: (s) => ValueItem(label: s, value: 0),
        onAddItem: (_) {},
        deleteMode: false,
      );
      addTearDown(c.dispose);
      int n = 0;
      c.addListener(() => n++);

      c.search('K');
      expect(c.canAdd, isTrue);
      expect(n, 1);
      c.search('Ki');
      expect(c.query, 'Ki');
      expect(n, 2);
      c.search('Ki');
      expect(n, 2);
    });
  });

  group('items: mode owns the selection (N61)', () {
    test('an unmodifiable const selectedItems is copied', () {
      final c = MultipleSearchDropDownController<int>(
        items: fruitItems(),
        selectedItems: const <ValueItem<int>>[],
        addMode: false,
        deleteMode: false,
      );
      addTearDown(c.dispose);

      c.toggle(c.listItems[1]);
      expect(c.selectedItems.map((e) => e.value), <int>[2]);
      c.forceMultipleSelection(<ValueItem<int>>[c.listItems[0]]);
      expect(c.selectedItems.map((e) => e.value), <int>[1]);
      c.resetSelection();
      expect(c.selectedItems, isEmpty);
    });

    test('a List.unmodifiable selection is copied and left untouched', () {
      final List<ValueItem<int>> initial = List<ValueItem<int>>.unmodifiable(
        <ValueItem<int>>[fruitItems()[0]],
      );
      final c = MultipleSearchDropDownController<int>(
        items: fruitItems(),
        selectedItems: initial,
        addMode: false,
        deleteMode: false,
      );
      addTearDown(c.dispose);

      c.toggle(c.listItems[1]);
      expect(c.selectedItems.map((e) => e.value), <int>[1, 2]);
      expect(initial, hasLength(1));
    });

    testWidgets('tapping a row with a const selection does not throw', (
      tester,
    ) async {
      final c = MultipleSearchDropDownController<int>(
        items: fruitItems(),
        selectedItems: const <ValueItem<int>>[],
        addMode: false,
        deleteMode: false,
      );
      await tester.pumpWidget(host(MultipleSearchDropDown<int>(controller: c)));
      await openMultiple(tester);
      await tester.tap(find.text('Banana'));
      await tester.pump();

      expect(tester.takeException(), isNull);
      expect(_labels(c.selectedItems), <String>['Banana']);
    });

    test('listItems: mode still shares the caller selection (7.x)', () {
      final List<ValueItem<int>> sel = <ValueItem<int>>[];
      final c = _shared(fruitItems(), selected: sel);
      addTearDown(c.dispose);

      c.toggle(c.listItems[0]);
      expect(identical(c.selectedItems, sel), isTrue);
      expect(sel, hasLength(1));
    });
  });
}
