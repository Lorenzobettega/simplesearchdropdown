// Settings and controller API of the single SearchDropDown that the other
// suites leave unchecked. Each test reads the value the rendered widget
// actually uses (the Material, Icon glyph, text style, geometry), so a
// setting that stops reaching the screen fails here.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:simple_search_dropdown/simple_search_dropdown.dart';

import '../support/harness.dart';

SearchDropDownController<int> _ctrl({
  List<ValueItem<int>>? items,
  ValueItem<int>? initial,
  List<ValueItem<int>?>? calls,
  bool deleteMode = false,
  Function(ValueItem<int>)? onDeleteItem,
  bool addMode = false,
}) => SearchDropDownController<int>(
  items: items ?? fruitItems(),
  initialSelectedItem: initial,
  updateSelectedItem: calls?.add,
  addMode: addMode,
  newValueItem: addMode ? (s) => ValueItem(label: s, value: 99) : null,
  onAddItem: addMode ? (_) {} : null,
  deleteMode: deleteMode,
  onDeleteItem: onDeleteItem,
);

Future<SearchDropDownController<int>> _pump(
  WidgetTester tester, {
  SearchDropDownController<int>? controller,
  SimpleSearchbarSettings bar = defaultSearchBarSettings,
  SimpleOverlaySettings overlay = const SimpleOverlaySettings(
    dialogHeight: 400,
  ),
  Widget? defaultAdditionalWidget,
}) async {
  final SearchDropDownController<int> c = controller ?? _ctrl();
  await tester.pumpWidget(
    host(
      SearchDropDown<int>(
        controller: c,
        searchBarSettings: bar,
        overlayListSettings: overlay,
        defaultAdditionalWidget: defaultAdditionalWidget,
      ),
    ),
  );
  return c;
}

const ValueItem<int> _banana = ValueItem(label: 'Banana', value: 2);

// ------------------------------------------------------------------ finders

/// The closed bar (the first SearchBar; the open view has its own header).
Finder _bar() => find.byType(SearchBar).first;

/// The Material that paints the closed bar.
Material _barMaterial(WidgetTester tester) => tester
    .widgetList<Material>(
      find.descendant(of: _bar(), matching: find.byType(Material)),
    )
    .first;

/// The open view's header bar (the SearchBar holding the focused field).
Finder _viewHeader() =>
    find.ancestor(of: focusedField(), matching: find.byType(SearchBar));

/// The Material that paints the open view: the outermost one above its field.
Material _viewMaterial(WidgetTester tester) => tester
    .widgetList<Material>(
      find.ancestor(of: focusedField(), matching: find.byType(Material)),
    )
    .last;

/// The glyph actually painted for [icon] under [scope]: its colour and size.
TextStyle _glyph(WidgetTester tester, IconData icon, Finder scope) {
  final RichText text = tester.widget<RichText>(
    find.descendant(
      of: find.descendant(of: scope, matching: find.byIcon(icon)),
      matching: find.byType(RichText),
    ),
  );
  return text.text.style!;
}

/// The style the hint [hint] is painted with under [scope].
TextStyle _hintStyle(WidgetTester tester, Finder scope, String hint) {
  final RichText text = tester.widget<RichText>(
    find.descendant(
      of: find.descendant(of: scope, matching: find.text(hint)),
      matching: find.byType(RichText),
      matchRoot: true,
    ),
  );
  return text.text.style!;
}

Finder _row(String label) => find.byWidgetPredicate(
  (w) => w is DefaultListTile<int> && w.item.label == label,
);

/// The overlay colour the row's ink paints with in [states].
Color? _rowOverlay(WidgetTester tester, String label, Set<WidgetState> states) {
  final InkWell ink = tester.widget<InkWell>(
    find.descendant(of: _row(label), matching: find.byType(InkWell)).first,
  );
  return ink.overlayColor!.resolve(states);
}

