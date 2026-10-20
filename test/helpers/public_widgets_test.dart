// Exported widgets and values the dropdown suites only use indirectly:
// ClearButton, Loading, DefaultListTile(highlighted:), darkGreen,
// CustomScrollBehavior, the SearchDropDownState type, and the shared
// enabled/dispose state both controllers inherit from DropDownControllerBase.

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:simple_search_dropdown/simple_search_dropdown.dart';
import 'package:simple_search_dropdown/src/core/controller_base.dart';

import '../support/harness.dart';

TextStyle _glyph(WidgetTester tester, IconData icon) => tester
    .widget<RichText>(
      find.descendant(of: find.byIcon(icon), matching: find.byType(RichText)),
    )
    .text
    .style!;

const ValueItem<int> _uva = ValueItem(label: 'Uva', value: 3);

Widget _tile({
  bool selected = false,
  bool highlighted = false,
  SimpleOverlaySettings settings = const SimpleOverlaySettings(),
}) => host(
  SizedBox(
    width: 300,
    child: DefaultListTile<int>(
      deleteMode: false,
      editMode: false,
      item: _uva,
      onDelete: (_) {},
      onEdit: (_) {},
      onPressed: (_) {},
      overlayListSettings: settings,
      selected: selected,
      highlighted: highlighted,
    ),
  ),
);

/// The Material the row's TextButton paints with.
Material _rowMaterial(WidgetTester tester) => tester.widget<Material>(
  find.descendant(of: find.byType(TextButton), matching: find.byType(Material)),
);

TextStyle _labelStyle(WidgetTester tester) => tester
    .widget<RichText>(
      find.descendant(
        of: find.text('Uva'),
        matching: find.byType(RichText),
        matchRoot: true,
      ),
    )
    .text
    .style!;

SearchDropDownController<int> _single({bool enabled = true}) =>
    SearchDropDownController<int>(
      items: fruitItems(),
      addMode: false,
      deleteMode: false,
      enabled: enabled,
    );

MultipleSearchDropDownController<int> _multiple({bool enabled = true}) =>
    MultipleSearchDropDownController<int>(
      items: fruitItems(),
      addMode: false,
      deleteMode: false,
      enabled: enabled,
    );

