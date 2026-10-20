// Drives the example app through its demo flows: every button, the three
// dropdowns, the list the app shares between the single and the multiple
// dropdown (kept in step through callbacks + updateListItems) and the dialog.
//
// The app copies its initial data, so every test starts from the same state.

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

/// The first single dropdown (over the shared list).
Finder get _single => find.byType(SearchDropDown<dynamic>);

/// The custom single dropdown (`SearchDropDown<Custom>`).
Finder get _custom => find.byType(SearchDropDown<Custom>);

/// The multiple dropdown (over the shared list).
Finder get _multiple => find.byType(MultipleSearchDropDown<dynamic>);

/// The open multiple overlay list.
Finder get _multipleOverlay => find.byWidgetPredicate(
      (w) => w.runtimeType.toString() == 'MultipleListView<dynamic>',
    );

SearchDropDownController<dynamic> _singleController(WidgetTester tester) =>
    tester.widget<SearchDropDown<dynamic>>(_single).controller;

SearchDropDownController<Custom> _customController(WidgetTester tester) =>
    tester.widget<SearchDropDown<Custom>>(_custom).controller;

MultipleSearchDropDownController<dynamic> _multipleController(
  WidgetTester tester,
) =>
    tester.widget<MultipleSearchDropDown<dynamic>>(_multiple).controller;

List<String> _labels(Iterable<ValueItem<dynamic>> items) =>
    items.map((e) => e.label).toList();

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
/// (that is how `enabled: false` is rendered).
bool _barIgnoresPointer(WidgetTester tester, Finder dropdown) => tester
    .widgetList<IgnorePointer>(
      find.ancestor(of: _barOf(dropdown), matching: find.byType(IgnorePointer)),
    )
    .any((w) => w.ignoring);

/// The text field that currently has focus (header of an open search view).
Finder _focusedField() =>
    find.byWidgetPredicate((w) => w is EditableText && w.focusNode.hasFocus);

/// A row (item button) with [label] inside the open single search view.
Finder _viewItem(String label) => find.widgetWithText(TextButton, label);

/// A row (item button) with [label] inside the open multiple overlay.
Finder _overlayItem(String label) => find.descendant(
      of: _multipleOverlay,
      matching: find.widgetWithText(TextButton, label),
    );

/// The [icon] button (edit or delete) of the open list's row for [label].
Finder _rowIcon(String label, IconData icon) => find.descendant(
      of: find.byWidgetPredicate(
        (w) => w is DefaultListTile && w.item.label == label,
      ),
      matching: find.byIcon(icon),
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

Future<void> _enableAndOpenSingle(WidgetTester tester) async {
  await _tapButton(tester, 'Enable/Disable Single Selection');
  await _openSingleView(tester, _single);
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

/// Taps a row's delete button and confirms with "Apagar". The row spins
/// while the dialog is up and the callback runs, so this does not settle.
Future<void> _deleteRow(WidgetTester tester, String label) async {
  await tester.tap(_rowIcon(label, Icons.delete));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 300));
  expect(find.byType(AlertDialog), findsOneWidget);
  expect(find.text('Tem certeza?'), findsOneWidget);
  expect(find.text('Cancelar'), findsOneWidget);
  await tester.tap(find.text('Apagar'));
  await tester.pump();
}

