import 'package:flutter_test/flutter_test.dart';
import 'package:simple_search_dropdown/simple_search_dropdown.dart';

import '../support/harness.dart';

SearchDropDownController<int> _controller() => SearchDropDownController<int>(
      listItems: fruitItems(),
      addMode: false,
      deleteMode: false,
    );

void main() {
  group('strings: defaults stay Portuguese', () {
    testWidgets('hint comes from SearchDropDownStrings', (tester) async {
      await tester
          .pumpWidget(host(SearchDropDown<int>(controller: _controller())));
      expect(find.text('Pesquisar'), findsOneWidget);
    });

    test('dialog buttons resolve to the PT texts', () {
      const settings = DialogSettings();
      const strings = SearchDropDownStrings();
      expect(settings.deleteButton(strings).text, 'Apagar');
      expect(settings.cancelButton(strings).text, 'Cancelar');
      expect(settings.okButton(strings).text, 'OK');
      expect(settings.editButton(strings).text, 'Editar');
    });
  });

  group('strings: per widget, app scope and explicit settings', () {
    testWidgets('widget strings win over the defaults', (tester) async {
      await tester.pumpWidget(host(SearchDropDown<int>(
        controller: _controller(),
        strings: const SearchDropDownStrings.en(),
      )));
      expect(find.text('Search'), findsOneWidget);
    });

    testWidgets('SearchDropDownStringsScope applies below it', (tester) async {
      await tester.pumpWidget(host(SearchDropDownStringsScope(
        strings: const SearchDropDownStrings(searchHint: 'Buscar'),
        child: SearchDropDown<int>(controller: _controller()),
      )));
      expect(find.text('Buscar'), findsOneWidget);
    });

    testWidgets('an explicit settings text wins over strings', (tester) async {
      await tester.pumpWidget(host(SearchDropDown<int>(
        controller: _controller(),
        strings: const SearchDropDownStrings.en(),
        searchBarSettings: const SimpleSearchbarSettings(hint: 'Custom'),
      )));
      expect(find.text('Custom'), findsOneWidget);
    });

    test('custom dialog button settings win over strings', () {
      const settings = DialogSettings(
        customDeleteButtonSettings: DialogButtonSettings('Remover'),
      );
      expect(
        settings.deleteButton(const SearchDropDownStrings.en()).text,
        'Remover',
      );
    });

    testWidgets('dialogs use the given strings', (tester) async {
      await tester.pumpWidget(host(WarningDialog(
        returnFunction: (_) {},
        strings: const SearchDropDownStrings.en(),
      )));
      expect(find.text('Are you sure?'), findsOneWidget);
      expect(find.text('Delete'), findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);
    });
  });
}
