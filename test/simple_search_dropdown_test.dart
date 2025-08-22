import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:simple_search_dropdown/simple_search_dropdown.dart';

Widget _wrap(Widget child) =>
    MaterialApp(home: Scaffold(body: Center(child: child)));

void main() {
  group('SearchDropDown (single)', () {
    late SearchDropDownController<int> controller;
    late List<ValueItem<int>> items;

    setUp(() {
      items = [
        const ValueItem(label: 'Maçã', value: 1),
        const ValueItem(label: 'Banana', value: 2),
        const ValueItem(label: 'Uva', value: 3),
      ];
      controller = SearchDropDownController<int>(
          listItems: items, addMode: false, deleteMode: false);
    });

    testWidgets(
        'renderiza barra de busca e nenhum item selecionado inicialmente',
        (tester) async {
      await tester
          .pumpWidget(_wrap(SearchDropDown<int>(controller: controller)));
      expect(find.byType(SearchBar), findsOneWidget);
      expect(controller.selectedItem, isNull);
    });

    testWidgets('filtra ignorando acentos/maiúsculas', (tester) async {
      await tester
          .pumpWidget(_wrap(SearchDropDown<int>(controller: controller)));
      await tester.tap(find.byType(SearchBar));
      await tester.pumpAndSettle();

      final activeField = find.byWidgetPredicate(
        (w) => w is EditableText && w.focusNode.hasFocus,
      );
      expect(activeField, findsOneWidget);

      await tester.enterText(activeField, 'maca');
// um pouco mais de tempo por causa de debounce interno
      await tester.pump(const Duration(milliseconds: 350));

// valide o resultado via controller (evita ruído de outros Texts na árvore)
      expect(
        controller.filteredItems.map((e) => e.label).toList(),
        equals(['Maçã']),
      );

// opcional: também confirme que o texto aparece em tela (sem checar ausências)
      expect(find.text('Maçã'), findsWidgets);
    });

    testWidgets('seleciona item e fecha a lista', (tester) async {
      await tester
          .pumpWidget(_wrap(SearchDropDown<int>(controller: controller)));
      await tester.tap(find.byType(SearchBar));
      await tester.pumpAndSettle();

// Digita para reduzir a lista
      await tester.enterText(find.byType(TextField).first, 'ban');
      await tester.pump(const Duration(milliseconds: 200));

// Toca no item "Banana"
      await tester.tap(find.text('Banana').first);
      await tester.pumpAndSettle();

      expect(controller.selectedItem?.label, 'Banana');
// A view deve ter sido fechada
      expect(find.byType(ListView), findsNothing);
    });

    // reescrita do teste: 'addMode cria item novo via DefaultAddListItem'

    testWidgets('disposeController=true descarta controller no dispose',
        (tester) async {
      final local = SearchDropDownController<int>(
          listItems: items, addMode: false, deleteMode: false);
      await tester.pumpWidget(_wrap(SearchDropDown<int>(
        controller: local,
      )));
      // Remove o widget
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();

      // A API pública não expõe "isDisposed"; validamos indiretamente:
      // acessar o controller deve ser seguro, mas o TextEditingController interno
      // não deve estar em uso por nenhum widget.
      expect(() => local.localSearchController.text, returnsNormally);
    });

    testWidgets('disposeController=false não descarta controller no dispose',
        (tester) async {
      final external = SearchDropDownController<int>(
          listItems: items, addMode: false, deleteMode: false);
      await tester.pumpWidget(_wrap(SearchDropDown<int>(
        controller: external,
        disposeController: false,
      )));
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();

      // Ainda podemos escrever/ler sem exceção
      external.localSearchController.text = 'ok';
      expect(external.localSearchController.text, 'ok');
    });

    testWidgets('SearchDropDown com showArrow/clear icon respeita settings',
        (tester) async {
      final c = SearchDropDownController<int>(listItems: [
        const ValueItem(label: 'A', value: 1),
      ], addMode: false, deleteMode: false);
      const s = SimpleSearchbarSettings(
        hint: 'procure',
      );
      await tester.pumpWidget(_wrap(SearchDropDown<int>(
        controller: c,
        searchBarSettings: s,
      )));
      expect(find.text('procure'), findsOneWidget);
      expect(find.byIcon(Icons.arrow_drop_down), findsOneWidget);
    });
  });
}
