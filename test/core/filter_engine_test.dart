import 'package:flutter_test/flutter_test.dart';
import 'package:simple_search_dropdown/simple_search_dropdown.dart';
import 'package:simple_search_dropdown/src/core/filter_engine.dart';

import '../support/harness.dart';

List<String> _labels(Iterable<ValueItem<int>> items) =>
    items.map((e) => e.label).toList();

/// Counts `==` calls, to measure hash-map lookups (N25).
class _CountingItem extends ValueItem<String> {
  _CountingItem(String s) : super(label: s, value: s);

  static int eq = 0;

  // Keeps ValueItem.hashCode on purpose: that is what the test measures.
  @override
  // ignore: hash_and_equals
  bool operator ==(Object other) {
    eq++;
    return super == other;
  }
}

/// A value with identity equality, like a caller's own class (N40).
class _Box {
  _Box(this.n);

  final int n;
}

void main() {
  group('SearchNormalization', () {
    test('defaults ignore accents, case and surrounding spaces', () {
      expect(const SearchNormalization().apply('  Maçã '), 'maca');
    });

    test('each option can be turned off', () {
      expect(const SearchNormalization(trim: false).apply(' a '), ' a ');
      expect(const SearchNormalization(latinize: false).apply('Maçã'), 'maçã');
      expect(
        const SearchNormalization(caseSensitive: true).apply('Maçã'),
        'Maca',
      );
    });
  });

  group('FilterEngine.filter', () {
    final FilterEngine<int> engine = FilterEngine<int>();

    test('substring match after normalization', () {
      expect(_labels(engine.filter(fruitItems(), 'MAC')), ['Maçã']);
      expect(_labels(engine.filter(fruitItems(), 'aba')), ['abacaxi']);
      expect(_labels(engine.filter(fruitItems(), 'an')), ['Banana']);
    });

    test('empty or blank query returns a copy of everything', () {
      final List<ValueItem<int>> source = fruitItems();
      final List<ValueItem<int>> result = engine.filter(source, '   ');
      expect(result, source);
      expect(identical(result, source), isFalse);
    });

    test('never mutates the source list', () {
      final List<ValueItem<int>> source = fruitItems();
      final List<String> before = _labels(source);
      engine.filter(source, 'a');
      expect(_labels(source), before);
    });

    test('items added to the source later are matched (lazy cache)', () {
      final List<ValueItem<int>> source = fruitItems();
      engine.filter(source, 'a');
      source.add(const ValueItem(label: 'Kiwi', value: 9));
      expect(_labels(engine.filter(source, 'kiw')), ['Kiwi']);
    });

    test('labels are normalized once per item', () {
      final FilterEngine<int> counting = FilterEngine<int>();
      final List<ValueItem<int>> source = numberedItems(1000);
      counting
        ..filter(source, 'Item 1')
        ..filter(source, 'Item 12')
        ..filter(source, 'Item 123');
      expect(counting.normalizeCount, 1000);
      counting
        ..clearCache()
        ..filter(source, 'x');
      expect(counting.normalizeCount, 2000);
    });

    test('duplicate labels are all kept', () {
      final List<ValueItem<int>> source = <ValueItem<int>>[
        const ValueItem(label: 'Same', value: 1),
        const ValueItem(label: 'Same', value: 2),
      ];
      expect(engine.filter(source, 'same'), hasLength(2));
    });
  });

  group('FilterEngine cache eviction', () {
    test('retainOnly drops labels of items replaced in place (N40)', () {
      final FilterEngine<_Box> engine = FilterEngine<_Box>();
      List<ValueItem<_Box>> fresh() => <ValueItem<_Box>>[
        for (int i = 0; i < 3; i++) ValueItem(label: 'a$i', value: _Box(i)),
      ];
      final List<ValueItem<_Box>> list = fresh();
      for (int round = 0; round < 5; round++) {
        list
          ..clear()
          ..addAll(fresh());
        engine
          ..retainOnly(list)
          ..filter(list, 'a')
          ..sorted(list, SortType.reverseAlphabetical);
      }
      engine.retainOnly(list);
      expect(engine.cachedLabelCount, 3);
      final int before = engine.normalizeCount;
      engine
        ..retainOnly(list)
        ..filter(list, 'a1');
      expect(engine.normalizeCount, before);
    });

    test('retainOnly also drops sort keys of a non-default policy (N40)', () {
      final FilterEngine<_Box> engine = FilterEngine<_Box>(
        normalization: const SearchNormalization(caseSensitive: true),
      );
      final List<ValueItem<_Box>> list = <ValueItem<_Box>>[
        ValueItem(label: 'b', value: _Box(1)),
        ValueItem(label: 'A', value: _Box(2)),
      ];
      engine.sorted(list, SortType.alphabetical);
      expect(engine.cachedLabelCount, 2);
      list
        ..clear()
        ..add(ValueItem(label: 'c', value: _Box(3)));
      engine.retainOnly(list);
      expect(engine.cachedLabelCount, 0);
    });

    test('forget and clearCache also drop sort keys (N40)', () {
      final FilterEngine<_Box> engine = FilterEngine<_Box>(
        normalization: const SearchNormalization(caseSensitive: true),
      );
      final List<ValueItem<_Box>> list = <ValueItem<_Box>>[
        ValueItem(label: 'b', value: _Box(1)),
        ValueItem(label: 'A', value: _Box(2)),
      ];
      engine.sorted(list, SortType.alphabetical);
      expect(engine.cachedLabelCount, 2);
      engine.forget(list.first);
      expect(engine.cachedLabelCount, 1);
      engine.clearCache();
      expect(engine.cachedLabelCount, 0);
    });
  });

  group('FilterEngine.findByLabel', () {
    test('matches the normalized label, null when absent', () {
      final FilterEngine<int> engine = FilterEngine<int>();
      expect(engine.findByLabel(fruitItems(), 'maca')?.value, 1);
      expect(engine.findByLabel(fruitItems(), 'nope'), isNull);
    });
  });

  group('FilterEngine sorting', () {
    final List<ValueItem<int>> source = <ValueItem<int>>[
      const ValueItem(label: 'b', value: 2),
      const ValueItem(label: 'c', value: 3),
      const ValueItem(label: 'a', value: 1),
    ];

    test('digits compare as text, like 7.x (Item 10 before Item 2)', () {
      final List<ValueItem<int>> items = <ValueItem<int>>[
        const ValueItem(label: 'Item 2', value: 2),
        const ValueItem(label: 'Item 10', value: 10),
        const ValueItem(label: 'Item 1', value: 1),
        const ValueItem(label: 'Item 20', value: 20),
      ];
      final FilterEngine<int> engine = FilterEngine<int>();
      expect(_labels(engine.sorted(items, SortType.alphabetical)), <String>[
        'Item 1',
        'Item 10',
        'Item 2',
        'Item 20',
      ]);
      expect(
        _labels(engine.sorted(items, SortType.reverseAlphabetical)),
        <String>['Item 20', 'Item 2', 'Item 10', 'Item 1'],
      );
    });

    test('sorted returns a copy in the requested order', () {
      expect(_labels(FilterEngine<int>().sorted(source, SortType.none)), [
        'b',
        'c',
        'a',
      ]);
      expect(
        _labels(FilterEngine<int>().sorted(source, SortType.alphabetical)),
        ['a', 'b', 'c'],
      );
      expect(
        _labels(
          FilterEngine<int>().sorted(source, SortType.reverseAlphabetical),
        ),
        ['c', 'b', 'a'],
      );
      expect(
        _labels(
          FilterEngine<int>().sorted(
            source,
            SortType.selectedFirst,
            selected: source[2],
          ),
        ),
        ['a', 'b', 'c'],
      );
      expect(_labels(source), ['b', 'c', 'a']);
    });

    test('alphabetical order ignores case and accents (D2)', () {
      final List<ValueItem<int>> mixed = <ValueItem<int>>[
        const ValueItem(label: 'Pzz', value: 1),
        const ValueItem(label: 'Banana', value: 2),
        const ValueItem(label: 'Pêra', value: 3),
        const ValueItem(label: 'abacaxi', value: 4),
      ];
      expect(
        _labels(FilterEngine<int>().sorted(mixed, SortType.alphabetical)),
        ['abacaxi', 'Banana', 'Pêra', 'Pzz'],
      );
      expect(
        _labels(
          FilterEngine<int>().sorted(mixed, SortType.reverseAlphabetical),
        ),
        ['Pzz', 'Pêra', 'Banana', 'abacaxi'],
      );
    });

    test('label == value items sort with O(1) cache lookups (N25)', () {
      const int n = 1000;
      final List<_CountingItem> items = <_CountingItem>[
        for (int i = 0; i < n; i++) _CountingItem('Item ${(i * 7919) % n}'),
      ];
      final List<String> expected = items.map((e) => e.label).toList()..sort();
      _CountingItem.eq = 0;
      final List<ValueItem<String>> result = FilterEngine<String>().sorted(
        items,
        SortType.alphabetical,
      );
      expect(result.map((e) => e.label).toList(), expected);
      expect(_CountingItem.eq, lessThan(4 * n * 10));
    });

    test('A-Z/Z-A ignore case and accents whatever the filter options '
        '(N24, D2)', () {
      final List<ValueItem<int>> cased = <ValueItem<int>>[
        const ValueItem(label: 'banana', value: 1),
        const ValueItem(label: 'Apple', value: 2),
        const ValueItem(label: 'cherry', value: 3),
        const ValueItem(label: 'Date', value: 4),
      ];
      final FilterEngine<int> cs = FilterEngine<int>(
        normalization: const SearchNormalization(caseSensitive: true),
      );
      expect(_labels(cs.sorted(cased, SortType.alphabetical)), <String>[
        'Apple',
        'banana',
        'cherry',
        'Date',
      ]);
      expect(_labels(cs.sorted(cased, SortType.reverseAlphabetical)), <String>[
        'Date',
        'cherry',
        'banana',
        'Apple',
      ]);
      final List<ValueItem<int>> accented = <ValueItem<int>>[
        const ValueItem(label: 'Zebra', value: 1),
        const ValueItem(label: 'Água', value: 2),
        const ValueItem(label: 'Pzz', value: 3),
        const ValueItem(label: 'Pêra', value: 4),
      ];
      final FilterEngine<int> nl = FilterEngine<int>(
        normalization: const SearchNormalization(latinize: false),
      );
      expect(_labels(nl.sorted(accented, SortType.alphabetical)), <String>[
        'Água',
        'Pêra',
        'Pzz',
        'Zebra',
      ]);
      final FilterEngine<int> untrimmed = FilterEngine<int>(
        normalization: const SearchNormalization(trim: false),
      );
      expect(
        _labels(
          untrimmed.sorted(<ValueItem<int>>[
            const ValueItem(label: 'b', value: 1),
            const ValueItem(label: ' c', value: 2),
            const ValueItem(label: 'a', value: 3),
          ], SortType.alphabetical),
        ),
        <String>['a', 'b', ' c'],
      );
      // Filtering keeps honouring the caller's policy.
      expect(_labels(cs.filter(cased, 'a')), <String>['banana', 'Date']);
      expect(_labels(nl.filter(accented, 'agua')), isEmpty);
    });

    test('an already ordered list is not sorted again (N50)', () {
      final FilterEngine<int> engine = FilterEngine<int>();
      final List<ValueItem<int>> az = List<ValueItem<int>>.unmodifiable(
        engine.sorted(fruitItems(), SortType.alphabetical),
      );
      expect(engine.sortCount, 1);
      engine.sortInPlace(az, SortType.alphabetical);
      expect(engine.sorted(az, SortType.alphabetical), az);
      expect(engine.sortCount, 1);
      final List<ValueItem<int>> za = engine.sorted(
        az,
        SortType.reverseAlphabetical,
      );
      expect(engine.sortCount, 2);
      engine.sortInPlace(za, SortType.reverseAlphabetical);
      expect(engine.sortCount, 2);
      // An unordered unmodifiable list still throws, like 7.x.
      expect(
        () => engine.sortInPlace(
          List<ValueItem<int>>.unmodifiable(fruitItems()),
          SortType.alphabetical,
        ),
        throwsUnsupportedError,
      );
    });

    test('selectedFirst without a selection keeps the order', () {
      expect(
        _labels(FilterEngine<int>().sorted(source, SortType.selectedFirst)),
        ['b', 'c', 'a'],
      );
    });
  });
}
