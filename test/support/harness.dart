import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:simple_search_dropdown/simple_search_dropdown.dart';

/// Hosts [child] the way a real app would (Material 3, centered, scaffold).
Widget host(Widget child, {ThemeData? theme}) => MaterialApp(
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
Finder focusedField() => find.byWidgetPredicate(
      (w) => w is EditableText && w.focusNode.hasFocus,
    );

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
  await tester.tap(box.first);
  await tester.pumpAndSettle();
}
