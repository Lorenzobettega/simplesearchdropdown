// Drives the example app through the user journeys that
// simple_search_dropdown 8.0 must keep working.
//
// The example keeps its data in global mutable lists (lib/listitems.dart);
// every test restores a snapshot of them in setUp so tests stay independent.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:simple_search_dropdown/simple_search_dropdown.dart';
import 'package:simple_search_dropdown_example/custom.dart';
import 'package:simple_search_dropdown_example/listitems.dart';
import 'package:simple_search_dropdown_example/main.dart';

// ----------------------------------------------------------------- helpers --

/// Pumps the example app on a surface tall enough to show every button.
Future<void> _pumpApp(WidgetTester tester) async {
  tester.view.physicalSize = const Size(1000, 1800);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(const MyApp());
  await tester.pumpAndSettle();
}

/// The first single dropdown (`SearchDropDown<dynamic>` with `listitems`).
Finder get _single => find.byType(SearchDropDown<dynamic>);

/// The custom single dropdown (`SearchDropDown<Custom>`).
Finder get _custom => find.byType(SearchDropDown<Custom>);

/// The multiple dropdown (`MultipleSearchDropDown<dynamic>`).
Finder get _multiple => find.byType(MultipleSearchDropDown<dynamic>);

/// The open multiple overlay list.
Finder get _multipleOverlay => find.byWidgetPredicate(
      (w) => w.runtimeType.toString() == 'MultipleListView<dynamic>',
    );

Finder _barOf(Finder dropdown) =>
    find.descendant(of: dropdown, matching: find.byType(SearchBar));

/// Text currently shown in the closed bar of a single dropdown.
String _barText(WidgetTester tester, Finder dropdown) => tester
    .widget<EditableText>(
      find.descendant(of: dropdown, matching: find.byType(EditableText)),
    )
    .controller
    .text;

/// Whether a [SearchAnchor] `IgnorePointer` blocks input to [dropdown]'s bar
/// (that is how `enabled: false` is rendered; the [SearchBar] itself keeps
/// `enabled: true`).
bool _barIgnoresPointer(WidgetTester tester, Finder dropdown) => tester
    .widgetList<IgnorePointer>(
      find.ancestor(of: _barOf(dropdown), matching: find.byType(IgnorePointer)),
    )
    .any((w) => w.ignoring);

/// The text field that currently has focus (header of an open search view).
Finder _focusedField() => find.byWidgetPredicate(
      (w) => w is EditableText && w.focusNode.hasFocus,
    );

/// A row (item button) with [label] inside the open single search view.
Finder _viewItem(String label) => find.widgetWithText(TextButton, label);

/// A row (item button) with [label] inside the open multiple overlay.
Finder _overlayItem(String label) => find.descendant(
      of: _multipleOverlay,
      matching: find.widgetWithText(TextButton, label),
    );

/// A chip with [label] inside the closed multiple box.
Finder _chip(String label) =>
    find.descendant(of: _multiple, matching: find.text(label));

Future<void> _tapButton(WidgetTester tester, String text) async {
  await tester.tap(find.widgetWithText(TextButton, text));
  await tester.pumpAndSettle();
}

Future<void> _openSingleView(WidgetTester tester, Finder dropdown) async {
  await tester.tap(_barOf(dropdown));
  await tester.pumpAndSettle();
}

Future<void> _openMultiple(WidgetTester tester) async {
  await tester.tap(
    find.descendant(of: _multiple, matching: find.byType(InkWell)).first,
  );
  await tester.pumpAndSettle();
}

/// Taps the full-screen transparent barrier of the multiple overlay.
Future<void> _closeMultiple(WidgetTester tester) async {
  await tester.tapAt(const Offset(5, 5));
  await tester.pumpAndSettle();
}

/// Runs [body] and returns everything the example app `print`ed meanwhile.
Future<List<String>> _capturePrints(Future<void> Function() body) async {
  final List<String> lines = <String>[];
  await runZoned(
    body,
    zoneSpecification: ZoneSpecification(
      print: (self, parent, zone, line) => lines.add(line),
    ),
  );
  return lines;
}

