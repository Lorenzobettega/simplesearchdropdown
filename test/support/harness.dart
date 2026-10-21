import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:simple_search_dropdown/simple_search_dropdown.dart';

/// Hosts [child] the way a real app would (Material 3, centered, scaffold).
Widget host(Widget child, {ThemeData? theme}) => MaterialApp(
  debugShowCheckedModeBanner: false,
  theme: theme ?? ThemeData(useMaterial3: true),
  home: Scaffold(body: Center(child: child)),
);

/// `n` items labelled `Item 0`..`Item n-1` with matching int values.
List<ValueItem<int>> numberedItems(int n) => List<ValueItem<int>>.generate(
  n,
  (i) => ValueItem<int>(label: 'Item $i', value: i),
);

/// Fruit fixture with accents and mixed case, for normalization tests.
List<ValueItem<int>> fruitItems() => <ValueItem<int>>[
  const ValueItem(label: 'Maçã', value: 1),
  const ValueItem(label: 'Banana', value: 2),
  const ValueItem(label: 'Uva', value: 3),
  const ValueItem(label: 'abacaxi', value: 4),
  const ValueItem(label: 'Pêra', value: 5),
];

/// The text field that currently has focus (the open search view header).
Finder focusedField() =>
    find.byWidgetPredicate((w) => w is EditableText && w.focusNode.hasFocus);

/// Opens a [SearchDropDown] by tapping its bar.
Future<void> openSingle(WidgetTester tester) async {
  await tester.tap(find.byType(SearchBar).first);
  await tester.pumpAndSettle();
}

/// Types [text] into the open single search view.
Future<void> typeInSingle(WidgetTester tester, String text) async {
  await tester.enterText(focusedField(), text);
  await tester.pump();
}

/// Opens a [MultipleSearchDropDown] by tapping its box.
Future<void> openMultiple(WidgetTester tester, {Finder? of}) async {
  final Finder box = find.descendant(
    of: of ?? find.byWidgetPredicate((w) => w is MultipleSearchDropDown),
    matching: find.byType(InkWell),
  );
  // Taps inside the left padding: the centre may hold a chip's remove icon.
  await tester.tapAt(tester.getRect(box.first).centerLeft + const Offset(5, 0));
  await tester.pumpAndSettle();
}

/// The `DefaultListTile<T>` row labelled [label] (any `T` when omitted).
Finder rowTile<T>(String label) => find.byWidgetPredicate(
  (Widget w) => w is DefaultListTile<T> && w.item.label == label,
);

/// [matching] inside the `DefaultListTile<T>` row labelled [label].
Finder inRow<T>(String label, Finder matching) =>
    find.descendant(of: rowTile<T>(label), matching: matching);

/// Row tiles of the open list in tree (build) order.
List<DefaultListTile<T>> treeRows<T>(WidgetTester tester) => tester
    .widgetList<DefaultListTile<T>>(find.byType(DefaultListTile<T>))
    .toList();

/// Labels of the open list's rows in tree (build) order.
List<String> rowLabels<T>(WidgetTester tester) =>
    treeRows<T>(tester).map((t) => t.item.label).toList();

/// Rows of the open list in visual (top to bottom) order.
List<DefaultListTile<T>> visualRows<T>(WidgetTester tester) {
  final List<DefaultListTile<T>> rows = treeRows<T>(tester);
  double top(DefaultListTile<T> row) =>
      tester.getTopLeft(find.byWidget(row)).dy;
  return rows..sort((a, b) => top(a).compareTo(top(b)));
}

/// Labels of the open list's rows in visual (top to bottom) order.
List<String> visualRowLabels<T>(WidgetTester tester) =>
    visualRows<T>(tester).map((r) => r.item.label).toList();

/// Labels of [items], in iteration order.
List<String> labelsOf<T>(Iterable<ValueItem<T>> items) =>
    items.map((e) => e.label).toList();

/// Sends [key] and settles.
Future<void> pressKey(WidgetTester tester, LogicalKeyboardKey key) async {
  await tester.sendKeyEvent(key);
  await tester.pumpAndSettle();
}

/// Taps the text button of the single-dropdown row labelled [label].
Future<void> tapSingleRow<T>(WidgetTester tester, String label) async {
  await tester.tap(inRow<T>(label, find.byType(TextButton)));
  await tester.pumpAndSettle();
}

/// The glyph [TextStyle] of the [Icon] showing [icon].
TextStyle iconGlyph(WidgetTester tester, IconData icon) => tester
    .widget<RichText>(
      find.descendant(of: find.byIcon(icon), matching: find.byType(RichText)),
    )
    .text
    .style!;
