import 'dart:collection';

import 'package:flutter_test/flutter_test.dart';
import 'package:simple_search_dropdown/simple_search_dropdown.dart';
import 'package:simple_search_dropdown/src/core/filter_engine.dart';
import 'package:simple_search_dropdown/src/core/shared_list.dart';

import '../support/harness.dart';

/// A list whose writes fail with something other than [UnsupportedError].
class _Broken extends ListBase<int> {
  @override
  int length = 0;

  @override
  int operator [](int index) => 0;

  @override
  void operator []=(int index, int value) => throw StateError('broken');

  @override
  void add(int element) => throw StateError('broken');
}

void main() {
  group('writeShared (F1)', () {
    test('writes a modifiable list', () {
      final List<int> list = <int>[1];
      writeShared(() => list.add(2));
      expect(list, <int>[1, 2]);
    });

    test('leaves an unmodifiable list as is', () {
      final List<int> list = List<int>.unmodifiable(<int>[1]);
      writeShared(() => list.add(2));
      writeShared(() => list.remove(1));
      expect(list, <int>[1]);
    });

    test('other errors still surface', () {
      final _Broken list = _Broken();
      expect(() => writeShared(() => list.add(1)), throwsStateError);
    });
  });

  group('FilterEngine.storedFor (F2)', () {
    final FilterEngine<int> engine = FilterEngine<int>();
    const ValueItem<int> kiwi = ValueItem<int>(label: 'Kiwi', value: 4);

    Set<ValueItem<int>> snapshot(List<ValueItem<int>> list) =>
        HashSet<ValueItem<int>>.identity()..addAll(list);

    test('null when the callback stored nothing', () {
      final List<ValueItem<int>> list = fruitItems();
      expect(engine.storedFor(list, snapshot(list), kiwi), isNull);
    });

    test('the item itself when the list holds it', () {
      final List<ValueItem<int>> list = fruitItems();
      final Set<ValueItem<int>> before = snapshot(list);
      list.add(kiwi);
      expect(engine.storedFor(list, before, kiwi), same(kiwi));
    });

    test('an equal item already in the list', () {
      final List<ValueItem<int>> list = <ValueItem<int>>[
        // A distinct instance on purpose.
        // ignore: prefer_const_constructors
        ValueItem<int>(label: 'Kiwi', value: 4),
      ];
      expect(engine.storedFor(list, snapshot(list), kiwi), same(list.single));
    });

    test('a new item with the same normalized label', () {
      final List<ValueItem<int>> list = fruitItems();
      final Set<ValueItem<int>> before = snapshot(list);
      list
        ..add(const ValueItem<int>(label: 'Other', value: 7))
        ..add(const ValueItem<int>(label: ' kíwi ', value: 42));
      expect(engine.storedFor(list, before, kiwi), same(list.last));
    });

    test('an old item with the same label is not a stored copy', () {
      final List<ValueItem<int>> list = <ValueItem<int>>[
        const ValueItem<int>(label: 'kiwi', value: 1),
      ];
      expect(engine.storedFor(list, snapshot(list), kiwi), isNull);
    });

    test('the item itself wins over a new copy', () {
      final List<ValueItem<int>> list = fruitItems();
      final Set<ValueItem<int>> before = snapshot(list);
      list
        ..add(const ValueItem<int>(label: 'Kiwi', value: 42))
        ..add(kiwi);
      expect(engine.storedFor(list, before, kiwi), same(kiwi));
    });

    test('the item itself wins over an earlier equal entry', () {
      final List<ValueItem<int>> list = <ValueItem<int>>[
        // A distinct instance on purpose.
        // ignore: prefer_const_constructors
        ValueItem<int>(label: 'Kiwi', value: 4),
        kiwi,
      ];
      expect(engine.storedFor(list, snapshot(list), kiwi), same(kiwi));
    });
  });
}
