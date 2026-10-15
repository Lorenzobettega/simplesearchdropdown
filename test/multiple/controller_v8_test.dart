import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:simple_search_dropdown/simple_search_dropdown.dart';

import '../support/harness.dart';

MultipleSearchDropDownController<int> _ctrl({
  List<ValueItem<int>>? items,
  List<ValueItem<int>>? selected,
  void Function(List<ValueItem<int>>)? onChanged,
  SortType sort = SortType.none,
}) =>
    MultipleSearchDropDownController<int>(
      items: items ?? fruitItems(),
      selectedItems: selected,
      updateSelectedItems: onChanged,
      addMode: false,
      deleteMode: false,
      sort: sort,
    );

void main() {
  group('multiple controller: API without GlobalKey', () {
    testWidgets('selection changes made in code update the chips',
        (tester) async {
      final c = _ctrl();
      addTearDown(c.dispose);
      await tester.pumpWidget(host(MultipleSearchDropDown<int>(controller: c)));
      expect(find.byType(Card), findsNothing);

      c
        ..forceSelection('uva')
        ..forceSelection('Banana');
      await tester.pump();
      expect(find.text('Uva'), findsOneWidget);
      expect(find.text('Banana'), findsOneWidget);

      c.resetSelection();
      await tester.pump();
      expect(find.byType(Card), findsNothing);
    });

    testWidgets('enabled toggles the box', (tester) async {
      final c = _ctrl();
      addTearDown(c.dispose);
      await tester.pumpWidget(host(MultipleSearchDropDown<int>(controller: c)));
      c.enabled = false;
      await tester.pump();
      expect(tester.widget<Opacity>(find.byType(Opacity).first).opacity, 0.38);
    });

    test('toggle, search and filtering use the shared engine', () {
      final List<List<ValueItem<int>>> changes = <List<ValueItem<int>>>[];
      final c = _ctrl(onChanged: (s) => changes.add(List.of(s)));
      addTearDown(c.dispose);

      c.search('MACA');
      expect(c.filteredItems.map((e) => e.label), <String>['Maçã']);
      c
        ..toggle(c.filteredItems.first)
        ..toggle(c.filteredItems.first);
      expect(changes, hasLength(2));
      expect(c.selectedItems, isEmpty);
    });

    test('items are copied; sorting never reorders the caller list', () {
      final List<ValueItem<int>> mine = fruitItems();
      final c = _ctrl(items: mine, sort: SortType.alphabetical);
      addTearDown(c.dispose);
      expect(c.filteredItems.first.label, 'abacaxi');
      expect(mine.first.label, 'Maçã');
    });

    testWidgets('the open list sits below dialogs (confirm delete works)',
        (tester) async {
      final List<ValueItem<int>> items = fruitItems();
      final c = MultipleSearchDropDownController<int>(
        listItems: items,
        addMode: false,
        confirmDelete: true,
        onDeleteItem: items.remove,
      );
      addTearDown(c.dispose);
      await tester.pumpWidget(host(MultipleSearchDropDown<int>(controller: c)));
      await openMultiple(tester);

      await tester.tap(find.byIcon(Icons.delete).first);
      await tester.pump(const Duration(milliseconds: 400));
      await tester.tap(find.text('Apagar'));
      await tester.pump(const Duration(milliseconds: 400));

      expect(find.byType(WarningDialog), findsNothing);
      expect(items.map((e) => e.label), isNot(contains('Maçã')));
    });
  });
}
