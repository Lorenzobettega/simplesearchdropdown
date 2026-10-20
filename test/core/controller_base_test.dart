import 'package:flutter_test/flutter_test.dart';
import 'package:simple_search_dropdown/simple_search_dropdown.dart';

const List<ValueItem<int>> _items = <ValueItem<int>>[
  ValueItem<int>(label: 'a', value: 1),
];

void main() {
  group('single controller lifecycle', () {
    SearchDropDownController<int> create() => SearchDropDownController<int>(
      items: _items,
      addMode: false,
      deleteMode: false,
    );

    test('dispose can be called twice', () {
      final SearchDropDownController<int> c = create()..dispose();
      expect(c.dispose, returnsNormally);
    });

    test('a change after dispose notifies nobody and does not throw', () {
      final SearchDropDownController<int> c = create();
      int calls = 0;
      c
        ..addListener(() => calls++)
        ..dispose();
      expect(() => c.enabled = false, returnsNormally);
      expect(c.toggleEnabled, returnsNormally);
      expect(calls, 0);
    });
  });

  group('multiple controller lifecycle', () {
    MultipleSearchDropDownController<int> create() =>
        MultipleSearchDropDownController<int>(
          items: _items,
          addMode: false,
          deleteMode: false,
        );

    test('dispose can be called twice', () {
      final MultipleSearchDropDownController<int> c = create()..dispose();
      expect(c.dispose, returnsNormally);
    });

    test('a change after dispose notifies nobody and does not throw', () {
      final MultipleSearchDropDownController<int> c = create();
      int calls = 0;
      c
        ..addListener(() => calls++)
        ..dispose();
      expect(() => c.enabled = false, returnsNormally);
      expect(c.toggleEnabled, returnsNormally);
      expect(calls, 0);
    });
  });
}
