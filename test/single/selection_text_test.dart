// Selection identity and text model of the single dropdown (C7: F4, F5, F6,
// N33, N23).

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:simple_search_dropdown/simple_search_dropdown.dart';

import '../support/harness.dart';

const SimpleOverlaySettings _tall = SimpleOverlaySettings(dialogHeight: 400);

SearchDropDownController<T> _ctrl<T>(
  List<ValueItem<T>> items, {
  ValueItem<T>? initial,
  List<ValueItem<T>?>? calls,
  void Function()? onFilterUpdated,
  bool editMode = false,
  ValueItem<T> Function(String)? newValueItem,
}) => SearchDropDownController<T>(
  items: items,
  addMode: false,
  deleteMode: false,
  editMode: editMode,
  onEditItem: editMode ? (_, _) {} : null,
  newValueItem: newValueItem,
  initialSelectedItem: initial,
  updateSelectedItem: calls?.add,
  onFilterUpdated: onFilterUpdated,
);

Future<void> _pump<T>(
  WidgetTester tester,
  SearchDropDownController<T> c, {
  SimpleSearchbarSettings settings = defaultSearchBarSettings,
}) => tester.pumpWidget(
  host(
    SearchDropDown<T>(
      controller: c,
      searchBarSettings: settings,
      overlayListSettings: _tall,
    ),
  ),
);

Finder _row<T>(String label) => find.byWidgetPredicate(
  (w) => w is DefaultListTile<T> && w.item.label == label,
);

DefaultListTile<T> _tile<T>(WidgetTester tester, String label) =>
    tester.widget<DefaultListTile<T>>(_row<T>(label));

List<String> _rowLabels<T>(WidgetTester tester) => tester
    .widgetList<DefaultListTile<T>>(find.byType(DefaultListTile<T>))
    .map((t) => t.item.label)
    .toList();

Future<void> _tapRow<T>(WidgetTester tester, String label) async {
  await tester.tap(
    find.descendant(of: _row<T>(label), matching: find.byType(TextButton)),
  );
  await tester.pumpAndSettle();
}

Future<void> _key(WidgetTester tester, LogicalKeyboardKey key) async {
  await tester.sendKeyEvent(key);
  await tester.pumpAndSettle();
}

Future<void> _closeWithArrow(WidgetTester tester) async {
  await tester.tap(find.byIcon(Icons.arrow_drop_up));
  await tester.pumpAndSettle();
}

Future<void> _edit<T>(WidgetTester tester, String label, String text) async {
  await tester.tap(
    find.descendant(of: _row<T>(label), matching: find.byIcon(Icons.edit)),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 400));
  await tester.enterText(
    find.descendant(
      of: find.byType(EditDialog),
      matching: find.byType(TextField),
    ),
    text,
  );
  await tester.tap(
    find.descendant(
      of: find.byType(AlertDialog),
      matching: find.text('Editar'),
    ),
  );
  await tester.pumpAndSettle();
}

List<String> _labels<T>(Iterable<ValueItem<T>> items) =>
    items.map((e) => e.label).toList();

/// A value without `==` (identity only), like the example's `Custom`.
class _Opaque {
  _Opaque();
}

/// A value whose `==` is counted (and compares [id]).
class _Counted {
  _Counted(this.id);
  final int id;
  static int equalityChecks = 0;

