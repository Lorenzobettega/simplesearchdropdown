// Settings and controller API of the MultipleSearchDropDown that the other
// suites leave unchecked. Each test reads the value the rendered widget
// actually uses (decoration, Material, text style, geometry, ink overlay),
// so a setting that stops reaching the screen fails here.

import 'dart:async';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:simple_search_dropdown/simple_search_dropdown.dart';
import 'package:simple_search_dropdown/src/multiple/multiple_listview.dart';

import '../support/harness.dart';

const SimpleOverlaySettings _tall = SimpleOverlaySettings(dialogHeight: 400);

// 'Cherry', 'apple', 'Banana'.
List<ValueItem<int>> _items() => <ValueItem<int>>[
  const ValueItem(label: 'Cherry', value: 3),
  const ValueItem(label: 'apple', value: 1),
  const ValueItem(label: 'Banana', value: 2),
];

/// A controller with every mode off unless asked; disposed at the end.
MultipleSearchDropDownController<int> _mc({
  List<ValueItem<int>>? items,
  List<ValueItem<int>>? selected,
  void Function(List<ValueItem<int>>)? onSelection,
  Function(ValueItem<int>)? onClearItem,
  Function()? onClearList,
  bool addMode = false,
  bool Function(ValueItem<int>)? verifyInputItem,
  DialogSettings? verifyDialogSettings,
  Function(ValueItem<int>)? onDeleteItem,
  bool confirmDelete = false,
  bool editMode = false,
  DialogSettings? editDialogSettings,
}) {
  final MultipleSearchDropDownController<int> c =
      MultipleSearchDropDownController<int>(
        items: items ?? _items(),
        selectedItems: selected,
        updateSelectedItems: onSelection,
        onClearItem: onClearItem,
        onClearList: onClearList,
        addMode: addMode,
        newValueItem: (s) => ValueItem<int>(label: s, value: 99),
        onAddItem: addMode ? (_) {} : null,
        verifyInputItem: verifyInputItem,
        verifyDialogSettings: verifyDialogSettings,
        deleteMode: onDeleteItem != null,
        onDeleteItem: onDeleteItem,
        confirmDelete: confirmDelete,
        editMode: editMode,
        onEditItem: editMode ? (_, _) {} : null,
        editDialogSettings: editDialogSettings,
      );
  addTearDown(c.dispose);
  return c;
}

/// The dropdown at (20, 20) on the top-left of the screen.
Future<void> _pump(
  WidgetTester tester,
  MultipleSearchDropDownController<int> c, {
  SimpleSearchbarSettings bar = defaultSearchBarSettings,
  SimpleOverlaySettings overlay = _tall,
  Widget? defaultAdditionalWidget,
}) => tester.pumpWidget(
  MaterialApp(
    home: Scaffold(
      body: Align(
        alignment: Alignment.topLeft,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: MultipleSearchDropDown<int>(
            controller: c,
            searchBarSettings: bar,
            overlayListSettings: overlay,
            defaultAdditionalWidget: defaultAdditionalWidget,
          ),
        ),
      ),
    ),
  ),
);

// ------------------------------------------------------------------ finders

Finder get _dropdown => find.byType(MultipleSearchDropDown<int>);
Finder get _list => find.byType(MultipleListView<int>);
Finder _inList(Finder f) => find.descendant(of: _list, matching: f);
Finder get _listBar => _inList(find.byType(SearchBar));
Finder get _listField => _inList(find.byType(EditableText));
Finder _row(String label) => find.byWidgetPredicate(
  (w) => w is DefaultListTile<int> && w.item.label == label,
);

Future<void> _type(WidgetTester tester, String text) async {
  await tester.enterText(_listField, text);
  await tester.pump();
}

/// Lets a dialog opened from a row come up (the row spinner keeps
/// animating while it is open, so it never settles).
Future<void> _openDialog(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 500));
}