void main() {
  group('single bar settings', () {
    testWidgets('dropdownHeight sizes the bar and the open view header', (
      tester,
    ) async {
      await _pump(
        tester,
        bar: const SimpleSearchbarSettings(dropdownHeight: 64),
      );
      expect(tester.getSize(_bar()).height, 64);

      await openSingle(tester);
      expect(tester.getSize(_viewHeader()).height, 64);
    });

    testWidgets('elevation lifts the bar and the open view', (tester) async {
      await _pump(tester, bar: const SimpleSearchbarSettings(elevation: 7));
      expect(_barMaterial(tester).elevation, 7);

      await openSingle(tester);
      expect(_viewMaterial(tester).elevation, 7);
    });

    testWidgets(
      'backgroundColor paints the bar and the view without dialogBackgroundColor',
      (tester) async {
        await _pump(
          tester,
          bar: const SimpleSearchbarSettings(backgroundColor: Colors.amber),
        );
        expect(_barMaterial(tester).color, Colors.amber);

        await openSingle(tester);
        expect(_viewMaterial(tester).color, Colors.amber);
      },
    );

    testWidgets('dialogBackgroundColor paints the view, not the bar', (
      tester,
    ) async {
      await _pump(
        tester,
        bar: const SimpleSearchbarSettings(backgroundColor: Colors.amber),
        overlay: const SimpleOverlaySettings(
          dialogHeight: 400,
          dialogBackgroundColor: Colors.teal,
        ),
      );
      expect(_barMaterial(tester).color, Colors.amber);

      await openSingle(tester);
      expect(_viewMaterial(tester).color, Colors.teal);
    });

    testWidgets('border shapes the bar', (tester) async {
      const OutlinedBorder border = BeveledRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(6)),
        side: BorderSide(color: Colors.red, width: 2),
      );
      await _pump(tester, bar: const SimpleSearchbarSettings(border: border));
      expect(_barMaterial(tester).shape, border);
    });

    testWidgets('clearIconColor colours the X in the bar and the open view', (
      tester,
    ) async {
      await _pump(
        tester,
        controller: _ctrl(initial: _banana),
        bar: const SimpleSearchbarSettings(clearIconColor: Colors.pink),
      );
      expect(_glyph(tester, Icons.clear, _bar()).color, Colors.pink);

      await openSingle(tester);
      expect(_glyph(tester, Icons.clear, _viewHeader()).color, Colors.pink);
    });

    testWidgets('outsideIconColor/Size style the arrows; the size also the X', (
      tester,
    ) async {
      const SimpleSearchbarSettings bar = SimpleSearchbarSettings(
        outsideIconColor: Colors.indigo,
        outsideIconSize: 31,
      );
      await _pump(
        tester,
        controller: _ctrl(initial: _banana),
        bar: bar,
      );
      final TextStyle closed = _glyph(tester, Icons.arrow_drop_down, _bar());
      expect(closed.color, Colors.indigo);
      expect(closed.fontSize, 31);
      expect(_glyph(tester, Icons.clear, _bar()).fontSize, 31);

      await openSingle(tester);
      final TextStyle open = _glyph(tester, Icons.arrow_drop_up, _viewHeader());
      expect(open.color, Colors.indigo);
      expect(open.fontSize, 31);
      expect(_glyph(tester, Icons.clear, _viewHeader()).fontSize, 31);
    });

    testWidgets('searchBarTextStyle styles the bar text and the view field', (
      tester,
    ) async {
      const TextStyle style = TextStyle(fontSize: 19, color: Colors.brown);
      await _pump(
        tester,
        controller: _ctrl(initial: _banana),
        bar: const SimpleSearchbarSettings(searchBarTextStyle: style),
      );
      final EditableText barField = tester.widget<EditableText>(
        find.descendant(of: _bar(), matching: find.byType(EditableText)),
      );
      expect(barField.style.fontSize, 19);
      expect(barField.style.color, Colors.brown);

      await openSingle(tester);
      final EditableText viewField = tester.widget<EditableText>(
        focusedField(),
      );
      expect(viewField.style.fontSize, 19);
      expect(viewField.style.color, Colors.brown);
    });

    testWidgets('hintStyle styles the hint in the bar and the open view', (
      tester,
    ) async {
      const TextStyle style = TextStyle(fontSize: 11, color: Colors.cyan);
      await _pump(tester, bar: const SimpleSearchbarSettings(hintStyle: style));
      final TextStyle closed = _hintStyle(tester, _bar(), 'Pesquisar');
      expect(closed.fontSize, 11);
      expect(closed.color, Colors.cyan);

      await openSingle(tester);
      final TextStyle open = _hintStyle(tester, _viewHeader(), 'Pesquisar');
      expect(open.fontSize, 11);
      expect(open.color, Colors.cyan);
    });

    testWidgets('hoverColor is the bar ink overlay', (tester) async {
      await _pump(
        tester,
        bar: const SimpleSearchbarSettings(hoverColor: Colors.lime),
      );
      final InkWell ink = tester.widget<InkWell>(
        find.descendant(of: _bar(), matching: find.byType(InkWell)).first,
      );
      expect(
        ink.overlayColor!.resolve(<WidgetState>{WidgetState.hovered}),
        Colors.lime,
      );
    });

    testWidgets('searchBarPadding insets the bar content', (tester) async {
      await _pump(
        tester,
        bar: const SimpleSearchbarSettings(
          searchBarPadding: EdgeInsets.only(left: 37),
        ),
      );
      final Finder content = find.descendant(
        of: _bar(),
        matching: find.byType(Row),
      );
      // The bar's content row starts exactly the padding in from its edge.
      expect(
        tester.getTopLeft(content.first).dx - tester.getTopLeft(_bar()).dx,
        37,
      );
    });
  });

  group('single row settings', () {
    testWidgets('itemsPadding insets every row', (tester) async {
      await _pump(
        tester,
        overlay: const SimpleOverlaySettings(
          dialogHeight: 400,
          itemsPadding: EdgeInsets.only(left: 13, right: 9),
        ),
      );
      await openSingle(tester);
      final Finder button = find.descendant(
        of: _row('Uva'),
        matching: find.byType(TextButton),
      );
      expect(
        tester.getTopLeft(button).dx - tester.getTopLeft(_row('Uva')).dx,
        13,
      );
      expect(
        tester.getTopRight(_row('Uva')).dx - tester.getTopRight(button).dx,
        9,
      );
    });

    testWidgets('selected/unselected hover colours are the row ink overlay', (
      tester,
    ) async {
      await _pump(
        tester,
        controller: _ctrl(initial: _banana),
        overlay: const SimpleOverlaySettings(
          dialogHeight: 400,
          selectedItemHoverColor: Colors.orange,
          unselectedItemHoverColor: Colors.green,
        ),
      );
      await openSingle(tester);
      const Set<WidgetState> hovered = <WidgetState>{WidgetState.hovered};
      expect(_rowOverlay(tester, 'Banana', hovered), Colors.orange);
      expect(_rowOverlay(tester, 'Uva', hovered), Colors.green);
    });

    testWidgets('addItemHintStyle styles the "Criar" button text', (
      tester,
    ) async {
      await _pump(
        tester,
        controller: _ctrl(addMode: true),
        overlay: const SimpleOverlaySettings(
          dialogHeight: 400,
          addItemHintStyle: TextStyle(fontSize: 21, color: Colors.deepOrange),
        ),
      );
      await openSingle(tester);
      await typeInSingle(tester, 'Kiwi');
      final RichText criar = tester.widget<RichText>(
        find.descendant(
          of: find.text('Criar'),
          matching: find.byType(RichText),
          matchRoot: true,
        ),
      );
      expect(criar.text.style!.fontSize, 21);
      expect(criar.text.style!.color, Colors.deepOrange);
    });

    testWidgets('additionalWidgetSpacing separates the extra widget', (
      tester,
    ) async {
      const Key extra = Key('extra');
      await _pump(
        tester,
        controller: _ctrl(deleteMode: true, onDeleteItem: (_) {}),
        overlay: const SimpleOverlaySettings(
          dialogHeight: 400,
          additionalWidgetSpacing: 23,
        ),
        defaultAdditionalWidget: const SizedBox(key: extra, width: 10),
      );
      await openSingle(tester);
      final Finder extraInRow = find.descendant(
        of: _row('Uva'),
        matching: find.byKey(extra),
      );
      final Finder delete = find.descendant(
        of: _row('Uva'),
        matching: find.byType(IconButton),
      );
      expect(
        tester.getTopLeft(delete).dx - tester.getTopRight(extraInRow).dx,
        23,
      );
    });

    testWidgets('loadingColor/Size style the spinner while a delete runs', (
      tester,
    ) async {
      final Completer<void> pending = Completer<void>();
      await _pump(
        tester,
        controller: _ctrl(
          deleteMode: true,
          onDeleteItem: (_) => pending.future,
        ),
        overlay: const SimpleOverlaySettings(
          dialogHeight: 400,
          loadingColor: Colors.purple,
          loadingSize: 17,
        ),
      );
      await openSingle(tester);
      await tester.tap(
        find.descendant(of: _row('Uva'), matching: find.byType(IconButton)),
      );
      await tester.pump();

      final Finder spinner = find.descendant(
        of: _row('Uva'),
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

  group('single controller API', () {
    testWidgets('clearVisible hides and shows the X', (tester) async {
      final c = await _pump(tester, controller: _ctrl(initial: _banana));
      expect(find.byIcon(Icons.clear), findsOneWidget);

      c.clearVisible = false;
      await tester.pump();
      expect(find.byIcon(Icons.clear), findsNothing);
      expect(c.selectedItem, _banana, reason: 'only the button changes');

      c.clearVisible = true;
      await tester.pump();
      expect(find.byIcon(Icons.clear), findsOneWidget);
    });

    test('clearSelection clears text and selection without the callback', () {
      final List<ValueItem<int>?> calls = <ValueItem<int>?>[];
      final c = _ctrl(initial: _banana, calls: calls);
      addTearDown(c.dispose);

      c.clearSelection();

      expect(c.selectedItem, isNull);
      expect(c.localSearchController.text, '');
      expect(c.clearVisible, isFalse);
      expect(calls, isEmpty);
    });

    test('resetSelection(highlight: true) also drops the highlight', () {
      final List<ValueItem<int>?> calls = <ValueItem<int>?>[];
      final c = _ctrl(initial: _banana, calls: calls);
      addTearDown(c.dispose);
      c.highlightNext();
      expect(c.highlightedIndex, isNot(-1));

      c.resetSelection();
      expect(c.highlightedIndex, isNot(-1), reason: 'kept by default');

      c.resetSelection(highlight: true);
      expect(c.highlightedIndex, -1);
      expect(c.selectedItem, isNull);
      expect(calls, <ValueItem<int>?>[null, null]);
    });

    test('resetHighlight clears the keyboard highlight', () {
      final c = _ctrl();
      addTearDown(c.dispose);
      c.highlightNext();
      expect(c.highlightedIndex, 0);

      c.resetHighlight();
      expect(c.highlightedIndex, -1);
    });

    test('handleEnterKey selects the first filtered item', () {
      final List<ValueItem<int>?> calls = <ValueItem<int>?>[];
      final c = _ctrl(calls: calls);
      addTearDown(c.dispose);
      c.filterList('ba');
      final ValueItem<int> first = c.filteredItems.first;
      expect(first.label, 'Banana', reason: 'not the first of all items');

      c.handleEnterKey();
      expect(c.selectedItem, first);
      expect(calls, <ValueItem<int>?>[first]);
    });

    test('selectHighlighted selects the highlighted item, else nothing', () {
      final List<ValueItem<int>?> calls = <ValueItem<int>?>[];
      final c = _ctrl(calls: calls);
      addTearDown(c.dispose);

      c.selectHighlighted();
      expect(c.selectedItem, isNull, reason: 'no highlight');
      expect(calls, isEmpty);

      c
        ..highlightNext()
        ..highlightNext();
      final ValueItem<int> second = c.filteredItems[1];
      c.selectHighlighted();
      expect(c.selectedItem, second);
      expect(calls, <ValueItem<int>?>[second]);
    });

    test('constructor arguments are exposed unchanged', () {
      ValueItem<int> newValue(String s) => ValueItem(label: s, value: 0);
      void onAdd(ValueItem<int> _) {}
      void onEdit(ValueItem<int> a, ValueItem<int> b) {}
      void onDelete(ValueItem<int> _) {}
      void onSelected(ValueItem<int>? _) {}
      bool verify(ValueItem<int> _) => true;
      void onFilter() {}
      const DialogSettings edit = DialogSettings(elevation: 1);
      const DialogSettings delete = DialogSettings(elevation: 2);
      const DialogSettings verifyDialog = DialogSettings(elevation: 3);

      final c = SearchDropDownController<int>(
        items: fruitItems(),
        newValueItem: newValue,
        onAddItem: onAdd,
        editMode: true,
        onEditItem: onEdit,
        editDialogSettings: edit,
        onDeleteItem: onDelete,
        deleteDialogSettings: delete,
        updateSelectedItem: onSelected,
        verifyInputItem: verify,
        verifyDialogSettings: verifyDialog,
        onFilterUpdated: onFilter,
        latinize: false,
        caseSensitive: true,
      );
      addTearDown(c.dispose);

      expect(c.newValueItem, same(newValue));
      expect(c.onAddItem, same(onAdd));
      expect(c.onEditItem, same(onEdit));
      expect(c.onDeleteItem, same(onDelete));
      expect(c.editDialogSettings, same(edit));
      expect(c.deleteDialogSettings, same(delete));
      expect(c.verifyDialogSettings, same(verifyDialog));
      expect(c.updateSelectedItem, same(onSelected));
      expect(c.verifyInputItem, same(verify));
      expect(c.onFilterUpdated, same(onFilter));
      expect(c.latinize, isFalse);
      expect(c.caseSensitive, isTrue);

      expect(c.trim, isTrue);

      // The opposite pattern, so no flag can read another one's value.
      final d = SearchDropDownController<int>(
        items: fruitItems(),
        addMode: false,
        deleteMode: false,
        trim: false,
      );
      addTearDown(d.dispose);
      expect(d.latinize, isTrue);
      expect(d.caseSensitive, isFalse);
      expect(d.trim, isFalse);

      // Defaults: a third pattern, so every flag differs from the others.
      final e = _ctrl();
      addTearDown(e.dispose);
      expect(e.latinize, isTrue);
      expect(e.caseSensitive, isFalse);
      expect(e.trim, isTrue);
    });
  });
}
