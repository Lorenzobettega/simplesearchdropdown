// ignore_for_file: cascade_invocations
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:simple_search_dropdown/simple_search_dropdown.dart';

import '../support/harness.dart';

const ValueItem<int> _banana = ValueItem<int>(label: 'Banana', value: 2);
const ValueItem<int> _kiwi = ValueItem<int>(label: 'Kiwi', value: 10);

SearchDropDownController<T> _controller<T>(
  List<ValueItem<T>> items, {
  SortType sort = SortType.none,
  void Function()? onFilterUpdated,
  void Function(ValueItem<T>?)? updateSelectedItem,
  ValueItem<T>? initialSelectedItem,
}) => SearchDropDownController<T>(
  items: items,
  addMode: false,
  deleteMode: false,
  sort: sort,
  onFilterUpdated: onFilterUpdated,
  updateSelectedItem: updateSelectedItem,
  initialSelectedItem: initialSelectedItem,
);

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

List<ValueItem<_Product>> _products(int price) => <ValueItem<_Product>>[
  ValueItem(label: 'Café', value: _Product(1, price)),
  ValueItem(label: 'Chá', value: _Product(2, price)),
];

/// Counts every `==` and `hashCode` call (list compares and label lookups).
class _Probe extends ValueItem<int> {
  _Probe(int i) : super(label: 'Item $i', value: i);
  static int touches = 0;

  @override
  bool operator ==(Object other) {
    touches++;
    return super == other;
  }

  @override
  int get hashCode {
    touches++;
    return super.hashCode;
  }
}