/// Taps a row's edit button, types [newLabel] and confirms with "Editar".
Future<void> _editRow(
    WidgetTester tester, String label, String newLabel) async {
  await tester.tap(_rowIcon(label, Icons.edit));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 300));
  final Finder dialog = find.byType(EditDialog);
  expect(dialog, findsOneWidget);
  expect(find.text('Editar o item:'), findsOneWidget);
  await tester.enterText(
    find.descendant(of: dialog, matching: find.byType(TextField)),
    newLabel,
  );
  await tester.tap(find.descendant(of: dialog, matching: find.text('Editar')));
  await tester.pump();
  await tester.pumpAndSettle();
  expect(find.byType(EditDialog), findsNothing);
}

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
  group('app renders the three dropdowns', () {
    testWidgets('MyApp builds without exceptions', (tester) async {
      await _pumpApp(tester);

      expect(tester.takeException(), isNull);
      expect(_single, findsOneWidget);
      expect(_multiple, findsOneWidget);
      expect(_custom, findsOneWidget);
      expect(find.byType(SearchBar), findsNWidgets(2));
    });

    testWidgets('first single shows initial "Teste"; custom shows "Lorenzo"', (
      tester,
    ) async {
      await _pumpApp(tester);

      expect(_barText(tester, _single), 'Teste');
      expect(_barText(tester, _custom), 'Lorenzo');
      // Nothing selected in the multiple box: the PT hint is shown.
      expect(
        find.descendant(of: _multiple, matching: find.text('Pesquisar')),
        findsOneWidget,
      );
    });

    testWidgets('first single uses actions (Icons.abc) as bar trailing', (
      tester,
    ) async {
      await _pumpApp(tester);

      expect(
        find.descendant(of: _single, matching: find.byIcon(Icons.abc)),
        findsOneWidget,
      );
      expect(
        find.descendant(
            of: _custom, matching: find.byIcon(Icons.arrow_drop_down)),
        findsNothing,
        reason: 'custom dropdown uses showArrow: false',
      );
    });

    testWidgets(
        'the custom row builder draws blue rows with edit and delete '
        'buttons beside them', (tester) async {
      await _pumpApp(tester);
      await _enableAndOpenSingle(tester);

      expect(
        find.ancestor(
          of: find.text('Lorenzo'),
          matching: find.byWidgetPredicate(
            (w) => w is Container && w.color == Colors.blue,
          ),
        ),
        findsOneWidget,
      );
      expect(_rowIcon('Lorenzo', Icons.edit), findsOneWidget);
      expect(_rowIcon('Lorenzo', Icons.delete), findsOneWidget);
    });

    testWidgets(
      'selectedFirst puts "Teste" on top of the single list; the app list '
      '(and the multiple, sort none) keeps its order',
      (tester) async {
        await _pumpApp(tester);
        await _enableAndOpenSingle(tester);

        expect(
          tester.getTopLeft(_viewItem('Teste')).dy,
          lessThan(tester.getTopLeft(_viewItem('Lorenzo')).dy),
        );
        expect(_labels(_multipleController(tester).items).take(2), <String>[
          'Lorenzo',
          'Teste',
        ]);
        expect(_labels(initialItems).take(2), <String>['Lorenzo', 'Teste']);
      },
    );
  });

  group('enable/disable the first single dropdown', () {
    testWidgets('starts disabled: tapping the bar does not open the view', (
      tester,
    ) async {
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

    testWidgets('"Enable/Disable Single Selection" enables it and it opens', (
      tester,
    ) async {
      await _pumpApp(tester);

      await _tapButton(tester, 'Enable/Disable Single Selection');
      expect(_barIgnoresPointer(tester, _single), isFalse);
      expect(_singleController(tester).enabled, isTrue);

      await _openSingleView(tester, _single);
      expect(tester.takeException(), isNull);
      // The view lists every item, scrolled to the selected 'Teste'.
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

  group('"Force Single Selection" / "Clear Single Selection"', () {
    testWidgets('Force selects "one more" on the first single dropdown', (
      tester,
    ) async {
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
        reason: 'updateSelectedItem wrote through to the app state',
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
      final List<String> result = await _capturePrints(
        () => _tapButton(tester, 'Print Single Result'),
      );
      expect(result.first, 'null');
    });
  });

  group('add, verify, edit and delete through the first single', () {
    testWidgets(
        'typed label + "Criar" adds after the 2s callback and the '
        'multiple dropdown gets it too', (tester) async {
      await _pumpApp(tester);

      await _enableAndOpenSingle(tester);
      await tester.enterText(_focusedField(), 'Single novo');
      await tester.pump();
      await tester.tap(_viewItem('Criar'));
      await tester.pump();
      expect(_labels(_multipleController(tester).items),
          isNot(contains('Single novo')));
      expect(_labels(_singleController(tester).items),
          isNot(contains('Single novo')));

      await tester.pump(const Duration(seconds: 2));
      await tester.pumpAndSettle();
      expect(_labels(_singleController(tester).items).last, 'Single novo');
      expect(_labels(_multipleController(tester).items).last, 'Single novo');
      expect(_barText(tester, _single), 'Single novo');

      await _openMultiple(tester);
      await tester.enterText(
        find.descendant(of: _multipleOverlay, matching: find.byType(SearchBar)),
        'Single',
      );
      await tester.pump();
      expect(_overlayItem('Single novo'), findsOneWidget);
    });

    testWidgets('verifyInputItem rejects "name" with the warning dialog', (
      tester,
    ) async {
      await _pumpApp(tester);

      await _enableAndOpenSingle(tester);
      await tester.enterText(_focusedField(), 'name');
      await tester.pump();
      await tester.tap(_viewItem('Criar'));
      // The add row spins while the warning is up: pump, do not settle.
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.byType(WarningDialog), findsOneWidget);
      expect(find.text('Erro!'), findsOneWidget);

      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();
      expect(find.byType(WarningDialog), findsNothing);
      expect(_labels(_singleController(tester).items), isNot(contains('name')));
      expect(
          _labels(_multipleController(tester).items), isNot(contains('name')));
    });

    testWidgets(
        'editing the selected "Teste" keeps it selected and renames the '
        'multiple chip', (tester) async {
      await _pumpApp(tester);

      await _openMultiple(tester);
      await tester.tap(_overlayItem('Teste'));
      await tester.pump();
      await _closeMultiple(tester);
      expect(_chip('Teste'), findsOneWidget);

      await _enableAndOpenSingle(tester);
      await _editRow(tester, 'Teste', 'Teste editado');
      expect(tester.takeException(), isNull);
      // The view stays open on the renamed row.
      expect(_viewItem('Teste editado'), findsOneWidget);
      expect(_singleController(tester).selectedItem?.label, 'Teste editado');

      final MultipleSearchDropDownController<dynamic> multiple =
          _multipleController(tester);
      expect(_labels(multiple.items), contains('Teste editado'));
      expect(_labels(multiple.items), isNot(contains('Teste')));
      expect(_labels(multiple.selectedItems), <String>['Teste editado']);
      expect(_chip('Teste editado'), findsOneWidget);
    });

    testWidgets(
        'delete (confirm "Apagar", 2s callback) removes the item from '
        'both dropdowns', (tester) async {
      await _pumpApp(tester);

      await _enableAndOpenSingle(tester);
      await _deleteRow(tester, 'Lorenzo');
      await tester.pump(const Duration(seconds: 1));
      expect(
        _labels(_multipleController(tester).items),
        contains('Lorenzo'),
        reason: 'the 2s callback is still running',
      );
      expect(_viewItem('Lorenzo'), findsOneWidget);
      await tester.pump(const Duration(seconds: 2));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.byType(AlertDialog), findsNothing);
      expect(_viewItem('Lorenzo'), findsNothing);
      expect(
          _labels(_singleController(tester).items), isNot(contains('Lorenzo')));
      expect(
        _labels(_multipleController(tester).items),
        isNot(contains('Lorenzo')),
      );
    });

    testWidgets('"Cancelar" on the delete confirmation keeps the item', (
      tester,
    ) async {
      await _pumpApp(tester);

      await _enableAndOpenSingle(tester);
      await tester.tap(_rowIcon('Lorenzo', Icons.delete));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      await tester.tap(find.text('Cancelar'));
      await tester.pumpAndSettle();

      expect(find.byType(AlertDialog), findsNothing);
      expect(_viewItem('Lorenzo'), findsOneWidget);
      expect(_labels(_singleController(tester).items), contains('Lorenzo'));
    });
  });

  group('custom dropdown (custom value type) select and clear', () {
    testWidgets('open, select "Peter", then "Clear Custom Selection"', (
      tester,
    ) async {
      await _pumpApp(tester);

      await _openSingleView(tester, _custom);
      // Opening lists every item, scrolled to 'Lorenzo'.
      expect(_viewItem('Lorenzo'), findsOneWidget);
      expect(_viewItem('Peter'), findsOneWidget);

      await tester.enterText(_focusedField(), 'Pet');
      await tester.pump();
      expect(_viewItem('Peter'), findsOneWidget);

      await tester.tap(_viewItem('Peter'));
      await tester.pumpAndSettle();
      expect(_viewItem('Lucas'), findsNothing, reason: 'view closed');
      expect(_barText(tester, _custom), 'Peter');
      expect(_customController(tester).selectedItem?.value?.id, 1);

      final List<String> printed = await _capturePrints(
        () => _tapButton(tester, 'Print Custom Result'),
      );
      expect(printed, contains('name: Peter'));
      expect(printed, contains('ValueItem<Custom>'));

      await _tapButton(tester, 'Clear Custom Selection');
      expect(_barText(tester, _custom), '');
      final List<String> cleared = await _capturePrints(
        () => _tapButton(tester, 'Print Custom Result'),
      );
      expect(cleared, <String>['null']);
    });

    testWidgets('after clearing, opening the custom view lists every item', (
      tester,
    ) async {
      await _pumpApp(tester);

      await _tapButton(tester, 'Clear Custom Selection');
      await _openSingleView(tester, _custom);
      for (final String label in <String>['Lorenzo', 'Peter', 'Lucas']) {
        expect(_viewItem(label), findsOneWidget, reason: label);
      }
      expect(_viewItem('Criar'), findsNothing, reason: 'addMode: false');
    });
  });

  group('"Reset custom list" (updateListItems)', () {
    testWidgets('replaces items with "Reset 1"/"Reset 2" and clears selection',
        (
      tester,
    ) async {
      await _pumpApp(tester);

      await _tapButton(tester, 'Reset custom list');
      expect(_barText(tester, _custom), '');
      expect(_customController(tester).selectedItem, isNull);
      expect(_labels(_customController(tester).items), <String>[
        'Reset 1',
        'Reset 2',
      ]);

      await _openSingleView(tester, _custom);
      expect(_viewItem('Reset 1'), findsOneWidget);
      expect(_viewItem('Reset 2'), findsOneWidget);
      expect(_viewItem('Peter'), findsNothing);
      expect(_viewItem('Lorenzo'), findsNothing);
    });

    testWidgets('deleting "Reset 1" after reset (confirm "Apagar") removes it',
        (
      tester,
    ) async {
      await _pumpApp(tester);

      await _tapButton(tester, 'Reset custom list');
      await _openSingleView(tester, _custom);

      final List<String> printed = await _capturePrints(() async {
        await _deleteRow(tester, 'Reset 1');
        await tester.pumpAndSettle();
      });

      expect(tester.takeException(), isNull);
      expect(printed, <String>['deleted Reset 1']);
      expect(find.byType(AlertDialog), findsNothing);
      expect(_labels(_customController(tester).items), <String>['Reset 2']);
      expect(_viewItem('Reset 1'), findsNothing);
      expect(_viewItem('Reset 2'), findsOneWidget);
    });
  });

  group('multiple dropdown select, clear and force', () {
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

    testWidgets('"Clear Multiple Selection" removes every chip', (
      tester,
    ) async {
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
      final List<String> printed = await _capturePrints(
        () => _tapButton(tester, 'Print Multiple Result'),
      );
      expect(printed, <String>['[]']);
    });

    testWidgets('"Force Multiple Selection" selects "one more"', (
      tester,
    ) async {
      await _pumpApp(tester);

      await _tapButton(tester, 'Force Multiple Selection');
      expect(_chip('one more'), findsOneWidget);

      // Forcing again does not toggle it off.
      await _tapButton(tester, 'Force Multiple Selection');
      expect(_chip('one more'), findsOneWidget);
    });

    testWidgets('chip close icon fires onClearItem; clear icon fires onClear', (
      tester,
    ) async {
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

  group('shared list: changes through the multiple reach the single', () {
    testWidgets(
        'an item added via the multiple "Criar" row is in both lists '
        'once and selected', (tester) async {
      await _pumpApp(tester);

      await _addThroughMultiple(tester, 'Novo item');

      expect(tester.takeException(), isNull);
      for (final List<String> labels in <List<String>>[
        _labels(_multipleController(tester).items),
        _labels(_singleController(tester).items),
      ]) {
        expect(labels.where((e) => e == 'Novo item'), hasLength(1));
      }
      expect(_chip('Novo item'), findsOneWidget);
      // The single keeps its own selection.
      expect(_barText(tester, _single), 'Teste');
    });

    testWidgets(
        'after clearing the single, enabling and opening it shows the '
        'item added via the multiple dropdown', (tester) async {
      await _pumpApp(tester);

      await _addThroughMultiple(tester, 'Novo item');
      await _tapButton(tester, 'Clear Single Selection');
      await _enableAndOpenSingle(tester);

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
        'searching the single (selected "Teste") finds a matching item '
        'added via the multiple dropdown', (tester) async {
      await _pumpApp(tester);

      await _addThroughMultiple(tester, 'Teste novo');
      await _enableAndOpenSingle(tester);
      expect(tester.takeException(), isNull);
      // The view lists everything; narrow it to both matches.
      await tester.enterText(_focusedField(), 'test');
      await tester.pump();

      expect(tester.takeException(), isNull);
      expect(_viewItem('Teste'), findsOneWidget);
      expect(_viewItem('Teste novo'), findsOneWidget);
    });

    testWidgets(
        'typing in the single filters to an item added via the '
        'multiple dropdown', (tester) async {
      await _pumpApp(tester);

      await _addThroughMultiple(tester, 'Novo item');
      await _tapButton(tester, 'Clear Single Selection');
      await _enableAndOpenSingle(tester);
      await tester.enterText(_focusedField(), 'Novo');
      await tester.pump();

      expect(tester.takeException(), isNull);
      expect(_viewItem('Novo item'), findsOneWidget);
      expect(_viewItem('Lorenzo'), findsNothing);
    });

    testWidgets(
        'editing "Teste" in the multiple renames it in the single, '
        'which keeps it selected', (tester) async {
      await _pumpApp(tester);

      await _openMultiple(tester);
      await _editRow(tester, 'Teste', 'Teste editado');
      expect(tester.takeException(), isNull);
      expect(_overlayItem('Teste editado'), findsOneWidget);
      expect(_overlayItem('Teste'), findsNothing);
      await _closeMultiple(tester);

      expect(_barText(tester, _single), 'Teste editado');
      final List<String> single = _labels(_singleController(tester).items);
      expect(single, contains('Teste editado'));
      expect(single, isNot(contains('Teste')));
      final List<String> printed = await _capturePrints(
        () => _tapButton(tester, 'Print Single Result'),
      );
      expect(printed.first, contains('label: Teste editado'));
    });

    testWidgets(
        'deleting the single\'s selected "Teste" in the multiple '
        'removes it there and clears the single', (tester) async {
      await _pumpApp(tester);

      await _openMultiple(tester);
      await tester.tap(_overlayItem('Teste'));
      await tester.pump();
      await _deleteRow(tester, 'Teste');
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(_overlayItem('Teste'), findsNothing);
      await _closeMultiple(tester);

      expect(_chip('Teste'), findsNothing, reason: 'it left the selection');
      expect(_barText(tester, _single), '');
      expect(_singleController(tester).selectedItem, isNull);
      expect(
          _labels(_singleController(tester).items), isNot(contains('Teste')));
    });
  });

  group('"Open Dialog" with a dropdown inside a dialog', () {
    testWidgets('dialog opens; its dropdown lists the shared items', (
      tester,
    ) async {
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
      expect(_viewItem('Criar'), findsNothing, reason: 'addMode: false');
      expect(find.byIcon(Icons.delete), findsNothing, reason: 'deleteMode');
      await tester.tap(_viewItem('Teste'));
      await tester.pumpAndSettle();
      expect(_barText(tester, dialogDropdown), 'Teste');
    });

    testWidgets(
        'the dialog gets the app list as it is, with items added '
        'through the multiple', (tester) async {
      await _pumpApp(tester);

      await _addThroughMultiple(tester, 'Novo item');
      await _tapButton(tester, 'Open Dialog');
      final SearchDropDownController<dynamic> dialog = tester
          .widget<SearchDropDown<dynamic>>(
            find.descendant(
              of: find.byType(Dialog),
              matching: find.byType(SearchDropDown<dynamic>),
            ),
          )
          .controller;
      expect(_labels(dialog.items).last, 'Novo item');
    });

    testWidgets('closing the dialog disposes its controller cleanly', (
      tester,
    ) async {
      await _pumpApp(tester);

      await _tapButton(tester, 'Open Dialog');
      final SearchDropDownController<dynamic> dialog = tester
          .widget<SearchDropDown<dynamic>>(
            find.descendant(
              of: find.byType(Dialog),
              matching: find.byType(SearchDropDown<dynamic>),
            ),
          )
          .controller;
      await tester.tapAt(const Offset(5, 5));
      await tester.pumpAndSettle();

      expect(find.text('Dialog Test'), findsNothing);
      expect(tester.takeException(), isNull);
      expect(dialog.isDisposed, isTrue);
    });
  });

  testWidgets('removing the app disposes its three controllers', (
    tester,
  ) async {
    await _pumpApp(tester);
    final SearchDropDownController<dynamic> single = _singleController(tester);
    final MultipleSearchDropDownController<dynamic> multiple =
        _multipleController(tester);
    final SearchDropDownController<Custom> custom = _customController(tester);

    await tester.pumpWidget(const SizedBox());
    expect(tester.takeException(), isNull);
    expect(single.isDisposed, isTrue);
    expect(multiple.isDisposed, isTrue);
    expect(custom.isDisposed, isTrue);
  });
}
