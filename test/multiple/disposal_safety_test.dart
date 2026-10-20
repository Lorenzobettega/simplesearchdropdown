// The multiple dropdown after its controller is disposed or while it is
// unmounted with the list open (#49).

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:simple_search_dropdown/simple_search_dropdown.dart';

import '../support/harness.dart';

Future<BuildContext> _context(WidgetTester tester) async {
  late BuildContext ctx;
  await tester.pumpWidget(
    host(
      Builder(
        builder: (BuildContext context) {
          ctx = context;
          return const SizedBox();
        },
      ),
    ),
  );
  return ctx;
}

void main() {
  group('#49: a callback that finishes after the controller is disposed', () {
    late List<ValueItem<int>> items;
    late List<List<ValueItem<int>>> selections;
    late Completer<void> pending;
    late MultipleSearchDropDownController<int> c;

    // Built inside each test: a Completer made in setUp lives outside the
    // test's fake-async zone.
    void build() {
      items = numberedItems(3);
      selections = <List<ValueItem<int>>>[];
      pending = Completer<void>();
      c = MultipleSearchDropDownController<int>(
        items: items,
        selectedItems: <ValueItem<int>>[items[1]],
        updateSelectedItems: selections.add,
        newValueItem: (String s) => ValueItem<int>(label: s, value: 99),
        onAddItem: (_) => pending.future,
        onDeleteItem: (_) => pending.future,
        editMode: true,
        onEditItem: (_, _) => pending.future,
      );
    }

    testWidgets('delete does not report a selection', (tester) async {
      build();
      final BuildContext ctx = await _context(tester);
      final Future<void> done = c.deleteItem(items[1], ctx);
      c.dispose();
      pending.complete();
      await expectLater(done, completes);
      await tester.pump();

      expect(tester.takeException(), isNull);
      expect(selections, isEmpty);
    });

    testWidgets('edit does not report a selection', (tester) async {
      build();
      final BuildContext ctx = await _context(tester);
      final Future<void> done = c.editItem(items[1], ctx);
      await tester.pumpAndSettle();
      await tester.enterText(
        find.descendant(
          of: find.byType(EditDialog),
          matching: find.byType(TextField),
        ),
        'Edited',
      );
      await tester.tap(find.text('Editar'));
      await tester.pumpAndSettle();
      c.dispose();
      pending.complete();
      await expectLater(done, completes);
      await tester.pump();

      expect(tester.takeException(), isNull);
      expect(selections, isEmpty);
    });

    testWidgets('add does not report a selection', (tester) async {
      build();
      final BuildContext ctx = await _context(tester);
      final Future<void> done = c.addItem('Kiwi', ctx);
      c.dispose();
      pending.complete();
      await expectLater(done, completes);
      await tester.pump();

      expect(tester.takeException(), isNull);
      expect(selections, isEmpty);
    });
  });

  group('#49: unmounting while the list is open', () {
    MultipleSearchDropDownController<int> controller() =>
        MultipleSearchDropDownController<int>(
          items: numberedItems(5),
          addMode: false,
          deleteMode: false,
        );

    testWidgets('with the controller disposed in that frame', (tester) async {
      final MultipleSearchDropDownController<int> c = controller();
      await tester.pumpWidget(host(MultipleSearchDropDown<int>(controller: c)));
      await openMultiple(tester);
      await tester.enterText(find.byType(TextField).last, 'Item');
      await tester.pump();

      await tester.pumpWidget(host(const SizedBox()));
      c.dispose();
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.byType(TextField), findsNothing);
    });

    testWidgets('a kept controller works when mounted again', (tester) async {
      final MultipleSearchDropDownController<int> c = controller();
      addTearDown(c.dispose);
      await tester.pumpWidget(host(MultipleSearchDropDown<int>(controller: c)));
      await openMultiple(tester);
      await tester.enterText(find.byType(TextField).last, 'Item 4');
      await tester.pump();
      await tester.pumpWidget(host(const SizedBox()));
      await tester.pumpAndSettle();

      await tester.pumpWidget(host(MultipleSearchDropDown<int>(controller: c)));
      await openMultiple(tester);
      // The list opens fresh: every item, an empty search.
      expect(c.query, '');
      expect(c.filteredItems, hasLength(5));
      await tester.enterText(find.byType(TextField).last, 'Item 2');
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(c.filteredItems.map((ValueItem<int> e) => e.label), <String>[
        'Item 2',
      ]);
    });
  });
}
