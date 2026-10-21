// Visual (golden) and deterministic performance baselines for
// simple_search_dropdown v7.8.0, recorded before the 8.0 refactor.
//
// (a) Golden tests (tag: golden) capture the whole 800x600 surface at
//     devicePixelRatio 1 with the default test font. Regenerate with
//     `flutter test --update-goldens <this file>` only on the pinned Flutter
//     version.
// (b) Perf baselines are NOT golden-tagged. They count widget work (rows
//     built through itemWidgetBuilder, onFilterUpdated calls, rebuilds of a
//     custom searchBarSettings.actions widget) with fake time only, print the
//     numbers as `BASELINE <metric>=<n>` and assert them loosely so a refactor
//     that does less work still passes.
//
// Rows that show an indeterminate spinner (delete / edit in progress) never
// settle, so those flows use [_frames] instead of pumpAndSettle.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:simple_search_dropdown/simple_search_dropdown.dart';
import 'package:simple_search_dropdown/src/multiple/multiple_listview.dart';

import '../support/harness.dart';

// A taller overlay so every row of the 5-item fixture is visible.
const SimpleOverlaySettings _tall = SimpleOverlaySettings(dialogHeight: 400);

const List<String> _goldenTags = <String>['golden'];

ValueItem<int> _newItem(String input) =>
    ValueItem<int>(label: input, value: 99);

SearchDropDownController<int> _ctrl(
  List<ValueItem<int>> items, {
  bool addMode = false,
  bool deleteMode = false,
  bool editMode = false,
  bool confirmDelete = false,
  bool showClearIcon = false,
  bool enabled = true,
  ValueItem<int>? initial,
  void Function()? onFilterUpdated,
}) => SearchDropDownController<int>(
  items: items,
  addMode: addMode,
  newValueItem: _newItem,
  onAddItem: (_) {},
  deleteMode: deleteMode,
  onDeleteItem: (_) {},
  confirmDelete: confirmDelete,
  editMode: editMode,
  onEditItem: (_, _) {},
  showClearIcon: showClearIcon,
  enabled: enabled,
  initialSelectedItem: initial,
  onFilterUpdated: onFilterUpdated,
);

/// Fixes the surface to 800x600 logical pixels at devicePixelRatio 1.
void _fixSurface(WidgetTester tester) {
  tester.view.physicalSize = const Size(800, 600);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
}