void main() {
  group('ClearButton', () {
    testWidgets('visible: paints the clear icon and taps call onPressed', (
      tester,
    ) async {
      int taps = 0;
      await tester.pumpWidget(
        host(
          ClearButton(
            visible: true,
            onPressed: () => taps++,
            iconColor: Colors.pink,
            iconSize: 33,
            tooltip: 'Limpar',
          ),
        ),
      );
      final TextStyle g = _glyph(tester, Icons.clear);
      expect(g.color, Colors.pink);
      expect(g.fontSize, 33);
      expect(find.byTooltip('Limpar'), findsOneWidget);
      await tester.tap(find.byType(ClearButton));
      expect(taps, 1);
    });

    testWidgets('not visible: nothing is shown, laid out or tappable', (
      tester,
    ) async {
      await tester.pumpWidget(
        host(
          ClearButton(
            visible: false,
            onPressed: () {},
            iconColor: null,
            iconSize: 24,
          ),
        ),
      );
      expect(find.byIcon(Icons.clear), findsNothing);
      expect(tester.getSize(find.byType(ClearButton)), Size.zero);
    });

    testWidgets('without tooltip there is no tooltip', (tester) async {
      await tester.pumpWidget(
        host(
          ClearButton(
            visible: true,
            onPressed: () {},
            iconColor: null,
            iconSize: 24,
          ),
        ),
      );
      expect(find.byType(Tooltip), findsNothing);
    });
  });

  group('Loading', () {
    testWidgets('a square indicator in cor, announced by semanticsLabel', (
      tester,
    ) async {
      final SemanticsHandle semantics = tester.ensureSemantics();
      await tester.pumpWidget(
        host(
          const SizedBox(
            width: 40,
            child: Loading(cor: Colors.teal, semanticsLabel: 'Carregando'),
          ),
        ),
      );
      expect(tester.getSize(find.byType(Loading)), const Size(40, 40));
      expect(
        tester
            .widget<CircularProgressIndicator>(
              find.byType(CircularProgressIndicator),
            )
            .color,
        Colors.teal,
      );
      expect(find.bySemanticsLabel('Carregando'), findsOneWidget);
      semantics.dispose();
    });
  });

  group('darkGreen', () {
    test('is the 7.x green and the default loadingColor', () {
      expect(darkGreen, const Color.fromARGB(255, 0, 67, 0));
      expect(const SimpleOverlaySettings().loadingColor, darkGreen);
    });
  });

  group('DefaultListTile(highlighted:)', () {
    testWidgets('not highlighted: transparent, no border, unselected style', (
      tester,
    ) async {
      await tester.pumpWidget(_tile());
      expect(_rowMaterial(tester).color, Colors.transparent);
      expect(
        (_rowMaterial(tester).shape! as RoundedRectangleBorder).side,
        BorderSide.none,
      );
      expect(_labelStyle(tester).color, Colors.black45);
    });

    testWidgets('highlighted: hover fill, border and the selected text style', (
      tester,
    ) async {
      await tester.pumpWidget(_tile(highlighted: true));
      expect(
        _rowMaterial(tester).color,
        const Color.fromRGBO(245, 245, 245, 1),
      );
      expect(
        (_rowMaterial(tester).shape! as RoundedRectangleBorder).side,
        const BorderSide(color: Colors.black26),
      );
      expect(_labelStyle(tester).color, Colors.black);
    });

    testWidgets('highlightedItemBackgroundColor wins for a highlighted row', (
      tester,
    ) async {
      await tester.pumpWidget(
        _tile(
          highlighted: true,
          settings: const SimpleOverlaySettings(
            highlightedItemBackgroundColor: Colors.cyan,
            highlightedItemBorderColor: Colors.red,
          ),
        ),
      );
      expect(_rowMaterial(tester).color, Colors.cyan);
      expect(
        (_rowMaterial(tester).shape! as RoundedRectangleBorder).side,
        const BorderSide(color: Colors.red),
      );
    });

    testWidgets('a highlighted selected row keeps the selected fill', (
      tester,
    ) async {
      await tester.pumpWidget(_tile(highlighted: true, selected: true));
      expect(_rowMaterial(tester).color, Colors.black38);
      expect(
        (_rowMaterial(tester).shape! as RoundedRectangleBorder).side,
        const BorderSide(color: Colors.black26),
      );
    });
  });

  group('CustomScrollBehavior', () {
    test('drags with touch and mouse', () {
      expect(CustomScrollBehavior().dragDevices, {
        PointerDeviceKind.touch,
        PointerDeviceKind.mouse,
      });
    });

    testWidgets('a mouse drag scrolls a list under it', (tester) async {
      final ScrollController sc = ScrollController();
      addTearDown(sc.dispose);
      await tester.pumpWidget(
        host(
          ScrollConfiguration(
            behavior: CustomScrollBehavior(),
            child: SizedBox(
              height: 200,
              child: ListView(
                controller: sc,
                children: [
                  for (int i = 0; i < 30; i++)
                    SizedBox(height: 50, child: Text('row $i')),
                ],
              ),
            ),
          ),
        ),
      );
      await tester.drag(
        find.byType(ListView),
        const Offset(0, -150),
        kind: PointerDeviceKind.mouse,
      );
      await tester.pumpAndSettle();
      expect(sc.offset, greaterThan(0));
    });
  });

  group('SearchDropDownState', () {
    testWidgets('a GlobalKey<SearchDropDownState> resolves to the state', (
      tester,
    ) async {
      final SearchDropDownController<int> c = _single();
      addTearDown(c.dispose);
      final GlobalKey<SearchDropDownState<int>> key = GlobalKey();
      await tester.pumpWidget(
        host(SearchDropDown<int>(key: key, controller: c)),
      );
      final SearchDropDownState<int> state = key.currentState!;
      expect(state.mounted, isTrue);
      expect(state.widget.controller, same(c));
    });
  });

  group('enabled and dispose state shared by both controllers', () {
    final Map<String, DropDownControllerBase Function({bool enabled})>
    controllers = {
      'SearchDropDownController': _single,
      'MultipleSearchDropDownController': _multiple,
    };

    for (final MapEntry<String, DropDownControllerBase Function({bool enabled})>
        e
        in controllers.entries) {
      test('${e.key} starts with the given enabled', () {
        final DropDownControllerBase on = e.value();
        final DropDownControllerBase off = e.value(enabled: false);
        addTearDown(on.dispose);
        addTearDown(off.dispose);
        expect(on.enabled, isTrue);
        expect(off.enabled, isFalse);
      });

      test('${e.key}: setting enabled notifies only on a change', () {
        int notified = 0;
        final DropDownControllerBase c = e.value()
          ..addListener(() => notified++);
        addTearDown(c.dispose);
        c.enabled = true;
        expect(notified, 0);
        c.enabled = false;
        expect(c.enabled, isFalse);
        expect(notified, 1);
      });

      test('${e.key}: toggleEnabled flips enabled and notifies', () {
        int notified = 0;
        final DropDownControllerBase c = e.value()
          ..addListener(() => notified++);
        addTearDown(c.dispose);
        c.toggleEnabled();
        expect(c.enabled, isFalse);
        c.toggleEnabled();
        expect(c.enabled, isTrue);
        expect(notified, 2);
      });

      test('${e.key}: isDisposed after dispose; a second dispose is a no-op; '
          'later notifications are dropped', () {
        final DropDownControllerBase c = e.value();
        expect(c.isDisposed, isFalse);
        c.dispose();
        expect(c.isDisposed, isTrue);
        expect(c.dispose, returnsNormally);
        expect(c.isDisposed, isTrue);
        expect(c.notifyListeners, returnsNormally);
        expect(() => c.enabled = false, returnsNormally);
      });
    }
  });
}
