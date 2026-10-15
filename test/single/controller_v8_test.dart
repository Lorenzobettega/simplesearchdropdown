import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:simple_search_dropdown/simple_search_dropdown.dart';

import '../support/harness.dart';

SearchDropDownController<int> _ctrl({
  List<ValueItem<int>>? listItems,
  List<ValueItem<int>>? items,
  ValueItem<int>? initial,
  bool addMode = false,
  bool deleteMode = false,
  Function(ValueItem<int>)? onAddItem,
  Function(ValueItem<int>)? onDeleteItem,
}) =>
    SearchDropDownController<int>(
      listItems: listItems,
      items: items,
      initialSelectedItem: initial,
      addMode: addMode,
      deleteMode: deleteMode,
      onAddItem: onAddItem,
      onDeleteItem: onDeleteItem,
      newValueItem: (s) => ValueItem<int>(label: s, value: s.length),
    );

void main() {
  group('controller: items (owned copy)', () {
    test('items are copied; the caller list is never touched', () {
      final List<ValueItem<int>> mine = fruitItems();
      final c = _ctrl(items: mine);
      addTearDown(c.dispose);
      c.sortBy(SortType.alphabetical);
      expect(identical(c.listItems, mine), isFalse);
      expect(mine.first.label, 'Maçã');
      expect(c.listItems.first.label, 'abacaxi');
    });

    test('exactly one of listItems or items is required', () {
      expect(() => _ctrl(), throwsAssertionError);
      expect(
        () => _ctrl(listItems: fruitItems(), items: fruitItems()),
        throwsAssertionError,
      );
    });

    testWidgets('add keeps a legacy callback that also adds: no duplicates',
        (tester) async {
      final List<ValueItem<int>> shared = fruitItems();
      final c = _ctrl(listItems: shared, addMode: true, onAddItem: shared.add);
      await tester.pumpWidget(host(SearchDropDown<int>(controller: c)));
      await openSingle(tester);
      await typeInSingle(tester, 'Kiwi');
      await tester.tap(find.text('Criar'));
      await tester.pumpAndSettle();
      expect(shared.where((e) => e.label == 'Kiwi'), hasLength(1));
      expect(c.selectedItem?.label, 'Kiwi');
    });

    testWidgets('the add row follows the text while results stay empty',
        (tester) async {
      final c = _ctrl(items: fruitItems(), addMode: true, onAddItem: (_) {});
      await tester.pumpWidget(host(SearchDropDown<int>(controller: c)));
      await openSingle(tester);
      await typeInSingle(tester, 'zz');
      await tester.pump();
      await typeInSingle(tester, 'zzz');
      await tester.pump();
      expect(
        tester.widget<DefaultAddListItem>(find.byType(DefaultAddListItem)).text,
        'zzz',
      );
    });

    testWidgets('owned mode adds the item itself', (tester) async {
      final c = _ctrl(items: fruitItems(), addMode: true, onAddItem: (_) {});
      await tester.pumpWidget(host(SearchDropDown<int>(controller: c)));
      await openSingle(tester);
      await typeInSingle(tester, 'Kiwi');
      await tester.tap(find.text('Criar'));
      await tester.pumpAndSettle();
      expect(c.listItems.last.label, 'Kiwi');
    });
  });

  group('controller: ChangeNotifier (#45)', () {
    testWidgets('selection made through the controller updates the bar',
        (tester) async {
      final c = _ctrl(listItems: fruitItems());
      await tester.pumpWidget(host(SearchDropDown<int>(controller: c)));
      expect(find.byIcon(Icons.clear), findsNothing);

      c.forceSelection('uva');
      await tester.pump();
      expect(c.localSearchController.text, 'Uva');
      expect(find.byIcon(Icons.clear), findsOneWidget);

      c.resetSelection();
      await tester.pump();
      expect(find.byIcon(Icons.clear), findsNothing);
    });

    testWidgets('enabled toggles the bar without a GlobalKey', (tester) async {
      final c = _ctrl(listItems: fruitItems());
      await tester.pumpWidget(host(SearchDropDown<int>(controller: c)));
      expect(find.byIcon(Icons.arrow_drop_down), findsOneWidget);

      c.enabled = false;
      await tester.pump();
      expect(find.byIcon(Icons.arrow_drop_down), findsNothing);
    });

    test('notifies listeners on selection, enabled and list changes', () {
      final c = _ctrl(listItems: fruitItems());
      addTearDown(c.dispose);
      int count = 0;
      c
        ..addListener(() => count++)
        ..forceSelection('Banana')
        ..toggleEnabled()
        ..updateListItems(numberedItems(3), true);
      expect(count, greaterThanOrEqualTo(3));
    });

    testWidgets('changes made during build are delivered after the frame',
        (tester) async {
      final c = _ctrl(listItems: fruitItems());
      await tester.pumpWidget(host(Builder(builder: (context) {
        if (c.listItems.length == 5) {
          c.updateListItems(numberedItems(2), true);
        }
        return SearchDropDown<int>(controller: c);
      })));
      await tester.pump();
      expect(tester.takeException(), isNull);
      expect(c.filteredItems, hasLength(2));
    });

    test('async callbacks finishing after dispose are ignored', () async {
      final c = _ctrl(
        listItems: fruitItems(),
        deleteMode: true,
        onDeleteItem: (_) => Future<void>.delayed(Duration.zero),
      );
      final ValueItem<int> banana = c.listItems[1];
      final BuildContext context = _FakeContext();
      final Future<void> pending = c.deleteItem(banana, context);
      c.dispose();
      await pending;
      expect(c.isDisposed, isTrue);
    });
  });

  group('view: opens scrolled to the selection (#46)', () {
    testWidgets('a selection far down the list is visible on open',
        (tester) async {
      final List<ValueItem<int>> items = numberedItems(200);
      final c = _ctrl(listItems: items, initial: items[150]);
      await tester.pumpWidget(host(SearchDropDown<int>(controller: c)));
      await openSingle(tester);

      final Finder row = find.widgetWithText(DefaultListTile<int>, 'Item 150');
      expect(row, findsOneWidget);
      expect(
        tester.widget<DefaultListTile<int>>(row).selected,
        isTrue,
      );
      expect(c.filteredItems, hasLength(200));
    });

    testWidgets('PageDown/PageUp highlight the last/first item',
        (tester) async {
      final c = _ctrl(listItems: numberedItems(50));
      await tester.pumpWidget(host(SearchDropDown<int>(controller: c)));
      await openSingle(tester);

      await tester.sendKeyEvent(LogicalKeyboardKey.pageDown);
      await tester.pumpAndSettle();
      expect(c.highlightedIndex, 49);
      expect(
          find.widgetWithText(DefaultListTile<int>, 'Item 49'), findsOneWidget);

      await tester.sendKeyEvent(LogicalKeyboardKey.pageUp);
      await tester.pumpAndSettle();
      expect(c.highlightedIndex, 0);
    });

    testWidgets('keys are ignored while a dialog covers the view',
        (tester) async {
      final List<ValueItem<int>> items = fruitItems();
      final c = SearchDropDownController<int>(
        listItems: items,
        addMode: false,
        confirmDelete: true,
        onDeleteItem: items.remove,
      );
      await tester.pumpWidget(host(SearchDropDown<int>(controller: c)));
      await openSingle(tester);
      await tester.tap(find.byIcon(Icons.delete).first);
      // The row spinner animates while the dialog is open: no settle.
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.byType(WarningDialog), findsOneWidget);

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pump();
      expect(c.highlightedIndex, -1);
    });
  });
}

class _FakeContext extends Fake implements BuildContext {
  @override
  bool get mounted => false;
}
