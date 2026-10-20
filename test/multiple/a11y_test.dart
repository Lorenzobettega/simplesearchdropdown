import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:simple_search_dropdown/simple_search_dropdown.dart';

import '../support/harness.dart';

/// A [Semantics] button labelled [label] (the multiple box uses Semantics
/// labels, not Tooltip widgets).
Finder _semanticButton(String label) => find.byWidgetPredicate(
  (w) =>
      w is Semantics &&
      w.properties.button == true &&
      w.properties.label == label,
);

void main() {
  group('a11y: multiple dropdown', () {
    testWidgets('trailing icons expose open/close/clear labels', (
      tester,
    ) async {
      final List<ValueItem<int>> items = fruitItems();
      final c = MultipleSearchDropDownController<int>(
        items: items,
        addMode: false,
        deleteMode: false,
      );
      addTearDown(c.dispose);
      await tester.pumpWidget(host(MultipleSearchDropDown<int>(controller: c)));
      expect(_semanticButton('Abrir lista'), findsOneWidget);

      await openMultiple(tester);
      expect(_semanticButton('Fechar lista'), findsOneWidget);

      c.toggle(c.items[1]);
      await tester.pump();
      expect(_semanticButton('Limpar seleção'), findsOneWidget);
    });

    testWidgets('labels come from the strings', (tester) async {
      final c = MultipleSearchDropDownController<int>(
        items: fruitItems(),
        addMode: false,
        deleteMode: false,
      );
      addTearDown(c.dispose);
      await tester.pumpWidget(
        host(
          MultipleSearchDropDown<int>(
            controller: c,
            strings: const SearchDropDownStrings.en(),
          ),
        ),
      );
      expect(_semanticButton('Open list'), findsOneWidget);
      expect(_semanticButton('Abrir lista'), findsNothing);
    });

    testWidgets('chip remove button is labelled and removes its item', (
      tester,
    ) async {
      final List<ValueItem<int>> items = fruitItems();
      final c = MultipleSearchDropDownController<int>(
        items: items,
        selectedItems: <ValueItem<int>>[items[1], items[2]],
        addMode: false,
        deleteMode: false,
      );
      addTearDown(c.dispose);
      await tester.pumpWidget(host(MultipleSearchDropDown<int>(controller: c)));
      expect(_semanticButton('Remover Banana'), findsOneWidget);
      expect(_semanticButton('Remover Uva'), findsOneWidget);

      await tester.tap(_semanticButton('Remover Banana'));
      await tester.pump();

      expect(c.selectedItems.map((e) => e.label), <String>['Uva']);
      expect(find.text('Banana'), findsNothing);
    });

    testWidgets('add and delete spinners carry the loading label', (
      tester,
    ) async {
      final c = MultipleSearchDropDownController<int>(
        items: fruitItems(),
        newValueItem: (s) => ValueItem<int>(label: s, value: 99),
        onAddItem: (_) => Future<void>.delayed(const Duration(seconds: 1)),
        onDeleteItem: (_) => Future<void>.delayed(const Duration(seconds: 1)),
      );
      addTearDown(c.dispose);
      await tester.pumpWidget(host(MultipleSearchDropDown<int>(controller: c)));
      await openMultiple(tester);

      await tester.enterText(find.byType(TextField).last, 'Kiwi');
      await tester.pump();
      await tester.tap(find.text('Criar'));
      await tester.pump();
      expect(
        tester
            .widget<CircularProgressIndicator>(
              find.byType(CircularProgressIndicator),
            )
            .semanticsLabel,
        'Carregando',
      );
      await tester.pump(const Duration(seconds: 1));
      await tester.pumpAndSettle();
      expect(find.byType(CircularProgressIndicator), findsNothing);

      await tester.enterText(find.byType(TextField).last, '');
      await tester.pump();
      await tester.tap(find.byIcon(Icons.delete).first);
      await tester.pump();
      expect(
        tester
            .widget<CircularProgressIndicator>(
              find.byType(CircularProgressIndicator),
            )
            .semanticsLabel,
        'Carregando',
      );
      await tester.pump(const Duration(seconds: 1));
      await tester.pumpAndSettle();
    });

    testWidgets('the spinner label follows custom strings', (tester) async {
      final c = MultipleSearchDropDownController<int>(
        items: fruitItems(),
        addMode: false,
        onDeleteItem: (_) => Future<void>.delayed(const Duration(seconds: 1)),
      );
      addTearDown(c.dispose);
      await tester.pumpWidget(
        host(
          MultipleSearchDropDown<int>(
            controller: c,
            strings: const SearchDropDownStrings(loadingLabel: 'Aguarde'),
          ),
        ),
      );
      await openMultiple(tester);
      await tester.tap(find.byIcon(Icons.delete).first);
      await tester.pump();
      expect(
        tester
            .widget<CircularProgressIndicator>(
              find.byType(CircularProgressIndicator),
            )
            .semanticsLabel,
        'Aguarde',
      );
      await tester.pump(const Duration(seconds: 1));
      await tester.pumpAndSettle();
    });
  });
}
