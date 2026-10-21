// Counts the work the single dropdown does per user action (E3): bar and row
// rebuilds, text writes the package makes to itself, and notifications.
// Each test failed before the change it guards.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:simple_search_dropdown/simple_search_dropdown.dart';

import '../support/harness.dart';

/// Counts the builds of the package-built bar subtree: `actions` is read
/// only in the dropdown's own bar build and returns a new probe each time,
/// so Flutter's own anchor and focus frames (same instances) are not counted.
class _ProbeSettings extends SimpleSearchbarSettings {
  _ProbeSettings(this.onBuild);

  final VoidCallback onBuild;

  @override
  List<Widget> get actions => <Widget>[_Probe(onBuild)];
}

class _Probe extends StatelessWidget {
  const _Probe(this.onBuild);

  final VoidCallback onBuild;

  @override
  Widget build(BuildContext context) {
    onBuild();
    return const SizedBox(width: 1, height: 1);
  }
}

/// Row builds, through `itemWidgetBuilder` (called by every row build).
class _Rows {
  int built = 0;
  final List<String> labels = <String>[];

  late final SimpleOverlaySettings settings = SimpleOverlaySettings(
    dialogHeight: 400,
    itemWidgetBuilder: (ValueItem item) {
      built++;
      labels.add(item.label);
      return Text(item.label);
    },
  );
}

SearchDropDownController<int> _ctrl(
  List<ValueItem<int>> items, {
  ValueItem<int>? initial,
  void Function(ValueItem<int>?)? onSelected,
  void Function()? onFilterUpdated,
}) => SearchDropDownController<int>(
  items: items,
  addMode: false,
  deleteMode: false,
  initialSelectedItem: initial,
  updateSelectedItem: onSelected,
  onFilterUpdated: onFilterUpdated,
);