  @override
  bool operator ==(Object other) {
    equalityChecks++;
    return other is _Counted && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

void main() {
  group('F4: the selected label shown at open is not a query', () {
    testWidgets('Enter right after reopening keeps the current selection', (
      tester,
    ) async {
      final calls = <ValueItem<int>?>[];
      final c = _ctrl(numberedItems(4), calls: calls);
      await _pump(tester, c);
      await openSingle(tester);
      await _tapRow<int>(tester, 'Item 2');
      await openSingle(tester);
      // D1: every item is listed.
      expect(_labels(c.filteredItems), hasLength(4));

      await _key(tester, LogicalKeyboardKey.enter);

      expect(c.selectedItem?.label, 'Item 2');
      expect(c.localSearchController.text, 'Item 2');
      expect(c.localSearchController.isOpen, isFalse);
      expect(_labels(calls.whereType<ValueItem<int>>()), <String>[
        'Item 2',
        'Item 2',
      ]);
    });

    testWidgets('IME done right after reopening keeps the current selection', (
      tester,
    ) async {
      final c = _ctrl(numberedItems(4));
      await _pump(tester, c);
      await openSingle(tester);
      await _tapRow<int>(tester, 'Item 2');
      await openSingle(tester);

      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();

      expect(c.selectedItem?.label, 'Item 2');
    });

    testWidgets('retyping the selected label filters and Enter selects it', (
      tester,
    ) async {
      final c = _ctrl(numberedItems(4));
      await _pump(tester, c);
      await openSingle(tester);
      await _tapRow<int>(tester, 'Item 2');
      await openSingle(tester);

      await typeInSingle(tester, 'Item');
      await typeInSingle(tester, 'Item 2');
      expect(_labels(c.filteredItems), <String>['Item 2']);

      await _key(tester, LogicalKeyboardKey.enter);
      expect(c.selectedItem?.label, 'Item 2');
    });

    test('typing the selected label after editing the text filters by it', () {
      final List<ValueItem<int>> items = fruitItems();
      final c = _ctrl(items, initial: items[1]);
      addTearDown(c.dispose);
      c.onSearchOpen();
      expect(_labels(c.filteredItems), hasLength(5), reason: 'D1');

      c.localSearchController.text = 'Ban';
      c.localSearchController.text = 'Banana';

      expect(_labels(c.filteredItems), <String>['Banana']);
    });

    testWidgets('Enter on reopen with a selection outside the list does '
        'nothing when its label matches no item (7.x)', (tester) async {
      final calls = <ValueItem<int>?>[];
      final c = _ctrl(
        numberedItems(3),
        initial: const ValueItem<int>(label: 'Kiwi', value: 99),
        calls: calls,
      );
      await _pump(tester, c);
      await openSingle(tester);
      expect(_labels(c.filteredItems), hasLength(3), reason: 'D1');

      await _key(tester, LogicalKeyboardKey.enter);

      expect(c.selectedItem?.label, 'Kiwi');
      expect(calls, isEmpty);
    });

    testWidgets('Enter on reopen with a selection outside the list selects '
        'the first item matching its label (7.x)', (tester) async {
      final calls = <ValueItem<int>?>[];
      final c = _ctrl(
        <ValueItem<int>>[
          const ValueItem(label: 'Apple', value: 1),
          const ValueItem(label: 'Item 7', value: 7),
        ],
        initial: const ValueItem<int>(label: 'Item', value: 99),
        calls: calls,
      );
      await _pump(tester, c);
      await openSingle(tester);

      await _key(tester, LogicalKeyboardKey.enter);

      expect(c.selectedItem?.label, 'Item 7');
      expect(_labels(calls.whereType<ValueItem<int>>()), <String>['Item 7']);
    });
  });

  group('F5: one selection predicate (== first, label as fallback)', () {
    final List<ValueItem<int>> dupes = <ValueItem<int>>[
      const ValueItem(label: 'João Silva', value: 1),
      const ValueItem(label: 'João Silva', value: 2),
      const ValueItem(label: 'Maria', value: 3),
    ];

    testWidgets('duplicate labels: only the == row is marked selected', (
      tester,
    ) async {
      final List<ValueItem<int>> items = List<ValueItem<int>>.of(dupes);
      final c = _ctrl(items, initial: items[1]);
      await _pump(tester, c);
      await openSingle(tester);

      final List<DefaultListTile<int>> tiles = tester
          .widgetList<DefaultListTile<int>>(find.byType(DefaultListTile<int>))
          .where((t) => t.item.label == 'João Silva')
          .toList();
      expect(tiles, hasLength(2));
      expect(tiles.where((t) => t.selected).map((t) => t.item.value), <int>[2]);
      expect(c.isSelected(items[0]), isFalse);
      expect(c.isSelected(items[1]), isTrue);
      expect(c.selectedIndex, 1);
    });

    test('values without ==: rows still match the selection by label', () {
      final List<ValueItem<Object>> items = <ValueItem<Object>>[
        ValueItem<Object>(label: 'Apple', value: _Opaque()),
        ValueItem<Object>(label: 'Banana', value: _Opaque()),
      ];
      final c = _ctrl<Object>(
        items,
        initial: ValueItem<Object>(label: 'Banana', value: _Opaque()),
      );
      addTearDown(c.dispose);
      expect(c.isSelected(items[1]), isTrue);
      expect(c.isSelected(items[0]), isFalse);
    });

    test('the label fallback follows a change of the results', () {
      final List<ValueItem<int>> items = List<ValueItem<int>>.of(dupes);
      final c = _ctrl(items, initial: items[1]);
      addTearDown(c.dispose);
      expect(c.isSelected(items[0]), isFalse);

      // The == row leaves the list: only the label can match now. The same
      // selection instance comes back, so only the new results tell.
      final ValueItem<int> other = items[0];
      final ValueItem<int> selected = items[1];
      c
        ..updateListItems(<ValueItem<int>>[...items]..removeAt(1), false)
        ..selectedItem = selected;

      expect(c.isSelected(other), isTrue);
    });

    test('the label fallback follows a change of the selection', () {
      final List<ValueItem<int>> items = List<ValueItem<int>>.of(dupes);
      final c = _ctrl(items, initial: items[1]);
      addTearDown(c.dispose);
      expect(c.isSelected(items[0]), isFalse);

      // A selection that is no row (e.g. rebuilt from storage).
      c.selectedItem = const ValueItem<int>(label: 'João Silva', value: 9);

      expect(c.isSelected(items[0]), isTrue);
      expect(c.isSelected(items[1]), isTrue);
    });

    test('marking rows costs O(1) per row (cached per results/selection)', () {
      final List<ValueItem<_Counted>> items =
          List<ValueItem<_Counted>>.generate(
            200,
            (i) => ValueItem<_Counted>(label: 'X', value: _Counted(i)),
          );
      final c = _ctrl<_Counted>(
        items,
        initial: ValueItem<_Counted>(label: 'X', value: _Counted(-1)),
      );
      addTearDown(c.dispose);
      _Counted.equalityChecks = 0;
      for (int pass = 0; pass < 2; pass++) {
        for (final ValueItem<_Counted> item in c.filteredItems) {
          expect(c.isSelected(item), isTrue);
        }
      }
      // One scan of the results plus one == per call; a scan per row would
      // be 200 * 200 * 2.
      expect(_Counted.equalityChecks, lessThan(1000));
    });
  });

  group('F6: editing the selected row', () {
    testWidgets('a row shown as selected by label (value without ==) is '
        're-selected after the edit', (tester) async {
      final List<ValueItem<Object>> items = <ValueItem<Object>>[
        ValueItem<Object>(label: 'Apple', value: _Opaque()),
        ValueItem<Object>(label: 'Banana', value: _Opaque()),
      ];
      final sel = <ValueItem<Object>?>[];
      final c = _ctrl<Object>(
        items,
        editMode: true,
        newValueItem: (s) => ValueItem<Object>(label: s, value: _Opaque()),
        calls: sel,
        initial: ValueItem<Object>(label: 'Banana', value: _Opaque()),
      );
      await _pump(tester, c);
      await openSingle(tester);
      expect(_tile<Object>(tester, 'Banana').selected, isTrue);

      await _edit<Object>(tester, 'Banana', 'Banana2');

      expect(c.selectedItem?.label, 'Banana2');
      expect(sel.single?.label, 'Banana2');
      expect(_labels(c.items), <String>['Apple', 'Banana2']);
      expect(c.selectedIndex, isNot(-1));
    });

    testWidgets('editing the selected row re-selects the new item and keeps '
        'the list open', (tester) async {
      const ValueItem<int> ana = ValueItem(label: 'Ana', value: 1);
      final List<ValueItem<int>> items = <ValueItem<int>>[
        ana,
        const ValueItem(label: 'Banana', value: 2),
        const ValueItem(label: 'Uva', value: 3),
      ];
      final selections = <ValueItem<int>?>[];
      final c = _ctrl(
        items,
        editMode: true,
        newValueItem: (s) => ValueItem<int>(label: s, value: s.length),
        calls: selections,
        initial: ana,
      );
      await _pump(tester, c);
      await openSingle(tester);
      c.clearVisible = false;

      await _edit<int>(tester, 'Ana', 'Ana2');

      expect(c.selectedItem?.label, 'Ana2');
      expect(c.clearVisible, isTrue, reason: 'as selectItem');
      expect(_labels(selections.whereType<ValueItem<int>>()), <String>['Ana2']);
      expect(c.localSearchController.isOpen, isTrue);
      expect(c.localSearchController.text, 'Ana2');
      expect(_labels(c.filteredItems), <String>['Ana2', 'Banana', 'Uva']);
      expect(_rowLabels<int>(tester), <String>['Ana2', 'Banana', 'Uva']);
      expect(_tile<int>(tester, 'Ana2').selected, isTrue);

      // The new label is not a query: Enter keeps it (F4).
      await _key(tester, LogicalKeyboardKey.enter);
      expect(c.selectedItem?.label, 'Ana2');
      expect(c.localSearchController.text, 'Ana2');
    });

    testWidgets('editing the selected row keeps a typed query', (tester) async {
      const ValueItem<int> ana = ValueItem(label: 'Ana', value: 1);
      final List<ValueItem<int>> items = <ValueItem<int>>[
        ana,
        const ValueItem(label: 'Banana', value: 2),
      ];
      final c = _ctrl(
        items,
        editMode: true,
        newValueItem: (s) => ValueItem<int>(label: s, value: s.length),
        initial: ana,
      );
      await _pump(tester, c);
      await openSingle(tester);
      await typeInSingle(tester, 'An');

      await _edit<int>(tester, 'Ana', 'Ana2');

      expect(c.selectedItem?.label, 'Ana2');
      expect(c.localSearchController.isOpen, isTrue);
      expect(c.localSearchController.text, 'An');
      expect(_labels(c.filteredItems), <String>['Ana2', 'Banana']);
    });

    testWidgets('editing a same-label row that is not == to the selection '
        'keeps the selection', (tester) async {
      final List<ValueItem<int>> items = <ValueItem<int>>[
        const ValueItem(label: 'X', value: 1),
        const ValueItem(label: 'X', value: 2),
      ];
      final selections = <ValueItem<int>?>[];
      final c = _ctrl(
        items,
        editMode: true,
        newValueItem: (s) => ValueItem<int>(label: s, value: 10),
        calls: selections,
        initial: items[1],
      );
      await _pump(tester, c);
      await openSingle(tester);
      await tester.tap(find.byIcon(Icons.edit).first);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      await tester.enterText(
        find.descendant(
          of: find.byType(EditDialog),
          matching: find.byType(TextField),
        ),
        'Y',
      );
      await tester.tap(
        find.descendant(
          of: find.byType(AlertDialog),
          matching: find.text('Editar'),
        ),
      );
      await tester.pumpAndSettle();

      expect(_labels(c.items), <String>['Y', 'X']);
      expect(c.selectedItem, items[1]);
      expect(selections, isEmpty);
    });
  });

  group('N33: assigning selectedItem', () {
    testWidgets('syncs the bar text and clear button, without the callback', (
      tester,
    ) async {
      final List<ValueItem<int>> items = fruitItems();
      final calls = <ValueItem<int>?>[];
      final c = _ctrl(items, initial: items[1], calls: calls);
      await _pump(tester, c);
      expect(c.localSearchController.text, 'Banana');
      expect(find.byIcon(Icons.clear), findsOneWidget);

      c.selectedItem = items[2];
      await tester.pump();
      expect(c.localSearchController.text, 'Uva');
      expect(c.clearVisible, isTrue);
      expect(find.byIcon(Icons.clear), findsOneWidget);

      c.selectedItem = null;
      await tester.pump();
      expect(c.localSearchController.text, '');
      expect(c.clearVisible, isFalse);
      expect(find.byIcon(Icons.clear), findsNothing);

      c.selectedItem = items[2];
      await tester.pump();
      await openSingle(tester);
      expect(c.filteredItems, hasLength(5), reason: 'D1');
      expect(_tile<int>(tester, 'Uva').selected, isTrue);
      expect(calls, isEmpty);
    });

    testWidgets('while the view is open shows the label and every item', (
      tester,
    ) async {
      final c = _ctrl(fruitItems());
      await _pump(tester, c);
      await openSingle(tester);
      await typeInSingle(tester, 'Ba');
      expect(c.filteredItems.length, lessThan(5));

      c.selectedItem = c.items.firstWhere((e) => e.label == 'Uva');
      await tester.pump();

      expect(c.localSearchController.text, 'Uva');
      expect(c.filteredItems, hasLength(5));
      expect(c.localSearchController.isOpen, isTrue);
    });

    testWidgets('while the view is open with the text already equal to the '
        'label, the list stops filtering by it', (tester) async {
      final c = _ctrl(fruitItems());
      await _pump(tester, c);
      await openSingle(tester);
      await typeInSingle(tester, 'Uva');
      expect(_labels(c.filteredItems), <String>['Uva']);

      c.selectedItem = c.items.firstWhere((e) => e.label == 'Uva');
      await tester.pump();

      expect(c.filteredItems, hasLength(5));
    });

    testWidgets('null keeps text the user typed (only clears the old label)', (
      tester,
    ) async {
      final List<ValueItem<int>> items = fruitItems();
      final c = _ctrl(items, initial: items[1]);
      await _pump(tester, c);
      await openSingle(tester);
      await typeInSingle(tester, 'Uv');

      c.selectedItem = null;
      await tester.pump();

      expect(c.localSearchController.text, 'Uv');
      expect(c.clearVisible, isFalse);
      expect(_labels(c.filteredItems), <String>['Uva']);
    });
  });

  test('N33: assigning the item whose label is already the (closed) text '
      'lists every item', () {
    final c = _ctrl(fruitItems());
    addTearDown(c.dispose);
    c
      ..onSearchOpen()
      ..onSearchClose(false);
    // Written from code: the value (text and selection) is then unchanged
    // by the setter's own write, so no listener runs.
    c.localSearchController.text = 'Uva';
    expect(_labels(c.filteredItems), <String>['Uva']);

    c.selectedItem = c.items.firstWhere((e) => e.label == 'Uva');

    expect(c.filteredItems, hasLength(5));
  });

  group('N23: text changes while closed filter after the first open (7.x)', () {
    const SimpleSearchbarSettings clearOnClose = SimpleSearchbarSettings(
      clearOnClose: true,
    );

    testWidgets('clearing on close re-filters to the full list', (
      tester,
    ) async {
      var updates = 0;
      final c = _ctrl(numberedItems(3), onFilterUpdated: () => updates++);
      await _pump(tester, c, settings: clearOnClose);
      await openSingle(tester);
      await typeInSingle(tester, 'zzz');
      await tester.pump();
      expect(c.filteredItems, isEmpty);
      final int before = updates;

      await _closeWithArrow(tester);

      expect(c.localSearchController.text, '');
      expect(_labels(c.filteredItems), <String>['Item 0', 'Item 1', 'Item 2']);
      expect(updates, before + 1);
    });

    testWidgets('restoring the selected label on close lists every item', (
      tester,
    ) async {
      final c = _ctrl(numberedItems(3));
      await _pump(tester, c, settings: clearOnClose);
      await openSingle(tester);
      await _tapRow<int>(tester, 'Item 1');
      await openSingle(tester);
      await typeInSingle(tester, 'zzz');

      await _closeWithArrow(tester);

      expect(c.localSearchController.text, 'Item 1');
      expect(c.filteredItems, hasLength(3));
    });

    testWidgets('without clearOnClose the typed results are kept', (
      tester,
    ) async {
      var updates = 0;
      final c = _ctrl(numberedItems(3), onFilterUpdated: () => updates++);
      await _pump(tester, c);
      await openSingle(tester);
      await typeInSingle(tester, 'zzz');
      await tester.pump();
      final int before = updates;

      await _closeWithArrow(tester);

      expect(c.localSearchController.text, 'zzz');
      expect(c.filteredItems, isEmpty);
      expect(updates, before);
    });

    test('after the first open, text written while closed filters', () {
      var calls = 0;
      final c = _ctrl(fruitItems(), onFilterUpdated: () => calls++);
      addTearDown(c.dispose);
      c
        ..onSearchOpen()
        ..onSearchClose(false);

      c.localSearchController.text = 'ban';
      expect(_labels(c.filteredItems), <String>['Banana']);
      expect(calls, 1);

      c.localSearchController.text = '';
      expect(c.filteredItems, hasLength(5));
      expect(calls, 2);
    });

    test('clearSelection and a selection arm it too (7.x)', () {
      final c = _ctrl(fruitItems());
      addTearDown(c.dispose);
      c.clearSelection();
      c.localSearchController.text = 'ban';
      expect(_labels(c.filteredItems), <String>['Banana']);

      final n = _ctrl(fruitItems());
      addTearDown(n.dispose);
      n.clearSelectionAndNotify();
      n.localSearchController.text = 'ban';
      expect(_labels(n.filteredItems), <String>['Banana']);

      final d = _ctrl(fruitItems());
      addTearDown(d.dispose);
      d.forceSelection('Banana');
      expect(d.filteredItems, hasLength(5), reason: 'the label is no query');
      d.localSearchController.text = 'uva';
      expect(_labels(d.filteredItems), <String>['Uva']);
    });
  });
}
