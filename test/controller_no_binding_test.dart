import 'package:flutter/scheduler.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:simple_search_dropdown/simple_search_dropdown.dart';

// Keep this file free of testWidgets (and of imports that declare one):
// declaring one initializes the binding for the whole file and hides F19.
List<ValueItem<int>> _items() => <ValueItem<int>>[
  const ValueItem(label: 'Banana', value: 1),
  const ValueItem(label: 'Maçã', value: 2),
  const ValueItem(label: 'Uva', value: 3),
];

void main() {
  test('precondition: no binding is initialized in this file', () {
    expect(() => SchedulerBinding.instance, throwsFlutterError);
  });

  test('single controller can be driven without a binding (7.x parity)', () {
    int notified = 0;
    int filtered = 0;
    final List<ValueItem<int>?> selections = <ValueItem<int>?>[];
    final c = SearchDropDownController<int>(
      listItems: _items(),
      addMode: false,
      deleteMode: false,
      onFilterUpdated: () => filtered++,
      updateSelectedItem: selections.add,
    );
    addTearDown(c.dispose);
    c
      ..addListener(() => notified++)
      ..forceSelection('Banana');
    expect(notified, 1, reason: 'delivered synchronously');
    expect(selections.single?.label, 'Banana');

    c
      ..toggleEnabled()
      ..enabled = true
      ..selectedItem = null
      ..clearVisible = false
      ..resetSelection();
    // selectedItem = null already hides the clear button (N33), so the
    // clearVisible = false that follows changes nothing and does not notify.
    expect(notified, 5);
    expect(selections.last, isNull);

    c
      ..updateListItems(_items().reversed.toList(), true)
      ..sortBy(SortType.alphabetical)
      ..filterList('uva');
    expect(filtered, greaterThan(0));
    expect(c.filteredItems.map((e) => e.label), <String>['Uva']);
    expect(c.selectedItem, isNull);
  });

  test('multiple controller can be driven without a binding (7.x parity)', () {
    int notified = 0;
    int filtered = 0;
    final List<int> selectionSizes = <int>[];
    final c = MultipleSearchDropDownController<int>(
      items: _items(),
      addMode: false,
      deleteMode: false,
      onFilterUpdated: () => filtered++,
      updateSelectedItems: (s) => selectionSizes.add(s.length),
    );
    addTearDown(c.dispose);
    c
      ..addListener(() => notified++)
      ..search('uva');
    expect(filtered, 1, reason: 'delivered synchronously');
    expect(notified, 1);

    c
      ..toggle(c.filteredItems.first)
      ..forceSelection('Banana')
      ..toggleEnabled()
      ..clear()
      ..forceSelection('Uva')
      ..resetSelection();
    expect(selectionSizes, <int>[1, 2, 0, 1, 0]);
    expect(notified, 7);
    expect(c.selectedItems, isEmpty);
    expect(c.enabled, isFalse);
  });
}