Future<void> _pump(
  WidgetTester tester,
  SearchDropDownController<int> controller, {
  SimpleOverlaySettings overlay = const SimpleOverlaySettings(
    dialogHeight: 400,
  ),
  SimpleSearchbarSettings bar = defaultSearchBarSettings,
}) async {
  tester.view.physicalSize = const Size(800, 600);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    host(
      SearchDropDown<int>(
        controller: controller,
        overlayListSettings: overlay,
        searchBarSettings: bar,
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Finder _row(String label) => find.byWidgetPredicate(
  (w) => w is DefaultListTile<int> && w.item.label == label,
);

/// A value whose `==` and `hashCode` count their calls.
class _Counted {
  _Counted(this.id);

  final int id;
  static int calls = 0;

  @override
  bool operator ==(Object other) {
    calls++;
    return other is _Counted && other.id == id;
  }

  @override
  int get hashCode {
    calls++;
    return id;
  }
}

void main() {
  group('bar', () {
    testWidgets('selecting a row does not rebuild the bar', (tester) async {
      int bar = 0;
      final c = _ctrl(numberedItems(20));
      await _pump(tester, c, bar: _ProbeSettings(() => bar++));
      await openSingle(tester);
      final int before = bar;
      await tester.tap(_row('Item 3'));
      await tester.pumpAndSettle();
      expect(c.selectedItem?.label, 'Item 3');
      expect(find.byType(DefaultListTile<int>), findsNothing);
      expect(bar - before, 0);
    });

    testWidgets('a selection from code does not rebuild the bar', (
      tester,
    ) async {
      int bar = 0;
      final c = _ctrl(numberedItems(20));
      await _pump(tester, c, bar: _ProbeSettings(() => bar++));
      final int before = bar;
      c
        ..selectedItem = c.items[4]
        ..clearVisible = false;
      await tester.pumpAndSettle();
      expect(bar - before, 0);
    });

    testWidgets('the clear button still follows the selection', (tester) async {
      final c = _ctrl(numberedItems(20));
      await _pump(tester, c);
      bool clearShown() =>
          find.byIcon(Icons.clear).hitTestable().evaluate().isNotEmpty;
      expect(clearShown(), isFalse);
      await openSingle(tester);
      await tester.tap(_row('Item 2'));
      await tester.pumpAndSettle();
      expect(clearShown(), isTrue);
      c.resetSelection();
      await tester.pumpAndSettle();
      expect(clearShown(), isFalse);
      c.clearVisible = true;
      await tester.pumpAndSettle();
      expect(clearShown(), isTrue);
    });

    testWidgets('enabled still rebuilds the bar', (tester) async {
      int bar = 0;
      final c = _ctrl(numberedItems(20));
      await _pump(tester, c, bar: _ProbeSettings(() => bar++));
      final int before = bar;
      c.enabled = false;
      await tester.pumpAndSettle();
      expect(bar - before, 1);
      expect(find.byType(DefaultListTile<int>), findsNothing);
      await tester.tap(find.byType(SearchBar), warnIfMissed: false);
      await tester.pumpAndSettle();
      expect(find.byType(DefaultListTile<int>), findsNothing, reason: 'off');
      c.enabled = true;
      await tester.pumpAndSettle();
      expect(bar - before, 2);
      await openSingle(tester);
      expect(find.byType(DefaultListTile<int>), findsWidgets);
    });
  });

  group('rows', () {
    testWidgets('a selection rebuilds only the old and the new selected row', (
      tester,
    ) async {
      final rows = _Rows();
      final c = _ctrl(numberedItems(20), initial: numberedItems(20)[1]);
      await _pump(tester, c, overlay: rows.settings);
      await openSingle(tester);
      expect(rows.built, greaterThan(5), reason: 'the view built its rows');
      rows
        ..built = 0
        ..labels.clear();
      await tester.tap(_row('Item 4'));
      await tester.pumpAndSettle();
      expect(c.selectedItem?.label, 'Item 4');
      expect(rows.labels.toSet(), <String>{'Item 1', 'Item 4'});
      expect(rows.built, 2);
    });

    testWidgets('an arrow key rebuilds only the rows it moves between', (
      tester,
    ) async {
      final rows = _Rows();
      final c = _ctrl(numberedItems(20), initial: numberedItems(20)[1]);
      await _pump(tester, c, overlay: rows.settings);
      await openSingle(tester);
      final List<List<String>> perKey = <List<String>>[];
      for (int i = 0; i < 3; i++) {
        rows.labels.clear();
        await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
        await tester.pumpAndSettle();
        perKey.add(List<String>.of(rows.labels)..sort());
      }
      expect(c.highlightedIndex, 3);
      expect(perKey, <List<String>>[
        <String>['Item 1'],
        <String>['Item 1', 'Item 2'],
        <String>['Item 2', 'Item 3'],
      ]);
      final DefaultListTile<int> tile = tester.widget(_row('Item 3'));
      expect(tile.highlighted, isTrue);
      expect(
        tester.widget<DefaultListTile<int>>(_row('Item 1')).selected,
        true,
      );
    });

    testWidgets('Enter on a highlight rebuilds at most two rows', (
      tester,
    ) async {
      final rows = _Rows();
      final c = _ctrl(numberedItems(20), initial: numberedItems(20)[1]);
      await _pump(tester, c, overlay: rows.settings);
      await openSingle(tester);
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pumpAndSettle();
      rows.built = 0;
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();
      expect(c.selectedItem?.label, 'Item 2');
      expect(c.highlightedIndex, -1);
      expect(rows.built, lessThanOrEqualTo(2));
    });
  });

  group('closing view', () {
    testWidgets('clearOnClose keeps the add row while the view fades', (
      tester,
    ) async {
      final c = SearchDropDownController<int>(
        items: numberedItems(5),
        newValueItem: (String s) => ValueItem<int>(label: s, value: 9),
        onAddItem: (_) {},
        deleteMode: false,
      );
      await _pump(
        tester,
        c,
        bar: const SimpleSearchbarSettings(clearOnClose: true),
      );
      await openSingle(tester);
      await typeInSingle(tester, 'zzz');
      await tester.pumpAndSettle();
      expect(find.byType(DefaultAddListItem), findsOneWidget);
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pump();
      expect(c.localSearchController.text, '');
      expect(find.byType(DefaultAddListItem), findsOneWidget);
      await tester.pumpAndSettle();
      expect(find.byType(DefaultAddListItem), findsNothing);
      expect(c.filteredItems.length, 5);
    });

    testWidgets('clearOnClose does not re-filter the fading rows (D1 kept)', (
      tester,
    ) async {
      final rows = _Rows();
      int filterUpdates = 0;
      final items = numberedItems(100);
      final c = _ctrl(
        items,
        initial: items[50],
        onFilterUpdated: () => filterUpdates++,
      );
      await _pump(
        tester,
        c,
        overlay: rows.settings,
        bar: const SimpleSearchbarSettings(clearOnClose: true),
      );
      await openSingle(tester);
      await typeInSingle(tester, 'Item 9');
      await tester.pumpAndSettle();
      expect(c.filteredItems.length, 11);
      rows.built = 0;
      final int updates = filterUpdates;
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pump();
      // The fading view keeps the rows it showed.
      expect(_row('Item 9'), findsOneWidget);
      expect(_row('Item 0'), findsNothing);
      await tester.pumpAndSettle();
      expect(find.byType(DefaultListTile<int>), findsNothing);
      expect(rows.built, 0);
      expect(c.localSearchController.text, 'Item 50');
      expect(c.filteredItems.length, 100);
      expect(filterUpdates - updates, 1, reason: 'onFilterUpdated unchanged');

      // D1: the next open lists every item, scrolled to the selection.
      await openSingle(tester);
      expect(_row('Item 50'), findsOneWidget);
      expect(_row('Item 0'), findsNothing);
      expect(c.filteredItems.length, 100);
    });

    testWidgets('the arrow closes without writing the text again', (
      tester,
    ) async {
      final items = numberedItems(20);
      final c = _ctrl(items, initial: items[2]);
      await _pump(tester, c);
      await openSingle(tester);
      await typeInSingle(tester, 'Item 1');
      int writes = 0;
      void count() => writes++;
      c.localSearchController.addListener(count);
      addTearDown(() => c.localSearchController.removeListener(count));
      await tester.tap(find.byTooltip('Fechar lista'));
      await tester.pumpAndSettle();
      expect(find.byType(DefaultListTile<int>), findsNothing);
      expect(c.localSearchController.text, 'Item 1');
      expect(writes, 0);
    });
  });

  group('notifications', () {
    testWidgets('re-selecting the selected item does not notify', (
      tester,
    ) async {
      final items = numberedItems(20);
      final List<ValueItem<int>?> selected = <ValueItem<int>?>[];
      final c = _ctrl(items, initial: items[3], onSelected: selected.add);
      await _pump(tester, c);
      await openSingle(tester);
      int notifies = 0;
      c.addListener(() => notifies++);
      await tester.tap(_row('Item 3'));
      await tester.pumpAndSettle();
      expect(find.byType(DefaultListTile<int>), findsNothing, reason: 'closed');
      expect(selected, <ValueItem<int>?>[items[3]]);
      expect(c.selectedItem, items[3]);
      expect(c.clearVisible, isTrue);
      expect(notifies, 0);
    });

    testWidgets('selecting another item still notifies once', (tester) async {
      final items = numberedItems(20);
      final c = _ctrl(items, initial: items[3]);
      await _pump(tester, c);
      await openSingle(tester);
      int notifies = 0;
      c.addListener(() => notifies++);
      await tester.tap(_row('Item 5'));
      await tester.pumpAndSettle();
      expect(notifies, 1);
    });

    testWidgets('updateListItems over a typed query filters once', (
      tester,
    ) async {
      int filterUpdates = 0;
      final c = _ctrl(
        numberedItems(20),
        onFilterUpdated: () => filterUpdates++,
      );
      await _pump(tester, c);
      await openSingle(tester);
      await typeInSingle(tester, 'Item 1');
      await tester.pumpAndSettle();
      expect(c.filteredItems.length, 11);
      filterUpdates = 0;
      int results = 0;
      c.results.addListener(() => results++);
      c.updateListItems(numberedItems(5), true);
      await tester.pumpAndSettle();
      expect(c.localSearchController.text, '');
      expect(c.filteredItems.length, 5);
      expect(results, 1);
      expect(filterUpdates, 1);
    });

    testWidgets('updateListItems with a selection notifies once', (
      tester,
    ) async {
      final items = numberedItems(20);
      final List<ValueItem<int>?> selected = <ValueItem<int>?>[];
      int filterUpdates = 0;
      final c = _ctrl(
        items,
        onSelected: selected.add,
        onFilterUpdated: () => filterUpdates++,
      );
      await _pump(tester, c);
      await openSingle(tester);
      await tester.tap(_row('Item 3'));
      await tester.pumpAndSettle();
      selected.clear();
      filterUpdates = 0;
      int notifies = 0;
      int results = 0;
      c.addListener(() => notifies++);
      c.results.addListener(() => results++);
      c.updateListItems(numberedItems(5), false);
      await tester.pumpAndSettle();
      expect(c.selectedItem, isNull);
      expect(c.localSearchController.text, '');
      expect(c.filteredItems.length, 5);
      expect(selected, <ValueItem<int>?>[null]);
      expect(notifies, 1);
      expect(results, 1);
      expect(filterUpdates, 1);
    });

    testWidgets('notifications made during a build are sent once', (
      tester,
    ) async {
      final c = _ctrl(numberedItems(3));
      addTearDown(c.dispose);
      int notifies = 0;
      c.addListener(() => notifies++);
      bool done = false;
      await tester.pumpWidget(
        Builder(
          builder: (_) {
            if (!done) {
              done = true;
              c
                ..clearVisible = true
                ..clearVisible = false
                ..clearVisible = true;
            }
            return const SizedBox();
          },
        ),
      );
      expect(c.clearVisible, isTrue);
      expect(notifies, 1);
      // A later build queues a new one.
      done = false;
      await tester.pumpWidget(Builder(builder: (_) => const SizedBox()));
      await tester.pumpWidget(
        Builder(
          builder: (_) {
            if (!done) {
              done = true;
              c.clearVisible = false;
            }
            return const SizedBox();
          },
        ),
      );
      expect(notifies, 2);
    });
  });

  group('open', () {
    // A sorted base reads every item's cached sort key (a hash lookup each)
    // when it is rebuilt.
    test('onSearchOpen does not rebuild an unchanged list', () {
      final items = List<ValueItem<_Counted>>.generate(
        1000,
        (i) => ValueItem<_Counted>(label: 'Item $i', value: _Counted(i)),
      );
      final c = SearchDropDownController<_Counted>(
        items: items,
        addMode: false,
        deleteMode: false,
        sort: SortType.alphabetical,
      );
      addTearDown(c.dispose);
      _Counted.calls = 0;
      c
        ..onSearchOpen()
        ..onSearchClose(false)
        ..onSearchOpen();
      expect(_Counted.calls, 0);
      expect(c.filteredItems.length, 1000);
      c.updateListItems(items.take(10).toList(), false);
      expect(c.filteredItems.length, 10);
    });
  });
}
