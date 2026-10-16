// Characterization tests exercise the legacy (deprecated) API on purpose.
// ignore_for_file: deprecated_member_use, deprecated_member_use_from_same_package

// Characterization tests for the single-selection SearchDropDown widget
// (interaction surface). They lock the behaviour of v7.8.0 before the 8.0
// refactor. Tests named 'B<n>: ...' assert the CORRECT behaviour of a known
// bug and are skipped until the bug is fixed. testWidgets() only accepts a
// bool skip, so the reason "B<n>: fixed in 8.0" is the trailing comment.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';
import 'package:simple_search_dropdown/simple_search_dropdown.dart';

import '../support/harness.dart';

// A taller overlay so every row of the small fixtures is built (rows are
// lazily built by the view's ListView).
const SimpleOverlaySettings _tallOverlay = SimpleOverlaySettings(
  dialogHeight: 400,
);

SearchDropDownController<int> _ctrl(
  List<ValueItem<int>> items, {
  List<ValueItem<int>?>? calls,
  bool? showClearIcon,
  bool enabled = true,
  ValueItem<int>? initial,
  SearchController? searchController,
}) => SearchDropDownController<int>(
  listItems: items,
  addMode: false,
  deleteMode: false,
  updateSelectedItem: calls?.add,
  showClearIcon: showClearIcon,
  enabled: enabled,
  initialSelectedItem: initial,
  searchController: searchController,
);

Widget _dropdown(
  SearchDropDownController<int> controller, {
  Key? key,
  SimpleSearchbarSettings settings = defaultSearchBarSettings,
  SimpleOverlaySettings overlay = _tallOverlay,
  Widget? defaultAditionalWidget,
  bool disposeController = true,
  bool removeFocus = true,
}) => SearchDropDown<int>(
  key: key,
  controller: controller,
  searchBarSettings: settings,
  overlayListSettings: overlay,
  defaultAditionalWidget: defaultAditionalWidget,
  disposeController: disposeController,
  removeFocus: removeFocus,
);

Future<void> _pump(WidgetTester tester, Widget dropdown) async {
  await tester.pumpWidget(host(dropdown));
}

// Items whose labels all contain "an", so reopening after selecting "An"
// still lists every item (the view pre-filters by the current text).
List<ValueItem<int>> _anItems() => <ValueItem<int>>[
  const ValueItem(label: 'Pan', value: 1),
  const ValueItem(label: 'An', value: 2),
  const ValueItem(label: 'Ant', value: 3),
  const ValueItem(label: 'Can', value: 4),
];

/// Rows of the open list in visual (top to bottom) order.
List<DefaultListTile<int>> _visualRows(WidgetTester tester) {
  final List<DefaultListTile<int>> rows = tester
      .widgetList<DefaultListTile<int>>(find.byType(DefaultListTile<int>))
      .toList();
  double top(DefaultListTile<int> row) =>
      tester.getTopLeft(find.byWidget(row)).dy;
  return rows..sort((a, b) => top(a).compareTo(top(b)));
}

Iterable<DefaultListTile<int>> _rows(WidgetTester tester) =>
    _visualRows(tester);

List<String> _rowLabels(WidgetTester tester) =>
    _rows(tester).map((r) => r.item.label).toList();

List<String> _selectedRows(WidgetTester tester) => _rows(
  tester,
).where((r) => r.selected || r.highlighted).map((r) => r.item.label).toList();

Finder _row(String label) => find.byWidgetPredicate(
  (w) => w is DefaultListTile<int> && w.item.label == label,
);

Future<void> _tapRow(WidgetTester tester, String label) async {
  await tester.tap(
    find.descendant(of: _row(label), matching: find.byType(TextButton)),
  );
  await tester.pumpAndSettle();
}

Color? _rowBackground(WidgetTester tester, String label) {
  final TextButton button = tester.widget<TextButton>(
    find.descendant(of: _row(label), matching: find.byType(TextButton)),
  );
  return button.style!.backgroundColor!.resolve(<WidgetState>{});
}

Finder _inBar(Finder matching) =>
    find.descendant(of: find.byType(SearchBar).first, matching: matching);

SearchAnchor _anchor(WidgetTester tester) => tester.widget<SearchAnchor>(
  find.byWidgetPredicate((w) => w is SearchAnchor),
);

EditableText _barField(WidgetTester tester) =>
    tester.widget<EditableText>(_inBar(find.byType(EditableText)));

Future<void> _key(WidgetTester tester, LogicalKeyboardKey key) async {
  await tester.sendKeyEvent(key);
  await tester.pumpAndSettle();
}

Future<void> _closeWithArrow(WidgetTester tester) async {
  await tester.tap(find.byIcon(Icons.arrow_drop_up));
  await tester.pumpAndSettle();
}

bool _focusInsideDropdown() {
  final BuildContext? ctx = FocusManager.instance.primaryFocus?.context;
  return ctx != null &&
      ctx.findAncestorWidgetOfExactType<SearchDropDown<int>>() != null;
}

