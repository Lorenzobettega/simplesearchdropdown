import 'package:flutter_test/flutter_test.dart';
import 'package:simple_search_dropdown/simple_search_dropdown.dart';
import 'package:simple_search_dropdown/src/core/filter_engine.dart';
import 'package:simple_search_dropdown/src/core/sort_type.dart';

import '../support/harness.dart';

List<String> _labels(Iterable<ValueItem<int>> items) =>
    items.map((e) => e.label).toList();

void main() {
  group('SearchNormalization', () {
    test('defaults ignore accents, case and surrounding spaces', () {
      expect(const SearchNormalization().apply('  Maçã '), 'maca');
    });

    test('each option can be turned off', () {
      expect(const SearchNormalization(trim: false).apply(' a '), ' a ');
      expect(const SearchNormalization(latinize: false).apply('Maçã'), 'maçã');
      expect(
          const SearchNormalization(caseSensitive: true).apply('Maçã'), 'Maca');
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

    test('legacy int maps to SortType and back', () {
      for (int i = 0; i < 4; i++) {
        expect(SortType.fromLegacy(i).legacyValue, i);
      }
      expect(SortType.fromLegacy(42), SortType.none);
    });

    test('sorted returns a copy in the requested order', () {
      expect(
          _labels(FilterEngine.sorted(source, SortType.none)), ['b', 'c', 'a']);
      expect(_labels(FilterEngine.sorted(source, SortType.alphabetical)),
          ['a', 'b', 'c']);
      expect(_labels(FilterEngine.sorted(source, SortType.reverseAlphabetical)),
          ['c', 'b', 'a']);
      expect(
          _labels(FilterEngine.sorted(source, SortType.selectedFirst,
              selected: source[2])),
          ['a', 'b', 'c']);
      expect(_labels(source), ['b', 'c', 'a']);
    });

    test('selectedFirst without a selection keeps the order', () {
      expect(_labels(FilterEngine.sorted(source, SortType.selectedFirst)),
          ['b', 'c', 'a']);
    });
  });
}
