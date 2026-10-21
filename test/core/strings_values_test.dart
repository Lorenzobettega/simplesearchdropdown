// Every SearchDropDownStrings value (Portuguese and English), the override of
// each named parameter, SearchDropDownStrings.of without a scope, and
// SearchDropDownStringsScope rebuilding its dependants only on a change.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:simple_search_dropdown/simple_search_dropdown.dart';

import '../support/harness.dart';

/// Every field, in declaration order.
final Map<String, String Function(SearchDropDownStrings s)> _fields = {
  'searchHint': (s) => s.searchHint,
  'addItem': (s) => s.addItem,
  'editTitle': (s) => s.editTitle,
  'editHint': (s) => s.editHint,
  'confirmDeleteTitle': (s) => s.confirmDeleteTitle,
  'confirmDeleteContent': (s) => s.confirmDeleteContent,
  'confirmDeleteItemTitle': (s) => s.confirmDeleteItemTitle,
  'confirmDeleteItemContent': (s) => s.confirmDeleteItemContent,
  'invalidItemTitle': (s) => s.invalidItemTitle,
  'invalidItemContent': (s) => s.invalidItemContent,
  'deleteButton': (s) => s.deleteButton,
  'cancelButton': (s) => s.cancelButton,
  'okButton': (s) => s.okButton,
  'editButton': (s) => s.editButton,
  'openTooltip': (s) => s.openTooltip,
  'closeTooltip': (s) => s.closeTooltip,
  'clearTooltip': (s) => s.clearTooltip,
  'editItemTooltip': (s) => s.editItemTooltip,
  'deleteItemTooltip': (s) => s.deleteItemTooltip,
  'removeChipTooltip': (s) => s.removeChipTooltip,
  'loadingLabel': (s) => s.loadingLabel,
};

Map<String, String> _values(SearchDropDownStrings s) =>
    _fields.map((name, get) => MapEntry(name, get(s)));

/// Each field set to 'X' through its own named parameter, per constructor.
final Map<String, SearchDropDownStrings> _ptOverrides = {
  'searchHint': const SearchDropDownStrings(searchHint: 'X'),
  'addItem': const SearchDropDownStrings(addItem: 'X'),
  'editTitle': const SearchDropDownStrings(editTitle: 'X'),
  'editHint': const SearchDropDownStrings(editHint: 'X'),
  'confirmDeleteTitle': const SearchDropDownStrings(confirmDeleteTitle: 'X'),
  'confirmDeleteContent': const SearchDropDownStrings(
    confirmDeleteContent: 'X',
  ),
  'confirmDeleteItemTitle': const SearchDropDownStrings(
    confirmDeleteItemTitle: 'X',
  ),
  'confirmDeleteItemContent': const SearchDropDownStrings(
    confirmDeleteItemContent: 'X',
  ),
  'invalidItemTitle': const SearchDropDownStrings(invalidItemTitle: 'X'),
  'invalidItemContent': const SearchDropDownStrings(invalidItemContent: 'X'),
  'deleteButton': const SearchDropDownStrings(deleteButton: 'X'),
  'cancelButton': const SearchDropDownStrings(cancelButton: 'X'),
  'okButton': const SearchDropDownStrings(okButton: 'X'),
  'editButton': const SearchDropDownStrings(editButton: 'X'),
  'openTooltip': const SearchDropDownStrings(openTooltip: 'X'),
  'closeTooltip': const SearchDropDownStrings(closeTooltip: 'X'),
  'clearTooltip': const SearchDropDownStrings(clearTooltip: 'X'),
  'editItemTooltip': const SearchDropDownStrings(editItemTooltip: 'X'),
  'deleteItemTooltip': const SearchDropDownStrings(deleteItemTooltip: 'X'),
  'removeChipTooltip': const SearchDropDownStrings(removeChipTooltip: 'X'),
  'loadingLabel': const SearchDropDownStrings(loadingLabel: 'X'),
};

