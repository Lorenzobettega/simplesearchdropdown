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
        listItems: items,
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
      final List<ValueItem<int>> items = fruitItems();
      final c = SearchDropDownController<int>(
        listItems: items,
        addMode: false,
        deleteMode: false,
        initialSelectedItem: items[1],
      );
      await tester.pumpWidget(host(SearchDropDown<int>(controller: c)));
      await openSingle(tester);
      bool selectedFlag(String label) => tester
          .widget<Semantics>(
            find
                .descendant(
                  of: find.widgetWithText(DefaultListTile<int>, label),
                  matching: find.byType(Semantics),
                )
                .first,
          )
          .properties
          .selected!;
      expect(selectedFlag('Banana'), isTrue);
      expect(selectedFlag('Uva'), isFalse);
    });

    testWidgets('keyboard highlight is distinct from the selection', (
      tester,
    ) async {
      final List<ValueItem<int>> items = fruitItems();
      final c = SearchDropDownController<int>(
        listItems: items,
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
    });

    group('highlight colours', () {
      Future<void> highlightBanana(
        WidgetTester tester,
        SimpleOverlaySettings overlay,
      ) async {
        final c = SearchDropDownController<int>(
          listItems: fruitItems(),
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

      ButtonStyle styleOf(WidgetTester tester, String label) => tester
          .widget<TextButton>(
            find.descendant(
              of: find.widgetWithText(DefaultListTile<int>, label),
              matching: find.byType(TextButton),
            ),
          )
          .style!;
      Color background(WidgetTester tester, String label) =>
          styleOf(tester, label).backgroundColor!.resolve(<WidgetState>{})!;
      BorderSide side(WidgetTester tester, String label) =>
          (styleOf(tester, label).shape!.resolve(<WidgetState>{})!
                  as RoundedRectangleBorder)
              .side;

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
        expect(background(tester, 'Banana'), Colors.red);
        expect(side(tester, 'Banana').color, Colors.blue);
        expect(background(tester, 'Uva'), Colors.transparent);
        expect(side(tester, 'Uva'), BorderSide.none);
      });

      testWidgets('defaults: hover colour and a black26 border', (
        tester,
      ) async {
        const SimpleOverlaySettings settings = SimpleOverlaySettings();
        await highlightBanana(tester, settings);
        expect(background(tester, 'Banana'), settings.unselectedItemHoverColor);
        expect(side(tester, 'Banana').color, Colors.black26);
        expect(background(tester, 'Uva'), Colors.transparent);
      });
    });
  });
}
