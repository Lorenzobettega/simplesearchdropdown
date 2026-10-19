// Lifecycle, controller swap and list behaviour of the single dropdown (C10:
// F20, N54, F16, F11, N43), plus the row key of the multiple list (F11).

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';
import 'package:simple_search_dropdown/simple_search_dropdown.dart';

import '../support/harness.dart';

SearchDropDownController<int> _ctrl(
  List<ValueItem<int>> items, {
  SearchController? searchController,
  List<ValueItem<int>?>? calls,
  ValueItem<int>? initial,
}) => SearchDropDownController<int>(
  listItems: items,
  searchController: searchController,
  addMode: false,
  deleteMode: false,
  updateSelectedItem: calls?.add,
  initialSelectedItem: initial,
);

Finder _row(String label) => find.byWidgetPredicate(
  (Widget w) => w is DefaultListTile && w.item.label == label,
);

Finder _inRow(String label, Finder matching) =>
    find.descendant(of: _row(label), matching: matching);

double _listTop(WidgetTester tester) =>
    tester.getTopLeft(find.byType(ScrollablePositionedList)).dy;

double _rowTop(WidgetTester tester, String label) =>
    tester.getTopLeft(_row(label)).dy;

ThemeData _shrinkWrapTheme() => ThemeData(
  useMaterial3: true,
  searchViewTheme: const SearchViewThemeData(shrinkWrap: true),
);