final Map<String, SearchDropDownStrings> _enOverrides = {
  'searchHint': const SearchDropDownStrings.en(searchHint: 'X'),
  'addItem': const SearchDropDownStrings.en(addItem: 'X'),
  'editTitle': const SearchDropDownStrings.en(editTitle: 'X'),
  'editHint': const SearchDropDownStrings.en(editHint: 'X'),
  'confirmDeleteTitle': const SearchDropDownStrings.en(confirmDeleteTitle: 'X'),
  'confirmDeleteContent': const SearchDropDownStrings.en(
    confirmDeleteContent: 'X',
  ),
  'confirmDeleteItemTitle': const SearchDropDownStrings.en(
    confirmDeleteItemTitle: 'X',
  ),
  'confirmDeleteItemContent': const SearchDropDownStrings.en(
    confirmDeleteItemContent: 'X',
  ),
  'invalidItemTitle': const SearchDropDownStrings.en(invalidItemTitle: 'X'),
  'invalidItemContent': const SearchDropDownStrings.en(invalidItemContent: 'X'),
  'deleteButton': const SearchDropDownStrings.en(deleteButton: 'X'),
  'cancelButton': const SearchDropDownStrings.en(cancelButton: 'X'),
  'okButton': const SearchDropDownStrings.en(okButton: 'X'),
  'editButton': const SearchDropDownStrings.en(editButton: 'X'),
  'openTooltip': const SearchDropDownStrings.en(openTooltip: 'X'),
  'closeTooltip': const SearchDropDownStrings.en(closeTooltip: 'X'),
  'clearTooltip': const SearchDropDownStrings.en(clearTooltip: 'X'),
  'editItemTooltip': const SearchDropDownStrings.en(editItemTooltip: 'X'),
  'deleteItemTooltip': const SearchDropDownStrings.en(deleteItemTooltip: 'X'),
  'removeChipTooltip': const SearchDropDownStrings.en(removeChipTooltip: 'X'),
  'loadingLabel': const SearchDropDownStrings.en(loadingLabel: 'X'),
};

/// Counts its builds and shows the scoped search hint.
class _Probe extends StatelessWidget {
  const _Probe(this.builds);

  final List<int> builds;

  @override
  Widget build(BuildContext context) {
    builds.add(1);
    return Text(SearchDropDownStrings.of(context).searchHint);
  }
}

Widget _scope(SearchDropDownStrings strings, Widget child) => MaterialApp(
  home: SearchDropDownStringsScope(strings: strings, child: child),
);

