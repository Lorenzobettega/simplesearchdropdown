// Theme-aware defaults (8.0.1): an unset colour keeps its fixed 8.0.0 value
// under a light theme and follows the ColorScheme under a dark one; a colour
// set in the settings always wins. Also the AA contrast of the dark pairs,
// the row spinner's default size, and dark goldens (tag: golden).

import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:simple_search_dropdown/simple_search_dropdown.dart';
import 'package:simple_search_dropdown/src/core/theme_colors.dart';

import '../support/harness.dart';

final ThemeData _light = ThemeData(useMaterial3: true);
final ThemeData _dark = ThemeData(
  useMaterial3: true,
  brightness: Brightness.dark,
);

/// The dark themes the contrast table is checked on: Flutter's default dark
/// scheme and one seeded from the package's own green.
final Map<String, ThemeData> _darkThemes = <String, ThemeData>{
  'default dark': _dark,
  'darkGreen seed': ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: darkGreen,
      brightness: Brightness.dark,
    ),
  ),
};

/// WCAG 2.x contrast ratio of [a] on [b] (both opaque).
double _contrast(Color a, Color b) {
  final double la = a.computeLuminance();
  final double lb = b.computeLuminance();
  return (math.max(la, lb) + 0.05) / (math.min(la, lb) + 0.05);
}

Finder _row(String label) => find.byWidgetPredicate(
  (w) => w is DefaultListTile<int> && w.item.label == label,
);

ButtonStyle _rowStyle(WidgetTester tester, String label) => tester
    .widget<TextButton>(
      find.descendant(of: _row(label), matching: find.byType(TextButton)),
    )
    .style!;

Color _rowBackground(WidgetTester tester, String label) =>
    _rowStyle(tester, label).backgroundColor!.resolve(<WidgetState>{})!;

Color? _rowTextColor(WidgetTester tester, String label) => tester
    .widget<Text>(find.descendant(of: _row(label), matching: find.text(label)))
    .style
    ?.color;

Color? _rowIconColor(WidgetTester tester, String label, IconData icon) => tester
    .widget<Icon>(find.descendant(of: _row(label), matching: find.byIcon(icon)))
    .color;

SearchBar _bar(WidgetTester tester) =>
    tester.widget<SearchBar>(find.byType(SearchBar).first);

BoxDecoration _boxDecoration(WidgetTester tester) =>
    tester
            .widgetList<Container>(
              find.descendant(
                of: find.byType(MultipleSearchDropDown<int>),
                matching: find.byWidgetPredicate(
                  (w) => w is Container && w.decoration is BoxDecoration,
                ),
              ),
            )
            .first
            .decoration!
        as BoxDecoration;

SearchDropDownController<int> _single({
  ValueItem<int>? initial,
  bool deleteMode = true,
  bool editMode = true,
  bool confirmDelete = false,
  FutureOr<void> Function(ValueItem<int>)? onDeleteItem,
}) => SearchDropDownController<int>(
  items: fruitItems(),
  addMode: false,
  deleteMode: deleteMode,
  editMode: editMode,
  confirmDelete: confirmDelete,
  onDeleteItem: onDeleteItem ?? (_) {},
  onEditItem: (_, _) {},
  newValueItem: (input) => ValueItem<int>(label: input, value: 0),
  initialSelectedItem: initial,
);

Future<void> _pumpSingle(
  WidgetTester tester,
  SearchDropDownController<int> controller, {
  ThemeData? theme,
  SimpleSearchbarSettings bar = defaultSearchBarSettings,
  SimpleOverlaySettings list = const SimpleOverlaySettings(dialogHeight: 400),
}) async {
  tester.view.physicalSize = const Size(800, 600);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    host(
      SearchDropDown<int>(
        controller: controller,
        searchBarSettings: bar,
        overlayListSettings: list,
      ),
      theme: theme ?? _dark,
    ),
  );
  await tester.pumpAndSettle();
}

