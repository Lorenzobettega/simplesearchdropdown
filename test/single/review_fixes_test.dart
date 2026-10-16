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

    testWidgets('an unchanged edit keeps the original instance and skips '
        'onEditItem (N45)', (tester) async {
      const ValueItem<int> apple = ValueItem(label: 'Apple', value: 1);
      const ValueItem<int> banana = ValueItem(label: 'Banana', value: 2);
      final List<ValueItem<int>> items = <ValueItem<int>>[apple, banana];
      int fresh = 100;
      final List<List<ValueItem<int>>> edits = <List<ValueItem<int>>>[];
      final List<ValueItem<int>?> selections = <ValueItem<int>?>[];
      final c = SearchDropDownController<int>(
        listItems: items,
        initialSelectedItem: apple,
        addMode: false,
        deleteMode: false,
        editMode: true,
        onEditItem: (o, n) => edits.add(<ValueItem<int>>[o, n]),
        updateSelectedItem: selections.add,
        newValueItem: (s) => ValueItem(label: s, value: fresh++),
      );
      addTearDown(c.dispose);
      await tester.pumpWidget(host(SearchDropDown<int>(controller: c)));
      await openSingle(tester);
      await tester.tap(find.byIcon(Icons.edit).first);
      await tester.pump(const Duration(milliseconds: 500));
      await tester.tap(find.text('Editar'));
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.byType(EditDialog), findsNothing);
      expect(edits, isEmpty);
      expect(selections, isEmpty);
      expect(fresh, 100);
      expect(identical(items.first, apple), isTrue);
      expect(identical(c.selectedItem, apple), isTrue);
    });
  });

  group('legacy listItems write-back (F1/F2)', () {
    SearchDropDownController<int> legacy(
      List<ValueItem<int>> list, {
      bool addMode = true,
      bool editMode = false,
      Function(ValueItem<int>)? onAddItem,
      Function(ValueItem<int>)? onDeleteItem,
      Function(ValueItem<int>, ValueItem<int>)? onEditItem,
      ValueItem<int> Function(String)? newValueItem,
      ValueItem<int>? initial,
    }) => SearchDropDownController<int>(
      listItems: list,
      addMode: addMode,
      newValueItem:
          newValueItem ?? (s) => ValueItem<int>(label: s, value: s.length),
      onAddItem: onAddItem ?? (_) {},
      deleteMode: onDeleteItem != null,
      onDeleteItem: onDeleteItem,
      editMode: editMode,
      onEditItem: onEditItem,
      initialSelectedItem: initial,
    );

    Future<void> submitEdit(
      WidgetTester tester,
      String label,
      String text,
    ) async {
      await tester.tap(
        find.descendant(
          of: find.widgetWithText(DefaultListTile<int>, label),
          matching: find.byIcon(Icons.edit),
        ),
      );
      await tester.pump(const Duration(milliseconds: 500));
      await tester.enterText(
        find.descendant(
          of: find.byType(EditDialog),
          matching: find.byType(TextField),
        ),
        text,
      );
      await tester.tap(find.text('Editar'));
      await tester.pumpAndSettle();
    }

    testWidgets('F1: add and delete finish with an unmodifiable list', (
      tester,
    ) async {
      final List<ValueItem<int>> frozen = List<ValueItem<int>>.unmodifiable(
        fruitItems(),
      );
      final List<String> calls = <String>[];
      final c = legacy(
        frozen,
        onAddItem: (i) => calls.add('add ${i.label}'),
        onDeleteItem: (i) => calls.add('del ${i.label}'),
      );
      await tester.pumpWidget(host(SearchDropDown<int>(controller: c)));
      final BuildContext ctx = tester.element(find.byType(SearchDropDown<int>));

      await c.addItem('Kiwi', ctx);
      expect(c.selectedItem?.label, 'Kiwi');

      final ValueItem<int> banana = frozen[1];
      c.selectItem(banana);
      await c.deleteItem(banana, ctx);
      await tester.pump();

      expect(c.selectedItem, isNull);
      expect(calls, <String>['add Kiwi', 'del Banana']);
      expect(c.listItems.map((e) => e.label), fruitItems().map((e) => e.label));
      expect(tester.takeException(), isNull);
    });

    testWidgets('F1: edit finishes with an unmodifiable list', (tester) async {
      final c = legacy(
        List<ValueItem<int>>.unmodifiable(fruitItems()),
        addMode: false,
        editMode: true,
        onEditItem: (_, _) {},
      );
      c.selectItem(c.listItems[1]);
      await tester.pumpWidget(host(SearchDropDown<int>(controller: c)));
      await openSingle(tester);
      await submitEdit(tester, 'Banana', 'Kiwi');

      expect(tester.takeException(), isNull);
      expect(c.selectedItem?.label, 'Kiwi');
      expect(c.listItems[1].label, 'Banana');
    });

    testWidgets('F2: an add whose callback stores its own copy (server id) '
        'is not duplicated and the copy is selected', (tester) async {
      final List<ValueItem<int>> shared = fruitItems();
      final List<ValueItem<int>?> notified = <ValueItem<int>?>[];
      final c = SearchDropDownController<int>(
        listItems: shared,
        newValueItem: (s) => ValueItem<int>(label: s, value: s.length),
        onAddItem: (i) async {
          await Future<void>.delayed(Duration.zero);
          shared.add(ValueItem<int>(label: i.label, value: 42));
        },
        deleteMode: false,
        updateSelectedItem: notified.add,
      );
      await tester.pumpWidget(host(SearchDropDown<int>(controller: c)));
      await openSingle(tester);
      await typeInSingle(tester, 'Kiwi');
      await tester.tap(find.text('Criar'));
      await tester.pumpAndSettle();

      expect(shared.where((e) => e.label == 'Kiwi'), hasLength(1));
      expect(shared.last, const ValueItem<int>(label: 'Kiwi', value: 42));
      expect(c.selectedItem, const ValueItem<int>(label: 'Kiwi', value: 42));
      expect(notified.last, const ValueItem<int>(label: 'Kiwi', value: 42));
    });

    testWidgets('F2: a copy that differs only in case and accents counts as '
        'stored', (tester) async {
      final List<ValueItem<int>> shared = fruitItems();
      final c = legacy(
        shared,
        onAddItem: (i) =>
            shared.add(const ValueItem<int>(label: 'kíwi', value: 42)),
      );
      await tester.pumpWidget(host(SearchDropDown<int>(controller: c)));
      final BuildContext ctx = tester.element(find.byType(SearchDropDown<int>));
      await c.addItem('Kiwi', ctx);

      expect(shared, hasLength(6));
      expect(c.selectedItem, same(shared.last));
    });

    testWidgets('F2: an unrelated item added by the callback is not taken for '
        'the stored copy', (tester) async {
      final List<ValueItem<int>> shared = fruitItems();
      final c = legacy(
        shared,
        onAddItem: (_) =>
            shared.add(const ValueItem<int>(label: 'Other', value: 7)),
      );
      await tester.pumpWidget(host(SearchDropDown<int>(controller: c)));
      final BuildContext ctx = tester.element(find.byType(SearchDropDown<int>));
      await c.addItem('Kiwi', ctx);

      expect(
        shared.map((e) => e.label),
        containsAll(<String>['Other', 'Kiwi']),
      );
      expect(shared, contains(const ValueItem<int>(label: 'Kiwi', value: 4)));
      expect(c.selectedItem, const ValueItem<int>(label: 'Kiwi', value: 4));
    });

    testWidgets('F2: an item already in the list with the same label is not '
        'taken for the stored copy', (tester) async {
      final List<ValueItem<int>> shared = <ValueItem<int>>[
        const ValueItem<int>(label: 'Kiwi', value: 1),
      ];
      final c = legacy(shared);
      await tester.pumpWidget(host(SearchDropDown<int>(controller: c)));
      final BuildContext ctx = tester.element(find.byType(SearchDropDown<int>));
      await c.addItem('kiwi', ctx);

      expect(shared, hasLength(2));
      expect(c.selectedItem, const ValueItem<int>(label: 'kiwi', value: 4));
    });

    testWidgets('F2: an edit whose callback swaps in its own copy is not '
        'duplicated and the copy stays selected', (tester) async {
      final List<ValueItem<int>> items = fruitItems();
      final c = legacy(
        items,
        addMode: false,
        editMode: true,
        initial: items[1],
        onEditItem: (old, nw) {
          items[items.indexOf(old)] = ValueItem<int>(
            label: nw.label,
            value: 42,
          );
        },
      );
      await tester.pumpWidget(host(SearchDropDown<int>(controller: c)));
      await openSingle(tester);
      await submitEdit(tester, 'Banana', 'Banana2');

      expect(items.where((e) => e.label == 'Banana2'), hasLength(1));
      expect(items[1], const ValueItem<int>(label: 'Banana2', value: 42));
      expect(c.selectedItem, same(items[1]));
    });

    testWidgets('F2: an edit that recreates an equal item selects the '
        'instance now in the list', (tester) async {
      final List<ValueItem<int>> items = <ValueItem<int>>[
        // A distinct instance on purpose; 'Banana' has 6 letters, so the
        // edited item equals the old one.
        // ignore: prefer_const_constructors
        ValueItem<int>(label: 'Banana', value: 6),
      ];
      final ValueItem<int> old = items.single;
      final c = legacy(
        items,
        addMode: false,
        editMode: true,
        initial: old,
        onEditItem: (_, _) {},
        // A new label that newValueItem turns back into the old item.
        newValueItem: (s) =>
            ValueItem<int>(label: s.trim(), value: s.trim().length),
      );
      await tester.pumpWidget(host(SearchDropDown<int>(controller: c)));
      await openSingle(tester);
      await submitEdit(tester, 'Banana', 'Banana ');

      expect(items, hasLength(1));
      expect(items.single, isNot(same(old)));
      expect(c.selectedItem, same(items.single));
    });

    testWidgets('F2: an edit whose callback adds its own copy but keeps the '
        'old item removes the old one', (tester) async {
      final List<ValueItem<int>> items = fruitItems();
      final c = legacy(
        items,
        addMode: false,
        editMode: true,
        initial: items[1],
        onEditItem: (_, nw) =>
            items.add(ValueItem<int>(label: nw.label, value: 42)),
      );
      await tester.pumpWidget(host(SearchDropDown<int>(controller: c)));
      await openSingle(tester);
      await submitEdit(tester, 'Banana', 'Banana2');

      expect(items.map((e) => e.label), <String>[
        'Maçã',
        'Uva',
        'abacaxi',
        'Pêra',
        'Banana2',
      ]);
      expect(c.selectedItem, same(items.last));
    });
  });
}