Future<void> _pumpSingle(
  WidgetTester tester,
  SearchDropDownController<int> controller, {
  SimpleOverlaySettings overlay = _tall,
  SimpleSearchbarSettings settings = defaultSearchBarSettings,
}) async {
  _fixSurface(tester);
  await tester.pumpWidget(
    host(
      SearchDropDown<int>(
        controller: controller,
        overlayListSettings: overlay,
        searchBarSettings: settings,
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> _pumpMultiple(
  WidgetTester tester,
  List<ValueItem<int>> items,
  List<ValueItem<int>> selected,
) async {
  _fixSurface(tester);
  final MultipleSearchDropDownController<int> controller =
      MultipleSearchDropDownController<int>(
        items: items,
        selectedItems: selected,
        addMode: false,
        deleteMode: false,
      );
  addTearDown(controller.dispose);
  await tester.pumpWidget(
    host(
      MultipleSearchDropDown<int>(
        controller: controller,
        overlayListSettings: _tall,
      ),
    ),
  );
  await tester.pumpAndSettle();
}

/// Pumps enough frames for a dialog route transition, without settling.
Future<void> _frames(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 400));
}

Future<void> _matchesGolden(String name) => expectLater(
  find.byType(MaterialApp),
  matchesGoldenFile('goldens/$name.png'),
);

// ---------------------------------------------------------------------------
// Perf helpers
// ---------------------------------------------------------------------------

/// Mutable counters shared between the fixtures and the test body.
class _Counters {
  int rows = 0;
  int bar = 0;
  int filterUpdates = 0;
}

/// A searchBarSettings.actions entry that counts its own builds.
class _CountingAction extends StatelessWidget {
  const _CountingAction(this.counters);

  final _Counters counters;

  @override
  Widget build(BuildContext context) {
    counters.bar++;
    return const SizedBox(width: 1, height: 1);
  }
}

/// Bar settings whose `actions` is a new widget on every read, so each
/// re-run of the dropdown's bar build (ListenableBuilder/setState) rebuilds
/// the probe: Flutter cannot short-circuit an identical widget instance.
class _CountingBarSettings extends SimpleSearchbarSettings {
  _CountingBarSettings(this.counters);

  final _Counters counters;

  @override
  List<Widget> get actions => <Widget>[_CountingAction(counters)];
}

const String _typed = 'Item 99';

Future<SearchDropDownController<int>> _pumpPerf(
  WidgetTester tester,
  _Counters counters,
) async {
  final SearchDropDownController<int> controller = _ctrl(
    numberedItems(10000),
    onFilterUpdated: () => counters.filterUpdates++,
  );
  await _pumpSingle(
    tester,
    controller,
    overlay: SimpleOverlaySettings(
      itemWidgetBuilder: (ValueItem item) {
        counters.rows++;
        return Text(item.label);
      },
    ),
    settings: _CountingBarSettings(counters),
  );
  return controller;
}

/// Types [_typed] one character at a time (each step replaces the field text
/// with the next prefix, like a user typing) and returns, per keystroke, the
/// delta of [read] measured after that keystroke settles.
Future<List<int>> _typeCounting(
  WidgetTester tester,
  int Function() read,
) async {
  final List<int> perKey = <int>[];
  for (int i = 1; i <= _typed.length; i++) {
    final int before = read();
    await tester.enterText(focusedField(), _typed.substring(0, i));
    await tester.pumpAndSettle();
    perKey.add(read() - before);
  }
  return perKey;
}

int _sum(List<int> values) => values.fold<int>(0, (a, b) => a + b);

void main() {
  // -------------------------------------------------------------------------
  // (a) Golden baselines
  // -------------------------------------------------------------------------

  group('golden: single closed, no selection', () {
    testWidgets('bar shows hint "Pesquisar" and closed arrow', (tester) async {
      await _pumpSingle(tester, _ctrl(fruitItems()));

      expect(find.text('Pesquisar'), findsOneWidget);
      expect(find.byIcon(Icons.arrow_drop_down), findsOneWidget);
      await _matchesGolden('single_closed');
    }, tags: _goldenTags);
  });

  group('golden: single closed with selection and clear icon', () {
    testWidgets('bar shows selected label and the clear icon', (tester) async {
      final items = fruitItems();
      await _pumpSingle(
        tester,
        _ctrl(items, showClearIcon: true, initial: items[1]),
      );

      expect(find.text('Banana'), findsOneWidget);
      expect(find.byIcon(Icons.clear), findsOneWidget);
      await _matchesGolden('single_closed_selected_clear');
    }, tags: _goldenTags);
  });

  group('golden: single open with 5 items', () {
    testWidgets('view lists all 5 fruit rows', (tester) async {
      await _pumpSingle(tester, _ctrl(fruitItems()));
      await openSingle(tester);

      expect(find.byType(DefaultListTile<int>), findsNWidgets(5));
      await _matchesGolden('single_open');
    }, tags: _goldenTags);
  });

  group('golden: single open filtered', () {
    testWidgets('typing "ba" leaves Banana and abacaxi', (tester) async {
      await _pumpSingle(tester, _ctrl(fruitItems()));
      await openSingle(tester);
      await typeInSingle(tester, 'ba');
      await tester.pumpAndSettle();

      expect(find.byType(DefaultListTile<int>), findsNWidgets(2));
      await _matchesGolden('single_open_filtered');
    }, tags: _goldenTags);
  });

  group('golden: single open empty result with add row', () {
    testWidgets('no match + addMode shows the "Criar" add row', (tester) async {
      await _pumpSingle(tester, _ctrl(fruitItems(), addMode: true));
      await openSingle(tester);
      await typeInSingle(tester, 'Kiwi');
      await tester.pumpAndSettle();

      expect(find.byType(DefaultListTile<int>), findsNothing);
      expect(find.byType(DefaultAddListItem), findsOneWidget);
      await _matchesGolden('single_open_add_row');
    }, tags: _goldenTags);
  });

  group('golden: single open with keyboard highlight (ArrowDown x2)', () {
    testWidgets('second row is highlighted', (tester) async {
      final controller = _ctrl(fruitItems());
      await _pumpSingle(tester, controller);
      await openSingle(tester);
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pumpAndSettle();

      expect(controller.highlightedIndex, 1);
      expect(
        tester.widget<DefaultListTile<int>>(rowTile<int>('Banana')).highlighted,
        isTrue,
      );
      await _matchesGolden('single_open_highlight');
    }, tags: _goldenTags);
  });

  group('golden: single disabled', () {
    testWidgets('disabled bar without the arrow', (tester) async {
      await _pumpSingle(tester, _ctrl(fruitItems(), enabled: false));

      expect(find.byIcon(Icons.arrow_drop_down), findsNothing);
      await _matchesGolden('single_disabled');
    }, tags: _goldenTags);
  });

  group('golden: multiple closed with 2 chips', () {
    testWidgets('two Card chips and the clear icon', (tester) async {
      final items = fruitItems();
      await _pumpMultiple(tester, items, <ValueItem<int>>[items[0], items[2]]);

      expect(find.byType(Card), findsNWidgets(2));
      expect(find.byIcon(Icons.clear), findsOneWidget);
      await _matchesGolden('multiple_closed_chips');
    }, tags: _goldenTags);
  });

  group('golden: multiple open', () {
    testWidgets('overlay list below the box with one selected row', (
      tester,
    ) async {
      final items = fruitItems();
      await _pumpMultiple(tester, items, <ValueItem<int>>[items[1]]);
      await openMultiple(tester);

      expect(find.byType(MultipleListView<int>), findsOneWidget);
      await _matchesGolden('multiple_open');
    }, tags: _goldenTags);
  });

  group('golden: delete confirm dialog', () {
    testWidgets('WarningDialog over the open view, row spinner behind', (
      tester,
    ) async {
      await _pumpSingle(
        tester,
        _ctrl(fruitItems(), deleteMode: true, confirmDelete: true),
      );
      await openSingle(tester);
      await tester.tap(inRow<int>('Banana', find.byIcon(Icons.delete)));
      await _frames(tester);

      expect(find.byType(WarningDialog), findsOneWidget);
      await _matchesGolden('delete_confirm_dialog');
    }, tags: _goldenTags);
  });

  group('golden: edit dialog', () {
    testWidgets('EditDialog over the open view', (tester) async {
      await _pumpSingle(tester, _ctrl(fruitItems(), editMode: true));
      await openSingle(tester);
      await tester.tap(inRow<int>('Banana', find.byIcon(Icons.edit)));
      await _frames(tester);

      expect(find.byType(EditDialog), findsOneWidget);
      await _matchesGolden('edit_dialog');
    }, tags: _goldenTags);
  });

  // -------------------------------------------------------------------------
  // (b) Deterministic perf baselines (10000 items, counting builders)
  // -------------------------------------------------------------------------

  group('perf baseline: rows built when opening a 10000-item view', () {
    testWidgets('counts itemWidgetBuilder calls during open', (tester) async {
      final counters = _Counters();
      final controller = await _pumpPerf(tester, counters);

      expect(counters.rows, 0, reason: 'closed bar builds no rows');
      await openSingle(tester);

      final int built = counters.rows;
      final int rendered = find.byType(DefaultListTile<int>).evaluate().length;
      debugPrint('BASELINE rows_built_on_open=$built');
      debugPrint('BASELINE rows_in_tree_after_open=$rendered');
      expect(controller.filteredItems.length, 10000);
      // 7.8 baseline: 9. 8.0 builds 10: ScrollablePositionedList caches two
      // viewports (needed to open scrolled to the selection, #46), but rows
      // are no longer rebuilt per frame or per unchanged keystroke, so the
      // open + type journey below costs far less than in 7.8.
      expect(built, inInclusiveRange(1, 10));
      expect(rendered, inInclusiveRange(1, 9999), reason: 'lazily built');
    });
  });

  group('perf baseline: rows built per keystroke typing "Item 99"', () {
    testWidgets('counts itemWidgetBuilder calls per keystroke', (tester) async {
      final counters = _Counters();
      final controller = await _pumpPerf(tester, counters);
      await openSingle(tester);

      final List<int> perKey = await _typeCounting(tester, () => counters.rows);
      for (int i = 0; i < perKey.length; i++) {
        debugPrint('BASELINE rows_built_keystroke_${i + 1}=${perKey[i]}');
      }
      debugPrint('BASELINE rows_built_typing_total=${_sum(perKey)}');
      expect(controller.filteredItems.length, 111);
      expect(perKey, hasLength(_typed.length));
      // 7.8 baseline: 9 rows per keystroke, 63 in total. 8.0 only rebuilds
      // rows when the results change: 20 in total.
      expect(_sum(perKey), lessThanOrEqualTo(20));
      // "Item " matches every item: those keys leave the rows alone; "9"
      // and "99" change the results and rebuild the visible rows.
      expect(perKey.take(5), everyElement(0));
      expect(perKey.skip(5), everyElement(greaterThan(0)));
    });
  });

  group('perf baseline: onFilterUpdated calls typing "Item 99"', () {
    testWidgets('counts onFilterUpdated calls for open + typing', (
      tester,
    ) async {
      final counters = _Counters();
      await _pumpPerf(tester, counters);
      final int beforeOpen = counters.filterUpdates;
      await openSingle(tester);
      final int onOpen = counters.filterUpdates - beforeOpen;

      final List<int> perKey = await _typeCounting(
        tester,
        () => counters.filterUpdates,
      );
      for (int i = 0; i < perKey.length; i++) {
        debugPrint(
          'BASELINE on_filter_updated_keystroke_${i + 1}=${perKey[i]}',
        );
      }
      debugPrint('BASELINE on_filter_updated_on_open=$onOpen');
      debugPrint('BASELINE on_filter_updated_typing_total=${_sum(perKey)}');
      // 7.8 baseline: 0 on open, 2 while typing (misses changes, see B13).
      expect(onOpen, lessThanOrEqualTo(1));
      expect(_sum(perKey), lessThanOrEqualTo(perKey.length));
      // Exactly once per key that changes the results ("9" and "99").
      expect(perKey, <int>[0, 0, 0, 0, 0, 1, 1]);
    });
  });

  group('perf baseline: search bar actions widget rebuilds per keystroke', () {
    testWidgets('counts builds of a searchBarSettings.actions widget', (
      tester,
    ) async {
      final counters = _Counters();
      await _pumpPerf(tester, counters);
      final int initial = counters.bar;
      await openSingle(tester);
      final int onOpen = counters.bar - initial;

      final List<int> perKey = await _typeCounting(tester, () => counters.bar);
      for (int i = 0; i < perKey.length; i++) {
        debugPrint(
          'BASELINE bar_action_builds_keystroke_${i + 1}=${perKey[i]}',
        );
      }
      debugPrint('BASELINE bar_action_builds_initial=$initial');
      debugPrint('BASELINE bar_action_builds_on_open=$onOpen');
      debugPrint('BASELINE bar_action_builds_typing_total=${_sum(perKey)}');
      expect(initial, greaterThanOrEqualTo(1), reason: 'actions are rendered');
      // 7.8 baseline: the bar does not rebuild while typing. The probe is a
      // new widget per bar build, so a ListenableBuilder/setState rebuild of
      // the bar while typing would be counted here.
      expect(_sum(perKey), 0);
    });

    testWidgets('the probe counts a bar rebuild caused by the controller', (
      tester,
    ) async {
      final counters = _Counters();
      final c = await _pumpPerf(tester, counters);
      final int before = counters.bar;
      // 8.0.1: only `enabled` rebuilds the bar (a selection no longer does,
      // see test/single/rebuild_counts_test.dart).
      c.enabled = false;
      await tester.pumpAndSettle();
      expect(counters.bar - before, greaterThanOrEqualTo(1));
    });

    testWidgets('the guard fails when every keystroke rebuilds the bar', (
      tester,
    ) async {
      final counters = _Counters();
      final c = await _pumpPerf(tester, counters);
      await openSingle(tester);
      // Simulates the regression: a bar rebuild on every keystroke.
      c.localSearchController.addListener(
        () => c
          ..enabled = false
          ..enabled = true,
      );
      final List<int> perKey = await _typeCounting(tester, () => counters.bar);
      expect(perKey.every((n) => n >= 1), isTrue, reason: '$perKey');
    });
  });
}
