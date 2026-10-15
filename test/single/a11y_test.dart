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
        onEditItem: (_, __) {},
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
        listItems: items,
        addMode: false,
        deleteMode: false,
        initialSelectedItem: items[1],
      );
      await tester.pumpWidget(host(SearchDropDown<int>(controller: c)));
      await openSingle(tester);
      final Finder row = find.widgetWithText(DefaultListTile<int>, 'Banana');
      expect(
        tester.getSemantics(
            find.descendant(of: row, matching: find.byType(Semantics)).first),
        isSemantics(isSelected: true, hasSelectedState: true),
      );
      handle.dispose();
    });

    testWidgets('keyboard highlight is distinct from the selection',
        (tester) async {
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

      final DefaultListTile<int> selected = tester
          .widget(find.widgetWithText(DefaultListTile<int>, items[0].label));
      final DefaultListTile<int> highlighted = tester
          .widget(find.widgetWithText(DefaultListTile<int>, items[1].label));
      expect(selected.selected && !selected.highlighted, isTrue);
      expect(highlighted.highlighted && !highlighted.selected, isTrue);
    });
  });
}
