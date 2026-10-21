// The single dropdown must not flash a selection highlight over its text
// when the view opens, closes or picks an item (reported on iOS: the label
// "blinked" each time).

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:simple_search_dropdown/simple_search_dropdown.dart';

import '../support/harness.dart';

void main() {
  for (final TargetPlatform platform in <TargetPlatform>[
    TargetPlatform.iOS,
    TargetPlatform.android,
  ]) {
    testWidgets('open, close and select never select the text '
        '(${platform.name})', (tester) async {
      final List<ValueItem<int>> items = fruitItems();
      final c = SearchDropDownController<int>(
        items: items,
        addMode: false,
        deleteMode: false,
        initialSelectedItem: items[1],
      );
      await tester.pumpWidget(
        host(
          SearchDropDown<int>(controller: c),
          theme: ThemeData(platform: platform),
        ),
      );
      final List<TextSelection> highlighted = <TextSelection>[];
      void record() {
        final TextSelection s = c.localSearchController.selection;
        if (s.isValid && !s.isCollapsed) {
          highlighted.add(s);
        }
      }

      c.localSearchController.addListener(record);
      addTearDown(() => c.localSearchController.removeListener(record));

      await openSingle(tester);
      expect(c.localSearchController.isOpen, isTrue);
      await tester.tap(find.byIcon(Icons.arrow_drop_up));
      await tester.pumpAndSettle();
      expect(c.localSearchController.isOpen, isFalse);

      await openSingle(tester);
      await tester.tap(find.widgetWithText(DefaultListTile<int>, 'Uva'));
      await tester.pumpAndSettle();

      expect(c.selectedItem?.label, 'Uva');
      expect(c.localSearchController.text, 'Uva');
      expect(highlighted, isEmpty);
    });
  }
}
