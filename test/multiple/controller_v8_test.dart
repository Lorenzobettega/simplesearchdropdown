import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
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
}
