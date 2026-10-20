import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:simple_search_dropdown/simple_search_dropdown.dart';

import '../support/harness.dart';

SearchDropDownController<int> _ctrl({
  List<ValueItem<int>> items = const <ValueItem<int>>[],
  ValueItem<int>? initial,
  bool addMode = false,
  bool deleteMode = false,
  Function(ValueItem<int>)? onAddItem,
  Function(ValueItem<int>)? onDeleteItem,
  void Function(ValueItem<int>?)? updateSelectedItem,
  void Function()? onFilterUpdated,
}) => SearchDropDownController<int>(
  items: items,
  initialSelectedItem: initial,
  addMode: addMode,
  deleteMode: deleteMode,
  onAddItem: onAddItem,
  onDeleteItem: onDeleteItem,
  updateSelectedItem: updateSelectedItem,
  onFilterUpdated: onFilterUpdated,
  newValueItem: (s) => ValueItem<int>(label: s, value: s.length),
);

void main() {
  group('controller: items (owned copy)', () {
    test('items are copied; the caller list is never touched', () {
      final List<ValueItem<int>> mine = fruitItems();
      final c = _ctrl(items: mine);
      addTearDown(c.dispose);
      c.sortBy(SortType.alphabetical);
      expect(identical(c.items, mine), isFalse);
      expect(mine.first.label, 'Maçã');
      expect(c.items.first.label, 'abacaxi');
    });

    testWidgets('a callback that adds to its own list: one item in each', (
      tester,
    ) async {
      final List<ValueItem<int>> mine = fruitItems();
      final c = _ctrl(items: mine, addMode: true, onAddItem: mine.add);
      await tester.pumpWidget(host(SearchDropDown<int>(controller: c)));
      await openSingle(tester);
      await typeInSingle(tester, 'Kiwi');
      await tester.tap(find.text('Criar'));
      await tester.pumpAndSettle();
      expect(mine.where((e) => e.label == 'Kiwi'), hasLength(1));
      expect(c.items.where((e) => e.label == 'Kiwi'), hasLength(1));
      expect(c.selectedItem?.label, 'Kiwi');
    });

    testWidgets('the add row follows the text while results stay empty', (
      tester,
    ) async {
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
      expect(c.items.last.label, 'Kiwi');
    });
  });

  group('controller: ChangeNotifier (#45)', () {
    testWidgets('selection made through the controller updates the bar', (
      tester,
    ) async {
      final c = _ctrl(items: fruitItems());
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
      final c = _ctrl(items: fruitItems());
      await tester.pumpWidget(host(SearchDropDown<int>(controller: c)));
      expect(find.byIcon(Icons.arrow_drop_down), findsOneWidget);

      c.enabled = false;
      await tester.pump();
      expect(find.byIcon(Icons.arrow_drop_down), findsNothing);
    });

    test('notifies listeners on selection, enabled and list changes', () {
      final c = _ctrl(items: fruitItems());
      addTearDown(c.dispose);
      int count = 0;
      c
        ..addListener(() => count++)
        ..forceSelection('Banana');
      expect(count, 1, reason: 'forceSelection/selectItem must notify once');

      c.toggleEnabled();
      expect(count, 2, reason: 'toggleEnabled must notify once');
      expect(c.enabled, isFalse);

      final int beforeList = count;
      c.updateListItems(numberedItems(3), true);
      expect(
        count - beforeList,
        greaterThanOrEqualTo(1),
        reason: 'updateListItems must notify',
      );
      expect(c.selectedItem, isNull);
    });

    testWidgets('changes made during build are delivered after the frame', (
      tester,
    ) async {
      final c = _ctrl(items: fruitItems());
      await tester.pumpWidget(
        host(
          Builder(
            builder: (context) {
              if (c.items.length == 5) {
                c.updateListItems(numberedItems(2), true);
              }
              return SearchDropDown<int>(controller: c);
            },
          ),
        ),
      );
      await tester.pump();
      expect(tester.takeException(), isNull);
      expect(c.filteredItems, hasLength(2));
    });

    testWidgets(
      'a mutation from a sibling rebuild defers notify and onFilterUpdated',
      (tester) async {
        late StateSetter rebuildParent;
        late StateSetter rebuildSibling;
        bool mutate = false;
        int filterUpdates = 0;
        final c = SearchDropDownController<int>(
          items: fruitItems(),
          addMode: false,
          deleteMode: false,
          onFilterUpdated: () {
            filterUpdates++;
            // An ancestor setState throws when called during a build.
            rebuildParent(() {});
          },
        );
        addTearDown(c.dispose);
        await tester.pumpWidget(
          host(
            StatefulBuilder(
              builder: (context, setParent) {
                rebuildParent = setParent;
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    // Mounted sibling listening to the controller.
                    SearchDropDown<int>(controller: c),
                    StatefulBuilder(
                      builder: (context, setSibling) {
                        rebuildSibling = setSibling;
                        if (mutate) {
                          mutate = false;
                          // shouldReset false: the bar text is untouched.
                          c.updateListItems(numberedItems(2), false);
                        }
                        return const SizedBox.shrink();
                      },
                    ),
                  ],
                );
              },
            ),
          ),
        );
        expect(filterUpdates, 0);

        rebuildSibling(() => mutate = true);
        await tester.pump(); // the sibling rebuilds inside drawFrame
        expect(tester.takeException(), isNull);
        expect(c.filteredItems, hasLength(2));
        expect(filterUpdates, 1, reason: 'delivered after that frame');

        await tester.pump(); // flushes the parent rebuild it asked for
        expect(tester.takeException(), isNull);
        expect(filterUpdates, 1);
        expect(c.items, hasLength(2));
      },
    );

    testWidgets(
      'changes made during build while the view is open are delivered after '
      'the frame (F7)',
      (tester) async {
        final c = _ctrl(items: fruitItems());
        final ValueNotifier<int> tick = ValueNotifier<int>(0);
        addTearDown(tick.dispose);
        int applied = 0;
        final List<int> lengthsSeenInBuild = <int>[];
        await tester.pumpWidget(
          host(
            ValueListenableBuilder<int>(
              valueListenable: tick,
              builder: (context, v, _) {
                if (v > applied) {
                  applied = v;
                  if (v == 1) {
                    // No selection, no text: the path 7.x handled silently.
                    c.updateListItems(numberedItems(3), false);
                  } else if (v == 2) {
                    c.sortBy(SortType.reverseAlphabetical);
                  } else if (v == 3) {
                    c.filterList('Item 1');
                  }
                  // Readable at once, as in 7.x; the open view keeps the
                  // list it was built with until after this frame.
                  lengthsSeenInBuild.add(c.filteredItems.length);
                }
                return SearchDropDown<int>(controller: c);
              },
            ),
          ),
        );
        await openSingle(tester);
        await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
        await tester.pump();
        expect(c.highlightedIndex, 0, reason: 'so the reset really notifies');

        tick.value = 1;
        await tester.pump();
        expect(tester.takeException(), isNull);
        expect(lengthsSeenInBuild, <int>[3]);
        expect(c.highlightedIndex, -1);
        expect(c.filteredItems.map((e) => e.label), <String>[
          'Item 0',
          'Item 1',
          'Item 2',
        ]);
        await tester.pump();
        expect(find.text('Maçã'), findsNothing);
        expect(find.text('Item 2'), findsOneWidget);

        tick.value = 2;
        await tester.pump();
        expect(tester.takeException(), isNull);
        expect(c.filteredItems.first.label, 'Item 2');

        tick.value = 3;
        await tester.pump();
        expect(tester.takeException(), isNull);
        await tester.pump();
        expect(c.filteredItems.map((e) => e.label), <String>['Item 1']);
        expect(find.text('Item 0'), findsNothing);
        expect(lengthsSeenInBuild, <int>[3, 3, 1]);
      },
    );

    testWidgets(
      'changes made during a build are readable at once, as in 7.x (F7)',
      (tester) async {
        final List<ValueItem<int>?> selections = <ValueItem<int>?>[];
        final c = _ctrl(
          items: fruitItems(),
          updateSelectedItem: selections.add,
        );
        addTearDown(c.dispose);
        c.highlightEdge(last: true); // outside a build: 'Pêra'
        expect(c.highlightedIndex, 4);
        final List<Object> seen = <Object>[];
        bool mutate = true;
        await tester.pumpWidget(
          host(
            Builder(
              builder: (context) {
                if (mutate) {
                  mutate = false;
                  c.filterList('uva');
                  seen
                    ..add(c.filteredItems.length)
                    ..add(c.highlightedIndex);
                  c.submit(); // the highlight was reset: the first result
                  seen.add(c.selectedIndex);
                  c.updateListItems(numberedItems(3), false);
                  seen.add(c.filteredItems.length);
                }
                return const SizedBox();
              },
            ),
          ),
        );
        expect(tester.takeException(), isNull);
        expect(seen, <Object>[1, -1, 0, 3]);
        expect(selections.map((e) => e?.label), <String?>['Uva', null]);
      },
    );

    testWidgets(
      'changes made during a build notify results and onFilterUpdated once '
      'after the frame',
      (tester) async {
        int filterUpdates = 0;
        final c = _ctrl(
          items: fruitItems(),
          onFilterUpdated: () => filterUpdates++,
        );
        addTearDown(c.dispose);
        int resultNotes = 0;
        c.results.addListener(() => resultNotes++);
        bool mutate = true;
        await tester.pumpWidget(
          host(
            Builder(
              builder: (context) {
                if (mutate) {
                  mutate = false;
                  c
                    ..filterList('ba')
                    ..filterList('uva');
                  expect(filterUpdates, 0);
                }
                return const SizedBox();
              },
            ),
          ),
        );
        expect(tester.takeException(), isNull);
        expect(c.filteredItems.map((e) => e.label), <String>['Uva']);
        expect(filterUpdates, 1);
        expect(resultNotes, 1);
      },
    );

    testWidgets(
      'a highlight reset made during a build notifies highlight listeners '
      'after the frame (F7)',
      (tester) async {
        final c = _ctrl(items: fruitItems());
        addTearDown(c.dispose);
        c.highlightEdge(last: true); // outside a build
        final List<int> heard = <int>[];
        c.highlight.addListener(() => heard.add(c.highlightedIndex));
        bool mutate = true;
        await tester.pumpWidget(
          host(
            Builder(
              builder: (context) {
                if (mutate) {
                  mutate = false;
                  c.filterList('uva');
                  expect(heard, isEmpty); // never during the build
                }
                return const SizedBox();
              },
            ),
          ),
        );
        expect(tester.takeException(), isNull);
        expect(heard, <int>[-1]);
      },
    );

    testWidgets(
      'the open list never adds the add row to the list it still shows while '
      'a change from a build is pending (F7)',
      (tester) async {
        final c = _ctrl(items: fruitItems(), addMode: true, onAddItem: (_) {});
        addTearDown(c.dispose);
        final ValueNotifier<int> tick = ValueNotifier<int>(0);
        addTearDown(tick.dispose);
        int applied = 0;
        await tester.pumpWidget(
          MaterialApp(
            // Above the navigator: built before the open view in a frame.
            builder: (context, child) => ValueListenableBuilder<int>(
              valueListenable: tick,
              builder: (context, v, _) {
                if (v > applied) {
                  applied = v;
                  // Nothing matches the typed 'Ma' any more.
                  c.updateListItems(numberedItems(3), false);
                }
                return child!;
              },
            ),
            home: Scaffold(
              body: Center(child: SearchDropDown<int>(controller: c)),
            ),
          ),
        );
        await openSingle(tester);
        await typeInSingle(tester, 'M');
        expect(find.text('Maçã'), findsWidgets);
        expect(find.byType(DefaultAddListItem), findsNothing);

        // The typed text rebuilds the open list in the frame whose build
        // empties the results.
        c.localSearchController.text = 'Ma';
        tick.value = 1;
        await tester.pump();
        expect(tester.takeException(), isNull);
        expect(c.filteredItems, isEmpty);
        expect(find.byType(DefaultAddListItem), findsNothing);

        await tester.pump();
        expect(find.byType(DefaultAddListItem), findsOneWidget);
      },
    );

    testWidgets(
      'filters run during a build narrow and compare against the latest '
      'results (F7)',
      (tester) async {
        final c = _ctrl(items: fruitItems());
        addTearDown(c.dispose);
        c.filterList('u'); // outside a build: applied now
        expect(c.filteredItems.map((e) => e.label), <String>['Uva']);
        int step = 0;
        final ValueNotifier<int> tick = ValueNotifier<int>(0);
        addTearDown(tick.dispose);
        await tester.pumpWidget(
          host(
            ValueListenableBuilder<int>(
              valueListenable: tick,
              builder: (context, v, _) {
                if (v > step) {
                  step = v;
                  if (v == 1) {
                    c
                      ..filterList('b')
                      ..filterList('ba'); // narrows the pending [Banana, ...]
                  } else if (v == 2) {
                    c
                      ..filterList('u')
                      ..filterList(''); // differs from the pending [Uva]
                  }
                }
                return const SizedBox();
              },
            ),
          ),
        );

        tick.value = 1;
        await tester.pump();
        expect(tester.takeException(), isNull);
        expect(c.filteredItems.map((e) => e.label), <String>[
          'Banana',
          'abacaxi',
        ]);

        c.filterList(''); // outside a build: applied now
        expect(c.filteredItems, hasLength(5));
        tick.value = 2;
        await tester.pump();
        expect(tester.takeException(), isNull);
        expect(c.filteredItems, hasLength(5));
      },
    );

    testWidgets(
      'a result deferred from a build never overwrites a newer one (F7)',
      (tester) async {
        final c = _ctrl(items: fruitItems());
        addTearDown(c.dispose);
        bool first = true;
        bool second = true;
        await tester.pumpWidget(
          host(
            Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Builder(
                  builder: (context) {
                    if (first) {
                      first = false;
                      // Registered before the deferred swap below, so it
                      // runs first and applies a newer result.
                      WidgetsBinding.instance.addPostFrameCallback(
                        (_) => c.filterList('Banana'),
                      );
                    }
                    return const SizedBox();
                  },
                ),
                Builder(
                  builder: (context) {
                    if (second) {
                      second = false;
                      c.updateListItems(numberedItems(3) + fruitItems(), false);
                    }
                    return const SizedBox();
                  },
                ),
              ],
            ),
          ),
        );
        expect(tester.takeException(), isNull);
        expect(c.filteredItems.map((e) => e.label), <String>['Banana']);
        c.filterList('Banan'); // narrows the right base
        expect(c.filteredItems.map((e) => e.label), <String>['Banana']);
      },
    );

    testWidgets(
      'updateSelectedItem from a reset during a descendant build is delivered '
      'after the frame (F18)',
      (tester) async {
        late StateSetter setScreen;
        String shown = 'Banana';
        bool mutate = true;
        final c = SearchDropDownController<int>(
          items: fruitItems(),
          addMode: false,
          deleteMode: false,
          // An ancestor setState throws when called during a build.
          updateSelectedItem: (v) => setScreen(() => shown = '${v?.label}'),
        );
        addTearDown(c.dispose);
        await tester.pumpWidget(
          host(
            StatefulBuilder(
              builder: (context, setState) {
                setScreen = setState;
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Text('sel:$shown'),
                    Builder(
                      builder: (context) {
                        if (mutate) {
                          mutate = false;
                          c.updateListItems(numberedItems(2), true);
                        }
                        return SearchDropDown<int>(controller: c);
                      },
                    ),
                  ],
                );
              },
            ),
          ),
        );
        expect(tester.takeException(), isNull);
        await tester.pump();
        expect(c.filteredItems, hasLength(2));
        expect(find.text('sel:null'), findsOneWidget);
      },
    );

    testWidgets(
      'updateSelectedItem from a selection during a descendant build is '
      'delivered after the frame (F18)',
      (tester) async {
        late StateSetter setScreen;
        String shown = 'none';
        bool mutate = true;
        final c = SearchDropDownController<int>(
          items: fruitItems(),
          addMode: false,
          deleteMode: false,
          updateSelectedItem: (v) => setScreen(() => shown = '${v?.label}'),
        );
        addTearDown(c.dispose);
        await tester.pumpWidget(
          host(
            StatefulBuilder(
              builder: (context, setState) {
                setScreen = setState;
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Text('sel:$shown'),
                    Builder(
                      builder: (context) {
                        if (mutate) {
                          mutate = false;
                          c.forceSelection('Uva');
                        }
                        return SearchDropDown<int>(controller: c);
                      },
                    ),
                  ],
                );
              },
            ),
          ),
        );
        expect(tester.takeException(), isNull);
        await tester.pump();
        expect(c.selectedItem?.label, 'Uva');
        expect(find.text('sel:Uva'), findsOneWidget);
      },
    );

    testWidgets(
      'updateSelectedItem from clearSelectionAndNotify during a descendant '
      'build is delivered after the frame (F18)',
      (tester) async {
        late StateSetter setScreen;
        String shown = 'none';
        bool mutate = false;
        final c = SearchDropDownController<int>(
          items: fruitItems(),
          addMode: false,
          deleteMode: false,
          updateSelectedItem: (v) => setScreen(() => shown = '${v?.label}'),
        );
        addTearDown(c.dispose);
        await tester.pumpWidget(
          host(
            StatefulBuilder(
              builder: (context, setState) {
                setScreen = setState;
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Text('sel:$shown'),
                    Builder(
                      builder: (context) {
                        if (mutate) {
                          mutate = false;
                          c.clearSelectionAndNotify();
                        }
                        return SearchDropDown<int>(controller: c);
                      },
                    ),
                  ],
                );
              },
            ),
          ),
        );
        c.forceSelection('Uva'); // outside a build
        await tester.pump();
        expect(find.text('sel:Uva'), findsOneWidget);

        mutate = true;
        setScreen(() {});
        await tester.pump();
        expect(tester.takeException(), isNull);
        await tester.pump();
        expect(c.selectedItem, isNull);
        expect(find.text('sel:null'), findsOneWidget);
      },
    );

    testWidgets(
      'a selection callback deferred from a build is still delivered when the '
      'controller is disposed before it runs',
      (tester) async {
        final List<ValueItem<int>?> selections = <ValueItem<int>?>[];
        int filterUpdates = 0;
        final c = _ctrl(
          items: fruitItems(),
          updateSelectedItem: selections.add,
          onFilterUpdated: () => filterUpdates++,
        );
        bool mutate = true;
        await tester.pumpWidget(
          host(
            Builder(
              builder: (context) {
                if (mutate) {
                  mutate = false;
                  // Runs before the deferred callbacks queued below.
                  WidgetsBinding.instance.addPostFrameCallback(
                    (_) => c.dispose(),
                  );
                  c
                    ..forceSelection('Uva')
                    ..filterList('uva');
                }
                return const SizedBox();
              },
            ),
          ),
        );
        expect(tester.takeException(), isNull);
        expect(c.selectedItem?.label, 'Uva');
        // As in 7.x, where it ran synchronously; only listeners and
        // onFilterUpdated are skipped.
        expect(selections.map((e) => e?.label), <String>['Uva']);
        expect(filterUpdates, 0);
      },
    );

    test('async callbacks finishing after dispose are ignored', () async {
      final List<ValueItem<int>> mine = fruitItems();
      final List<ValueItem<int>?> selections = <ValueItem<int>?>[];
      final c = _ctrl(
        items: mine,
        deleteMode: true,
        onDeleteItem: (_) => Future<void>.delayed(Duration.zero),
        updateSelectedItem: selections.add,
      );
      final ValueItem<int> banana = mine[1];
      final BuildContext context = _FakeContext();
      final Future<void> pending = c.deleteItem(banana, context);
      c.dispose();
      await pending;
      expect(mine, hasLength(5));
      expect(mine, contains(banana));
      expect(selections, isEmpty);
    });

    test(
      'async add finishing after dispose leaves the caller list alone',
      () async {
        final List<ValueItem<int>> mine = fruitItems();
        final List<ValueItem<int>?> selections = <ValueItem<int>?>[];
        final c = _ctrl(
          items: mine,
          addMode: true,
          onAddItem: (_) => Future<void>.delayed(Duration.zero),
          updateSelectedItem: selections.add,
        );
        final Future<void> pending = c.addItem('Kiwi', _FakeContext());
        c.dispose();
        await pending;
        expect(mine.map((e) => e.label), isNot(contains('Kiwi')));
        expect(mine, hasLength(5));
        expect(selections, isEmpty);
      },
    );
  });

  group('view: selection matched by label when values are not comparable', () {
    testWidgets('an equal-label initialSelectedItem is shown as selected', (
      tester,
    ) async {
      final List<ValueItem<Object>> items = <ValueItem<Object>>[
        for (int i = 0; i < 60; i++)
          ValueItem<Object>(label: 'P$i', value: Object()),
      ];
      // Same label, different value instance (no == on the value type).
      final c = SearchDropDownController<Object>(
        items: items,
        addMode: false,
        deleteMode: false,
        initialSelectedItem: const ValueItem<Object>(
          label: 'P40',
          value: Object(),
        ),
      );
      await tester.pumpWidget(host(SearchDropDown<Object>(controller: c)));
      await openSingle(tester);
      final Finder row = find.widgetWithText(DefaultListTile<Object>, 'P40');
      expect(row, findsOneWidget);
      expect(tester.widget<DefaultListTile<Object>>(row).selected, isTrue);
      expect(c.selectedIndex, 40);
    });

    testWidgets(
      'opening with a selection selects the text so typing replaces',
      (tester) async {
        final List<ValueItem<int>> items = fruitItems();
        final c = SearchDropDownController<int>(
          items: items,
          addMode: false,
          deleteMode: false,
          initialSelectedItem: items[1],
        );
        await tester.pumpWidget(host(SearchDropDown<int>(controller: c)));
        await openSingle(tester);
        final TextSelection sel = c.localSearchController.selection;
        expect(sel.start, 0);
        expect(sel.end, 'Banana'.length);
      },
    );
  });

  group('view: opens scrolled to the selection (#46)', () {
    testWidgets('a selection far down the list is visible on open', (
      tester,
    ) async {
      final List<ValueItem<int>> items = numberedItems(200);
      final c = _ctrl(items: items, initial: items[150]);
      await tester.pumpWidget(host(SearchDropDown<int>(controller: c)));
      await openSingle(tester);

      final Finder row = find.widgetWithText(DefaultListTile<int>, 'Item 150');
      expect(row, findsOneWidget);
      expect(tester.widget<DefaultListTile<int>>(row).selected, isTrue);
      expect(c.filteredItems, hasLength(200));
    });

    testWidgets('PageDown/PageUp highlight the last/first item', (
      tester,
    ) async {
      final c = _ctrl(items: numberedItems(50));
      await tester.pumpWidget(host(SearchDropDown<int>(controller: c)));
      await openSingle(tester);

      await tester.sendKeyEvent(LogicalKeyboardKey.pageDown);
      await tester.pumpAndSettle();
      expect(c.highlightedIndex, 49);
      expect(
        find.widgetWithText(DefaultListTile<int>, 'Item 49'),
        findsOneWidget,
      );

      await tester.sendKeyEvent(LogicalKeyboardKey.pageUp);
      await tester.pumpAndSettle();
      expect(c.highlightedIndex, 0);
    });

    testWidgets('keys are ignored while a dialog covers the view', (
      tester,
    ) async {
      final List<ValueItem<int>> items = fruitItems();
      final c = SearchDropDownController<int>(
        items: items,
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

  group('dialogs that finish after dispose (F9)', () {
    testWidgets('a rejected add whose dialog closes after dispose leaves the '
        'disposed SearchController alone', (tester) async {
      final c = SearchDropDownController<int>(
        items: fruitItems(),
        deleteMode: false,
        newValueItem: (s) => ValueItem<int>(label: s, value: 99),
        onAddItem: (_) {},
        verifyInputItem: (_) => false,
      );
      late BuildContext ctx;
      await tester.pumpWidget(
        host(
          Builder(
            builder: (context) {
              ctx = context;
              return const SizedBox();
            },
          ),
        ),
      );
      // Non-empty, so clearing it would notify the disposed controller.
      c.localSearchController.text = 'Kiwi';
      final Future<void> done = expectLater(c.addItem('Kiwi', ctx), completes);
      await tester.pumpAndSettle();
      expect(find.byType(AlertDialog), findsOneWidget);
      c.dispose();
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();
      await done;
      expect(find.byType(AlertDialog), findsNothing);
      expect(tester.takeException(), isNull);
    });
  });
  group('public API surface (moved from the 7.x compile test)', () {
    test('controller.showClearIcon is a bool (default true) (F14)', () {
      final SearchDropDownController<int> c = SearchDropDownController<int>(
        items: <ValueItem<int>>[const ValueItem(label: 'A', value: 1)],
        addMode: false,
        deleteMode: false,
      );
      addTearDown(c.dispose);
      final bool v = c.showClearIcon;
      expect(v, isTrue);

      final SearchDropDownController<int> off = SearchDropDownController<int>(
        items: <ValueItem<int>>[],
        addMode: false,
        deleteMode: false,
        showClearIcon: false,
      );
      addTearDown(off.dispose);
      expect(off.showClearIcon ? 1 : 0, 0);
    });

    test('controller fields and methods keep their types', () {
      final List<ValueItem<int>> items = fruitItems();
      final List<ValueItem<int>?> calls = <ValueItem<int>?>[];
      final SearchDropDownController<int> c = SearchDropDownController<int>(
        items: items,
        addMode: false,
        deleteMode: false,
        sort: SortType.alphabetical,
        updateSelectedItem: calls.add,
      );
      addTearDown(c.dispose);
      final List<ValueItem<int>> l = c.items;
      final bool latinize = c.latinize;
      final bool caseSensitive = c.caseSensitive;
      final bool trim = c.trim;
      final int highlighted = c.highlightedIndex;
      expect(identical(l, items), isFalse);
      expect(<bool>[latinize, caseSensitive, trim], <bool>[true, false, true]);
      expect(highlighted, -1);
      c
        ..enabled = false
        ..enabled = true
        ..sortBy(SortType.reverseAlphabetical)
        ..filterList('a')
        ..forceSelection('Uva');
      final ValueItem<int>? selected = c.selectedItem;
      final bool clear = c.clearVisible;
      expect(selected?.label, 'Uva');
      expect(clear, isTrue);
      c
        ..clearVisible = false
        ..selectedItem = null
        ..resetSelection()
        ..updateListItems(fruitItems(), true);
      expect(calls.last, isNull);
    });
  });
}

class _FakeContext extends Fake implements BuildContext {
  @override
  bool get mounted => false;
}
