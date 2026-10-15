import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:simple_search_dropdown/simple_search_dropdown.dart';

import '../support/harness.dart';

void main() {
  group('review fixes: single', () {
    testWidgets('confirming the edit dialog unchanged keeps the item (R1)', (
      tester,
    ) async {
      final List<ValueItem<String>> items = <ValueItem<String>>[
        const ValueItem(label: 'Apple', value: 'Apple'),
        const ValueItem(label: 'Banana', value: 'Banana'),
      ];
      final c = SearchDropDownController<String>(
        listItems: items,
        addMode: false,
        deleteMode: false,
        editMode: true,
        onEditItem: (_, _) {},
        newValueItem: (s) => ValueItem(label: s, value: s),
      );
      await tester.pumpWidget(host(SearchDropDown<String>(controller: c)));
      await openSingle(tester);
      await tester.tap(find.byIcon(Icons.edit).first);
      await tester.pump(const Duration(milliseconds: 500));
      await tester.tap(find.text('Editar'));
      await tester.pump(const Duration(milliseconds: 500));
      expect(items.map((e) => e.label), <String>['Apple', 'Banana']);
    });

    testWidgets('the keyboard highlight resets when the view reopens (R2)', (
      tester,
    ) async {
      final c = SearchDropDownController<int>(
        listItems: numberedItems(5),
        addMode: false,
        deleteMode: false,
      );
      await tester.pumpWidget(host(SearchDropDown<int>(controller: c)));
      await openSingle(tester);
      for (int i = 0; i < 3; i++) {
        await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      }
      expect(c.highlightedIndex, 2);
      c.localSearchController.closeView(null);
      await tester.pumpAndSettle();
      await openSingle(tester);
      expect(c.highlightedIndex, -1);
    });

    testWidgets('selecting does not re-filter while the view closes (R3)', (
      tester,
    ) async {
      int updates = 0;
      final c = SearchDropDownController<int>(
        listItems: fruitItems(),
        addMode: false,
        deleteMode: false,
        onFilterUpdated: () => updates++,
      );
      await tester.pumpWidget(host(SearchDropDown<int>(controller: c)));
      await openSingle(tester);
      await typeInSingle(tester, 'Ban');
      final int before = updates;
      await tester.tap(find.text('Banana').last);
      await tester.pumpAndSettle();
      expect(updates, before);
    });

    testWidgets('swapping controllers back and forth does not crash (R9)', (
      tester,
    ) async {
      final a = SearchDropDownController<int>(
        listItems: fruitItems(),
        addMode: false,
        deleteMode: false,
      );
      final b = SearchDropDownController<int>(
        listItems: numberedItems(3),
        addMode: false,
        deleteMode: false,
      );
      await tester.pumpWidget(host(SearchDropDown<int>(controller: a)));
      await tester.pumpWidget(host(SearchDropDown<int>(controller: b)));
      await tester.pumpWidget(host(SearchDropDown<int>(controller: a)));
      await openSingle(tester);
      expect(tester.takeException(), isNull);
      expect(find.text('Banana'), findsWidgets);
    });

    test('typing narrows the previous results (R19)', () {
      final c = SearchDropDownController<int>(
        listItems: numberedItems(1000),
        addMode: false,
        deleteMode: false,
      );
      addTearDown(c.dispose);
      c
        ..onSearchOpen()
        ..filterList('Item 9');
      expect(c.filteredItems, hasLength(111));
      c.filterList('Item 99');
      expect(c.filteredItems, hasLength(11));
      c.filterList('Item 1');
      expect(c.filteredItems, hasLength(111));
    });
  });
}
