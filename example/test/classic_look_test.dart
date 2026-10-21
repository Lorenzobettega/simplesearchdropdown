// The README's "8.0.0 look" settings (lib/readme_samples.dart) really draw
// the 8.0.0 light colours: a selected row, a keyboard-highlighted row, a plain
// row, the icons and the bar.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:simple_search_dropdown/simple_search_dropdown.dart';
import 'package:simple_search_dropdown_example/readme_samples.dart';

Finder _row(String label) => find.byWidgetPredicate(
      (w) => w is DefaultListTile<int> && w.item.label == label,
    );

ButtonStyle _style(WidgetTester tester, String label) => tester
    .widget<TextButton>(
        find.descendant(of: _row(label), matching: find.byType(TextButton)))
    .style!;

Color? _fill(WidgetTester tester, String label) =>
    _style(tester, label).backgroundColor!.resolve(<WidgetState>{});

Color? _text(WidgetTester tester, String label) => tester
    .widget<Text>(find.descendant(of: _row(label), matching: find.text(label)))
    .style
    ?.color;

void main() {
  testWidgets('classicBar and classicList draw the 8.0.0 light colours',
      (tester) async {
    const List<ValueItem<int>> items = <ValueItem<int>>[
      ValueItem<int>(label: 'A', value: 0),
      ValueItem<int>(label: 'B', value: 1),
      ValueItem<int>(label: 'C', value: 2),
    ];
    final SearchDropDownController<int> controller =
        SearchDropDownController<int>(
      items: items,
      addMode: false,
      editMode: true,
      onDeleteItem: (_) {},
      onEditItem: (_, __) {},
      newValueItem: (input) => ValueItem<int>(label: input, value: 9),
      initialSelectedItem: items[0],
    );
    addTearDown(controller.dispose);
    await tester.pumpWidget(MaterialApp(
      theme: ThemeData(useMaterial3: true),
      home: Scaffold(
        body: Center(
          child: SearchDropDown<int>(
            controller: controller,
            searchBarSettings: classicBar,
            overlayListSettings: classicList,
          ),
        ),
      ),
    ));
    final SearchBar bar = tester.widget(find.byType(SearchBar));
    expect(bar.backgroundColor!.resolve(<WidgetState>{}), Colors.white);
    expect(
      bar.overlayColor!.resolve(<WidgetState>{}),
      const Color.fromRGBO(245, 245, 245, 1),
    );

    await tester.tap(find.byType(SearchBar));
    await tester.pumpAndSettle();
    // Two arrows: A (selected) then B (highlighted).
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.pumpAndSettle();
    expect(controller.highlightedIndex, 1);

    expect(_fill(tester, 'A'), Colors.black38);
    expect(_text(tester, 'A'), Colors.black);
    expect(_fill(tester, 'B'), const Color.fromRGBO(245, 245, 245, 1));
    expect(_text(tester, 'B'), Colors.black);
    final RoundedRectangleBorder shape = _style(tester, 'B')
        .shape!
        .resolve(<WidgetState>{})! as RoundedRectangleBorder;
    expect(shape.side.color, Colors.black26);
    expect(_fill(tester, 'C'), Colors.transparent);
    expect(_text(tester, 'C'), Colors.black45);
    expect(
      tester
          .widget<Icon>(
              find.descendant(of: _row('C'), matching: find.byIcon(Icons.edit)))
          .color,
      Colors.black,
    );
    expect(
      tester
          .widget<Icon>(find.descendant(
              of: _row('C'), matching: find.byIcon(Icons.delete)))
          .color,
      const Color.fromRGBO(183, 28, 28, 1),
    );
  });
}
