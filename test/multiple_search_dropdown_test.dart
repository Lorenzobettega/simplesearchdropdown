import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:simple_search_dropdown/simple_search_dropdown.dart';

Widget _wrap(Widget child) => MaterialApp(home: Scaffold(body: child));

void main() {
  testWidgets('MultipleSearchDropDown respeita sortType', (tester) async {
    final items = <ValueItem<int>>[
      const ValueItem(label: 'c', value: 1),
      const ValueItem(label: 'a', value: 2),
      const ValueItem(label: 'b', value: 3),
    ];
    final key = UniqueKey();
    var selected = <ValueItem<int>>[];

    await tester.pumpWidget(_wrap(MultipleSearchDropDown<int>(
      key: key,
      listItems: items,
      selectedItems: selected,
      sortType: 1,
      updateSelectedItems: (v) => selected = List<ValueItem<int>>.from(v),
      addMode: false,
      deleteMode: false,
    )));
    await tester.pumpAndSettle();

    final tappable = find
        .descendant(
          of: find.byKey(key),
          matching: find.byWidgetPredicate(
            (w) =>
                (w is InkWell && w.onTap != null) ||
                (w is GestureDetector && w.onTap != null),
          ),
        )
        .first;

    await tester.ensureVisible(tappable);
    await tester.tap(tappable);
    await tester.pumpAndSettle();

    final opened = find.byType(TextField).evaluate().isNotEmpty ||
        find.byType(Scrollable).evaluate().isNotEmpty;
    expect(opened, isTrue);

    expect(find.text('a'), findsWidgets);
    expect(find.text('b'), findsWidgets);
    expect(find.text('c'), findsWidgets);

    final aY = tester.getTopLeft(find.text('a').first).dy;
    final bY = tester.getTopLeft(find.text('b').first).dy;
    final cY = tester.getTopLeft(find.text('c').first).dy;
    expect(aY <= bY && bY <= cY, isTrue);

    await tester.tap(find.text('a').first);
    await tester.pump();
    expect(selected.any((e) => e.label == 'a'), isTrue);
  });
}