void main() {
  group('F20: unmount releases only what the widget owns', () {
    testWidgets('with a caller SearchController the default '
        'disposeController leaves the controller usable by a new dropdown '
        '(7.x)', (tester) async {
      final SearchController external = SearchController();
      addTearDown(external.dispose);
      final SearchDropDownController<int> c = _ctrl(
        numberedItems(3),
        searchController: external,
      );
      addTearDown(c.dispose);
      await tester.pumpWidget(host(SearchDropDown<int>(controller: c)));
      await tester.pumpWidget(host(const SizedBox()));

      expect(c.isDisposed, isFalse);
      expect(c.ownsSearchController, isFalse);

      await tester.pumpWidget(host(SearchDropDown<int>(controller: c)));
      await openSingle(tester);
      expect(find.byType(DefaultListTile<int>), findsNWidgets(3));

      await typeInSingle(tester, 'Item 1');
      await tester.pumpAndSettle();
      expect(find.byType(DefaultListTile<int>), findsOneWidget);
      expect(_row('Item 1'), findsOneWidget);
    });

    testWidgets('a controller that owns its SearchController is still '
        'disposed with the widget', (tester) async {
      final SearchDropDownController<int> c = _ctrl(numberedItems(3));
      expect(c.ownsSearchController, isTrue);
      await tester.pumpWidget(host(SearchDropDown<int>(controller: c)));
      await tester.pumpWidget(host(const SizedBox()));

      expect(c.isDisposed, isTrue);
      expect(
        () => c.localSearchController.addListener(() {}),
        throwsFlutterError,
      );
    });
  });

  group('N54: the open view follows a swapped controller', () {
    testWidgets('the view arrow closes the view', (tester) async {
      final SearchDropDownController<int> a = _ctrl(fruitItems());
      addTearDown(a.dispose);
      final SearchDropDownController<int> b = _ctrl(numberedItems(3));
      await tester.pumpWidget(host(SearchDropDown<int>(controller: a)));
      await openSingle(tester);

      await tester.pumpWidget(host(SearchDropDown<int>(controller: b)));
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(Icons.arrow_drop_up));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.byIcon(Icons.arrow_drop_up), findsNothing);
      expect(b.localSearchController.isOpen, isFalse);
    });

    testWidgets('the view X follows and clears the current controller', (
      tester,
    ) async {
      final List<ValueItem<int>?> aCalls = <ValueItem<int>?>[];
      final List<ValueItem<int>?> bCalls = <ValueItem<int>?>[];
      final SearchDropDownController<int> a = _ctrl(
        fruitItems(),
        calls: aCalls,
      );
      addTearDown(a.dispose);
      final List<ValueItem<int>> items = numberedItems(3);
      final SearchDropDownController<int> b = _ctrl(
        items,
        calls: bCalls,
        initial: items[1],
      );
      await tester.pumpWidget(host(SearchDropDown<int>(controller: a)));
      await openSingle(tester);

      await tester.pumpWidget(host(SearchDropDown<int>(controller: b)));
      await tester.pumpAndSettle();
      final Finder viewClear = find.descendant(
        of: find.byType(SearchBar).last,
        matching: find.byIcon(Icons.clear),
      );
      expect(viewClear, findsOneWidget);

      await tester.tap(viewClear);
      await tester.pump();
      expect(b.selectedItem, isNull);
      expect(bCalls, <ValueItem<int>?>[null]);
      expect(aCalls, isEmpty);
    });
  });

  group('F16: the selection anchor lasts until the first typed query', () {
    testWidgets('typing after opening with a selection lists the results '
        'from the first match', (tester) async {
      final List<ValueItem<int>> items = numberedItems(200);
      final SearchDropDownController<int> c = _ctrl(items, initial: items[20]);
      await tester.pumpWidget(host(SearchDropDown<int>(controller: c)));
      await openSingle(tester);
      expect(_row('Item 20'), findsOneWidget);

      await typeInSingle(tester, 'Item 1');
      await tester.pumpAndSettle();
      expect(c.filteredItems.first.label, 'Item 1');
      expect(_row('Item 1'), findsOneWidget);
      expect(
        _rowTop(tester, 'Item 1'),
        moreOrLessEquals(_listTop(tester), epsilon: 1),
      );
    });

    testWidgets('narrowing then widening the query does not keep a stale '
        'index', (tester) async {
      final List<ValueItem<int>> items = numberedItems(200);
      final SearchDropDownController<int> c = _ctrl(items, initial: items[150]);
      await tester.pumpWidget(host(SearchDropDown<int>(controller: c)));
      await openSingle(tester);

      await typeInSingle(tester, 'Item 19');
      await tester.pumpAndSettle();
      await typeInSingle(tester, 'Item 1');
      await tester.pumpAndSettle();
      expect(_row('Item 1'), findsOneWidget);
      expect(
        _rowTop(tester, 'Item 1'),
        moreOrLessEquals(_listTop(tester), epsilon: 1),
      );
    });

    testWidgets('editing the selected item in the open view keeps the '
        'anchor (not a typed query)', (tester) async {
      final List<ValueItem<int>> items = numberedItems(200);
      final SearchDropDownController<int> c = SearchDropDownController<int>(
        listItems: items,
        addMode: false,
        deleteMode: false,
        editMode: true,
        newValueItem: (String s) => ValueItem<int>(label: s, value: 150),
        onEditItem: (ValueItem<int> a, ValueItem<int> b) {},
        initialSelectedItem: items[150],
      );
      await tester.pumpWidget(host(SearchDropDown<int>(controller: c)));
      await openSingle(tester);

      await tester.tap(_inRow('Item 150', find.byIcon(Icons.edit)));
      // The row spinner runs while the dialog is open: no pumpAndSettle.
      await tester.pump(const Duration(milliseconds: 400));
      await tester.enterText(
        find.descendant(
          of: find.byType(EditDialog),
          matching: find.byType(TextField),
        ),
        'Item 150 b',
      );
      await tester.tap(
        find.descendant(
          of: find.byType(AlertDialog),
          matching: find.text('Editar'),
        ),
      );
      await tester.pumpAndSettle();

      expect(c.selectedItem?.label, 'Item 150 b');
      expect(c.localSearchController.isOpen, isTrue);
      expect(_row('Item 150 b'), findsOneWidget);
      expect(_row('Item 0'), findsNothing);
    });
  });

  group('F16: what keeps or drops the anchor', () {
    testWidgets('the keyboard still scrolls the list once the anchor is '
        'dropped', (tester) async {
      final List<ValueItem<int>> items = numberedItems(200);
      final SearchDropDownController<int> c = _ctrl(items, initial: items[20]);
      await tester.pumpWidget(host(SearchDropDown<int>(controller: c)));
      await openSingle(tester);
      await typeInSingle(tester, 'Item 1');
      await tester.pumpAndSettle();
      expect(_row('Item 199'), findsNothing);

      await tester.sendKeyEvent(LogicalKeyboardKey.pageDown);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(c.highlightedIndex, c.filteredItems.length - 1);
      expect(_row('Item 199'), findsOneWidget);
    });

    testWidgets('clearing the selection from the open view, then deleting a '
        'row, keeps the anchor', (tester) async {
      final List<ValueItem<int>> items = numberedItems(200);
      final SearchDropDownController<int> c = SearchDropDownController<int>(
        listItems: items,
        addMode: false,
        onDeleteItem: (_) {},
        initialSelectedItem: items[150],
      );
      await tester.pumpWidget(host(SearchDropDown<int>(controller: c)));
      await openSingle(tester);

      await tester.tap(
        find.descendant(
          of: find.byType(SearchBar).last,
          matching: find.byIcon(Icons.clear),
        ),
      );
      await tester.pumpAndSettle();
      expect(c.selectedItem, isNull);
      expect(c.localSearchController.isOpen, isTrue);
      expect(_row('Item 150'), findsOneWidget);

      // A results change with the text empty (no typed query).
      await tester.tap(_inRow('Item 151', find.byType(IconButton)));
      await tester.pumpAndSettle();
      expect(_row('Item 151'), findsNothing);
      expect(_row('Item 150'), findsOneWidget);
      expect(_row('Item 0'), findsNothing);
    });

    testWidgets('reopening with a leftover query lists its results from the '
        'top, not from the selection', (tester) async {
      final List<ValueItem<int>> items = numberedItems(200);
      final SearchDropDownController<int> c = _ctrl(items, initial: items[150]);
      await tester.pumpWidget(host(SearchDropDown<int>(controller: c)));
      await openSingle(tester);
      await typeInSingle(tester, 'Item 1');
      await tester.tap(find.byIcon(Icons.arrow_drop_up));
      await tester.pumpAndSettle();
      expect(c.localSearchController.text, 'Item 1');

      await openSingle(tester);
      expect(c.filteredItems.first.label, 'Item 1');
      expect(c.selectedIndex, greaterThan(0));
      expect(_row('Item 1'), findsOneWidget);
      expect(
        _rowTop(tester, 'Item 1'),
        moreOrLessEquals(_listTop(tester), epsilon: 1),
      );
    });
  });

  group('F11: a row spinner stays with its item', () {
    testWidgets('single: results changing during an async delete do not '
        'move the spinner to another item', (tester) async {
      final Completer<void> pending = Completer<void>();
      final SearchDropDownController<int> c = SearchDropDownController<int>(
        listItems: fruitItems(),
        addMode: false,
        onDeleteItem: (_) => pending.future,
      );
      await tester.pumpWidget(
        host(
          SearchDropDown<int>(
            controller: c,
            overlayListSettings: const SimpleOverlaySettings(dialogHeight: 400),
          ),
        ),
      );
      await openSingle(tester);

      await tester.tap(_inRow('Banana', find.byType(IconButton)));
      await tester.pump();
      expect(
        _inRow('Banana', find.byType(CircularProgressIndicator)),
        findsOneWidget,
      );

      c.localSearchController.text = 'b';
      await tester.pump();
      expect(find.byType(DefaultListTile<int>), findsNWidgets(2));
      expect(
        _inRow('abacaxi', find.byType(CircularProgressIndicator)),
        findsNothing,
      );
      expect(_inRow('abacaxi', find.byType(IconButton)), findsOneWidget);

      pending.complete();
      await tester.pumpAndSettle();
      expect(_row('Banana'), findsNothing);
      expect(find.byType(CircularProgressIndicator), findsNothing);
    });

    testWidgets('multiple: results changing during an async delete do not '
        'move the spinner to another item', (tester) async {
      final Completer<void> pending = Completer<void>();
      final MultipleSearchDropDownController<int> c =
          MultipleSearchDropDownController<int>(
            listItems: fruitItems(),
            addMode: false,
            onDeleteItem: (_) => pending.future,
          );
      addTearDown(c.dispose);
      await tester.pumpWidget(host(MultipleSearchDropDown<int>(controller: c)));
      await openMultiple(tester);

      await tester.tap(_inRow('Banana', find.byType(IconButton)));
      await tester.pump();
      expect(
        _inRow('Banana', find.byType(CircularProgressIndicator)),
        findsOneWidget,
      );

      c.search('b');
      await tester.pump();
      expect(find.byType(DefaultListTile<int>), findsNWidgets(2));
      expect(
        _inRow('abacaxi', find.byType(CircularProgressIndicator)),
        findsNothing,
      );
      expect(_inRow('abacaxi', find.byType(IconButton)), findsOneWidget);

      pending.complete();
      await tester.pumpAndSettle();
      expect(_row('Banana'), findsNothing);
    });
  });

  group('N43: SearchViewThemeData.shrinkWrap', () {
    testWidgets('a short list shrinks the view like 7.x', (tester) async {
      final SearchDropDownController<int> c = _ctrl(numberedItems(2));
      await tester.pumpWidget(
        host(SearchDropDown<int>(controller: c), theme: _shrinkWrapTheme()),
      );
      await openSingle(tester);

      final Finder rows = find.byType(DefaultListTile<int>);
      expect(rows, findsNWidgets(2));
      final double rowsHeight =
          tester.getSize(rows.first).height + tester.getSize(rows.last).height;
      final double listHeight = tester
          .getSize(find.byType(ScrollablePositionedList))
          .height;
      expect(listHeight, moreOrLessEquals(rowsHeight, epsilon: 1));
    });

    testWidgets('shrinkWrap still caps at dialogHeight and opens scrolled to '
        'the selection', (tester) async {
      final List<ValueItem<int>> items = numberedItems(200);
      final SearchDropDownController<int> c = _ctrl(items, initial: items[150]);
      await tester.pumpWidget(
        host(SearchDropDown<int>(controller: c), theme: _shrinkWrapTheme()),
      );
      await openSingle(tester);

      expect(
        tester.getSize(find.byType(ScrollablePositionedList)).height,
        lessThanOrEqualTo(200),
      );
      expect(_row('Item 150'), findsOneWidget);
      expect(
        tester.widget<DefaultListTile<int>>(_row('Item 150')).selected,
        isTrue,
      );
    });

    testWidgets('without the theme a short list keeps the full height', (
      tester,
    ) async {
      final SearchDropDownController<int> c = _ctrl(numberedItems(2));
      await tester.pumpWidget(host(SearchDropDown<int>(controller: c)));
      await openSingle(tester);

      final Finder rows = find.byType(DefaultListTile<int>);
      final double rowsHeight =
          tester.getSize(rows.first).height + tester.getSize(rows.last).height;
      expect(
        tester.getSize(find.byType(ScrollablePositionedList)).height,
        greaterThan(rowsHeight + 1),
      );
    });
  });
}