/// Taps the empty screen below the list: the barrier closes it.
Future<void> _tapOutside(WidgetTester tester) async {
  await tester.tapAt(const Offset(780, 580));
  await tester.pumpAndSettle();
}

/// The decoration painting the closed box.
BoxDecoration _boxDecoration(WidgetTester tester) =>
    tester
            .widgetList<Container>(
              find.descendant(
                of: _dropdown,
                matching: find.byWidgetPredicate(
                  (w) => w is Container && w.decoration is BoxDecoration,
                ),
              ),
            )
            .first
            .decoration!
        as BoxDecoration;

/// The Card around the open list.
Card _listCard(WidgetTester tester) =>
    tester.widgetList<Card>(_inList(find.byType(Card))).first;

/// The style [text] is painted with under [scope].
TextStyle _textStyle(WidgetTester tester, Finder scope, String text) {
  final RichText rich = tester.widget<RichText>(
    find.descendant(
      of: find.descendant(of: scope, matching: find.text(text)),
      matching: find.byType(RichText),
      matchRoot: true,
    ),
  );
  return rich.text.style!;
}

/// The overlay colour the row's ink paints with in [states].
Color? _rowOverlay(WidgetTester tester, String label, Set<WidgetState> states) {
  final InkWell ink = tester.widget<InkWell>(
    find.descendant(of: _row(label), matching: find.byType(InkWell)).first,
  );
  return ink.overlayColor!.resolve(states);
}

