import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:simple_search_dropdown/simple_search_dropdown.dart';

import '../support/harness.dart';

void main() {
  group('a11y: single dropdown', () {
    testWidgets('arrow, clear, edit and delete have tooltips', (tester) async {
      final List<ValueItem<int>> items = fruitItems();
      final c = SearchDropDownController<int>(
        items: items,
        addMode: false,
        onDeleteItem: items.remove,
        editMode: true,
        onEditItem: (_, _) {},
        newValueItem: (s) => ValueItem<int>(label: s, value: 0),
        initialSelectedItem: items.first,
      );
      await tester.pumpWidget(host(SearchDropDown<int>(controller: c)));
      expect(find.byTooltip('Abrir lista'), findsOneWidget);
      expect(find.byTooltip('Limpar seleção'), findsOneWidget);

      await openSingle(tester);
      expect(find.byTooltip('Fechar lista'), findsOneWidget);
      expect(find.byTooltip('Editar item'), findsWidgets);
      expect(find.byTooltip('Apagar item'), findsWidgets);
    });

    testWidgets('the selected row is announced as selected', (tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      final List<ValueItem<int>> items = fruitItems();
      final c = SearchDropDownController<int>(
        items: items,
        addMode: false,
        deleteMode: false,
        initialSelectedItem: items[1],
      );
      await tester.pumpWidget(host(SearchDropDown<int>(controller: c)));
      await openSingle(tester);
      // The flag sits on the button node that carries the row's label.
      expect(
        tester.getSemantics(_rowText('Banana')),
        _announces('Banana', selected: true),
      );
      expect(
        tester.getSemantics(_rowText('Uva')),
        _announces('Uva', selected: false),
      );
      handle.dispose();
    });

    testWidgets('a custom itemWidgetBuilder row is announced as selected', (
      tester,
    ) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      final List<ValueItem<int>> items = fruitItems();
      final c = SearchDropDownController<int>(
        items: items,
        addMode: false,
        deleteMode: false,
        initialSelectedItem: items[1],
      );
      await tester.pumpWidget(
        host(
          SearchDropDown<int>(
            controller: c,
            overlayListSettings: SimpleOverlaySettings(
              itemWidgetBuilder: (i) => Text('<${i.label}>'),
            ),
          ),
        ),
      );
      await openSingle(tester);
      expect(
        tester.getSemantics(_rowText('<Banana>')),
        _announces('<Banana>', selected: true),
      );
      expect(
        tester.getSemantics(_rowText('<Uva>')),
        _announces('<Uva>', selected: false),
      );
      handle.dispose();
    });

    testWidgets('keyboard highlight is distinct from the selection', (
      tester,
    ) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      final List<ValueItem<int>> items = fruitItems();
      final c = SearchDropDownController<int>(
        items: items,
        addMode: false,
        deleteMode: false,
        initialSelectedItem: items[0],
      );
      await tester.pumpWidget(host(SearchDropDown<int>(controller: c)));
      await openSingle(tester);
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pumpAndSettle();

      final DefaultListTile<int> selected = tester.widget(
        find.widgetWithText(DefaultListTile<int>, items[0].label),
      );
      final DefaultListTile<int> highlighted = tester.widget(
        find.widgetWithText(DefaultListTile<int>, items[1].label),
      );
      expect(selected.selected && !selected.highlighted, isTrue);
      expect(highlighted.highlighted && !highlighted.selected, isTrue);
      // Only the selection is announced as selected, not the highlight.
      expect(
        tester.getSemantics(_rowText(items[1].label)),
        _announces(items[1].label, selected: false),
      );
      expect(
        tester.getSemantics(_rowText(items[0].label)),
        _announces(items[0].label, selected: true),
      );
      handle.dispose();
    });

    testWidgets('keyboard highlight is visible on the selected row', (
      tester,
    ) async {
      final List<ValueItem<int>> items = fruitItems();
      final c = SearchDropDownController<int>(
        items: items,
        addMode: false,
        deleteMode: false,
        initialSelectedItem: items[1],
      );
      await tester.pumpWidget(host(SearchDropDown<int>(controller: c)));
      await openSingle(tester);
      expect(_side(tester, 'Banana'), BorderSide.none);

      // The first arrow press puts the highlight on the selected row.
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pumpAndSettle();
      final DefaultListTile<int> row = tester.widget(
        find.widgetWithText(DefaultListTile<int>, 'Banana'),
      );
      expect(row.selected && row.highlighted, isTrue);
      expect(
        _side(tester, 'Banana').color,
        const SimpleOverlaySettings().highlightedItemBorderColor,
      );
      expect(
        _background(tester, 'Banana'),
        const SimpleOverlaySettings().selectedItemBackgroundColor,
      );

      // Wrapping back onto the selected row keeps the cue.
      for (int i = 0; i < c.filteredItems.length; i++) {
        await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      }
      await tester.pumpAndSettle();
      expect(c.highlightedIndex, c.selectedIndex);
      expect(_side(tester, 'Banana'), isNot(BorderSide.none));
      expect(_side(tester, 'Uva'), BorderSide.none);
    });

    group('highlight colours', () {
      Future<void> highlightBanana(
        WidgetTester tester,
        SimpleOverlaySettings overlay,
      ) async {
        final c = SearchDropDownController<int>(
          items: fruitItems(),
          addMode: false,
          deleteMode: false,
        );
        await tester.pumpWidget(
          host(
            SearchDropDown<int>(controller: c, overlayListSettings: overlay),
          ),
        );
        await openSingle(tester);
        await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
        await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
        await tester.pumpAndSettle();
        expect(
          tester
              .widget<DefaultListTile<int>>(
                find.widgetWithText(DefaultListTile<int>, 'Banana'),
              )
              .highlighted,
          isTrue,
        );
      }

      testWidgets('custom colours are applied to the highlighted row', (
        tester,
      ) async {
        await highlightBanana(
          tester,
          const SimpleOverlaySettings(
            highlightedItemBackgroundColor: Colors.red,
            highlightedItemBorderColor: Colors.blue,
          ),
        );
        expect(_background(tester, 'Banana'), Colors.red);
        expect(_side(tester, 'Banana').color, Colors.blue);
        expect(_background(tester, 'Uva'), Colors.transparent);
        expect(_side(tester, 'Uva'), BorderSide.none);
      });

      testWidgets('defaults: hover colour and a black26 border', (
        tester,
      ) async {
        const SimpleOverlaySettings settings = SimpleOverlaySettings();
        await highlightBanana(tester, settings);
        expect(
          _background(tester, 'Banana'),
          settings.unselectedItemHoverColor,
        );
        expect(_side(tester, 'Banana').color, Colors.black26);
        expect(_background(tester, 'Uva'), Colors.transparent);
      });

      // 7.x drew a highlighted row with the caller's selected pair; a custom
      // selected text style must not land on the stock light hover fill.
      const SimpleOverlaySettings dark = SimpleOverlaySettings(
        dialogBackgroundColor: Color(0xFF212121),
        selectedItemBackgroundColor: Colors.white24,
        selectedItemTextStyle: TextStyle(color: Colors.white),
        unselectedItemTextStyle: TextStyle(color: Colors.white54),
      );

      testWidgets('a customised selected style keeps its own background', (
        tester,
      ) async {
        await highlightBanana(tester, dark);
        expect(_background(tester, 'Banana'), Colors.white24);
        expect(
          tester.widget<Text>(_rowText('Banana')).style?.color,
          Colors.white,
        );
        expect(_side(tester, 'Banana').color, dark.highlightedItemBorderColor);
        expect(_background(tester, 'Uva'), Colors.transparent);
      });

      testWidgets('a customised hover colour keeps the selected background', (
        tester,
      ) async {
        await highlightBanana(
          tester,
          const SimpleOverlaySettings(
            selectedItemBackgroundColor: Colors.purple,
            unselectedItemHoverColor: Colors.white10,
          ),
        );
        expect(_background(tester, 'Banana'), Colors.purple);
      });

      testWidgets('highlightedItemBackgroundColor wins over a custom style', (
        tester,
      ) async {
        await highlightBanana(
          tester,
          const SimpleOverlaySettings(
            selectedItemBackgroundColor: Colors.white24,
            selectedItemTextStyle: TextStyle(color: Colors.white),
            highlightedItemBackgroundColor: Colors.amber,
          ),
        );
        expect(_background(tester, 'Banana'), Colors.amber);
      });
    });
  });

  group('a11y: multiple dropdown', () {
    testWidgets('selected rows are announced as selected', (tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      final List<ValueItem<int>> items = fruitItems();
      final c = MultipleSearchDropDownController<int>(
        items: items,
        selectedItems: <ValueItem<int>>[items[1]],
        addMode: false,
        deleteMode: false,
      );
      addTearDown(c.dispose);
      await tester.pumpWidget(host(MultipleSearchDropDown<int>(controller: c)));
      await openMultiple(tester);
      expect(
        tester.getSemantics(_rowText('Banana')),
        _announces('Banana', selected: true),
      );
      expect(
        tester.getSemantics(_rowText('Uva')),
        _announces('Uva', selected: false),
      );
      handle.dispose();
    });
  });
}

/// A labelled button node whose selected state is [selected].
Matcher _announces(String label, {required bool selected}) =>
    // isSemantics replaces it only after the 3.32 floor.
    // ignore: deprecated_member_use
    containsSemantics(
      label: label,
      isButton: true,
      hasSelectedState: true,
      isSelected: selected,
    );

/// The label of the row for [label], not the search bar's or a chip's text.
Finder _rowText(String label) => find.descendant(
  of: find.byType(DefaultListTile<int>),
  matching: find.text(label),
);

ButtonStyle _styleOf(WidgetTester tester, String label) => tester
    .widget<TextButton>(
      find.descendant(
        of: find.widgetWithText(DefaultListTile<int>, label),
        matching: find.byType(TextButton),
      ),
    )
    .style!;

Color _background(WidgetTester tester, String label) =>
    _styleOf(tester, label).backgroundColor!.resolve(<WidgetState>{})!;

BorderSide _side(WidgetTester tester, String label) =>
    (_styleOf(tester, label).shape!.resolve(<WidgetState>{})!
            as RoundedRectangleBorder)
        .side;