Future<MultipleSearchDropDownController<int>> _pumpMultiple(
  WidgetTester tester, {
  ThemeData? theme,
  List<int> selected = const <int>[0, 2],
}) async {
  tester.view.physicalSize = const Size(800, 600);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final List<ValueItem<int>> items = fruitItems();
  final MultipleSearchDropDownController<int> controller =
      MultipleSearchDropDownController<int>(
        items: items,
        selectedItems: <ValueItem<int>>[for (final int i in selected) items[i]],
        addMode: false,
        deleteMode: false,
      );
  addTearDown(controller.dispose);
  await tester.pumpWidget(
    host(
      MultipleSearchDropDown<int>(
        controller: controller,
        overlayListSettings: const SimpleOverlaySettings(dialogHeight: 400),
      ),
      theme: theme ?? _dark,
    ),
  );
  await tester.pumpAndSettle();
  return controller;
}

void main() {
  group('settings: unset colours', () {
    test('read as the 8.0.0 light values', () {
      const SimpleSearchbarSettings bar = SimpleSearchbarSettings();
      expect(bar.customBackgroundColor, isNull);
      expect(bar.customHoverColor, isNull);
      expect(bar.customBoxMultiSelectedBackgroundColor, isNull);
      expect(bar.backgroundColor, Colors.white);
      expect(bar.hoverColor, const Color.fromRGBO(245, 245, 245, 1));
      expect(
        bar.boxMultiSelectedBackgroundColor,
        const Color.fromRGBO(224, 224, 224, 1),
      );

      const SimpleOverlaySettings list = SimpleOverlaySettings();
      expect(list.customSelectedItemBackgroundColor, isNull);
      expect(list.customSelectedItemHoverColor, isNull);
      expect(list.customUnselectedItemHoverColor, isNull);
      expect(list.customHighlightedItemBorderColor, isNull);
      expect(list.customDialogDeleteIcon, isNull);
      expect(list.customDialogEditIcon, isNull);
      expect(list.customLoadingColor, isNull);
      expect(list.selectedItemBackgroundColor, Colors.black38);
      expect(
        list.selectedItemHoverColor,
        const Color.fromRGBO(224, 224, 224, 1),
      );
      expect(
        list.unselectedItemHoverColor,
        const Color.fromRGBO(245, 245, 245, 1),
      );
      expect(list.highlightedItemBorderColor, Colors.black26);
      expect(list.dialogDeleteIcon.icon, Icons.delete);
      expect(list.dialogDeleteIcon.color, const Color.fromRGBO(183, 28, 28, 1));
      expect(list.dialogDeleteIcon.size, 20);
      expect(list.dialogEditIcon.icon, Icons.edit);
      expect(list.dialogEditIcon.color, Colors.black);
      expect(list.dialogEditIcon.size, 20);
      expect(list.loadingColor, darkGreen);
    });

    test('set ones are kept as given', () {
      const Icon delete = Icon(Icons.close);
      const Icon edit = Icon(Icons.create);
      const SimpleSearchbarSettings bar = SimpleSearchbarSettings(
        backgroundColor: Colors.amber,
        hoverColor: Colors.lime,
        boxMultiSelectedBackgroundColor: Colors.teal,
      );
      expect(bar.customBackgroundColor, Colors.amber);
      expect(bar.customHoverColor, Colors.lime);
      expect(bar.customBoxMultiSelectedBackgroundColor, Colors.teal);
      expect(bar.backgroundColor, Colors.amber);

      const SimpleOverlaySettings list = SimpleOverlaySettings(
        selectedItemBackgroundColor: Colors.purple,
        selectedItemHoverColor: Colors.orange,
        unselectedItemHoverColor: Colors.green,
        highlightedItemBorderColor: Colors.blue,
        dialogDeleteIcon: delete,
        dialogEditIcon: edit,
        loadingColor: Colors.pink,
      );
      expect(list.customSelectedItemBackgroundColor, Colors.purple);
      expect(list.customSelectedItemHoverColor, Colors.orange);
      expect(list.customUnselectedItemHoverColor, Colors.green);
      expect(list.customHighlightedItemBorderColor, Colors.blue);
      expect(list.customDialogDeleteIcon, same(delete));
      expect(list.customDialogEditIcon, same(edit));
      expect(list.customLoadingColor, Colors.pink);
      expect(list.dialogDeleteIcon, same(delete));
      expect(list.loadingColor, Colors.pink);
    });

    test('a light theme resolves to exactly those values', () {
      const SimpleSearchbarSettings bar = SimpleSearchbarSettings();
      final BarColors b = BarColors.of(bar, _light);
      expect(b.background, bar.backgroundColor);
      expect(b.hover, bar.hoverColor);
      expect(b.chipBackground, bar.boxMultiSelectedBackgroundColor);
      expect(b.chipTextStyle, isNull);
      expect(b.chipIconColor, isNull);
      expect(b.hintStyle, bar.hintStyle);
      expect(b.shadow, Colors.grey);

      const SimpleOverlaySettings list = SimpleOverlaySettings();
      final ListColors l = ListColors.of(list, _light);
      expect(l.selectedBackground, list.selectedItemBackgroundColor);
      expect(l.selectedHover, list.selectedItemHoverColor);
      expect(l.unselectedHover, list.unselectedItemHoverColor);
      expect(l.highlightedBackground, list.unselectedItemHoverColor);
      expect(l.highlightedBorder, list.highlightedItemBorderColor);
      expect(l.selectedTextStyle, list.selectedItemTextStyle);
      expect(l.unselectedTextStyle, list.unselectedItemTextStyle);
      expect(l.editIcon.color, Colors.black);
      expect(l.deleteIcon.color, const Color.fromRGBO(183, 28, 28, 1));
      expect(l.loading, darkGreen);
    });
  });

  group('dark theme: unset colours follow the ColorScheme', () {
    final ColorScheme scheme = _dark.colorScheme;

    testWidgets('single bar: surfaceContainerHigh, onSurfaceVariant hint', (
      tester,
    ) async {
      await _pumpSingle(tester, _single());
      final SearchBar bar = _bar(tester);
      expect(
        bar.backgroundColor!.resolve(<WidgetState>{}),
        scheme.surfaceContainerHigh,
      );
      expect(
        bar.overlayColor!.resolve(<WidgetState>{}),
        scheme.onSurface.withAlpha(20),
      );
      final TextStyle hint = bar.hintStyle!.resolve(<WidgetState>{})!;
      expect(hint.color, scheme.onSurfaceVariant);
      // The stock 14 px size is kept.
      expect(hint.fontSize, 14);
    });

    testWidgets('single rows: selected, highlighted, unselected and icons', (
      tester,
    ) async {
      final List<ValueItem<int>> items = fruitItems();
      final SearchDropDownController<int> c = _single(initial: items[0]);
      await _pumpSingle(tester, c);
      await openSingle(tester);
      // Arrow keys move the highlight to Banana (the selection stays Maçã).
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pumpAndSettle();
      expect(c.highlightedIndex, 1);

      expect(_rowBackground(tester, 'Maçã'), scheme.secondaryContainer);
      expect(_rowTextColor(tester, 'Maçã'), scheme.onSecondaryContainer);

      expect(_rowBackground(tester, 'Banana'), scheme.onSurface.withAlpha(20));
      expect(_rowTextColor(tester, 'Banana'), scheme.onSecondaryContainer);
      final RoundedRectangleBorder shape =
          _rowStyle(tester, 'Banana').shape!.resolve(<WidgetState>{})!
              as RoundedRectangleBorder;
      expect(shape.side.color, scheme.outline);

      expect(_rowBackground(tester, 'Uva'), Colors.transparent);
      expect(_rowTextColor(tester, 'Uva'), scheme.onSurfaceVariant);
      expect(
        _rowStyle(tester, 'Uva').overlayColor!.resolve(<WidgetState>{}),
        scheme.onSurface.withAlpha(20),
      );
      expect(
        _rowStyle(tester, 'Maçã').overlayColor!.resolve(<WidgetState>{}),
        scheme.onSecondaryContainer.withAlpha(31),
      );
      expect(_rowIconColor(tester, 'Uva', Icons.edit), scheme.onSurfaceVariant);
      expect(_rowIconColor(tester, 'Uva', Icons.delete), scheme.error);
    });

    testWidgets('multiple box, chips and list', (tester) async {
      await _pumpMultiple(tester);
      final BoxDecoration box = _boxDecoration(tester);
      expect(box.color, scheme.surfaceContainerHigh);
      expect(box.boxShadow!.single.color, Colors.black.withAlpha(125));

      final Card chip = tester.widget<Card>(
        find.ancestor(of: find.text('Maçã'), matching: find.byType(Card)),
      );
      expect(chip.color, scheme.secondaryContainer);
      expect(
        tester.widget<Text>(find.text('Maçã')).style?.color,
        scheme.onSecondaryContainer,
      );
      expect(
        tester.widget<Icon>(find.byIcon(Icons.close).first).color,
        scheme.onSecondaryContainer,
      );

      await openMultiple(tester);
      final SearchBar field = _bar(tester);
      expect(
        field.backgroundColor!.resolve(<WidgetState>{}),
        scheme.surfaceContainerHigh,
      );
      expect(
        field.hintStyle!.resolve(<WidgetState>{})!.color,
        scheme.onSurfaceVariant,
      );
      expect(
        field.overlayColor!.resolve(<WidgetState>{}),
        scheme.onSurface.withAlpha(20),
      );
      expect(_rowBackground(tester, 'Maçã'), scheme.secondaryContainer);
      expect(_rowTextColor(tester, 'Banana'), scheme.onSurfaceVariant);
    });

    testWidgets('the multiple hint, without a selection', (tester) async {
      await _pumpMultiple(tester, selected: const <int>[]);
      expect(
        tester.widget<Text>(find.text('Pesquisar')).style?.color,
        scheme.onSurfaceVariant,
      );
    });

    testWidgets('the row spinner is colorScheme.primary', (tester) async {
      final Completer<void> pending = Completer<void>();
      await _pumpSingle(tester, _single(onDeleteItem: (_) => pending.future));
      await openSingle(tester);
      await tester.tap(
        find.descendant(of: _row('Uva'), matching: find.byIcon(Icons.delete)),
      );
      await tester.pump();
      expect(
        tester
            .widget<CircularProgressIndicator>(
              find.byType(CircularProgressIndicator),
            )
            .color,
        scheme.primary,
      );
      pending.complete();
      await tester.pumpAndSettle();
    });
  });

  group('dark theme: colours set in the settings win', () {
    testWidgets('bar, rows, icons and spinner', (tester) async {
      final Completer<void> pending = Completer<void>();
      final List<ValueItem<int>> items = fruitItems();
      await _pumpSingle(
        tester,
        _single(initial: items[0], onDeleteItem: (_) => pending.future),
        bar: const SimpleSearchbarSettings(
          backgroundColor: Colors.amber,
          hoverColor: Colors.lime,
          hintStyle: TextStyle(color: Colors.pink),
        ),
        list: const SimpleOverlaySettings(
          dialogHeight: 400,
          selectedItemBackgroundColor: Colors.purple,
          selectedItemTextStyle: TextStyle(color: Colors.yellow),
          unselectedItemTextStyle: TextStyle(color: Colors.cyan),
          dialogEditIcon: Icon(Icons.edit, color: Colors.orange),
          dialogDeleteIcon: Icon(Icons.delete, color: Colors.brown),
          loadingColor: Colors.teal,
        ),
      );
      final SearchBar bar = _bar(tester);
      expect(bar.backgroundColor!.resolve(<WidgetState>{}), Colors.amber);
      expect(bar.overlayColor!.resolve(<WidgetState>{}), Colors.lime);
      expect(bar.hintStyle?.resolve(<WidgetState>{})?.color, Colors.pink);

      await openSingle(tester);
      expect(_rowBackground(tester, 'Maçã'), Colors.purple);
      expect(_rowTextColor(tester, 'Maçã'), Colors.yellow);
      expect(_rowTextColor(tester, 'Uva'), Colors.cyan);
      expect(_rowIconColor(tester, 'Uva', Icons.edit), Colors.orange);
      expect(_rowIconColor(tester, 'Uva', Icons.delete), Colors.brown);

      await tester.tap(
        find.descendant(of: _row('Uva'), matching: find.byIcon(Icons.delete)),
      );
      await tester.pump();
      expect(
        tester
            .widget<CircularProgressIndicator>(
              find.byType(CircularProgressIndicator),
            )
            .color,
        Colors.teal,
      );
      pending.complete();
      await tester.pumpAndSettle();
    });

    test('a hint style with a color, chip colours and a highlight colour', () {
      final ColorScheme scheme = _dark.colorScheme;
      final BarColors b = BarColors.of(
        const SimpleSearchbarSettings(
          hintStyle: TextStyle(color: Colors.pink, fontSize: 12),
          boxMultiSelectedBackgroundColor: Colors.teal,
          boxMultiSelectedTextStyle: TextStyle(color: Colors.white),
          boxMultiSelectedClearIconColor: Colors.white70,
        ),
        _dark,
      );
      expect(b.hintStyle, const TextStyle(color: Colors.pink, fontSize: 12));
      expect(b.chipBackground, Colors.teal);
      expect(b.chipTextStyle?.color, Colors.white);
      expect(b.chipIconColor, Colors.white70);

      final ListColors l = ListColors.of(
        const SimpleOverlaySettings(
          highlightedItemBackgroundColor: Colors.red,
          highlightedItemBorderColor: Colors.blue,
          selectedItemHoverColor: Colors.orange,
          unselectedItemHoverColor: Colors.green,
        ),
        _dark,
      );
      expect(l.highlightedBackground, Colors.red);
      expect(l.highlightedBorder, Colors.blue);
      expect(l.selectedHover, Colors.orange);
      expect(l.unselectedHover, Colors.green);
      // A custom hover colour keeps the selected fill on the highlighted row,
      // as under a light theme.
      expect(
        ListColors.of(
          const SimpleOverlaySettings(unselectedItemHoverColor: Colors.green),
          _dark,
        ).highlightedBackground,
        scheme.secondaryContainer,
      );
    });
  });

  group('dark theme: AA contrast of the default pairs', () {
    for (final MapEntry<String, ThemeData> entry in _darkThemes.entries) {
      test(entry.key, () {
        final ThemeData theme = entry.value;
        final ColorScheme scheme = theme.colorScheme;
        final BarColors b = BarColors.of(defaultSearchBarSettings, theme);
        final ListColors l = ListColors.of(defaultOverlaySettings, theme);
        final Color surface = b.background;
        final Color highlighted = Color.alphaBlend(
          l.highlightedBackground,
          surface,
        );

        // Text: at least 4.5:1.
        final Map<String, double> text = <String, double>{
          'hint on bar': _contrast(b.hintStyle!.color!, surface),
          'typed text on bar': _contrast(scheme.onSurface, surface),
          'chip label on chip': _contrast(
            b.chipTextStyle!.color!,
            b.chipBackground,
          ),
          'row label on list': _contrast(
            l.unselectedTextStyle!.color!,
            surface,
          ),
          'selected label on selected row': _contrast(
            l.selectedTextStyle!.color!,
            l.selectedBackground,
          ),
          'highlighted label on highlighted row': _contrast(
            l.selectedTextStyle!.color!,
            highlighted,
          ),
        };
        for (final MapEntry<String, double> pair in text.entries) {
          expect(pair.value, greaterThanOrEqualTo(4.5), reason: pair.key);
        }

        // Icons, the spinner and the highlight border: at least 3:1.
        final Map<String, double> graphics = <String, double>{
          'edit icon': _contrast(l.editIcon.color!, surface),
          'delete icon': _contrast(l.deleteIcon.color!, surface),
          'spinner': _contrast(l.loading, surface),
          'highlight border': _contrast(l.highlightedBorder, highlighted),
          'chip remove icon': _contrast(b.chipIconColor!, b.chipBackground),
        };
        for (final MapEntry<String, double> pair in graphics.entries) {
          expect(pair.value, greaterThanOrEqualTo(3), reason: pair.key);
        }
      });
    }
  });

  group('row spinner', () {
    test('defaults to 24 px with a 2.5 stroke', () {
      const SimpleOverlaySettings list = SimpleOverlaySettings();
      expect(list.loadingSize, 24);
      expect(list.loadingStrokeWidth, 2.5);
    });

    testWidgets('the busy row shows a 24 px, 2.5 stroke, darkGreen ring', (
      tester,
    ) async {
      final Completer<void> pending = Completer<void>();
      await _pumpSingle(
        tester,
        _single(onDeleteItem: (_) => pending.future),
        theme: _light,
      );
      await openSingle(tester);
      await tester.tap(
        find.descendant(of: _row('Uva'), matching: find.byIcon(Icons.delete)),
      );
      await tester.pump();
      final Finder spinner = find.descendant(
        of: _row('Uva'),
        matching: find.byType(CircularProgressIndicator),
      );
      final CircularProgressIndicator ring = tester.widget(spinner);
      expect(ring.color, darkGreen);
      expect(ring.strokeWidth, 2.5);
      expect(tester.getSize(spinner), const Size(24, 24));
      pending.complete();
      await tester.pumpAndSettle();
    });

    testWidgets('loadingStrokeWidth sets the ring stroke', (tester) async {
      final Completer<void> pending = Completer<void>();
      await _pumpSingle(
        tester,
        _single(onDeleteItem: (_) => pending.future),
        list: const SimpleOverlaySettings(
          dialogHeight: 400,
          loadingStrokeWidth: 4,
        ),
      );
      await openSingle(tester);
      await tester.tap(
        find.descendant(of: _row('Uva'), matching: find.byIcon(Icons.delete)),
      );
      await tester.pump();
      expect(
        tester
            .widget<CircularProgressIndicator>(
              find.byType(CircularProgressIndicator),
            )
            .strokeWidth,
        4,
      );
      pending.complete();
      await tester.pumpAndSettle();
    });
  });

  group('golden: dark theme', () {
    Future<void> matches(String name) => expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/$name.png'),
    );

    testWidgets('single closed', (tester) async {
      await _pumpSingle(tester, _single());
      expect(find.text('Pesquisar'), findsOneWidget);
      await matches('dark_single_closed');
    }, tags: <String>['golden']);

    testWidgets('single open with a selection and a keyboard highlight', (
      tester,
    ) async {
      final List<ValueItem<int>> items = fruitItems();
      final SearchDropDownController<int> c = _single(initial: items[0]);
      await _pumpSingle(tester, c);
      await openSingle(tester);
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pumpAndSettle();
      expect(c.highlightedIndex, 1);
      await matches('dark_single_open_highlight');
    }, tags: <String>['golden']);

    testWidgets('multiple with chips and the open list', (tester) async {
      await _pumpMultiple(tester);
      await openMultiple(tester);
      await matches('dark_multiple_open_chips');
    }, tags: <String>['golden']);

    testWidgets('delete confirmation', (tester) async {
      await _pumpSingle(tester, _single(confirmDelete: true));
      await openSingle(tester);
      await tester.tap(
        find.descendant(
          of: _row('Banana'),
          matching: find.byIcon(Icons.delete),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.byType(WarningDialog), findsOneWidget);
      await matches('dark_delete_confirm_dialog');
    }, tags: <String>['golden']);
  });
}