void main() {
  group('multiple dialogs', () {
    testWidgets('verifyDialogSettings replaces the rejected-item warning', (
      tester,
    ) async {
      final c = _mc(
        addMode: true,
        verifyInputItem: (_) => false,
        verifyDialogSettings: const DialogSettings(title: Text('Bad!')),
      );
      await _pump(tester, c);
      await openMultiple(tester);
      await _type(tester, 'Zed');
      await tester.tap(_inList(find.text('Criar')));
      await tester.pumpAndSettle();

      expect(find.byType(WarningDialog), findsOneWidget);
      expect(find.text('Bad!'), findsOneWidget);
      expect(find.text('Erro!'), findsNothing);
    });

    testWidgets('editDialogSettings sets the edit title and field hint', (
      tester,
    ) async {
      final c = _mc(
        editMode: true,
        editDialogSettings: const DialogSettings(
          title: Text('Rename'),
          editHint: 'New label',
        ),
      );
      await _pump(tester, c);
      await openMultiple(tester);
      await tester.tap(
        find.descendant(of: _row('apple'), matching: find.byIcon(Icons.edit)),
      );
      await _openDialog(tester);

      final Finder dialog = find.byType(EditDialog);
      expect(dialog, findsOneWidget);
      expect(
        find.descendant(of: dialog, matching: find.text('Rename')),
        findsOneWidget,
      );
      final TextField field = tester.widget<TextField>(
        find.descendant(of: dialog, matching: find.byType(TextField)),
      );
      expect(field.decoration!.hintText, 'New label');
    });
  });

  group('multiple delete and reopen', () {
    testWidgets(
      '(8.0) deleting a selected item reports the remaining selection once',
      (tester) async {
        final List<List<ValueItem<int>>> updates = <List<ValueItem<int>>>[];
        final List<ValueItem<int>> cleared = <ValueItem<int>>[];
        final List<ValueItem<int>> items = _items();
        final c = _mc(
          items: items,
          selected: <ValueItem<int>>[items[0], items[1]],
          onSelection: updates.add,
          onClearItem: cleared.add,
          onDeleteItem: (_) {},
        );
        await _pump(tester, c);
        await openMultiple(tester);

        await tester.tap(
          find.descendant(
            of: _row('Banana'),
            matching: find.byIcon(Icons.delete),
          ),
        );
        await tester.pumpAndSettle();
        expect(updates, isEmpty, reason: 'Banana was not selected');

        await tester.tap(
          find.descendant(
            of: _row('Cherry'),
            matching: find.byIcon(Icons.delete),
          ),
        );
        await tester.pumpAndSettle();

        expect(updates, <List<ValueItem<int>>>[
          <ValueItem<int>>[items[1]],
        ]);
        expect(cleared, isEmpty, reason: 'a delete is not a deselection');
        expect(c.selectedItems, <ValueItem<int>>[items[1]]);
      },
    );

    testWidgets('reopening clears the search: empty field, every row', (
      tester,
    ) async {
      final c = _mc();
      await _pump(tester, c);
      await openMultiple(tester);
      await _type(tester, 'ch');
      expect(find.byType(DefaultListTile<int>), findsOneWidget);

      await _tapOutside(tester);
      expect(_list, findsNothing);
      await openMultiple(tester);

      expect(tester.widget<EditableText>(_listField).controller.text, '');
      expect(find.byType(DefaultListTile<int>), findsNWidgets(3));
      expect(c.query, '');
    });

    testWidgets('reOpenedScrollDuration is how long the scroll to the '
        'selection takes', (tester) async {
      final List<ValueItem<int>> items = numberedItems(50);
      final c = _mc(items: items, selected: <ValueItem<int>>[items[40]]);
      await _pump(
        tester,
        c,
        overlay: const SimpleOverlaySettings(
          dialogHeight: 400,
          reOpenedScrollDuration: Duration(seconds: 2),
        ),
      );
      await tester.tap(
        find.descendant(of: _dropdown, matching: find.byType(InkWell)).first,
      );
      await tester.pump();
      // Frames of 100 ms until the scroll animation stops: 2 s of them.
      final int frames = await tester.pumpAndSettle();
      expect(frames, inInclusiveRange(20, 25));

      final Finder target = _inList(find.text('Item 40'));
      final double top = tester.getRect(target).top;
      final Rect list = tester.getRect(_list);
      expect(top >= list.top && top < list.bottom, isTrue, reason: '$top');
    });
  });

  group('multiple box and list settings', () {
    testWidgets('box: backgroundColor fills it, elevation 0 drops the shadow', (
      tester,
    ) async {
      await _pump(
        tester,
        _mc(),
        bar: const SimpleSearchbarSettings(
          backgroundColor: Colors.red,
          elevation: 0,
        ),
      );
      final BoxDecoration flat = _boxDecoration(tester);
      expect(flat.color, Colors.red);
      expect(flat.boxShadow!.single.color.a, 0);
    });

    testWidgets('box: the default elevation casts a visible shadow', (
      tester,
    ) async {
      await _pump(tester, _mc());
      final BoxDecoration raised = _boxDecoration(tester);
      expect(raised.color, Colors.white);
      final BoxShadow shadow = raised.boxShadow!.single;
      expect(shadow.color, Colors.grey.withAlpha(125));
      expect(shadow.blurRadius, 2);
      expect(shadow.offset, const Offset(0, 1));
    });

    testWidgets('list Card: dialogBackgroundColor and the bar elevation', (
      tester,
    ) async {
      await _pump(
        tester,
        _mc(),
        bar: const SimpleSearchbarSettings(
          backgroundColor: Colors.teal,
          elevation: 5,
        ),
        overlay: const SimpleOverlaySettings(
          dialogHeight: 400,
          dialogBackgroundColor: Colors.amber,
        ),
      );
      await openMultiple(tester);
      final Card card = _listCard(tester);
      expect(card.color, Colors.amber);
      expect(card.elevation, 5);
    });

    testWidgets('list Card: without dialogBackgroundColor, the bar colour', (
      tester,
    ) async {
      await _pump(
        tester,
        _mc(),
        bar: const SimpleSearchbarSettings(backgroundColor: Colors.teal),
      );
      await openMultiple(tester);
      expect(_listCard(tester).color, Colors.teal);
    });

    testWidgets('dialogHeight is the list height', (tester) async {
      await _pump(
        tester,
        _mc(),
        overlay: const SimpleOverlaySettings(dialogHeight: 150),
      );
      await openMultiple(tester);
      expect(
        tester.getSize(_inList(find.byType(AnimatedContainer))).height,
        150,
      );
    });

    testWidgets(
      'animationDuration drives the list container (100 ms default)',
      (tester) async {
        Duration duration() => tester
            .widget<AnimatedContainer>(_inList(find.byType(AnimatedContainer)))
            .duration;
        await _pump(tester, _mc());
        await openMultiple(tester);
        expect(duration(), const Duration(milliseconds: 100));

        await _pump(
          tester,
          _mc(),
          overlay: const SimpleOverlaySettings(
            dialogHeight: 400,
            animationDuration: Duration(milliseconds: 750),
          ),
        );
        await tester.pumpAndSettle();
        expect(duration(), const Duration(milliseconds: 750));
      },
    );

    testWidgets('search field: hint, searchBarTextStyle and border', (
      tester,
    ) async {
      const OutlinedBorder border = BeveledRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(6)),
        side: BorderSide(color: Colors.red, width: 2),
      );
      await _pump(
        tester,
        _mc(),
        bar: const SimpleSearchbarSettings(
          hint: 'Choose',
          hintStyle: TextStyle(fontSize: 11, color: Colors.cyan),
          searchBarTextStyle: TextStyle(fontSize: 19, color: Colors.brown),
          border: border,
        ),
      );
      await openMultiple(tester);

      final TextStyle hint = _textStyle(tester, _listBar, 'Choose');
      expect(hint.fontSize, 11);
      expect(hint.color, Colors.cyan);
      final EditableText field = tester.widget<EditableText>(_listField);
      expect(field.style.fontSize, 19);
      expect(field.style.color, Colors.brown);
      final Material material = tester
          .widgetList<Material>(
            find.descendant(of: _listBar, matching: find.byType(Material)),
          )
          .first;
      // The list field takes the border's shape; its side is never drawn
      // (as in 7.x).
      expect(
        material.shape,
        border.copyWith(side: const BorderSide(style: BorderStyle.none)),
      );
    });

    testWidgets('search field: without searchBarTextStyle, hintStyle', (
      tester,
    ) async {
      await _pump(
        tester,
        _mc(),
        bar: const SimpleSearchbarSettings(
          hintStyle: TextStyle(fontSize: 11, color: Colors.cyan),
        ),
      );
      await openMultiple(tester);
      final EditableText field = tester.widget<EditableText>(_listField);
      expect(field.style.fontSize, 11);
      expect(field.style.color, Colors.cyan);
    });
  });

  group('multiple row settings', () {
    testWidgets('separatorHeight is the gap between rows', (tester) async {
      await _pump(
        tester,
        _mc(),
        overlay: const SimpleOverlaySettings(
          dialogHeight: 400,
          separatorHeight: 7,
        ),
      );
      await openMultiple(tester);
      expect(
        tester.getTopLeft(_row('apple')).dy -
            tester.getBottomLeft(_row('Cherry')).dy,
        7,
      );
    });

    testWidgets('itemsPadding insets every row', (tester) async {
      await _pump(
        tester,
        _mc(),
        overlay: const SimpleOverlaySettings(
          dialogHeight: 400,
          itemsPadding: EdgeInsets.only(left: 13, right: 9),
        ),
      );
      await openMultiple(tester);
      final Finder button = find.descendant(
        of: _row('apple'),
        matching: find.byType(TextButton),
      );
      expect(
        tester.getTopLeft(button).dx - tester.getTopLeft(_row('apple')).dx,
        13,
      );
      expect(
        tester.getTopRight(_row('apple')).dx - tester.getTopRight(button).dx,
        9,
      );
    });

    testWidgets('additionalWidgetSpacing separates the extra widget', (
      tester,
    ) async {
      const Key extra = Key('extra');
      await _pump(
        tester,
        _mc(onDeleteItem: (_) {}),
        overlay: const SimpleOverlaySettings(
          dialogHeight: 400,
          additionalWidgetSpacing: 23,
        ),
        defaultAdditionalWidget: const SizedBox(key: extra, width: 10),
      );
      await openMultiple(tester);
      final Finder extraInRow = find.descendant(
        of: _row('apple'),
        matching: find.byKey(extra),
      );
      final Finder delete = find.descendant(
        of: _row('apple'),
        matching: find.byType(IconButton),
      );
      expect(
        tester.getTopLeft(delete).dx - tester.getTopRight(extraInRow).dx,
        23,
      );
    });

    testWidgets('selected/unselected hover colours and text styles', (
      tester,
    ) async {
      final List<ValueItem<int>> items = _items();
      await _pump(
        tester,
        _mc(items: items, selected: <ValueItem<int>>[items[0]]),
        overlay: const SimpleOverlaySettings(
          dialogHeight: 400,
          selectedItemHoverColor: Colors.orange,
          unselectedItemHoverColor: Colors.green,
          selectedItemTextStyle: TextStyle(fontSize: 15, color: Colors.blue),
          unselectedItemTextStyle: TextStyle(fontSize: 13, color: Colors.pink),
        ),
      );
      await openMultiple(tester);
      const Set<WidgetState> hovered = <WidgetState>{WidgetState.hovered};
      expect(_rowOverlay(tester, 'Cherry', hovered), Colors.orange);
      expect(_rowOverlay(tester, 'apple', hovered), Colors.green);

      final TextStyle selected = _textStyle(tester, _row('Cherry'), 'Cherry');
      expect(selected.fontSize, 15);
      expect(selected.color, Colors.blue);
      final TextStyle unselected = _textStyle(tester, _row('apple'), 'apple');
      expect(unselected.fontSize, 13);
      expect(unselected.color, Colors.pink);
    });

    testWidgets('addItemHintStyle styles the "Criar" button text', (
      tester,
    ) async {
      await _pump(
        tester,
        _mc(addMode: true),
        overlay: const SimpleOverlaySettings(
          dialogHeight: 400,
          addItemHintStyle: TextStyle(fontSize: 21, color: Colors.deepOrange),
        ),
      );
      await openMultiple(tester);
      await _type(tester, 'Kiwi');
      final TextStyle criar = _textStyle(tester, _list, 'Criar');
      expect(criar.fontSize, 21);
      expect(criar.color, Colors.deepOrange);
    });

    testWidgets('loadingColor/Size style the spinner while a delete runs', (
      tester,
    ) async {
      final Completer<void> pending = Completer<void>();
      await _pump(
        tester,
        _mc(onDeleteItem: (_) => pending.future),
        overlay: const SimpleOverlaySettings(
          dialogHeight: 400,
          loadingColor: Colors.purple,
          loadingSize: 17,
        ),
      );
      await openMultiple(tester);
      await tester.tap(
        find.descendant(of: _row('apple'), matching: find.byIcon(Icons.delete)),
      );
      await tester.pump();

      final Finder spinner = find.descendant(
        of: _row('apple'),
        matching: find.byType(CircularProgressIndicator),
      );
      expect(
        tester.widget<CircularProgressIndicator>(spinner).color,
        Colors.purple,
      );
      expect(tester.getSize(spinner), const Size(17, 17));

      pending.complete();
      await tester.pumpAndSettle();
    });
  });

  group('multiple chips', () {
    testWidgets('a mouse drag scrolls the chip row (CustomScrollBehavior)', (
      tester,
    ) async {
      final List<ValueItem<int>> items = numberedItems(12);
      await _pump(tester, _mc(items: items, selected: items));
      final Finder chips = find.descendant(
        of: _dropdown,
        matching: find.byType(Scrollable),
      );
      final ScrollPosition position = tester
          .state<ScrollableState>(chips.first)
          .position;
      expect(position.maxScrollExtent, greaterThan(0), reason: 'overflows');
      expect(position.pixels, 0);

      await tester.dragFrom(
        tester.getCenter(chips.first),
        const Offset(-120, 0),
        kind: PointerDeviceKind.mouse,
      );
      await tester.pumpAndSettle();

      expect(position.pixels, greaterThan(0));
      expect(find.byType(MultipleListView<int>), findsNothing);
    });
  });

  group('multiple controller API', () {
    test('refresh clears the query and lists every item again', () {
      final c = _mc()..search('ch');
      expect(c.filteredItems.map((e) => e.label), <String>['Cherry']);

      c.refresh();
      expect(c.query, '');
      expect(c.filteredItems, c.items);
    });

    test('toggle(forced: true) selects but never deselects', () {
      final List<List<ValueItem<int>>> updates = <List<ValueItem<int>>>[];
      final List<ValueItem<int>> cleared = <ValueItem<int>>[];
      final List<ValueItem<int>> items = _items();
      final c = _mc(
        items: items,
        selected: <ValueItem<int>>[items[0]],
        onSelection: updates.add,
        onClearItem: cleared.add,
      );
      expect(c.isSelected(items[0]), isTrue);

      c.toggle(items[0], forced: true);
      expect(c.selectedItems, <ValueItem<int>>[items[0]]);
      c.toggle(items[1], forced: true);
      expect(c.selectedItems, <ValueItem<int>>[items[0], items[1]]);
      expect(cleared, isEmpty);
      expect(updates, <List<ValueItem<int>>>[
        <ValueItem<int>>[items[0]],
        <ValueItem<int>>[items[0], items[1]],
      ]);

      c.toggle(items[0]);
      expect(c.selectedItems, <ValueItem<int>>[items[1]]);
      expect(cleared, <ValueItem<int>>[items[0]]);
    });

    testWidgets('editDialogSettings set after creation is used', (
      tester,
    ) async {
      final c = _mc(editMode: true)
        ..editDialogSettings = const DialogSettings(title: Text('Later edit'));
      await _pump(tester, c);
      await openMultiple(tester);
      await tester.tap(
        find.descendant(of: _row('apple'), matching: find.byIcon(Icons.edit)),
      );
      await _openDialog(tester);
      expect(find.text('Later edit'), findsOneWidget);
    });

    testWidgets('deleteDialogSettings set after creation is used', (
      tester,
    ) async {
      final c = _mc(onDeleteItem: (_) {}, confirmDelete: true)
        ..deleteDialogSettings = const DialogSettings(title: Text('Later del'));
      await _pump(tester, c);
      await openMultiple(tester);
      await tester.tap(
        find.descendant(of: _row('apple'), matching: find.byIcon(Icons.delete)),
      );
      await _openDialog(tester);
      expect(find.text('Later del'), findsOneWidget);
      expect(find.text('Tem certeza?'), findsNothing);
    });

    testWidgets('verifyDialogSettings set after creation is used', (
      tester,
    ) async {
      final c = _mc(addMode: true, verifyInputItem: (_) => false)
        ..verifyDialogSettings = const DialogSettings(title: Text('Later bad'));
      await _pump(tester, c);
      await openMultiple(tester);
      await _type(tester, 'Zed');
      await tester.tap(_inList(find.text('Criar')));
      await tester.pumpAndSettle();
      expect(find.text('Later bad'), findsOneWidget);
      expect(find.text('Erro!'), findsNothing);
    });

    test('onClearItem and onClearList are exposed unchanged', () {
      void onItem(ValueItem<int> _) {}
      void onList() {}
      final c = _mc(onClearItem: onItem, onClearList: onList);
      expect(c.onClearItem, same(onItem));
      expect(c.onClearList, same(onList));

      final d = _mc();
      expect(d.onClearItem, isNull);
      expect(d.onClearList, isNull);
    });
  });
}
