// ignore_for_file: cascade_invocations
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:simple_search_dropdown/simple_search_dropdown.dart';

import '../support/harness.dart';

MultipleSearchDropDownController<int> _ctrl({
  List<ValueItem<int>>? items,
  List<ValueItem<int>>? selected,
  void Function(List<ValueItem<int>>)? onChanged,
  SortType sort = SortType.none,
}) => MultipleSearchDropDownController<int>(
  items: items ?? fruitItems(),
  selectedItems: selected,
  updateSelectedItems: onChanged,
  addMode: false,
  deleteMode: false,
  sort: sort,
);

void main() {
  group('multiple controller: API without GlobalKey', () {
    testWidgets('selection changes made in code update the chips', (
      tester,
    ) async {
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

    testWidgets('disabling while the list is open closes it (N58)', (
      tester,
    ) async {
      final c = _ctrl();
      addTearDown(c.dispose);
      await tester.pumpWidget(host(MultipleSearchDropDown<int>(controller: c)));
      await openMultiple(tester);
      expect(find.byType(MultipleListView<int>), findsOneWidget);
      c.enabled = false;
      await tester.pumpAndSettle();
      expect(find.byType(MultipleListView<int>), findsNothing);
      // Code can still change the selection while disabled (7.x).
      c.forceSelection('Uva');
      await tester.pump();
      expect(find.text('Uva'), findsOneWidget);
      c.enabled = true;
      await tester.pump();
      await openMultiple(tester);
      expect(find.byType(MultipleListView<int>), findsOneWidget);
    });

    testWidgets('a swapped-in disabled controller closes the list (N58)', (
      tester,
    ) async {
      final a = _ctrl();
      final b = _ctrl()..enabled = false;
      addTearDown(a.dispose);
      addTearDown(b.dispose);
      MultipleSearchDropDownController<int> current = a;
      late StateSetter swap;
      await tester.pumpWidget(
        host(
          StatefulBuilder(
            builder: (context, setState) {
              swap = setState;
              return MultipleSearchDropDown<int>(controller: current);
            },
          ),
        ),
      );
      await openMultiple(tester);
      swap(() => current = b);
      await tester.pumpAndSettle();
      expect(find.byType(MultipleListView<int>), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('a disabled box cannot be opened or edited from the keyboard '
        '(N58)', (tester) async {
      final items = fruitItems();
      final c = _ctrl(items: items, selected: <ValueItem<int>>[items[1]]);
      addTearDown(c.dispose);
      await tester.pumpWidget(host(MultipleSearchDropDown<int>(controller: c)));
      // While enabled, Tab + Enter opens the list (kept from 7.x).
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();
      expect(find.byType(MultipleListView<int>), findsOneWidget);
      c.enabled = false;
      await tester.pumpAndSettle();
      expect(find.byType(MultipleListView<int>), findsNothing);
      for (int i = 0; i < 3; i++) {
        // box, chip close, clear
        await tester.sendKeyEvent(LogicalKeyboardKey.tab);
        await tester.pump();
        await tester.sendKeyEvent(LogicalKeyboardKey.enter);
        await tester.pumpAndSettle();
      }
      expect(find.byType(MultipleListView<int>), findsNothing);
      expect(c.selectedItems.map((e) => e.label), <String>['Banana']);
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

    test('caseSensitive does not change the A-Z order (N24, D2)', () {
      final c = MultipleSearchDropDownController<int>(
        items: fruitItems(),
        addMode: false,
        deleteMode: false,
        sort: SortType.alphabetical,
        caseSensitive: true,
      );
      addTearDown(c.dispose);
      expect(c.filteredItems.first.label, 'abacaxi');
    });

    test('items are copied; sorting never reorders the caller list', () {
      final List<ValueItem<int>> mine = fruitItems();
      final c = _ctrl(items: mine, sort: SortType.alphabetical);
      addTearDown(c.dispose);
      expect(c.filteredItems.first.label, 'abacaxi');
      expect(mine.first.label, 'Maçã');
    });

    testWidgets('the open list sits below dialogs (confirm delete works)', (
      tester,
    ) async {
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

  group('multiple controller: flags and sort can change (N46)', () {
    MultipleSearchDropDownController<int> make(List<ValueItem<int>> items) {
      final c = MultipleSearchDropDownController<int>(
        listItems: items,
        newValueItem: (s) => ValueItem<int>(label: s, value: 99),
        onAddItem: (_) {},
        onDeleteItem: (_) {},
        onEditItem: (_, _) {},
      );
      addTearDown(c.dispose);
      return c;
    }

    test('sort reorders the results, not the caller list, once', () {
      final List<ValueItem<int>> items = fruitItems();
      final c = make(items);
      int notified = 0;
      c.addListener(() => notified++);
      c.sort = SortType.alphabetical;
      expect(c.sort, SortType.alphabetical);
      expect(c.filteredItems.map((e) => e.label), <String>[
        'abacaxi',
        'Banana',
        'Maçã',
        'Pêra',
        'Uva',
      ]);
      expect(items.map((e) => e.label), <String>[
        'Maçã',
        'Banana',
        'Uva',
        'abacaxi',
        'Pêra',
      ]);
      expect(notified, 1);
      c.sort = SortType.alphabetical;
      expect(notified, 1);
      c.sort = SortType.none;
      expect(c.filteredItems.first.label, 'Maçã');
      expect(notified, 2);
    });

    test('sort applies to a list that is already in order', () {
      final List<ValueItem<int>> items = <ValueItem<int>>[
        const ValueItem(label: 'a', value: 1),
        const ValueItem(label: 'b', value: 2),
      ];
      final c = make(items);
      int notified = 0;
      c.addListener(() => notified++);
      // Same results: listeners still learn that sort changed.
      c.sort = SortType.alphabetical;
      expect(c.filteredItems.map((e) => e.label), <String>['a', 'b']);
      expect(notified, 1);
      c.sort = SortType.reverseAlphabetical;
      expect(c.filteredItems.map((e) => e.label), <String>['b', 'a']);
      final List<ValueItem<int>> pinned = <ValueItem<int>>[items[1]];
      final p = MultipleSearchDropDownController<int>(
        listItems: items,
        selectedItems: pinned,
        addMode: false,
        deleteMode: false,
      );
      addTearDown(p.dispose);
      p.sort = SortType.selectedFirst;
      expect(p.filteredItems.map((e) => e.label), <String>['b', 'a']);
    });

    test('addMode, deleteMode and editMode notify only on change', () {
      final c = make(fruitItems());
      int notified = 0;
      c
        ..addListener(() => notified++)
        ..search('kiwi');
      expect(c.canAdd, isTrue);
      notified = 0;
      c.addMode = false;
      expect(c.addMode, isFalse);
      expect(c.canAdd, isFalse);
      expect(notified, 1);
      c.addMode = false;
      expect(notified, 1);
      c.deleteMode = false;
      expect(c.deleteMode, isFalse);
      expect(notified, 2);
      c.deleteMode = false;
      c.editMode = true;
      expect(c.editMode, isTrue);
      expect(notified, 3);
      c.editMode = true;
      expect(notified, 3);
      c.confirmDelete = true;
      expect(c.confirmDelete, isTrue);
    });

    test('the setters keep the constructor asserts', () {
      final c = _ctrl();
      addTearDown(c.dispose);
      expect(() => c.addMode = true, throwsAssertionError);
      expect(() => c.deleteMode = true, throwsAssertionError);
      expect(() => c.editMode = true, throwsAssertionError);
    });
  });

  group('multiple controller: normalization options are forwarded', () {
    MultipleSearchDropDownController<int> make({
      bool latinize = true,
      bool caseSensitive = false,
      bool trim = true,
    }) {
      final c = MultipleSearchDropDownController<int>(
        items: fruitItems(),
        addMode: false,
        deleteMode: false,
        latinize: latinize,
        caseSensitive: caseSensitive,
        trim: trim,
      );
      addTearDown(c.dispose);
      return c;
    }

    List<String> found(MultipleSearchDropDownController<int> c, String q) {
      c.search(q);
      return c.filteredItems.map((e) => e.label).toList();
    }

    test('defaults ignore case, accents and surrounding spaces', () {
      final c = make();
      expect(found(c, 'MACA'), <String>['Maçã']);
      expect(found(c, ' uva '), <String>['Uva']);
    });

    test('caseSensitive: true', () {
      final c = make(caseSensitive: true);
      expect(found(c, 'MACA'), isEmpty);
      expect(found(c, 'banana'), isEmpty);
      expect(found(c, 'Banana'), <String>['Banana']);
      c.forceSelection('banana');
      expect(c.selectedItems, isEmpty);
    });

    test('latinize: false', () {
      final c = make(latinize: false);
      expect(found(c, 'maca'), isEmpty);
      expect(found(c, 'maçã'), <String>['Maçã']);
      expect(found(c, 'pera'), isEmpty);
    });

    test('trim: false', () {
      final c = make(trim: false);
      expect(found(c, ' uva '), isEmpty);
      expect(found(c, 'uva'), <String>['Uva']);
    });
  });

  group('multiple controller: onFilterUpdated', () {
    testWidgets(
      'fires once per change of filteredItems, never during a build',
      (tester) async {
        final List<List<String>> calls = <List<String>>[];
        final List<SchedulerPhase> phases = <SchedulerPhase>[];
        late final MultipleSearchDropDownController<int> c;
        c = MultipleSearchDropDownController<int>(
          items: fruitItems(),
          addMode: false,
          deleteMode: false,
          onFilterUpdated: () {
            calls.add(c.filteredItems.map((e) => e.label).toList());
            phases.add(SchedulerBinding.instance.schedulerPhase);
          },
        );
        addTearDown(c.dispose);
        await tester.pumpWidget(
          host(MultipleSearchDropDown<int>(controller: c)),
        );
        expect(calls, isEmpty, reason: 'construction does not fire');

        c.search('ma');
        expect(calls, <List<String>>[
          <String>['Maçã'],
        ]);
        c.search('maç'); // same result
        expect(calls, hasLength(1));

        // Opening refreshes the list during a build: delivered after it.
        await openMultiple(tester);
        expect(tester.takeException(), isNull);
        expect(calls, hasLength(2));
        expect(calls.last, <String>[
          'Maçã',
          'Banana',
          'Uva',
          'abacaxi',
          'Pêra',
        ]);

        await tester.enterText(find.byType(TextField).last, 'zzz');
        await tester.pump();
        expect(calls, hasLength(3));
        expect(calls.last, isEmpty);
        await tester.enterText(find.byType(TextField).last, 'zzzz');
        await tester.pump();
        expect(calls, hasLength(3));

        expect(phases, isNot(contains(SchedulerPhase.persistentCallbacks)));
      },
    );
  });

  group('multiple controller: selection callbacks during a build (F18)', () {
    testWidgets('are delivered after the frame, in order', (tester) async {
      late StateSetter setScreen;
      late StateSetter setChild;
      final List<String> calls = <String>[];
      String mutation = 'force';
      late final MultipleSearchDropDownController<int> c;
      c = MultipleSearchDropDownController<int>(
        items: fruitItems(),
        addMode: false,
        deleteMode: false,
        // An ancestor setState throws when called during a build.
        updateSelectedItems: (s) =>
            setScreen(() => calls.add('update:${s.length}')),
        onClearItem: (item) =>
            setScreen(() => calls.add('clear:${item.label}')),
        onClearList: () => setScreen(() => calls.add('clearList')),
      );
      addTearDown(c.dispose);
      await tester.pumpWidget(
        host(
          StatefulBuilder(
            builder: (context, setState) {
              setScreen = setState;
              return StatefulBuilder(
                builder: (context, setState) {
                  setChild = setState;
                  switch (mutation) {
                    case 'force':
                      c.forceSelection('Banana');
                    case 'toggle':
                      c.toggle(c.selectedItems.first);
                    case 'reset':
                      c.resetSelection();
                    case 'clear':
                      c.clear();
                  }
                  mutation = '';
                  return MultipleSearchDropDown<int>(controller: c);
                },
              );
            },
          ),
        ),
      );
      expect(tester.takeException(), isNull);
      await tester.pump();
      expect(calls, <String>['update:1']);

      for (final String next in <String>['toggle', 'reset', 'clear']) {
        setChild(() => mutation = next);
        await tester.pump();
        expect(tester.takeException(), isNull, reason: next);
        await tester.pump();
      }
      expect(calls, <String>[
        'update:1',
        'clear:Banana',
        'update:0',
        'update:0',
        'update:0',
        'clearList',
      ]);
    });

    testWidgets('are delivered even when the controller is disposed in that '
        'frame', (tester) async {
      final List<String> calls = <String>[];
      final c = MultipleSearchDropDownController<int>(
        items: fruitItems(),
        selectedItems: fruitItems().take(2).toList(),
        addMode: false,
        deleteMode: false,
        updateSelectedItems: (s) => calls.add('update:${s.length}'),
        onClearItem: (item) => calls.add('clear:${item.label}'),
        onClearList: () => calls.add('clearList'),
        onFilterUpdated: () => calls.add('filter'),
      );
      bool mutate = true;
      await tester.pumpWidget(
        host(
          Builder(
            builder: (context) {
              if (mutate) {
                mutate = false;
                // Runs before the deferred callbacks queued below.
                SchedulerBinding.instance.addPostFrameCallback(
                  (_) => c.dispose(),
                );
                c
                  ..toggle(c.selectedItems.first)
                  ..clear()
                  ..search('uva');
              }
              return const SizedBox();
            },
          ),
        ),
      );
      expect(tester.takeException(), isNull);
      expect(c.isDisposed, isTrue);
      // The values 7.x passed synchronously: 1 of 2 left after the toggle.
      // onFilterUpdated, like listeners, is skipped after dispose.
      expect(calls, <String>[
        'clear:Maçã',
        'update:1',
        'update:0',
        'clearList',
      ]);
    });
  });
  group('public API surface (moved from the 7.x compile test)', () {
    test('MultipleSearchDropDown listItems/selectedItems/updateSelectedItems '
        'read as non-null (F14)', () {
      final List<ValueItem<int>> items = fruitItems();
      final List<ValueItem<int>> sel = <ValueItem<int>>[];
      final List<List<ValueItem<int>>> calls = <List<ValueItem<int>>>[];
      final MultipleSearchDropDown<int> w = MultipleSearchDropDown<int>(
        listItems: items,
        selectedItems: sel,
        updateSelectedItems: calls.add,
        addMode: false,
        deleteMode: false,
      );
      final List<ValueItem<int>> l = w.listItems;
      final List<ValueItem<int>> s = w.selectedItems;
      final Function(List<ValueItem<int>>) update = w.updateSelectedItems;
      expect(identical(l, items), isTrue);
      expect(identical(s, sel), isTrue);
      update(sel);
      expect(calls, hasLength(1));
      expect(w.selectedItems.isEmpty, isTrue);

      // Controller mode: the getters read the controller.
      final List<List<ValueItem<int>>> ctrlCalls = <List<ValueItem<int>>>[];
      final MultipleSearchDropDownController<int> mc =
          MultipleSearchDropDownController<int>(
            items: fruitItems(),
            updateSelectedItems: ctrlCalls.add,
            addMode: false,
            deleteMode: false,
          );
      addTearDown(mc.dispose);
      final MultipleSearchDropDown<int> cw = MultipleSearchDropDown<int>(
        controller: mc,
      );
      expect(identical(cw.listItems, mc.listItems), isTrue);
      expect(identical(cw.selectedItems, mc.selectedItems), isTrue);
      cw.updateSelectedItems(mc.selectedItems);
      expect(ctrlCalls, hasLength(1));
      // The controller wins over the list parameters passed alongside it.
      final MultipleSearchDropDown<int> both = MultipleSearchDropDown<int>(
        controller: mc,
        listItems: items,
        selectedItems: sel,
        updateSelectedItems: calls.add,
      );
      expect(identical(both.listItems, mc.listItems), isTrue);
      expect(identical(both.selectedItems, mc.selectedItems), isTrue);
      both.updateSelectedItems(mc.selectedItems);
      expect(ctrlCalls, hasLength(2));
      expect(calls, hasLength(1));
      // Without a callback the getter is a no-op, never null.
      final MultipleSearchDropDownController<int> silent =
          MultipleSearchDropDownController<int>(
            items: fruitItems(),
            addMode: false,
            deleteMode: false,
          );
      addTearDown(silent.dispose);
      MultipleSearchDropDown<int>(
        controller: silent,
      ).updateSelectedItems(silent.selectedItems);
    });

    testWidgets('state members: aberto reads false, hideOverlay on a closed '
        'list is a no-op (F10)', (tester) async {
      final GlobalKey<MultipleSearchDropDownState<int>> key = GlobalKey();
      final List<ValueItem<int>> sel = <ValueItem<int>>[];
      await tester.pumpWidget(
        host(
          MultipleSearchDropDown<int>(
            key: key,
            listItems: fruitItems(),
            selectedItems: sel,
            updateSelectedItems: (_) {},
            addMode: false,
            deleteMode: false,
            sort: SortType.alphabetical,
          ),
        ),
      );
      final MultipleSearchDropDownState<int> state = key.currentState!;
      final bool open = state.aberto;
      expect(open, isFalse);
      state.hideOverlay();
      await tester.pump();
      expect(sel, isEmpty);
      expect(tester.takeException(), isNull);
    });
  });
}