/// Whether a plain [SearchAnchor.bar] still has the focus after its view
/// closes on this Flutter version (the reference for `removeFocus: false`).
Future<bool> _frameworkKeepsBarFocus(WidgetTester tester) async {
  final SearchController search = SearchController();
  addTearDown(search.dispose);
  await tester.pumpWidget(
    host(
      SearchAnchor.bar(
        searchController: search,
        suggestionsBuilder: (_, _) => <Widget>[],
      ),
    ),
  );
  await tester.tap(find.byType(SearchBar));
  await tester.pumpAndSettle();
  search.closeView('x');
  await tester.pumpAndSettle();
  await tester.pump(const Duration(milliseconds: 700));
  final BuildContext? ctx = FocusManager.instance.primaryFocus?.context;
  final bool keeps =
      ctx != null && ctx.findAncestorWidgetOfExactType<SearchBar>() != null;
  await tester.pumpWidget(const SizedBox.shrink());
  return keeps;
}

Widget _withLeadingField(Widget dropdown) => Column(
  mainAxisSize: MainAxisSize.min,
  children: <Widget>[
    const SizedBox(width: 300, child: TextField(key: Key('before'))),
    dropdown,
  ],
);

void main() {
  group('single: open view on tap', () {
    testWidgets('tapping the bar opens the view listing every item in order', (
      tester,
    ) async {
      await _pump(tester, _dropdown(_ctrl(numberedItems(4))));
      expect(find.byType(DefaultListTile<int>), findsNothing);

      await openSingle(tester);

      expect(_rowLabels(tester), <String>[
        'Item 0',
        'Item 1',
        'Item 2',
        'Item 3',
      ]);
      expect(_selectedRows(tester), isEmpty);
    });

    testWidgets('reopening after a selection lists every item (D1, 8.0)', (
      tester,
    ) async {
      final c = _ctrl(numberedItems(4));
      await _pump(tester, _dropdown(c));
      await openSingle(tester);
      await _tapRow(tester, 'Item 2');

      await openSingle(tester);

      expect(_rowLabels(tester), contains('Item 2'));
      expect(c.filteredItems.map((e) => e.label), <String>[
        'Item 0',
        'Item 1',
        'Item 2',
        'Item 3',
      ]);
      expect(_selectedRows(tester), <String>['Item 2']);
    });

    testWidgets('typing in the open view filters the rows', (tester) async {
      final c = _ctrl(numberedItems(4));
      await _pump(tester, _dropdown(c));
      await openSingle(tester);

      await typeInSingle(tester, 'm 3');

      expect(_rowLabels(tester), <String>['Item 3']);
    });
  });

  group('single: select item', () {
    testWidgets(
      'tapping a row sets selectedItem, closes the view, notifies once and '
      'writes the label into the bar',
      (tester) async {
        final calls = <ValueItem<int>?>[];
        final c = _ctrl(numberedItems(4), calls: calls);
        await _pump(tester, _dropdown(c));
        await openSingle(tester);

        await _tapRow(tester, 'Item 1');

        expect(c.selectedItem, const ValueItem(label: 'Item 1', value: 1));
        expect(calls, <ValueItem<int>?>[
          const ValueItem(label: 'Item 1', value: 1),
        ]);
        expect(find.byType(DefaultListTile<int>), findsNothing);
        expect(c.localSearchController.isOpen, isFalse);
        expect(c.localSearchController.text, 'Item 1');
        expect(_barField(tester).controller.text, 'Item 1');
      },
    );
  });

  group('single: arrow icon', () {
    testWidgets(
      'closed arrow (arrow_drop_down) is shown in the bar by default',
      (tester) async {
        await _pump(tester, _dropdown(_ctrl(numberedItems(2))));
        expect(_inBar(find.byIcon(Icons.arrow_drop_down)), findsOneWidget);
        expect(find.byIcon(Icons.arrow_drop_up), findsNothing);
      },
    );

    testWidgets('closed arrow is hidden when the controller is disabled', (
      tester,
    ) async {
      await _pump(tester, _dropdown(_ctrl(numberedItems(2), enabled: false)));
      expect(find.byIcon(Icons.arrow_drop_down), findsNothing);
    });

    testWidgets('showArrow false hides the closed and the opened arrow', (
      tester,
    ) async {
      await _pump(
        tester,
        _dropdown(
          _ctrl(numberedItems(2)),
          settings: const SimpleSearchbarSettings(showArrow: false),
        ),
      );
      expect(find.byIcon(Icons.arrow_drop_down), findsNothing);
      await openSingle(tester);
      expect(find.byIcon(Icons.arrow_drop_up), findsNothing);
      expect(_rowLabels(tester), hasLength(2));
    });

    testWidgets(
      'tapping the closed arrow opens the view with all items; the opened '
      'arrow (arrow_drop_up) closes it keeping the typed text',
      (tester) async {
        final c = _ctrl(numberedItems(3));
        await _pump(tester, _dropdown(c));

        await tester.tap(_inBar(find.byIcon(Icons.arrow_drop_down)));
        await tester.pumpAndSettle();
        expect(c.localSearchController.isOpen, isTrue);
        expect(_rowLabels(tester), <String>['Item 0', 'Item 1', 'Item 2']);
        expect(find.byIcon(Icons.arrow_drop_up), findsOneWidget);

        await typeInSingle(tester, 'abc');
        await _closeWithArrow(tester);

        expect(c.localSearchController.isOpen, isFalse);
        expect(find.byType(DefaultListTile<int>), findsNothing);
        expect(c.localSearchController.text, 'abc');
        expect(c.selectedItem, isNull);
      },
    );

    testWidgets('custom dropdownClosedArrowIcon / dropdownOpenedArrowIcon', (
      tester,
    ) async {
      await _pump(
        tester,
        _dropdown(
          _ctrl(numberedItems(2)),
          settings: const SimpleSearchbarSettings(
            dropdownClosedArrowIcon: Icons.expand_more,
            dropdownOpenedArrowIcon: Icons.expand_less,
          ),
        ),
      );
      expect(_inBar(find.byIcon(Icons.expand_more)), findsOneWidget);
      expect(find.byIcon(Icons.arrow_drop_down), findsNothing);

      await openSingle(tester);
      expect(find.byIcon(Icons.expand_less), findsOneWidget);
      expect(find.byIcon(Icons.arrow_drop_up), findsNothing);
    });

    testWidgets('dropdownClosedIconFunction replaces opening the view', (
      tester,
    ) async {
      int taps = 0;
      final c = _ctrl(numberedItems(2));
      await _pump(
        tester,
        _dropdown(
          c,
          settings: SimpleSearchbarSettings(
            dropdownClosedIconFunction: () => taps++,
          ),
        ),
      );

      await tester.tap(_inBar(find.byIcon(Icons.arrow_drop_down)));
      await tester.pumpAndSettle();

      expect(taps, 1);
      expect(c.localSearchController.isOpen, isFalse);
      expect(find.byType(DefaultListTile<int>), findsNothing);
    });

    testWidgets('dropdownOpenedIconFunction replaces closing the view', (
      tester,
    ) async {
      int taps = 0;
      final c = _ctrl(numberedItems(2));
      await _pump(
        tester,
        _dropdown(
          c,
          settings: SimpleSearchbarSettings(
            dropdownOpenedIconFunction: () => taps++,
          ),
        ),
      );
      await openSingle(tester);

      await tester.tap(find.byIcon(Icons.arrow_drop_up));
      await tester.pumpAndSettle();

      expect(taps, 1);
      expect(c.localSearchController.isOpen, isTrue);
      expect(_rowLabels(tester), hasLength(2));
    });

    testWidgets(
      'searchBarSettings.actions replaces the bar trailing (arrow and clear)',
      (tester) async {
        final c = _ctrl(
          numberedItems(2),
          showClearIcon: true,
          initial: const ValueItem(label: 'Item 0', value: 0),
        );
        await _pump(
          tester,
          _dropdown(
            c,
            settings: const SimpleSearchbarSettings(
              actions: <Widget>[Icon(Icons.search)],
            ),
          ),
        );

        expect(_inBar(find.byIcon(Icons.search)), findsOneWidget);
        expect(_inBar(find.byIcon(Icons.arrow_drop_down)), findsNothing);
        expect(_inBar(find.byIcon(Icons.clear)), findsNothing);
      },
    );

    testWidgets(
      'B7: opening the view via the arrow then typing filters the list',
      (tester) async {
        final c = _ctrl(numberedItems(5));
        await _pump(tester, _dropdown(c));
        await tester.tap(_inBar(find.byIcon(Icons.arrow_drop_down)));
        await tester.pumpAndSettle();

        await typeInSingle(tester, 'Item 1');

        expect(c.filteredItems.map((e) => e.label), <String>['Item 1']);
        expect(_rowLabels(tester), <String>['Item 1']);
      },
    ); // B7: fixed in 8.0
  });

  group('single: clear button', () {
    testWidgets(
      'controller.showClearIcon + settings.showClearIcon with an initial '
      'selection: clear is visible; tapping it clears and notifies null',
      (tester) async {
        final calls = <ValueItem<int>?>[];
        final c = _ctrl(
          numberedItems(3),
          calls: calls,
          showClearIcon: true,
          initial: const ValueItem(label: 'Item 1', value: 1),
        );
        await _pump(tester, _dropdown(c));
        expect(c.clearVisible, isTrue);
        expect(_inBar(find.byIcon(Icons.clear)), findsOneWidget);

        await tester.tap(_inBar(find.byIcon(Icons.clear)));
        await tester.pumpAndSettle();

        expect(c.selectedItem, isNull);
        expect(c.localSearchController.text, '');
        expect(c.clearVisible, isFalse);
        expect(calls, <ValueItem<int>?>[null]);
      },
    );

    testWidgets('after selecting through the view the bar clear button shows '
        'right away (8.0: controller notifies)', (tester) async {
      final calls = <ValueItem<int>?>[];
      final c = _ctrl(numberedItems(3), calls: calls, showClearIcon: true);
      late StateSetter rebuild;
      await tester.pumpWidget(
        host(
          StatefulBuilder(
            builder: (context, setState) {
              rebuild = setState;
              return _dropdown(c);
            },
          ),
        ),
      );
      expect(_inBar(find.byIcon(Icons.clear)), findsNothing);

      await openSingle(tester);
      await _tapRow(tester, 'Item 2');
      expect(c.clearVisible, isTrue);
      expect(_inBar(find.byIcon(Icons.clear)), findsOneWidget);

      rebuild(() {});
      await tester.pump();
      expect(_inBar(find.byIcon(Icons.clear)), findsOneWidget);

      await tester.tap(_inBar(find.byIcon(Icons.clear)));
      await tester.pumpAndSettle();
      expect(c.selectedItem, isNull);
      expect(c.localSearchController.text, '');
      expect(calls, <ValueItem<int>?>[
        const ValueItem(label: 'Item 2', value: 2),
        null,
      ]);
    });

    testWidgets(
      'controller.showClearIcon true + settings.showClearIcon false: no '
      'clear in the bar nor in the open view (8.0)',
      (tester) async {
        final c = _ctrl(
          numberedItems(3),
          showClearIcon: true,
          initial: const ValueItem(label: 'Item 1', value: 1),
        );
        await _pump(
          tester,
          _dropdown(
            c,
            settings: const SimpleSearchbarSettings(showClearIcon: false),
          ),
        );
        expect(find.byIcon(Icons.clear), findsNothing);

        await openSingle(tester);
        expect(find.byIcon(Icons.clear), findsNothing);
      },
    );

    testWidgets('controller.showClearIcon false: clear never appears after '
        'selecting', (tester) async {
      final c = _ctrl(numberedItems(3), showClearIcon: false);
      late StateSetter rebuild;
      await tester.pumpWidget(
        host(
          StatefulBuilder(
            builder: (context, setState) {
              rebuild = setState;
              return _dropdown(c);
            },
          ),
        ),
      );
      await openSingle(tester);
      await _tapRow(tester, 'Item 1');
      rebuild(() {});
      await tester.pump();

      expect(c.clearVisible, isFalse);
      expect(find.byIcon(Icons.clear), findsNothing);
    });

    testWidgets(
      'B6: with default settings the clear button appears after selecting',
      (tester) async {
        final c = _ctrl(numberedItems(3));
        late StateSetter rebuild;
        await tester.pumpWidget(
          host(
            StatefulBuilder(
              builder: (context, setState) {
                rebuild = setState;
                return _dropdown(c);
              },
            ),
          ),
        );
        await openSingle(tester);
        await _tapRow(tester, 'Item 1');
        rebuild(() {});
        await tester.pump();

        expect(_inBar(find.byIcon(Icons.clear)), findsOneWidget);
      },
    ); // B6: fixed in 8.0
  });

  group('single: clearOnClose', () {
    const SimpleSearchbarSettings clearOnClose = SimpleSearchbarSettings(
      clearOnClose: true,
    );

    testWidgets('true: closing with typed text restores the selected label', (
      tester,
    ) async {
      final calls = <ValueItem<int>?>[];
      final c = _ctrl(numberedItems(3), calls: calls);
      await _pump(tester, _dropdown(c, settings: clearOnClose));
      await openSingle(tester);
      await _tapRow(tester, 'Item 1');

      await openSingle(tester);
      await typeInSingle(tester, 'zzz');
      await _closeWithArrow(tester);

      expect(c.localSearchController.text, 'Item 1');
      expect(c.selectedItem?.label, 'Item 1');
      expect(calls, hasLength(1));
    });

    testWidgets('true: closing with typed text and no selection clears it', (
      tester,
    ) async {
      final c = _ctrl(numberedItems(3));
      await _pump(tester, _dropdown(c, settings: clearOnClose));
      await openSingle(tester);
      await typeInSingle(tester, 'zzz');
      await _closeWithArrow(tester);

      expect(c.localSearchController.text, '');
      expect(c.selectedItem, isNull);
    });

    testWidgets('false (default): typed text is kept, selection unchanged', (
      tester,
    ) async {
      final c = _ctrl(numberedItems(3));
      await _pump(tester, _dropdown(c));
      await openSingle(tester);
      await _tapRow(tester, 'Item 1');

      await openSingle(tester);
      await typeInSingle(tester, 'zzz');
      await _closeWithArrow(tester);

      expect(c.localSearchController.text, 'zzz');
      expect(c.selectedItem?.label, 'Item 1');
    });
  });

  group('single: enabled / enableDisable() / resetSelection()', () {
    testWidgets('enabled false disables the bar; tapping does not open', (
      tester,
    ) async {
      final c = _ctrl(numberedItems(3), enabled: false);
      await _pump(tester, _dropdown(c));
      expect(_anchor(tester).enabled, isFalse);

      await tester.tap(find.byType(SearchBar).first, warnIfMissed: false);
      await tester.pumpAndSettle();

      expect(c.localSearchController.isOpen, isFalse);
      expect(find.byType(DefaultListTile<int>), findsNothing);
    });

    testWidgets('SearchDropDownState.enableDisable() toggles enabled', (
      tester,
    ) async {
      final key = GlobalKey<SearchDropDownState<int>>();
      final c = _ctrl(numberedItems(3));
      await _pump(tester, _dropdown(c, key: key));

      key.currentState!.enableDisable();
      await tester.pump();
      expect(c.enabled, isFalse);
      expect(_anchor(tester).enabled, isFalse);
      expect(find.byIcon(Icons.arrow_drop_down), findsNothing);

      key.currentState!.enableDisable();
      await tester.pump();
      expect(c.enabled, isTrue);
      expect(_anchor(tester).enabled, isTrue);
      expect(find.byIcon(Icons.arrow_drop_down), findsOneWidget);
      await openSingle(tester);
      expect(_rowLabels(tester), hasLength(3));
    });

    testWidgets(
      'SearchDropDownState.resetSelection() clears selection and text and '
      'notifies null',
      (tester) async {
        final key = GlobalKey<SearchDropDownState<int>>();
        final calls = <ValueItem<int>?>[];
        final c = _ctrl(numberedItems(3), calls: calls);
        await _pump(tester, _dropdown(c, key: key));
        await openSingle(tester);
        await _tapRow(tester, 'Item 2');

        key.currentState!.resetSelection();
        await tester.pump();

        expect(c.selectedItem, isNull);
        expect(c.localSearchController.text, '');
        expect(_barField(tester).controller.text, '');
        expect(calls, <ValueItem<int>?>[
          const ValueItem(label: 'Item 2', value: 2),
          null,
        ]);
      },
    );
  });

  group('single: keyboard arrow navigation', () {
    testWidgets('ArrowDown with no highlight starts at 0 and wraps around', (
      tester,
    ) async {
      final c = _ctrl(_anItems());
      await _pump(tester, _dropdown(c));
      await openSingle(tester);
      expect(c.highlightedIndex, -1);

      final seen = <int>[];
      final painted = <List<String>>[];
      for (int i = 0; i < 5; i++) {
        await _key(tester, LogicalKeyboardKey.arrowDown);
        seen.add(c.highlightedIndex);
        painted.add(_selectedRows(tester));
      }

      expect(seen, <int>[0, 1, 2, 3, 0]);
      expect(painted.first, <String>['Pan']);
      expect(painted.last, <String>['Pan']);
      expect(painted[3], <String>['Can']);
    });

    testWidgets('ArrowUp with no highlight starts at the last item and wraps', (
      tester,
    ) async {
      final c = _ctrl(_anItems());
      await _pump(tester, _dropdown(c));
      await openSingle(tester);

      final seen = <int>[];
      for (int i = 0; i < 5; i++) {
        await _key(tester, LogicalKeyboardKey.arrowUp);
        seen.add(c.highlightedIndex);
      }

      expect(seen, <int>[3, 2, 1, 0, 3]);
      expect(_selectedRows(tester), <String>['Can']);
    });

    testWidgets('ArrowDown starts from the selected item when one exists', (
      tester,
    ) async {
      final c = _ctrl(_anItems());
      await _pump(tester, _dropdown(c));
      await openSingle(tester);
      await _tapRow(tester, 'An');
      await openSingle(tester);
      expect(_rowLabels(tester), <String>['Pan', 'An', 'Ant', 'Can']);

      await _key(tester, LogicalKeyboardKey.arrowDown);
      expect(c.highlightedIndex, 1);
      await _key(tester, LogicalKeyboardKey.arrowDown);
      expect(c.highlightedIndex, 2);
    });

    testWidgets('ArrowUp starts from the selected item when one exists', (
      tester,
    ) async {
      final c = _ctrl(_anItems());
      await _pump(tester, _dropdown(c));
      await openSingle(tester);
      await _tapRow(tester, 'An');
      await openSingle(tester);

      await _key(tester, LogicalKeyboardKey.arrowUp);
      expect(c.highlightedIndex, 1);
      await _key(tester, LogicalKeyboardKey.arrowUp);
      expect(c.highlightedIndex, 0);
    });

    testWidgets('arrow keys and Enter are ignored while the view is closed', (
      tester,
    ) async {
      final calls = <ValueItem<int>?>[];
      final c = _ctrl(numberedItems(3), calls: calls);
      await _pump(tester, _dropdown(c));

      await _key(tester, LogicalKeyboardKey.arrowDown);
      await _key(tester, LogicalKeyboardKey.enter);

      expect(c.highlightedIndex, -1);
      expect(c.selectedItem, isNull);
      expect(calls, isEmpty);
    });

    testWidgets(
      'typing after highlighting resets controller.highlightedIndex to -1',
      (tester) async {
        final c = _ctrl(numberedItems(12));
        await _pump(tester, _dropdown(c));
        await openSingle(tester);
        await _key(tester, LogicalKeyboardKey.arrowDown);
        await _key(tester, LogicalKeyboardKey.arrowDown);
        expect(c.highlightedIndex, 1);

        await typeInSingle(tester, '1');
        await tester.pumpAndSettle();

        expect(c.highlightedIndex, -1);
        expect(c.filteredItems.map((e) => e.label), <String>[
          'Item 1',
          'Item 10',
          'Item 11',
        ]);
      },
    );

    testWidgets(
      'B4: after typing resets the highlight, no row is painted highlighted',
      (tester) async {
        final c = _ctrl(numberedItems(12));
        await _pump(tester, _dropdown(c));
        await openSingle(tester);
        await _key(tester, LogicalKeyboardKey.arrowDown);
        await _key(tester, LogicalKeyboardKey.arrowDown);

        await typeInSingle(tester, '1');
        await tester.pumpAndSettle();

        expect(c.highlightedIndex, -1);
        expect(_selectedRows(tester), isEmpty);
      },
    ); // B4: fixed in 8.0
  });

  group('single: Enter key / onSubmitted', () {
    testWidgets('Enter selects the highlighted item and closes the view', (
      tester,
    ) async {
      final calls = <ValueItem<int>?>[];
      final c = _ctrl(numberedItems(4), calls: calls);
      await _pump(tester, _dropdown(c));
      await openSingle(tester);
      await _key(tester, LogicalKeyboardKey.arrowDown);
      await _key(tester, LogicalKeyboardKey.arrowDown);

      await _key(tester, LogicalKeyboardKey.enter);

      expect(c.selectedItem?.label, 'Item 1');
      expect(c.localSearchController.text, 'Item 1');
      expect(c.localSearchController.isOpen, isFalse);
      expect(calls.map((e) => e?.label), <String>['Item 1']);
    });

    testWidgets('Enter with no highlight selects the first filtered item', (
      tester,
    ) async {
      final calls = <ValueItem<int>?>[];
      final c = _ctrl(numberedItems(4), calls: calls);
      await _pump(tester, _dropdown(c));
      await openSingle(tester);
      await typeInSingle(tester, 'm 2');

      await _key(tester, LogicalKeyboardKey.enter);

      expect(c.selectedItem?.label, 'Item 2');
      expect(c.localSearchController.isOpen, isFalse);
      expect(calls.map((e) => e?.label), <String>['Item 2']);
    });

    testWidgets('numpadEnter behaves like Enter', (tester) async {
      final c = _ctrl(numberedItems(4));
      await _pump(tester, _dropdown(c));
      await openSingle(tester);

      await _key(tester, LogicalKeyboardKey.numpadEnter);

      expect(c.selectedItem?.label, 'Item 0');
    });

    testWidgets(
      'onSubmitted (IME done action) selects the first filtered item',
      (tester) async {
        final calls = <ValueItem<int>?>[];
        final c = _ctrl(numberedItems(4), calls: calls);
        await _pump(tester, _dropdown(c));
        await openSingle(tester);
        await typeInSingle(tester, '3');

        await tester.testTextInput.receiveAction(TextInputAction.done);
        await tester.pumpAndSettle();

        expect(c.selectedItem?.label, 'Item 3');
        expect(c.localSearchController.text, 'Item 3');
        expect(calls.map((e) => e?.label), <String>['Item 3']);
      },
    );

    // Not reproduced: the hardware handler closes the view synchronously and
    // the IME connection is gone before a done action can arrive; in the
    // reverse order onSubmitted closes the view so the handler ignores Enter.
    testWidgets(
      'B8 (not reproduced): a physical Enter (key event + IME submit, in '
      'either order) notifies exactly once',
      (tester) async {
        final calls = <ValueItem<int>?>[];
        final c = _ctrl(numberedItems(4), calls: calls);
        await _pump(tester, _dropdown(c));

        await openSingle(tester);
        await tester.sendKeyEvent(LogicalKeyboardKey.enter);
        await tester.testTextInput.receiveAction(TextInputAction.done);
        await tester.pumpAndSettle();
        expect(calls, hasLength(1));

        await openSingle(tester);
        await tester.testTextInput.receiveAction(TextInputAction.done);
        await tester.sendKeyEvent(LogicalKeyboardKey.enter);
        await tester.pumpAndSettle();
        expect(calls, hasLength(2));
      },
    );
  });

  group('single: openFullScreen', () {
    testWidgets('default false; true makes the view fill the screen', (
      tester,
    ) async {
      await _pump(tester, _dropdown(_ctrl(numberedItems(3))));
      expect(_anchor(tester).isFullScreen, isFalse);

      await _pump(
        tester,
        _dropdown(
          _ctrl(numberedItems(3)),
          overlay: const SimpleOverlaySettings(openFullScreen: true),
        ),
      );
      expect(_anchor(tester).isFullScreen, isTrue);
      await openSingle(tester);
      expect(_rowLabels(tester), hasLength(3));
      expect(tester.getSize(find.byType(ScrollablePositionedList)).width, 800);
    });
  });

  group('single: viewConstraints (dropdownWidth / dialogHeight)', () {
    testWidgets('defaults map to maxWidth 300 / maxHeight 200', (tester) async {
      await _pump(
        tester,
        _dropdown(_ctrl(numberedItems(20)), overlay: defaultOverlaySettings),
      );
      expect(
        _anchor(tester).viewConstraints,
        const BoxConstraints(maxWidth: 300, maxHeight: 200),
      );
      await openSingle(tester);
      expect(
        tester.getSize(find.byType(ScrollablePositionedList)).height,
        lessThanOrEqualTo(200),
      );
      expect(
        tester.getSize(find.byType(ScrollablePositionedList)).width,
        lessThanOrEqualTo(300),
      );
    });

    testWidgets('custom dropdownWidth and dialogHeight', (tester) async {
      await _pump(
        tester,
        _dropdown(
          _ctrl(numberedItems(20)),
          settings: const SimpleSearchbarSettings(dropdownWidth: 250),
          overlay: const SimpleOverlaySettings(dialogHeight: 120),
        ),
      );
      expect(
        _anchor(tester).viewConstraints,
        const BoxConstraints(maxWidth: 250, maxHeight: 120),
      );
    });
  });

  group('single: hint text', () {
    testWidgets('default hint is Pesquisar on the bar and the view', (
      tester,
    ) async {
      await _pump(tester, _dropdown(_ctrl(numberedItems(2))));
      expect(_inBar(find.text('Pesquisar')), findsOneWidget);
      expect(_anchor(tester).viewHintText, 'Pesquisar');
    });

    testWidgets('custom hint is used on the bar and the view', (tester) async {
      await _pump(
        tester,
        _dropdown(
          _ctrl(numberedItems(2)),
          settings: const SimpleSearchbarSettings(hint: 'Escolha'),
        ),
      );
      expect(_inBar(find.text('Escolha')), findsOneWidget);
      expect(_anchor(tester).viewHintText, 'Escolha');
    });
  });

  group('single: showKeyboardOnTap / keyboardType / textInputAction', () {
    testWidgets('default: keyboardType null on the anchor, text on the field', (
      tester,
    ) async {
      await _pump(tester, _dropdown(_ctrl(numberedItems(2))));
      expect(_anchor(tester).keyboardType, isNull);
      expect(_barField(tester).keyboardType, TextInputType.text);
    });

    testWidgets('showKeyboardOnTap false forces TextInputType.none', (
      tester,
    ) async {
      await _pump(
        tester,
        _dropdown(
          _ctrl(numberedItems(2)),
          settings: const SimpleSearchbarSettings(
            showKeyboardOnTap: false,
            keyboardType: TextInputType.number,
          ),
        ),
      );
      expect(_anchor(tester).keyboardType, TextInputType.none);
      expect(_barField(tester).keyboardType, TextInputType.none);
      await openSingle(tester);
      expect(
        tester.widget<EditableText>(focusedField()).keyboardType,
        TextInputType.none,
      );
    });

    testWidgets('keyboardType and textInputAction are passed through', (
      tester,
    ) async {
      await _pump(
        tester,
        _dropdown(
          _ctrl(numberedItems(2)),
          settings: const SimpleSearchbarSettings(
            keyboardType: TextInputType.number,
            textInputAction: TextInputAction.search,
          ),
        ),
      );
      expect(_anchor(tester).keyboardType, TextInputType.number);
      expect(_anchor(tester).textInputAction, TextInputAction.search);
    });
  });

  group('single: showDivider', () {
    testWidgets(
      'false (default): divider painted with the view background colour',
      (tester) async {
        await _pump(tester, _dropdown(_ctrl(numberedItems(2))));
        expect(_anchor(tester).dividerColor, Colors.white);

        await _pump(
          tester,
          _dropdown(
            _ctrl(numberedItems(2)),
            overlay: const SimpleOverlaySettings(
              dialogBackgroundColor: Colors.amber,
            ),
          ),
        );
        expect(_anchor(tester).dividerColor, Colors.amber);
      },
    );

    testWidgets('true: dividerColor left null (theme default)', (tester) async {
      await _pump(
        tester,
        _dropdown(
          _ctrl(numberedItems(2)),
          settings: const SimpleSearchbarSettings(showDivider: true),
        ),
      );
      expect(_anchor(tester).dividerColor, isNull);
    });
  });

  group('single: itemWidgetBuilder', () {
    testWidgets('custom builder is used as the content of every row', (
      tester,
    ) async {
      final c = _ctrl(numberedItems(3));
      await _pump(
        tester,
        _dropdown(
          c,
          overlay: SimpleOverlaySettings(
            dialogHeight: 400,
            itemWidgetBuilder: (item) => Text('custom ${item.label}'),
          ),
        ),
      );
      await openSingle(tester);

      expect(find.text('custom Item 0'), findsOneWidget);
      expect(find.text('custom Item 2'), findsOneWidget);
      expect(find.text('Item 1'), findsNothing);

      await tester.tap(find.text('custom Item 1'));
      await tester.pumpAndSettle();
      expect(c.selectedItem?.label, 'Item 1');
    });
  });

  group('single: defaultAditionalWidget', () {
    testWidgets('rendered once in each row', (tester) async {
      await _pump(
        tester,
        _dropdown(
          _ctrl(numberedItems(3)),
          defaultAditionalWidget: const Icon(Icons.star),
        ),
      );
      await openSingle(tester);

      expect(find.byIcon(Icons.star), findsNWidgets(3));
      expect(
        find.descendant(of: _row('Item 1'), matching: find.byIcon(Icons.star)),
        findsOneWidget,
      );
    });
  });

  group('single: disposeController', () {
    testWidgets(
      'true (default) disposes the owned SearchController on unmount',
      (tester) async {
        final c = _ctrl(numberedItems(2));
        await _pump(tester, _dropdown(c));
        await tester.pumpWidget(host(const SizedBox()));

        expect(
          () => c.localSearchController.addListener(() {}),
          throwsFlutterError,
        );
      },
    );

    testWidgets(
      'true does not dispose an externally supplied SearchController',
      (tester) async {
        final external = SearchController();
        addTearDown(external.dispose);
        final c = _ctrl(numberedItems(2), searchController: external);
        await _pump(tester, _dropdown(c));
        await tester.pumpWidget(host(const SizedBox()));

        expect(() => external.addListener(() {}), returnsNormally);
      },
    );

    testWidgets('false keeps the controller usable by a new SearchDropDown', (
      tester,
    ) async {
      final c = _ctrl(numberedItems(2));
      addTearDown(c.dispose);
      await _pump(tester, _dropdown(c, disposeController: false));
      await tester.pumpWidget(host(const SizedBox()));

      expect(() => c.localSearchController.addListener(() {}), returnsNormally);

      await _pump(tester, _dropdown(c, disposeController: false));
      await openSingle(tester);
      expect(_rowLabels(tester), <String>['Item 0', 'Item 1']);
    });
  });

  group('single: removeFocus', () {
    testWidgets('true (default): Tab into the bar keeps the focus (B11, 8.0)', (
      tester,
    ) async {
      // B11: fixed in 8.0 (the focus is only dropped after a view closes).
      await tester.pumpWidget(
        host(_withLeadingField(_dropdown(_ctrl(numberedItems(2))))),
      );
      await tester.tap(find.byKey(const Key('before')));
      await tester.pump();

      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();

      expect(_focusInsideDropdown(), isTrue);
    });

    testWidgets('false: Tab into the bar keeps the focus there', (
      tester,
    ) async {
      await tester.pumpWidget(
        host(
          _withLeadingField(
            _dropdown(_ctrl(numberedItems(2)), removeFocus: false),
          ),
        ),
      );
      await tester.tap(find.byKey(const Key('before')));
      await tester.pump();

      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();

      expect(_focusInsideDropdown(), isTrue);
    });

    testWidgets('true: after selecting, focus is not left in the bar', (
      tester,
    ) async {
      await _pump(tester, _dropdown(_ctrl(numberedItems(2))));
      await openSingle(tester);
      await _tapRow(tester, 'Item 1');

      expect(_focusInsideDropdown(), isFalse);
    });

    testWidgets('false: after selecting, focus stays in the bar (6.3.0)', (
      tester,
    ) async {
      // N49: newer Flutter versions (after 3.32) unfocus a SearchAnchor's
      // bar themselves after its view closes, so `false` can only keep the
      // focus where the framework does.
      final bool frameworkKeeps = await _frameworkKeepsBarFocus(tester);
      final c = _ctrl(numberedItems(2));
      await _pump(tester, _dropdown(c, removeFocus: false));
      await openSingle(tester);
      await _tapRow(tester, 'Item 1');
      // Past the 600 ms window in which `true` drops the focus.
      await tester.pump(const Duration(milliseconds: 700));

      expect(c.selectedItem?.label, 'Item 1');
      expect(_focusInsideDropdown(), frameworkKeeps);
    });
  });

  group('single: selected row styling', () {
    const SimpleOverlaySettings styled = SimpleOverlaySettings(
      dialogHeight: 400,
      selectedItemBackgroundColor: Colors.purple,
      selectedItemTextStyle: TextStyle(color: Colors.green),
      unselectedItemTextStyle: TextStyle(color: Colors.grey),
    );

    testWidgets(
      'selected row uses selectedItemBackgroundColor/TextStyle; others are '
      'transparent with the unselected style',
      (tester) async {
        final c = _ctrl(_anItems());
        await _pump(tester, _dropdown(c, overlay: styled));
        await openSingle(tester);
        await _tapRow(tester, 'An');
        await openSingle(tester);

        expect(_selectedRows(tester), <String>['An']);
        expect(_rowBackground(tester, 'An'), Colors.purple);
        expect(_rowBackground(tester, 'Pan'), Colors.transparent);
        expect(
          tester.widget<Text>(find.text('An').last).style?.color,
          Colors.green,
        );
        expect(tester.widget<Text>(find.text('Pan')).style?.color, Colors.grey);
      },
    );

    testWidgets(
      'typing an exact label does not mark the row selected (B10, 8.0)',
      (tester) async {
        final c = _ctrl(numberedItems(4));
        await _pump(tester, _dropdown(c, overlay: styled));
        await openSingle(tester);

        await typeInSingle(tester, 'Item 2');

        expect(c.selectedItem, isNull);
        expect(_selectedRows(tester), isEmpty);
        expect(_rowBackground(tester, 'Item 2'), isNot(Colors.purple));
      },
    );

    testWidgets(
      'B10: typing the exact label of an unselected item does not render '
      'that row as selected',
      (tester) async {
        final c = _ctrl(numberedItems(4));
        await _pump(tester, _dropdown(c, overlay: styled));
        await openSingle(tester);

        await typeInSingle(tester, 'Item 2');

        expect(c.selectedItem, isNull);
        expect(_selectedRows(tester), isEmpty);
        expect(_rowBackground(tester, 'Item 2'), Colors.transparent);
      },
    ); // B10: fixed in 8.0
  });
}
