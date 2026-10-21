// Characterization tests for SearchDropDownController + SearchDropDown
// (single selection): filtering, sorting and list data management.
//
// Written against v7.8.0, these tests now lock the 8.0 behaviour; "(8.0)"
// marks a deliberate change from 7.x. Tests tagged 'B<n>' are regression
// tests for a 7.x bug fixed in 8.0.
//
// Note: tests that only need the controller's data logic drive it through
// the public controller API (onSearchOpen + localSearchController.text is
// exactly what typing into the open view does). Anything that calls
// selectItem (forceSelection) needs a mounted SearchDropDown, because
// SearchController.isOpen asserts that the controller is attached.

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

const List<String> _fruitAZ = <String>[
  'abacaxi',
  'Banana',
  'Maçã',
  'Pêra',
  'Uva',
];

// D2 (8.0): ordering ignores case and accents.
const List<String> _fruitZA = <String>[
  'Uva',
  'Pêra',
  'Maçã',
  'Banana',
  'abacaxi',
];

const ValueItem<int> _banana = ValueItem<int>(label: 'Banana', value: 2);
const ValueItem<int> _kiwi = ValueItem<int>(label: 'Kiwi', value: 10);
const ValueItem<int> _figo = ValueItem<int>(label: 'Figo', value: 11);

SearchDropDownController<int> _controller(
  List<ValueItem<int>> items, {
  ValueItem<int>? initialSelectedItem,
  SortType sort = SortType.none,
  bool showClearIcon = false,
  bool latinize = true,
  bool caseSensitive = false,
  bool trim = true,
  void Function()? onFilterUpdated,
  void Function(ValueItem<int>?)? updateSelectedItem,
}) => SearchDropDownController<int>(
  items: items,
  addMode: false,
  deleteMode: false,
  initialSelectedItem: initialSelectedItem,
  sort: sort,
  showClearIcon: showClearIcon,
  latinize: latinize,
  caseSensitive: caseSensitive,
  trim: trim,
  onFilterUpdated: onFilterUpdated,
  updateSelectedItem: updateSelectedItem,
);

List<ValueItem<int>> _newList() => <ValueItem<int>>[_kiwi, _figo];

Future<void> _pump(
  WidgetTester tester,
  SearchDropDownController<int> c, {
  Key? key,
}) => tester.pumpWidget(host(SearchDropDown<int>(key: key, controller: c)));

Future<void> _type(WidgetTester tester, String text) async {
  await tester.enterText(focusedField(), text);
  await tester.pumpAndSettle();
}

/// Text currently displayed by the closed search bar.
String _barText(WidgetTester tester) => tester
    .widget<EditableText>(
      find.descendant(
        of: find.byType(SearchBar).first,
        matching: find.byType(EditableText),
      ),
    )
    .controller
    .text;

/// Visibility of the clear button rendered in the closed search bar.
bool _barClearVisible(WidgetTester tester) => tester
    .widget<ClearButton>(
      find.descendant(
        of: find.byType(SearchBar).first,
        matching: find.byType(ClearButton),
      ),
    )
    .visible;

/// Simulates typing into the open view without a widget tree: this is the
/// same listener path the SearchAnchor text field drives.
void _typeViaController(SearchDropDownController<int> c, String text) {
  c.localSearchController.text = text;
}