void main() {
  group('SearchDropDownStrings values', () {
    test('the default constructor is the 7.x Portuguese', () {
      expect(_values(const SearchDropDownStrings()), {
        'searchHint': 'Pesquisar',
        'addItem': 'Criar',
        'editTitle': 'Editar item',
        'editHint': 'Novo valor',
        'confirmDeleteTitle': 'Tem certeza?',
        'confirmDeleteContent': 'Essa ação não poderá ser desfeita.',
        'confirmDeleteItemTitle': 'Apagar item?',
        'confirmDeleteItemContent': '“{item}” será apagado.',
        'invalidItemTitle': 'Erro!',
        'invalidItemContent': 'O valor adicionado não é válido.',
        'deleteButton': 'Apagar',
        'cancelButton': 'Cancelar',
        'okButton': 'OK',
        'editButton': 'Editar',
        'openTooltip': 'Abrir lista',
        'closeTooltip': 'Fechar lista',
        'clearTooltip': 'Limpar seleção',
        'editItemTooltip': 'Editar item',
        'deleteItemTooltip': 'Apagar item',
        'removeChipTooltip': 'Remover',
        'loadingLabel': 'Carregando',
      });
    });

    test('.en() is English', () {
      expect(_values(const SearchDropDownStrings.en()), {
        'searchHint': 'Search',
        'addItem': 'Create',
        'editTitle': 'Edit item',
        'editHint': 'New value',
        'confirmDeleteTitle': 'Are you sure?',
        'confirmDeleteContent': 'This action cannot be undone.',
        'confirmDeleteItemTitle': 'Delete item?',
        'confirmDeleteItemContent': '“{item}” will be deleted.',
        'invalidItemTitle': 'Error!',
        'invalidItemContent': 'The value is not valid.',
        'deleteButton': 'Delete',
        'cancelButton': 'Cancel',
        'okButton': 'OK',
        'editButton': 'Edit',
        'openTooltip': 'Open list',
        'closeTooltip': 'Close list',
        'clearTooltip': 'Clear selection',
        'editItemTooltip': 'Edit item',
        'deleteItemTooltip': 'Delete item',
        'removeChipTooltip': 'Remove',
        'loadingLabel': 'Loading',
      });
    });

    for (final (
          String ctor,
          SearchDropDownStrings base,
          Map<String, SearchDropDownStrings> overrides,
        )
        in [
          (
            'SearchDropDownStrings()',
            const SearchDropDownStrings(),
            _ptOverrides,
          ),
          (
            'SearchDropDownStrings.en()',
            const SearchDropDownStrings.en(),
            _enOverrides,
          ),
        ]) {
      test('$ctor: each named parameter overrides only its field', () {
        expect(overrides.keys, _fields.keys);
        for (final MapEntry<String, SearchDropDownStrings> o
            in overrides.entries) {
          expect(_values(o.value), {
            ..._values(base),
            o.key: 'X',
          }, reason: o.key);
        }
      });
    }
  });

  group('SearchDropDownStrings.of', () {
    testWidgets('without a scope returns the Portuguese defaults', (
      tester,
    ) async {
      late SearchDropDownStrings found;
      await tester.pumpWidget(
        host(
          Builder(
            builder: (context) {
              found = SearchDropDownStrings.of(context);
              return const SizedBox();
            },
          ),
        ),
      );
      expect(_values(found), _values(const SearchDropDownStrings()));
    });

    testWidgets('under a scope returns its strings', (tester) async {
      const SearchDropDownStrings en = SearchDropDownStrings.en();
      late SearchDropDownStrings found;
      await tester.pumpWidget(
        _scope(
          en,
          Builder(
            builder: (context) {
              found = SearchDropDownStrings.of(context);
              return const SizedBox();
            },
          ),
        ),
      );
      expect(found, same(en));
    });
  });

  group('SearchDropDownStringsScope', () {
    test(
      'updateShouldNotify is true for other strings, false for the same',
      () {
        const SearchDropDownStringsScope pt = SearchDropDownStringsScope(
          strings: SearchDropDownStrings(),
          child: SizedBox(),
        );
        const SearchDropDownStringsScope en = SearchDropDownStringsScope(
          strings: SearchDropDownStrings.en(),
          child: SizedBox(),
        );
        const SearchDropDownStringsScope pt2 = SearchDropDownStringsScope(
          strings: SearchDropDownStrings(),
          child: SizedBox(),
        );
        expect(en.updateShouldNotify(pt), isTrue);
        expect(pt2.updateShouldNotify(pt), isFalse);
      },
    );

    testWidgets('swapping the strings rebuilds a dependant', (tester) async {
      final List<int> builds = [];
      final _Probe probe = _Probe(builds);
      await tester.pumpWidget(_scope(const SearchDropDownStrings(), probe));
      expect(find.text('Pesquisar'), findsOneWidget);
      expect(builds, hasLength(1));

      await tester.pumpWidget(_scope(const SearchDropDownStrings(), probe));
      expect(builds, hasLength(1), reason: 'same strings: no rebuild');

      await tester.pumpWidget(_scope(const SearchDropDownStrings.en(), probe));
      expect(find.text('Search'), findsOneWidget);
      expect(builds, hasLength(2));
    });

    testWidgets('swapping the strings updates a mounted dropdown', (
      tester,
    ) async {
      final SearchDropDownController<int> c = SearchDropDownController<int>(
        items: fruitItems(),
        addMode: false,
        deleteMode: false,
      );
      addTearDown(c.dispose);
      final Widget dropdown = Scaffold(
        body: Center(child: SearchDropDown<int>(controller: c)),
      );
      await tester.pumpWidget(_scope(const SearchDropDownStrings(), dropdown));
      expect(find.text('Pesquisar'), findsOneWidget);

      await tester.pumpWidget(
        _scope(const SearchDropDownStrings.en(), dropdown),
      );
      expect(find.text('Search'), findsOneWidget);
      expect(find.text('Pesquisar'), findsNothing);
    });
  });
}
