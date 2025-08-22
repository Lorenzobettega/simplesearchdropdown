// test/search_dropdown_controller_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:simple_search_dropdown/simple_search_dropdown.dart';

void main() {
  group('SearchDropDownController – construção e flags', () {
    test('constrói com addMode=false sem exigir callbacks', () {
      final c = SearchDropDownController<int>(
        listItems: const [],
        addMode: false,
        deleteMode: false,
      );
      expect(c.listItems, isEmpty);
      expect(c.filteredItems, isEmpty);
    });

    test('asserta quando addMode=true sem newValueItem/onAddItem', () {
      expect(
        () => SearchDropDownController<int>(
          listItems: const [],
          deleteMode: false,
        ),
        throwsA(isA<AssertionError>()),
      );
    });

    test('ordenação respeita sortType (0=none,1=asc,2=desc)', () {
      final base = <ValueItem<int>>[
        const ValueItem(label: 'c', value: 1),
        const ValueItem(label: 'a', value: 2),
        const ValueItem(label: 'b', value: 3),
      ];

      final cAsc = SearchDropDownController<int>(
        listItems: List<ValueItem<int>>.of(base),
        addMode: false,
        deleteMode: false,
        sortType: 1,
      );
      expect(cAsc.filteredItems.map((e) => e.label).toList(), ['a', 'b', 'c']);

      final cDesc = SearchDropDownController<int>(
        listItems: List<ValueItem<int>>.of(base),
        addMode: false,
        deleteMode: false,
        sortType: 2,
      );
      expect(cDesc.filteredItems.map((e) => e.label).toList(), ['c', 'b', 'a']);

      final cNone = SearchDropDownController<int>(
        listItems: List<ValueItem<int>>.of(base),
        addMode: false,
        deleteMode: false,
      );
      expect(cNone.filteredItems.map((e) => e.label).toList(), ['c', 'a', 'b']);
    });
  });

  group('SearchDropDownController – filtro/pesquisa', () {
    late SearchDropDownController<int> c;
    setUp(() {
      c = SearchDropDownController<int>(
        listItems: const [
          ValueItem(label: 'Maçã', value: 1),
          ValueItem(label: 'Banana', value: 2),
          ValueItem(label: 'Uva', value: 3),
        ],
        addMode: false,
        deleteMode: false,
      );
    });

    test('filterList ignora acentos/maiúsculas', () {
      c.filterList('maca');
      expect(c.filteredItems.map((e) => e.label).toList(), ['Maçã']);

      c.filterList('BAN');
      expect(c.filteredItems.map((e) => e.label).toList(), ['Banana']);

      c.filterList('');
      expect(c.filteredItems.length, 3);
    });

    test('filterList com texto vindo do controller local', () {
      c.localSearchController.text = 'uVa';
      c.filterList(c.localSearchController.text);
      expect(c.filteredItems.map((e) => e.label).toList(), ['Uva']);
    });
  });

  group('SearchDropDownController – abertura/fechamento da busca', () {
    test('onSearchOpen/onSearchClose ajustam estado sem exceção', () {
      final c = SearchDropDownController<int>(
        listItems: const [ValueItem(label: 'A', value: 1)],
        addMode: false,
        deleteMode: false,
      );

      expect(() => c.onSearchOpen(), returnsNormally);
      expect(() => c.onSearchClose(true), returnsNormally);
    });
  });

  group('SearchDropDownController – dispose', () {
    test('dispose deve ser chamado uma única vez; segunda chamada lança erro',
        () {
      final c = SearchDropDownController<int>(
        listItems: const [],
        addMode: false,
        deleteMode: false,
      );

      expect(() => c.dispose(), returnsNormally);
      expect(() => c.dispose(),
          throwsA(isA<FlutterError>())); // segunda chamada deve falhar
    });
// ajuste no teste de lifecycle para validar o contrato correto pós-dispose
    testWidgets('SearchDropDown respeita disposeController=true/false',
        (tester) async {
      final cTrue = SearchDropDownController<String>(
          listItems: const [], addMode: false, deleteMode: false);
      final cFalse = SearchDropDownController<String>(
          listItems: const [], addMode: false, deleteMode: false);

      await tester.pumpWidget(MaterialApp(
        home: Column(children: [
          SearchDropDown<String>(
              controller: cTrue), // disposeController default = true
          SearchDropDown<String>(controller: cFalse, disposeController: false),
        ]),
      ));
      await tester.pump();

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();

      // cFalse segue utilizável
      cFalse.localSearchController.text = 'ok';
      expect(cFalse.localSearchController.text, 'ok');

      // cTrue foi descartado pelo widget; acessar deve lançar erro
      expect(
        () => cTrue.localSearchController.addListener(() {}),
        throwsA(isA<FlutterError>()),
      );
    });
  });

  group('Search normalization (unit-like through controller)', () {
    test('filtra ignorando acentos, caixa e espaços', () {
      final items = [
        const ValueItem(label: 'São Paulo', value: 1),
        const ValueItem(label: 'Sao Tome', value: 2),
        const ValueItem(label: 'Porto Alegre', value: 3),
      ];
      final c = SearchDropDownController<int>(
          listItems: items, addMode: false, deleteMode: false)

        // Filtro "sao" deve encontrar 'São Paulo' e 'Sao Tome'
        ..filterList('sao');
      expect(
        c.filteredItems.map((e) => e.label),
        containsAll(['São Paulo', 'Sao Tome']),
      );

      // Filtro "PORTO" deve pegar 'Porto Alegre'
      c.filterList('PORTO');
      expect(c.filteredItems.single.label, 'Porto Alegre');

      // Vazio retorna todos
      c.filterList('');
      expect(c.filteredItems.length, 3);
    });
  });
}