void main() {
  group('updateListItems feeds filterList and typing (N53)', () {
    test('the new items show up', () {
      final List<ValueItem<int>> items = fruitItems();
      int calls = 0;
      final c = _controller(items, onFilterUpdated: () => calls++);
      addTearDown(c.dispose);

      items
        ..remove(_banana)
        ..add(_kiwi);
      c.updateListItems(items, false);
      c.filterList('');
      expect(labelsOf(c.filteredItems), <String>[
        'Maçã',
        'Uva',
        'abacaxi',
        'Pêra',
        'Kiwi',
      ]);
      expect(calls, 1);
      c.filterList('ban');
      expect(c.filteredItems, isEmpty);
      c.filterList('kiw');
      expect(labelsOf(c.filteredItems), <String>['Kiwi']);
    });

    test('a longer query does not narrow results of the old list', () {
      final List<ValueItem<int>> items = fruitItems();
      final c = _controller(items);
      addTearDown(c.dispose);

      c.filterList('a');
      expect(labelsOf(c.filteredItems), contains('abacaxi'));
      items.removeWhere((e) => e.label == 'abacaxi');
      c.updateListItems(items, false);
      c.filterList('ab');
      expect(c.filteredItems, isEmpty);
    });

    test('A-Z sorts the new items but not the list passed in', () {
      final c = _controller(fruitItems(), sort: SortType.alphabetical);
      addTearDown(c.dispose);

      const ValueItem<int> aaa = ValueItem<int>(label: 'Aaa', value: 99);
      final List<ValueItem<int>> next = fruitItems()..add(aaa);
      c.updateListItems(next, false);
      c.filterList('');
      expect(labelsOf(c.filteredItems).first, 'Aaa');
      expect(next.last, aaa);
    });

    test('typing in the open view filters the new items', () {
      final c = _controller(fruitItems());
      addTearDown(c.dispose);

      c.onSearchOpen();
      c.updateListItems(fruitItems()..add(_kiwi), false);
      c.localSearchController.text = 'kiw';
      expect(labelsOf(c.filteredItems), <String>['Kiwi']);
    });
  });

  group('fresh instances replace stale ones (N42)', () {
    test('updateListItems hands back the fresh instances', () {
      int updates = 0;
      final c = SearchDropDownController<_Product>(
        items: _products(10),
        addMode: false,
        deleteMode: false,
        onFilterUpdated: () => updates++,
      );
      addTearDown(c.dispose);
      int fires = 0;
      c.results.addListener(() => fires++);

      c.updateListItems(_products(12), false);
      expect(identical(c.filteredItems.first, c.items.first), isTrue);
      expect(c.filteredItems.first.value!.price, 12);
      // Same results: no onFilterUpdated (7.x), but the view is refreshed.
      expect(updates, 0);
      expect(fires, 1);

      c.onSearchOpen();
      c.filterList('Caf');
      expect(c.filteredItems.single.value!.price, 12);
    });

    test('a swap of fresh instances keeps the keyboard highlight', () {
      final List<ValueItem<_Product>> items = _products(10);
      final c = _controller<_Product>(items);
      addTearDown(c.dispose);

      c.onSearchOpen();
      c.highlightNext();
      expect(c.highlightedIndex, 0);
      items[1] = ValueItem(label: 'Chá', value: _Product(2, 12));
      c.updateListItems(items, false);
      expect(c.filteredItems[1].value!.price, 12);
      expect(c.highlightedIndex, 0);
    });

    testWidgets('tapping a row after a same-label refresh selects the fresh '
        'item', (tester) async {
      final List<ValueItem<_Product>?> selected = <ValueItem<_Product>?>[];
      final c = SearchDropDownController<_Product>(
        items: _products(10),
        addMode: false,
        deleteMode: false,
        updateSelectedItem: selected.add,
      );
      await tester.pumpWidget(host(SearchDropDown<_Product>(controller: c)));
      await openSingle(tester);

      c.updateListItems(_products(12), false);
      await tester.pump();
      await tester.tap(find.text('Café').last);
      await tester.pumpAndSettle();

      expect(selected.last!.value!.price, 12);
      expect(identical(c.selectedItem, c.items.first), isTrue);
    });
  });

  group('caret, selection and IME changes do not re-filter (F15)', () {
    test('only a text change filters', () {
      final List<ValueItem<int>> items = <ValueItem<int>>[
        for (int i = 0; i < 1000; i++) _Probe(i),
      ];
      final c = _controller(items, initialSelectedItem: items[500]);
      addTearDown(c.dispose);
      final SearchController sc = c.localSearchController;
      void caretOnly() {
        _Probe.touches = 0;
        final int len = sc.text.length;
        sc.selection = TextSelection.collapsed(offset: len);
        sc.selection = const TextSelection.collapsed(offset: 0);
        if (len > 0) {
          sc.value = sc.value.copyWith(
            selection: TextSelection(baseOffset: 0, extentOffset: len),
            composing: TextRange(start: 0, end: len),
          );
        }
        expect(_Probe.touches, 0, reason: 'text "${sc.text}" unchanged');
      }

      c.onSearchOpen();
      expect(c.filteredItems, hasLength(1000));
      caretOnly();
      sc.text = 'Item 1';
      expect(c.filteredItems, hasLength(111));
      caretOnly();
      sc.text = '';
      expect(c.filteredItems, hasLength(1000));
      caretOnly();
      sc.text = 'Item 99';
      expect(c.filteredItems, hasLength(11));
    });

    test('the same query after a change to the list still filters', () {
      final List<ValueItem<int>> items = fruitItems();
      final c = _controller(items);
      addTearDown(c.dispose);

      c.filterList('k');
      expect(c.filteredItems, isEmpty);
      c.updateListItems(items..add(_kiwi), false);
      c.filterList('k');
      expect(labelsOf(c.filteredItems), <String>['Kiwi']);
    });
  });

  group('explicit rebuilds always apply (N53/N42 guards)', () {
    test('sortBy reorders even when the instances are the same', () {
      final List<ValueItem<int>> items = <ValueItem<int>>[
        const ValueItem(label: 'b', value: 2),
        const ValueItem(label: 'a', value: 1),
      ];
      final c = SearchDropDownController<int>(
        items: items,
        addMode: false,
        deleteMode: false,
      );
      addTearDown(c.dispose);

      c.sortBy(SortType.alphabetical);
      expect(labelsOf(c.filteredItems), <String>['a', 'b']);
      c.sortBy(SortType.reverseAlphabetical);
      expect(labelsOf(c.filteredItems), <String>['b', 'a']);
    });
  });
}