/// The vertical list of suggestions of the open single search view.
Finder get _viewList => find
    .byWidgetPredicate(
      (w) => w is Scrollable && w.axisDirection == AxisDirection.down,
    )
    .last;

/// Adds [label] through the multiple dropdown's add row ('Criar').
Future<void> _addThroughMultiple(WidgetTester tester, String label) async {
  await _openMultiple(tester);
  await tester.enterText(
    find.descendant(of: _multipleOverlay, matching: find.byType(SearchBar)),
    label,
  );
  await tester.pump();
  await tester.tap(
    find.descendant(
      of: _multipleOverlay,
      matching: find.widgetWithText(TextButton, 'Criar'),
    ),
  );
  await tester.pump();
  await _closeMultiple(tester);
}

// ------------------------------------------------------------------- tests --

void main() {
  late List<ValueItem<dynamic>> listSnapshot;
  late List<ValueItem<Custom>> customSnapshot;

  setUpAll(() {
    listSnapshot = List<ValueItem<dynamic>>.of(listitems);
    customSnapshot = List<ValueItem<Custom>>.of(customListitems);
  });

  setUp(() {
    listitems
      ..clear()
      ..addAll(listSnapshot);
    customListitems
      ..clear()
      ..addAll(customSnapshot);
  });

  group('compat: app renders the three dropdowns', () {
    testWidgets('MyApp builds without exceptions', (tester) async {
      await _pumpApp(tester);

      expect(tester.takeException(), isNull);
      expect(_single, findsOneWidget);
      expect(_multiple, findsOneWidget);
      expect(_custom, findsOneWidget);
      expect(find.byType(SearchBar), findsNWidgets(2));
    });

    testWidgets('first single shows initial "Teste"; custom shows "Lorenzo"',
        (tester) async {
      await _pumpApp(tester);

      expect(_barText(tester, _single), 'Teste');
      expect(_barText(tester, _custom), 'Lorenzo');
      // Nothing selected in the multiple box: hint is shown.
      expect(
        find.descendant(of: _multiple, matching: find.text('Pesquisar')),
        findsOneWidget,
      );
    });

    testWidgets('first single uses actions (Icons.abc) as bar trailing',
        (tester) async {
      await _pumpApp(tester);

      expect(
        find.descendant(of: _single, matching: find.byIcon(Icons.abc)),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: _custom,
          matching: find.byIcon(Icons.arrow_drop_down),
        ),
        findsNothing,
        reason: 'custom dropdown uses showArrow: false',
      );
    });

    testWidgets(
        'selectedFirst sort of the first single moves "Teste" to the top of '
        'its list (the shared list keeps its order)', (tester) async {
      await _pumpApp(tester);
      await _tapButton(tester, 'Enable/Disable Single Selection');
      await _openSingleView(tester, _single);

      expect(
        tester.getTopLeft(_viewItem('Teste')).dy,
        lessThan(tester.getTopLeft(_viewItem('Lorenzo')).dy),
      );
      expect(listitems.first.label, 'Lorenzo');
      expect(listitems[1].label, 'Teste');
    });
  });

  group('compat: enable/disable the first single dropdown', () {
    testWidgets('starts disabled: tapping the bar does not open the view',
        (tester) async {
      await _pumpApp(tester);

      expect(_barIgnoresPointer(tester, _single), isTrue);
      expect(_barIgnoresPointer(tester, _custom), isFalse);
      // SearchAnchor dims a disabled bar.
      expect(
        tester
            .widget<AnimatedOpacity>(
              find
                  .ancestor(
                    of: _barOf(_single),
                    matching: find.byType(AnimatedOpacity),
                  )
                  .first,
            )
            .opacity,
        lessThan(1),
      );
      await tester.tap(_barOf(_single), warnIfMissed: false);
      await tester.pumpAndSettle();
      expect(find.byType(SearchBar), findsNWidgets(2));
      expect(_viewItem('Lorenzo'), findsNothing);
    });

    testWidgets('"Enable/Disable Single Selection" enables it and it opens',
        (tester) async {
      await _pumpApp(tester);

      await _tapButton(tester, 'Enable/Disable Single Selection');
      expect(_barIgnoresPointer(tester, _single), isFalse);

      await _openSingleView(tester, _single);
      expect(tester.takeException(), isNull);
      // D1 (8.0): the view lists every item, scrolled to the selected 'Teste'.
      expect(_viewItem('Teste'), findsOneWidget);
      expect(_viewItem('Lorenzo'), findsOneWidget);
    });

    testWidgets('pressing the button twice disables it again', (tester) async {
      await _pumpApp(tester);

      await _tapButton(tester, 'Enable/Disable Single Selection');
      await _tapButton(tester, 'Enable/Disable Single Selection');
      expect(_barIgnoresPointer(tester, _single), isTrue);
    });
  });

  group('compat: "Force Single Selection" / "Clear Single Selection"', () {
    testWidgets('Force selects "one more" on the first single dropdown',
        (tester) async {
      await _pumpApp(tester);

      await _tapButton(tester, 'Force Single Selection');
      expect(_barText(tester, _single), 'one more');

      final List<String> printed = await _capturePrints(
        () => _tapButton(tester, 'Print new Single Selection'),
      );
      expect(printed, <String>['one more']);

      final List<String> result = await _capturePrints(
        () => _tapButton(tester, 'Print Single Result'),
      );
      expect(
        result.first,
        contains('label: one more'),
        reason: 'updateSelectedItem wrote through to the example state',
      );
    });

    testWidgets('Clear Single Selection empties the bar', (tester) async {
      await _pumpApp(tester);

      await _tapButton(tester, 'Clear Single Selection');
      expect(_barText(tester, _single), '');
      final List<String> printed = await _capturePrints(
        () => _tapButton(tester, 'Print new Single Selection'),
      );
      expect(printed, <String>['null']);
    });
  });

  group('compat: custom dropdown select and clear', () {
    testWidgets('open, select "Peter", then "Clear Custom Selection"',
        (tester) async {
      await _pumpApp(tester);

      await _openSingleView(tester, _custom);
      // D1 (8.0): opening lists every item, scrolled to 'Lorenzo'.
      expect(_viewItem('Lorenzo'), findsOneWidget);
      expect(_viewItem('Peter'), findsOneWidget);

      await tester.enterText(_focusedField(), 'Pet');
      await tester.pump();
      expect(_viewItem('Peter'), findsOneWidget);

      await tester.tap(_viewItem('Peter'));
      await tester.pumpAndSettle();
      expect(_viewItem('Lucas'), findsNothing, reason: 'view closed');
      expect(_barText(tester, _custom), 'Peter');

      final List<String> printed = await _capturePrints(
        () => _tapButton(tester, 'Print Custom Result'),
      );
      expect(printed, contains('name: Peter'));

      await _tapButton(tester, 'Clear Custom Selection');
      expect(_barText(tester, _custom), '');
      final List<String> cleared = await _capturePrints(
        () => _tapButton(tester, 'Print Custom Result'),
      );
      expect(cleared, <String>['null']);
    });

    testWidgets('after clearing, opening the custom view lists every item',
        (tester) async {
      await _pumpApp(tester);

      await _tapButton(tester, 'Clear Custom Selection');
      await _openSingleView(tester, _custom);
      for (final String label in <String>['Lorenzo', 'Peter', 'Lucas']) {
        expect(_viewItem(label), findsOneWidget, reason: label);
      }
    });
  });

  group('compat: "Reset custom list" (updateList)', () {
    testWidgets('replaces items with "Reset 1"/"Reset 2" and clears selection',
        (tester) async {
      await _pumpApp(tester);

      await _tapButton(tester, 'Reset custom list');
      expect(_barText(tester, _custom), '');
      expect(
        customListitems.map((e) => e.label).toList(),
        <String>['Reset 1', 'Reset 2'],
        reason: 'the app resets its own list along with the controller',
      );

      await _openSingleView(tester, _custom);
      expect(_viewItem('Reset 1'), findsOneWidget);
      expect(_viewItem('Reset 2'), findsOneWidget);
      expect(_viewItem('Peter'), findsNothing);
      expect(_viewItem('Lorenzo'), findsNothing);
    });

    testWidgets('deleting "Reset 1" after reset (confirm "Apagar") removes it',
        (tester) async {
      await _pumpApp(tester);

      await _tapButton(tester, 'Reset custom list');
      await _openSingleView(tester, _custom);

      await tester.tap(
        find.descendant(
          of: find.byWidgetPredicate(
            (w) => w is DefaultListTile<Custom> && w.item.label == 'Reset 1',
          ),
          matching: find.byIcon(Icons.delete),
        ),
      );
      // The tile shows an endless spinner while the dialog is up, so no
      // pumpAndSettle here.
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.byType(AlertDialog), findsOneWidget);
      expect(find.text('Cancelar'), findsOneWidget);

      await tester.tap(find.text('Apagar'));
      await tester.pump();
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.byType(AlertDialog), findsNothing);
      expect(
        customListitems.map((e) => e.label).toList(),
        <String>['Reset 2'],
      );
      expect(_viewItem('Reset 1'), findsNothing);
      expect(_viewItem('Reset 2'), findsOneWidget);
    });
  });

  group('compat: multiple dropdown select, clear and force', () {
    testWidgets('open, select two items, chips appear', (tester) async {
      await _pumpApp(tester);

      await _openMultiple(tester);
      expect(_multipleOverlay, findsOneWidget);
      await tester.tap(_overlayItem('Teste'));
      await tester.pump();
      await tester.tap(_overlayItem('Lorenzo'));
      await tester.pump();
      await _closeMultiple(tester);

      expect(_multipleOverlay, findsNothing);
      expect(_chip('Teste'), findsOneWidget);
      expect(_chip('Lorenzo'), findsOneWidget);
      expect(
        find.descendant(of: _multiple, matching: find.byIcon(Icons.close)),
        findsNWidgets(2),
      );

      final List<String> printed = await _capturePrints(
        () => _tapButton(tester, 'Print Multiple Result'),
      );
      expect(printed.single, contains('label: Teste'));
      expect(printed.single, contains('label: Lorenzo'));
    });

    testWidgets('"Clear Multiple Selection" removes every chip',
        (tester) async {
      await _pumpApp(tester);

      await _openMultiple(tester);
      await tester.tap(_overlayItem('Teste'));
      await tester.pump();
      await tester.tap(_overlayItem('Lorenzo'));
      await tester.pump();
      await _closeMultiple(tester);

      await _tapButton(tester, 'Clear Multiple Selection');
      expect(_chip('Teste'), findsNothing);
      expect(_chip('Lorenzo'), findsNothing);
      expect(
        find.descendant(of: _multiple, matching: find.text('Pesquisar')),
        findsOneWidget,
      );
    });

    testWidgets('"Force Multiple Selection" selects "one more"',
        (tester) async {
      await _pumpApp(tester);

      await _tapButton(tester, 'Force Multiple Selection');
      expect(_chip('one more'), findsOneWidget);

      // Forcing again does not toggle it off.
      await _tapButton(tester, 'Force Multiple Selection');
      expect(_chip('one more'), findsOneWidget);
    });

    testWidgets('chip close icon fires onClearItem; clear icon fires onClear',
        (tester) async {
      await _pumpApp(tester);

      await _tapButton(tester, 'Force Multiple Selection');
      final List<String> itemCleared = await _capturePrints(() async {
        await tester.tap(
          find.descendant(of: _multiple, matching: find.byIcon(Icons.close)),
        );
        await tester.pumpAndSettle();
      });
      expect(itemCleared, <String>['item clear']);
      expect(_chip('one more'), findsNothing);

      await _tapButton(tester, 'Force Multiple Selection');
      final List<String> listCleared = await _capturePrints(() async {
        await tester.tap(
          find.descendant(of: _multiple, matching: find.byIcon(Icons.clear)),
        );
        await tester.pumpAndSettle();
      });
      expect(listCleared, <String>['clear']);
      expect(_chip('one more'), findsNothing);
    });
  });

  group('compat: shared list between multiple and first single', () {
    testWidgets(
        'item added via the multiple "Criar" row is in the shared list '
        'and selected', (tester) async {
      await _pumpApp(tester);

      await _addThroughMultiple(tester, 'Novo item');

      expect(tester.takeException(), isNull);
      expect(listitems.last.label, 'Novo item');
      expect(listitems.where((e) => e.label == 'Novo item'), hasLength(1));
      expect(_chip('Novo item'), findsOneWidget);
    });

    testWidgets(
        'after clearing the single, enabling and opening it shows the '
        'item added via the multiple dropdown', (tester) async {
      await _pumpApp(tester);

      await _addThroughMultiple(tester, 'Novo item');
      await _tapButton(tester, 'Clear Single Selection');
      await _tapButton(tester, 'Enable/Disable Single Selection');
      await _openSingleView(tester, _single);

      await tester.scrollUntilVisible(
        _viewItem('Novo item'),
        500,
        scrollable: _viewList,
      );
      expect(tester.takeException(), isNull);
      expect(_viewItem('Novo item'), findsOneWidget);

      await tester.tap(_viewItem('Novo item'));
      await tester.pumpAndSettle();
      expect(_barText(tester, _single), 'Novo item');
    });

    testWidgets(
      'enabling and opening the single (text "Teste") shows a matching item '
      'added via the multiple dropdown',
      (tester) async {
        await _pumpApp(tester);

        await _addThroughMultiple(tester, 'Teste novo');
        await _tapButton(tester, 'Enable/Disable Single Selection');
        await _openSingleView(tester, _single);
        expect(tester.takeException(), isNull);
        // D1 (8.0): the view lists everything; narrow it to both matches.
        await tester.enterText(_focusedField(), 'test');
        await tester.pump();

        expect(tester.takeException(), isNull);
        expect(_viewItem('Teste'), findsOneWidget);
        expect(_viewItem('Teste novo'), findsOneWidget);
      }, // compat: fixed in 8.0 (lazy label cache)
    );

    testWidgets(
      'typing in the single filters to an item added via the multiple dropdown',
      (tester) async {
        await _pumpApp(tester);

        await _addThroughMultiple(tester, 'Novo item');
        await _tapButton(tester, 'Clear Single Selection');
        await _tapButton(tester, 'Enable/Disable Single Selection');
        await _openSingleView(tester, _single);
        await tester.enterText(_focusedField(), 'Novo');
        await tester.pump();

        expect(tester.takeException(), isNull);
        expect(_viewItem('Novo item'), findsOneWidget);
        expect(_viewItem('Lorenzo'), findsNothing);
      },
      // compat: fixed in 8.0 (lazy label cache)
    );
  });

  group('compat: add through the first single (2s async onAddItem)', () {
    testWidgets('typed label + "Criar" adds to the shared list after 2s',
        (tester) async {
      await _pumpApp(tester);

      await _tapButton(tester, 'Enable/Disable Single Selection');
      await _openSingleView(tester, _single);
      await tester.enterText(_focusedField(), 'Single novo');
      await tester.pump();
      await tester.tap(_viewItem('Criar'));
      await tester.pump();
      expect(listitems.where((e) => e.label == 'Single novo'), isEmpty);

      await tester.pump(const Duration(seconds: 2));
      await tester.pumpAndSettle();
      expect(listitems.last.label, 'Single novo');
      expect(_barText(tester, _single), 'Single novo');

      await _openMultiple(tester);
      await tester.enterText(
        find.descendant(of: _multipleOverlay, matching: find.byType(SearchBar)),
        'Single',
      );
      await tester.pump();
      expect(_overlayItem('Single novo'), findsOneWidget);
    });
  });

  group('compat: "Open Dialog" with a dropdown inside a dialog', () {
    testWidgets('dialog opens; its dropdown lists the shared items',
        (tester) async {
      await _pumpApp(tester);

      await _tapButton(tester, 'Open Dialog');
      expect(find.text('Dialog Test'), findsOneWidget);
      final Finder dialogDropdown = find.descendant(
        of: find.byType(Dialog),
        matching: find.byType(SearchDropDown<dynamic>),
      );
      expect(dialogDropdown, findsOneWidget);
      expect(_barText(tester, dialogDropdown), '');

      await _openSingleView(tester, dialogDropdown);
      expect(tester.takeException(), isNull);
      expect(_viewItem('Teste'), findsOneWidget);
      await tester.tap(_viewItem('Teste'));
      await tester.pumpAndSettle();
      expect(_barText(tester, dialogDropdown), 'Teste');
    });
  });
}