void main() {
  group('filter: substring match (default options)', () {
    testWidgets('matches anywhere in the label, keeps list order', (
      tester,
    ) async {
      final c = _controller(fruitItems());
      await _pump(tester, c);
      await openSingle(tester);

      // Only the tiles that fit in the view are built (lazy list), so the
      // full list is checked through filteredItems.
      expect(labelsOf(c.filteredItems), _fruitOrder);

      await _type(tester, 'ca');
      expect(labelsOf(c.filteredItems), <String>['Maçã', 'abacaxi']);
      expect(visualRowLabels<int>(tester), <String>['Maçã', 'abacaxi']);

      await _type(tester, 'cax');
      expect(labelsOf(c.filteredItems), <String>['abacaxi']);
      expect(visualRowLabels<int>(tester), <String>['abacaxi']);
    });

    testWidgets('no match shows no tiles (addMode false)', (tester) async {
      final c = _controller(fruitItems());
      await _pump(tester, c);
      await openSingle(tester);

      await _type(tester, 'xyz');
      expect(c.filteredItems, isEmpty);
      expect(visualRowLabels<int>(tester), isEmpty);
    });
  });

  group('filter: latinize (accent-insensitive, default true)', () {
    testWidgets('default: accents ignored on both query and labels', (
      tester,
    ) async {
      final c = _controller(fruitItems());
      await _pump(tester, c);
      await openSingle(tester);

      await _type(tester, 'maca');
      expect(labelsOf(c.filteredItems), <String>['Maçã']);
      expect(visualRowLabels<int>(tester), <String>['Maçã']);

      await _type(tester, 'PERA');
      expect(labelsOf(c.filteredItems), <String>['Pêra']);

      await _type(tester, 'maçã');
      expect(labelsOf(c.filteredItems), <String>['Maçã']);
    });

    testWidgets('latinize false: accents are significant', (tester) async {
      final c = _controller(fruitItems(), latinize: false);
      await _pump(tester, c);
      await openSingle(tester);

      await _type(tester, 'maca');
      expect(c.filteredItems, isEmpty);

      await _type(tester, 'maçã');
      expect(labelsOf(c.filteredItems), <String>['Maçã']);

      // Case folding still applies to accented characters.
      await _type(tester, 'MAÇÃ');
      expect(labelsOf(c.filteredItems), <String>['Maçã']);

      await _type(tester, 'pera');
      expect(c.filteredItems, isEmpty);

      await _type(tester, 'pêra');
      expect(labelsOf(c.filteredItems), <String>['Pêra']);
    });
  });

  group('filter: caseSensitive (default false)', () {
    testWidgets('default: case ignored', (tester) async {
      final c = _controller(fruitItems());
      await _pump(tester, c);
      await openSingle(tester);

      await _type(tester, 'BAN');
      expect(labelsOf(c.filteredItems), <String>['Banana']);

      await _type(tester, 'ABACAXI');
      expect(labelsOf(c.filteredItems), <String>['abacaxi']);
    });

    testWidgets('caseSensitive true: case must match, latinize still applies', (
      tester,
    ) async {
      final c = _controller(fruitItems(), caseSensitive: true);
      await _pump(tester, c);
      await openSingle(tester);

      await _type(tester, 'ban');
      expect(c.filteredItems, isEmpty);

      await _type(tester, 'Ban');
      expect(labelsOf(c.filteredItems), <String>['Banana']);

      await _type(tester, 'Maca');
      expect(labelsOf(c.filteredItems), <String>['Maçã']);

      await _type(tester, 'maca');
      expect(c.filteredItems, isEmpty);
    });
  });

  group('filter: trim (default true)', () {
    testWidgets('default: leading/trailing whitespace of the query ignored', (
      tester,
    ) async {
      final c = _controller(fruitItems());
      await _pump(tester, c);
      await openSingle(tester);

      await _type(tester, '  ban  ');
      expect(labelsOf(c.filteredItems), <String>['Banana']);

      // A whitespace-only query normalizes to '' and matches everything.
      await _type(tester, '   ');
      expect(labelsOf(c.filteredItems), _fruitOrder);
    });

    testWidgets('trim false: surrounding whitespace is significant', (
      tester,
    ) async {
      final c = _controller(fruitItems(), trim: false);
      await _pump(tester, c);
      await openSingle(tester);

      await _type(tester, ' ban');
      expect(c.filteredItems, isEmpty);

      await _type(tester, 'ana');
      expect(labelsOf(c.filteredItems), <String>['Banana']);

      await _type(tester, '   ');
      expect(c.filteredItems, isEmpty);
    });

    testWidgets('trim false: inner whitespace still matches as substring', (
      tester,
    ) async {
      final c = _controller(numberedItems(12), trim: false);
      await _pump(tester, c);
      await openSingle(tester);

      await _type(tester, 'm 1');
      expect(labelsOf(c.filteredItems), <String>[
        'Item 1',
        'Item 10',
        'Item 11',
      ]);
    });
  });

  group('filter: suppressed until the search view opens', () {
    test('changing the text before onSearchOpen does not filter', () {
      final c = _controller(fruitItems());
      addTearDown(c.dispose);

      _typeViaController(c, 'ban');
      expect(labelsOf(c.filteredItems), _fruitOrder);

      // Opening applies the current text once.
      c.onSearchOpen();
      expect(labelsOf(c.filteredItems), <String>['Banana']);
    });

    test(
      'after onSearchOpen text changes filter immediately (no debounce)',
      () {
        final c = _controller(fruitItems());
        addTearDown(c.dispose);

        c.onSearchOpen();
        expect(labelsOf(c.filteredItems), _fruitOrder);
        _typeViaController(c, 'uva');
        expect(labelsOf(c.filteredItems), <String>['Uva']);
      },
    );
  });

  group('filter: filterList() direct API', () {
    test('filters from the full list, empty text restores all', () {
      final c = _controller(fruitItems());
      addTearDown(c.dispose);

      c.filterList('ca');
      expect(labelsOf(c.filteredItems), <String>['Maçã', 'abacaxi']);
      c.filterList('ban');
      expect(labelsOf(c.filteredItems), <String>['Banana']);
      c.filterList('');
      expect(labelsOf(c.filteredItems), _fruitOrder);
    });

    test('ignores accents and case on both sides', () {
      final c = _controller(const <ValueItem<int>>[
        ValueItem(label: 'São Paulo', value: 1),
        ValueItem(label: 'Sao Tome', value: 2),
        ValueItem(label: 'Porto Alegre', value: 3),
      ]);
      addTearDown(c.dispose);

      c.filterList('sao');
      expect(labelsOf(c.filteredItems), <String>['São Paulo', 'Sao Tome']);
      c.filterList('SÃO');
      expect(labelsOf(c.filteredItems), <String>['São Paulo', 'Sao Tome']);
      c.filterList('PORTO');
      expect(labelsOf(c.filteredItems), <String>['Porto Alegre']);
      c.filterList('');
      expect(c.filteredItems, hasLength(3));
    });

    test('honours normalization options', () {
      final c = _controller(fruitItems(), caseSensitive: true);
      addTearDown(c.dispose);

      c.filterList('ban');
      expect(c.filteredItems, isEmpty);
      c.filterList('  Ban ');
      expect(labelsOf(c.filteredItems), <String>['Banana']);
    });

    test(
      'empty text shows everything and reports the change (8.0, B13 class)',
      () {
        var calls = 0;
        final c = _controller(fruitItems(), onFilterUpdated: () => calls++);
        addTearDown(c.dispose);

        c.filterList('ban');
        expect(calls, 1);
        c.filterList('');
        expect(labelsOf(c.filteredItems), _fruitOrder);
        expect(calls, 2);
      },
    );
  });

  group('filter: incremental refine and widen', () {
    testWidgets('typing more refines, deleting widens back', (tester) async {
      final c = _controller(fruitItems());
      await _pump(tester, c);
      await openSingle(tester);

      await _type(tester, 'a');
      expect(labelsOf(c.filteredItems), _fruitOrder);

      await _type(tester, 'an');
      expect(labelsOf(c.filteredItems), <String>['Banana']);
      expect(visualRowLabels<int>(tester), <String>['Banana']);

      await _type(tester, 'a');
      expect(labelsOf(c.filteredItems), _fruitOrder);
      expect(visualRowLabels<int>(tester).first, 'Maçã');

      // Replacing (non-prefix change) re-filters from the full list.
      await _type(tester, 'b');
      expect(labelsOf(c.filteredItems), <String>['Banana', 'abacaxi']);

      await _type(tester, '');
      expect(labelsOf(c.filteredItems), _fruitOrder);
    });

    testWidgets('numbered items: refine to one, widen back to three', (
      tester,
    ) async {
      final c = _controller(numberedItems(12));
      await _pump(tester, c);
      await openSingle(tester);

      await _type(tester, '1');
      expect(labelsOf(c.filteredItems), <String>[
        'Item 1',
        'Item 10',
        'Item 11',
      ]);
      await _type(tester, '11');
      expect(labelsOf(c.filteredItems), <String>['Item 11']);
      await _type(tester, '1');
      expect(labelsOf(c.filteredItems), <String>[
        'Item 1',
        'Item 10',
        'Item 11',
      ]);
      await _type(tester, '');
      expect(c.filteredItems, hasLength(12));
    });
  });

  group('filter: onFilterUpdated callback', () {
    testWidgets('fires only when the result set changes', (tester) async {
      var calls = 0;
      final c = _controller(fruitItems(), onFilterUpdated: () => calls++);
      await _pump(tester, c);
      await openSingle(tester);

      // Opening with empty text uses the reset path: no callback.
      expect(calls, 0);

      await _type(tester, 'an');
      expect(calls, 1);

      // Same result ([Banana]) -> no callback.
      await _type(tester, 'ana');
      expect(calls, 1);

      // Some -> none.
      await _type(tester, 'zzz');
      expect(calls, 2);

      // None -> none.
      await _type(tester, 'zzzz');
      expect(calls, 2);

      // None -> all.
      await _type(tester, '');
      expect(calls, 3);
    });

    testWidgets('filteredItems is already updated when the callback runs', (
      tester,
    ) async {
      final snapshots = <List<String>>[];
      late final SearchDropDownController<int> c;
      c = _controller(
        fruitItems(),
        onFilterUpdated: () => snapshots.add(labelsOf(c.filteredItems)),
      );
      await _pump(tester, c);
      await openSingle(tester);

      await _type(tester, 'uva');
      expect(snapshots, <List<String>>[
        <String>['Uva'],
      ]);
    });

    test('fires when the length is equal but the first item differs', () {
      var calls = 0;
      final c = _controller(<ValueItem<int>>[
        const ValueItem(label: 'AX', value: 1),
        const ValueItem(label: 'BX', value: 2),
        const ValueItem(label: 'AY', value: 3),
        const ValueItem(label: 'BY', value: 4),
      ], onFilterUpdated: () => calls++);
      addTearDown(c.dispose);

      c.onSearchOpen();
      _typeViaController(c, 'x');
      expect(labelsOf(c.filteredItems), <String>['AX', 'BX']);
      expect(calls, 1);
      _typeViaController(c, 'y');
      expect(labelsOf(c.filteredItems), <String>['AY', 'BY']);
      expect(calls, 2);
    });

    test('updateListItems reports the new results (8.0)', () {
      var calls = 0;
      final c = _controller(fruitItems(), onFilterUpdated: () => calls++);
      addTearDown(c.dispose);

      c.updateListItems(_newList(), false);
      expect(labelsOf(c.filteredItems), <String>['Kiwi', 'Figo']);
      expect(calls, 1);
    });

    test(
      'B13: fires when only a middle element changes',
      () {
        var calls = 0;
        final c = _controller(<ValueItem<int>>[
          const ValueItem(label: 'AXY', value: 1),
          const ValueItem(label: 'BX', value: 2),
          const ValueItem(label: 'BY', value: 3),
          const ValueItem(label: 'CXY', value: 4),
        ], onFilterUpdated: () => calls++);
        addTearDown(c.dispose);

        c.onSearchOpen();
        _typeViaController(c, 'x');
        expect(labelsOf(c.filteredItems), <String>['AXY', 'BX', 'CXY']);
        expect(calls, 1);

        // Same length, same first, same last; only the middle differs.
        _typeViaController(c, 'y');
        expect(labelsOf(c.filteredItems), <String>['AXY', 'BY', 'CXY']);
        expect(calls, 2);
      }, // B13: fixed in 8.0
    );
  });

  group('sort: none keeps original order', () {
    test('filteredItems and listItems keep insertion order', () {
      final items = fruitItems();
      final c = _controller(items);
      addTearDown(c.dispose);

      expect(labelsOf(c.filteredItems), _fruitOrder);
      expect(labelsOf(items), _fruitOrder);
    });

    test('works with an unmodifiable caller list', () {
      final c = _controller(List<ValueItem<int>>.unmodifiable(fruitItems()));
      addTearDown(c.dispose);

      expect(labelsOf(c.filteredItems), _fruitOrder);
    });
  });

  group('sort: alphabetical A-Z', () {
    test('A-Z ignores case and accents (D2) and sorts only the copy', () {
      final items = fruitItems();
      final c = _controller(items, sort: SortType.alphabetical);
      addTearDown(c.dispose);

      // 8.0 (D2): case and accents are ignored ('abacaxi' first).
      expect(labelsOf(c.filteredItems), _fruitAZ);
      expect(identical(c.items, items), isFalse);
      expect(labelsOf(c.items), _fruitAZ);
      expect(labelsOf(items), _fruitOrder);
    });

    test('accented characters sort with their base letter (D2, 8.0)', () {
      final c = _controller(<ValueItem<int>>[
        const ValueItem(label: 'Pêra', value: 1),
        const ValueItem(label: 'Pzz', value: 2),
        const ValueItem(label: 'Pera', value: 3),
      ], sort: SortType.alphabetical);
      addTearDown(c.dispose);

      expect(labelsOf(c.filteredItems), <String>['Pera', 'Pêra', 'Pzz']);
    });

    test('filter results keep the sorted order', () {
      final c = _controller(fruitItems(), sort: SortType.alphabetical);
      addTearDown(c.dispose);

      c.onSearchOpen();
      _typeViaController(c, 'a');
      expect(labelsOf(c.filteredItems), _fruitAZ);
      _typeViaController(c, 'ca');
      expect(labelsOf(c.filteredItems), <String>['abacaxi', 'Maçã']);
    });

    test('caseSensitive/latinize do not change the A-Z order (N24, D2)', () {
      final items = fruitItems();
      final c = _controller(
        items,
        sort: SortType.alphabetical,
        caseSensitive: true,
        latinize: false,
      );
      addTearDown(c.dispose);

      expect(labelsOf(c.filteredItems), _fruitAZ);
      expect(labelsOf(c.items), _fruitAZ);
    });

    test('an unmodifiable caller list is sorted on the copy', () {
      final c = _controller(
        List<ValueItem<int>>.unmodifiable(fruitItems()),
        sort: SortType.alphabetical,
      );
      addTearDown(c.dispose);

      expect(labelsOf(c.filteredItems), _fruitAZ);
    });

    test('digits compare as text, like 7.x (D2: Item 10 before Item 2)', () {
      final items = <ValueItem<int>>[
        const ValueItem(label: 'Item 2', value: 2),
        const ValueItem(label: 'Item 10', value: 10),
        const ValueItem(label: 'Item 1', value: 1),
      ];
      final c = _controller(items, sort: SortType.alphabetical);
      addTearDown(c.dispose);

      expect(labelsOf(c.filteredItems), <String>[
        'Item 1',
        'Item 10',
        'Item 2',
      ]);
      expect(labelsOf(c.items), <String>['Item 1', 'Item 10', 'Item 2']);
    });
  });

  group('sort: reverseAlphabetical Z-A', () {
    test('Z-A ignores case and accents (D2) and sorts only the copy', () {
      final items = fruitItems();
      final c = _controller(items, sort: SortType.reverseAlphabetical);
      addTearDown(c.dispose);

      expect(labelsOf(c.filteredItems), _fruitZA);
      expect(labelsOf(c.items), _fruitZA);
      expect(labelsOf(items), _fruitOrder);
    });

    test('filter results keep the sorted order', () {
      final c = _controller(fruitItems(), sort: SortType.reverseAlphabetical);
      addTearDown(c.dispose);

      c.onSearchOpen();
      _typeViaController(c, 'ca');
      expect(labelsOf(c.filteredItems), <String>['Maçã', 'abacaxi']);
    });
  });

  group('sort: selectedFirst moves initialSelectedItem first', () {
    test('selected item moved to index 0, rest keep order, caller kept', () {
      final items = fruitItems();
      final c = _controller(
        items,
        initialSelectedItem: const ValueItem<int>(label: 'Uva', value: 3),
        sort: SortType.selectedFirst,
      );
      addTearDown(c.dispose);

      const expected = <String>['Uva', 'Maçã', 'Banana', 'abacaxi', 'Pêra'];
      expect(labelsOf(c.filteredItems), expected);
      expect(labelsOf(c.items), expected);
      expect(labelsOf(items), _fruitOrder);
    });

    test('matches by value equality and inserts the selected instance', () {
      final items = fruitItems();
      final uva = const ValueItem<int>(label: 'Uva', value: 3).copyWith();
      expect(identical(uva, items[2]), isFalse);

      final c = _controller(
        items,
        initialSelectedItem: uva,
        sort: SortType.selectedFirst,
      );
      addTearDown(c.dispose);

      expect(labelsOf(c.items).first, 'Uva');
      expect(c.items, hasLength(5));
      expect(identical(c.items.first, uva), isTrue);
    });

    test('no initialSelectedItem: order unchanged', () {
      final items = fruitItems();
      final c = _controller(items, sort: SortType.selectedFirst);
      addTearDown(c.dispose);

      expect(labelsOf(c.filteredItems), _fruitOrder);
      expect(labelsOf(items), _fruitOrder);
    });

    test(
      'initialSelectedItem not in list: order unchanged, still selected',
      () {
        final items = fruitItems();
        final c = _controller(
          items,
          initialSelectedItem: _kiwi,
          sort: SortType.selectedFirst,
        );
        addTearDown(c.dispose);

        expect(labelsOf(c.filteredItems), _fruitOrder);
        expect(c.selectedItem, _kiwi);
      },
    );
  });

  group('sort: sortBy() public method', () {
    test('sorts the copy and refreshes filteredItems immediately', () {
      final items = fruitItems();
      final c = _controller(items);
      addTearDown(c.dispose);

      c.sortBy(SortType.reverseAlphabetical);
      expect(labelsOf(c.items), _fruitZA);
      expect(labelsOf(items), _fruitOrder);
      // 8.0: filteredItems follows immediately.
      expect(labelsOf(c.filteredItems), _fruitZA);
      c.onSearchOpen();
      expect(labelsOf(c.filteredItems), _fruitZA);
    });

    test('sort is re-applied by updateListItems', () {
      final c = _controller(fruitItems(), sort: SortType.alphabetical);
      addTearDown(c.dispose);

      final newList = <ValueItem<int>>[
        _kiwi,
        _figo,
        const ValueItem(label: 'Abacate', value: 12),
      ];
      c.updateListItems(newList, false);
      expect(labelsOf(c.filteredItems), <String>['Abacate', 'Figo', 'Kiwi']);
      expect(labelsOf(c.items), <String>['Abacate', 'Figo', 'Kiwi']);
      // The argument list itself is copied, not sorted.
      expect(labelsOf(newList), <String>['Kiwi', 'Figo', 'Abacate']);
    });
  });

  group('initialSelectedItem: bar text, selection and clear icon', () {
    testWidgets('label shown in the bar and selectedItem set', (tester) async {
      final selected = <ValueItem<int>?>[];
      final c = _controller(
        fruitItems(),
        initialSelectedItem: _banana,
        updateSelectedItem: selected.add,
      );
      await _pump(tester, c);

      expect(_barText(tester), 'Banana');
      expect(c.selectedItem, _banana);
      expect(c.localSearchController.text, 'Banana');
      // Construction does not notify updateSelectedItem.
      expect(selected, isEmpty);
      // filteredItems still holds every item until the view opens.
      expect(labelsOf(c.filteredItems), _fruitOrder);
    });

    testWidgets('showClearIcon true -> clearVisible and bar clear button', (
      tester,
    ) async {
      final c = _controller(
        fruitItems(),
        initialSelectedItem: _banana,
        showClearIcon: true,
      );
      await _pump(tester, c);

      expect(c.clearVisible, isTrue);
      expect(_barClearVisible(tester), isTrue);
    });

    testWidgets('showClearIcon: false on the controller -> clear hidden', (
      tester,
    ) async {
      // _controller passes showClearIcon: false (the controller default is
      // true).
      final c = _controller(fruitItems(), initialSelectedItem: _banana);
      await _pump(tester, c);

      expect(c.clearVisible, isFalse);
      expect(_barClearVisible(tester), isFalse);
    });

    testWidgets(
      'no initialSelectedItem -> clear hidden even if showClearIcon',
      (tester) async {
        final c = _controller(fruitItems(), showClearIcon: true);
        await _pump(tester, c);

        expect(c.selectedItem, isNull);
        expect(c.clearVisible, isFalse);
        expect(_barClearVisible(tester), isFalse);
        expect(_barText(tester), '');
      },
    );

    testWidgets('opening the view lists every item (D1, 8.0)', (tester) async {
      var calls = 0;
      final c = _controller(
        fruitItems(),
        initialSelectedItem: _banana,
        onFilterUpdated: () => calls++,
      );
      await _pump(tester, c);
      await openSingle(tester);

      expect(labelsOf(c.filteredItems), _fruitOrder);
      expect(visualRowLabels<int>(tester), contains('Banana'));
      expect(calls, 0);
    });

    test('ignored when listItems is empty', () {
      final c = _controller(
        <ValueItem<int>>[],
        initialSelectedItem: _banana,
        showClearIcon: true,
      );
      addTearDown(c.dispose);

      expect(c.selectedItem, isNull);
      expect(c.localSearchController.text, '');
      expect(c.clearVisible, isFalse);
    });

    test('accepted even when not contained in listItems', () {
      final c = _controller(fruitItems(), initialSelectedItem: _kiwi);
      addTearDown(c.dispose);

      expect(c.selectedItem, _kiwi);
      expect(c.localSearchController.text, 'Kiwi');
    });
  });

  group('forceSelection: select by normalized label', () {
    testWidgets('selects by case-insensitive label and notifies', (
      tester,
    ) async {
      final selected = <ValueItem<int>?>[];
      final c = _controller(fruitItems(), updateSelectedItem: selected.add);
      await _pump(tester, c);

      c.forceSelection('banana');
      await tester.pump();

      expect(c.selectedItem, _banana);
      expect(_barText(tester), 'Banana');
      expect(selected, <ValueItem<int>?>[_banana]);
    });

    testWidgets('label is normalized with trim + latinize + lowercase', (
      tester,
    ) async {
      final c = _controller(fruitItems());
      await _pump(tester, c);

      c.forceSelection('  MACA ');
      await tester.pump();

      expect(c.selectedItem?.label, 'Maçã');
      expect(_barText(tester), 'Maçã');
    });

    testWidgets('unknown label is a no-op', (tester) async {
      final selected = <ValueItem<int>?>[];
      final c = _controller(
        fruitItems(),
        initialSelectedItem: _banana,
        updateSelectedItem: selected.add,
      );
      await _pump(tester, c);

      c.forceSelection('kiwi');
      await tester.pump();

      expect(c.selectedItem, _banana);
      expect(_barText(tester), 'Banana');
      expect(selected, isEmpty);
    });

    testWidgets('respects caseSensitive', (tester) async {
      final c = _controller(fruitItems(), caseSensitive: true);
      await _pump(tester, c);

      c.forceSelection('banana');
      expect(c.selectedItem, isNull);

      c.forceSelection('Banana');
      expect(c.selectedItem, _banana);
    });

    testWidgets('sets clearVisible when showClearIcon', (tester) async {
      final c = _controller(fruitItems(), showClearIcon: true);
      await _pump(tester, c);
      expect(_barClearVisible(tester), isFalse);

      c.forceSelection('uva');
      expect(c.clearVisible, isTrue);
    });

    testWidgets('an exact label wins over a normalized duplicate (8.0)', (
      tester,
    ) async {
      final c = _controller(<ValueItem<int>>[
        const ValueItem(label: 'Maca', value: 10),
        const ValueItem(label: 'Maçã', value: 1),
      ]);
      await _pump(tester, c);

      // 7.x picked the later 'Maçã' even for the exact label 'Maca'.
      c.forceSelection('Maca');
      expect(c.selectedItem?.value, 10);
      c.forceSelection('Maçã');
      expect(c.selectedItem?.value, 1);
      // Without an exact match the first normalized match wins.
      c.forceSelection('MACA');
      expect(c.selectedItem?.value, 10);
    });

    testWidgets('while the view is open it closes the view', (tester) async {
      final c = _controller(fruitItems());
      await _pump(tester, c);
      await openSingle(tester);
      expect(c.localSearchController.isOpen, isTrue);

      c.forceSelection('uva');
      await tester.pumpAndSettle();

      expect(c.localSearchController.isOpen, isFalse);
      expect(c.selectedItem?.label, 'Uva');
      expect(_barText(tester), 'Uva');
    });
  });

  group('updateListItems: replace items and reset semantics', () {
    test("replaces the controller's items; the first list is untouched", () {
      final items = fruitItems();
      final c = _controller(items);
      addTearDown(c.dispose);

      final newList = _newList();
      c.updateListItems(newList, false);

      expect(identical(c.items, items), isFalse);
      expect(labelsOf(items), _fruitOrder);
      expect(labelsOf(c.items), <String>['Kiwi', 'Figo']);
      expect(labelsOf(c.filteredItems), <String>['Kiwi', 'Figo']);

      // The argument is copied: later changes to it are not reflected.
      newList.add(const ValueItem(label: 'Lima', value: 12));
      expect(labelsOf(c.items), <String>['Kiwi', 'Figo']);
    });

    test('shouldReset false, no selection: text kept, no notification', () {
      final selected = <ValueItem<int>?>[];
      final c = _controller(fruitItems(), updateSelectedItem: selected.add);
      addTearDown(c.dispose);

      c.localSearchController.text = 'Ban';
      c.updateListItems(_newList(), false);

      expect(c.localSearchController.text, 'Ban');
      expect(selected, isEmpty);
      // The kept text is not re-applied: every new item is listed.
      expect(labelsOf(c.filteredItems), <String>['Kiwi', 'Figo']);
    });

    test('shouldReset true with A-Z: the new list is sorted and the '
        'selection reset', () {
      final selected = <ValueItem<int>?>[];
      final c = _controller(
        fruitItems(),
        sort: SortType.alphabetical,
        initialSelectedItem: _banana,
        updateSelectedItem: selected.add,
      );
      addTearDown(c.dispose);
      expect(labelsOf(c.filteredItems), _fruitAZ);
      expect(c.selectedItem, _banana);

      c.updateListItems(<ValueItem<int>>[_kiwi, _figo], true);

      expect(labelsOf(c.items), <String>['Figo', 'Kiwi']);
      expect(labelsOf(c.filteredItems), <String>['Figo', 'Kiwi']);
      expect(c.selectedItem, isNull);
      expect(c.localSearchController.text, '');
      expect(selected, <ValueItem<int>?>[null]);
    });

    test('shouldReset true: text cleared and updateSelectedItem(null)', () {
      final selected = <ValueItem<int>?>[];
      final c = _controller(fruitItems(), updateSelectedItem: selected.add);
      addTearDown(c.dispose);

      c.localSearchController.text = 'Ban';
      c.updateListItems(_newList(), true);

      expect(c.localSearchController.text, '');
      expect(c.selectedItem, isNull);
      expect(selected, <ValueItem<int>?>[null]);
    });

    testWidgets('a selection bypasses shouldReset false (reset anyway)', (
      tester,
    ) async {
      final selected = <ValueItem<int>?>[];
      final c = _controller(
        fruitItems(),
        showClearIcon: true,
        updateSelectedItem: selected.add,
      );
      await _pump(tester, c);
      c.forceSelection('banana');
      expect(c.clearVisible, isTrue);

      c.updateListItems(_newList(), false);
      await tester.pump();

      expect(c.selectedItem, isNull);
      expect(c.clearVisible, isFalse);
      expect(_barText(tester), '');
      expect(selected, <ValueItem<int>?>[_banana, null]);
      expect(labelsOf(c.filteredItems), <String>['Kiwi', 'Figo']);
    });

    testWidgets('lookup caches rebuilt: new labels found, old ones gone', (
      tester,
    ) async {
      final c = _controller(fruitItems());
      await _pump(tester, c);

      c
        ..updateListItems(_newList(), false)
        ..forceSelection('banana');
      expect(c.selectedItem, isNull);

      c.forceSelection('kiwi');
      expect(c.selectedItem, _kiwi);
    });

    testWidgets('new items are filterable after the update', (tester) async {
      final c = _controller(fruitItems());
      await _pump(tester, c);

      c.updateListItems(_newList(), false);
      await openSingle(tester);
      expect(visualRowLabels<int>(tester), <String>['Kiwi', 'Figo']);

      await _type(tester, 'fi');
      expect(labelsOf(c.filteredItems), <String>['Figo']);
      expect(visualRowLabels<int>(tester), <String>['Figo']);
    });

    test(
      'B3: updateListItems with the SAME list instance keeps its items',
      () {
        final items = fruitItems();
        final c = _controller(items);
        addTearDown(c.dispose);

        items.add(_kiwi);
        c.updateListItems(items, false);

        const expected = <String>[..._fruitOrder, 'Kiwi'];
        expect(labelsOf(c.items), expected);
        expect(labelsOf(c.filteredItems), expected);
      }, // B3: fixed in 8.0
    );
  });

  group('updateListItems on a mounted dropdown', () {
    testWidgets('shouldreset true clears text and notifies', (tester) async {
      final selected = <ValueItem<int>?>[];
      final c = _controller(fruitItems(), updateSelectedItem: selected.add);
      await _pump(tester, c);

      c.localSearchController.text = 'Ban';
      c.updateListItems(_newList(), true);
      await tester.pump();

      expect(_barText(tester), '');
      expect(selected, <ValueItem<int>?>[null]);
      expect(labelsOf(c.items), <String>['Kiwi', 'Figo']);
      expect(labelsOf(c.filteredItems), <String>['Kiwi', 'Figo']);
    });

    testWidgets('shouldreset false without selection keeps text', (
      tester,
    ) async {
      final selected = <ValueItem<int>?>[];
      final c = _controller(fruitItems(), updateSelectedItem: selected.add);
      await _pump(tester, c);

      c.localSearchController.text = 'Ban';
      c.updateListItems(_newList(), false);
      await tester.pump();

      expect(_barText(tester), 'Ban');
      expect(selected, isEmpty);
      expect(labelsOf(c.filteredItems), <String>['Kiwi', 'Figo']);
    });

    testWidgets('shouldreset false with a selection still resets', (
      tester,
    ) async {
      final c = _controller(fruitItems(), initialSelectedItem: _banana);
      await _pump(tester, c);

      c.updateListItems(_newList(), false);
      await tester.pump();

      expect(c.selectedItem, isNull);
      expect(_barText(tester), '');
      expect(labelsOf(c.filteredItems), <String>['Kiwi', 'Figo']);
    });
  });

  group('data: items replaced from outside', () {
    test(
      'B9: typing after an external add does not crash filtering',
      () {
        final errors = <FlutterErrorDetails>[];
        final previous = FlutterError.onError;
        FlutterError.onError = errors.add;
        addTearDown(() => FlutterError.onError = previous);

        final items = fruitItems();
        final c = _controller(items);
        addTearDown(c.dispose);

        c
          ..updateListItems(items..add(_kiwi), false)
          ..onSearchOpen();
        _typeViaController(c, 'ban');

        expect(errors, isEmpty);
        expect(labelsOf(c.filteredItems), <String>['Banana']);
      }, // B9: fixed in 8.0
    );
  });

  group('filteredItems: unmodifiable live view', () {
    test('mutations throw UnsupportedError', () {
      final c = _controller(fruitItems());
      addTearDown(c.dispose);

      final view = c.filteredItems;
      expect(() => view.add(_kiwi), throwsUnsupportedError);
      expect(() => view.remove(_banana), throwsUnsupportedError);
      expect(view.clear, throwsUnsupportedError);
      expect(() => view[0] = _kiwi, throwsUnsupportedError);
      expect(view.sort, throwsUnsupportedError);
      expect(labelsOf(c.filteredItems), _fruitOrder);
    });

    test('a view obtained earlier reflects later filtering', () {
      final c = _controller(fruitItems());
      addTearDown(c.dispose);

      final view = c.filteredItems;
      c.filterList('uva');
      expect(labelsOf(view), <String>['Uva']);
    });
  });
}
