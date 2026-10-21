// Keyboard and focus behaviour of the single dropdown (C9: N55, F17, N26,
// N69, F21, N70).

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:simple_search_dropdown/simple_search_dropdown.dart';

import '../support/harness.dart';

SearchDropDownController<int> _ctrl(
  List<ValueItem<int>> items, {
  List<ValueItem<int>?>? calls,
  bool enabled = true,
  ValueItem<int>? initial,
}) => SearchDropDownController<int>(
  items: items,
  addMode: false,
  deleteMode: false,
  updateSelectedItem: calls?.add,
  enabled: enabled,
  initialSelectedItem: initial,
);

Widget _dropdown(SearchDropDownController<int> c, {bool removeFocus = true}) =>
    SearchDropDown<int>(
      controller: c,
      removeFocus: removeFocus,
      overlayListSettings: const SimpleOverlaySettings(dialogHeight: 400),
    );

/// A text field before and after the dropdown.
Widget _betweenFields(Widget dropdown) => Column(
  mainAxisSize: MainAxisSize.min,
  children: <Widget>[
    const SizedBox(width: 300, child: TextField(key: Key('before'))),
    dropdown,
    const SizedBox(width: 300, child: TextField(key: Key('after'))),
  ],
);

bool _focusInsideDropdown() {
  final BuildContext? ctx = FocusManager.instance.primaryFocus?.context;
  return ctx != null &&
      ctx.findAncestorWidgetOfExactType<SearchDropDown<int>>() != null;
}

Key? _focusedFieldKey() => FocusManager.instance.primaryFocus?.context
    ?.findAncestorWidgetOfExactType<TextField>()
    ?.key;

/// Focuses the 'before' field and Tabs into the dropdown's closed bar.
Future<void> _tabIntoBar(WidgetTester tester) async {
  await tester.tap(find.byKey(const Key('before')));
  await tester.pump();
  await tester.sendKeyEvent(LogicalKeyboardKey.tab);
  await tester.pump();
}

EditableText _barField(WidgetTester tester) => tester.widget<EditableText>(
  find.descendant(
    of: find.byType(SearchDropDown<int>),
    matching: find.byType(EditableText),
  ),
);

/// Tabs from the 'before' field to the closed bar's text field (SearchBar
/// puts its own InkWell first in the focus order).
Future<void> _tabIntoBarField(WidgetTester tester) async {
  await _tabIntoBar(tester);
  for (int i = 0; i < 3 && !_barField(tester).focusNode.hasPrimaryFocus; i++) {
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pump();
  }
  expect(_barField(tester).focusNode.hasPrimaryFocus, isTrue);
  expect(tester.testTextInput.hasAnyClients, isTrue);
}

/// Presses (Shift+)Tab until the focus leaves the dropdown (at most 8 times;
/// a focus trap never leaves).
Future<void> _tabOut(WidgetTester tester, {bool shift = false}) async {
  for (int i = 0; i < 8 && _focusInsideDropdown(); i++) {
    if (shift) {
      await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
    }
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    if (shift) {
      await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
    }
    await tester.pump();
  }
}

void main() {
  group('N55: a key burst into the focused closed bar', () {
    testWidgets('two characters in one frame open a single view', (
      tester,
    ) async {
      final calls = <ValueItem<int>?>[];
      final c = _ctrl(numberedItems(3), calls: calls);
      await tester.pumpWidget(host(_betweenFields(_dropdown(c))));
      await _tabIntoBarField(tester);

      // No frame between the two: the view's field is not focused yet.
      tester.testTextInput.enterText('Item');
      await tester.idle();
      tester.testTextInput.enterText('Item 1');
      await tester.idle();
      await tester.pumpAndSettle();

      expect(find.byType(SearchBar), findsNWidgets(2));
      expect(rowLabels<int>(tester), <String>['Item 1']);
      expect(c.localSearchController.isOpen, isTrue);

      await tester.tap(
        find.descendant(
          of: rowTile<int>('Item 1'),
          matching: find.byType(TextButton),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(DefaultListTile<int>), findsNothing);
      expect(c.localSearchController.isOpen, isFalse);
      expect(calls.map((e) => e?.label), <String?>['Item 1']);
    });

    testWidgets('openView while the view is open is ignored', (tester) async {
      final c = _ctrl(numberedItems(3));
      await tester.pumpWidget(host(_dropdown(c)));
      await openSingle(tester);

      c.localSearchController.openView();
      await tester.pumpAndSettle();

      expect(find.byType(SearchBar), findsNWidgets(2));
      expect(c.localSearchController.isOpen, isTrue);
      c.localSearchController.closeView(null);
      await tester.pumpAndSettle();
      expect(find.byType(DefaultListTile<int>), findsNothing);
    });
  });

  group('F17: Enter on the focused closed bar', () {
    testWidgets('selects nothing', (tester) async {
      final calls = <ValueItem<int>?>[];
      final c = _ctrl(numberedItems(3), calls: calls);
      await tester.pumpWidget(host(_betweenFields(_dropdown(c))));
      await _tabIntoBarField(tester);
      expect(c.localSearchController.isOpen, isFalse);

      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();

      expect(c.selectedItem, isNull);
      expect(c.localSearchController.text, isEmpty);
      expect(calls, isEmpty);
    });

    testWidgets('keeps the current selection', (tester) async {
      final calls = <ValueItem<int>?>[];
      final items = numberedItems(3);
      final c = _ctrl(items, calls: calls, initial: items[2]);
      await tester.pumpWidget(host(_betweenFields(_dropdown(c))));
      await _tabIntoBarField(tester);

      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();

      expect(c.selectedItem?.label, 'Item 2');
      expect(c.localSearchController.text, 'Item 2');
      expect(calls, isEmpty);
    });

    testWidgets('Enter in the open view still selects', (tester) async {
      final calls = <ValueItem<int>?>[];
      final c = _ctrl(numberedItems(3), calls: calls);
      await tester.pumpWidget(host(_dropdown(c)));
      await openSingle(tester);

      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();

      expect(calls.map((e) => e?.label), <String?>['Item 0']);
    });
  });

  group('N26: a disabled dropdown is not keyboard-reachable', () {
    testWidgets('Tab skips the bar and its clear button; typing and Enter do '
        'nothing', (tester) async {
      final items = numberedItems(3);
      final calls = <ValueItem<int>?>[];
      final c = _ctrl(items, enabled: false, initial: items[2], calls: calls);
      await tester.pumpWidget(host(_betweenFields(_dropdown(c))));
      expect(find.byIcon(Icons.clear), findsOneWidget);
      await tester.tap(find.byKey(const Key('before')));
      await tester.pump();

      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
      expect(_focusInsideDropdown(), isFalse);
      expect(_focusedFieldKey(), const Key('after'));
      expect(_barField(tester).focusNode.canRequestFocus, isFalse);

      tester.testTextInput.enterText('I');
      await tester.pumpAndSettle();
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();

      expect(c.localSearchController.isOpen, isFalse);
      expect(find.byType(DefaultListTile<int>), findsNothing);
      expect(c.selectedItem, items[2]);
      expect(calls, isEmpty);
    });

    testWidgets('disabling drops the focus; enabling makes it reachable '
        'again', (tester) async {
      final c = _ctrl(numberedItems(2));
      await tester.pumpWidget(host(_betweenFields(_dropdown(c))));
      await _tabIntoBar(tester);
      expect(_focusInsideDropdown(), isTrue);

      c.enabled = false;
      await tester.pump();
      expect(_focusInsideDropdown(), isFalse);

      c.enabled = true;
      await tester.pump();
      await _tabIntoBar(tester);
      expect(_focusInsideDropdown(), isTrue);
    });
  });

  group('N69: Tab and Shift+Tab leave the bar', () {
    for (final bool removeFocus in <bool>[true, false]) {
      testWidgets('removeFocus: $removeFocus', (tester) async {
        await tester.pumpWidget(
          host(
            _betweenFields(
              _dropdown(_ctrl(numberedItems(2)), removeFocus: removeFocus),
            ),
          ),
        );
        await _tabIntoBar(tester);
        expect(_focusInsideDropdown(), isTrue);

        await _tabOut(tester);
        expect(_focusInsideDropdown(), isFalse);
        expect(_focusedFieldKey(), const Key('after'));

        await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
        await tester.sendKeyEvent(LogicalKeyboardKey.tab);
        await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
        await tester.pump();
        expect(_focusInsideDropdown(), isTrue);

        await _tabOut(tester, shift: true);
        expect(_focusedFieldKey(), const Key('before'));
      });
    }

    testWidgets('with a selection, Tab passes the clear button and leaves', (
      tester,
    ) async {
      final items = numberedItems(2);
      await tester.pumpWidget(
        host(_betweenFields(_dropdown(_ctrl(items, initial: items[1])))),
      );
      expect(find.byIcon(Icons.clear), findsOneWidget);
      await _tabIntoBar(tester);
      expect(_focusInsideDropdown(), isTrue);

      await _tabOut(tester);
      expect(_focusedFieldKey(), const Key('after'));
    });
  });

  group('F21: keys drive the list only from the view field', () {
    testWidgets('Enter on a focused row activates only that row', (
      tester,
    ) async {
      final calls = <ValueItem<int>?>[];
      final c = _ctrl(numberedItems(4), calls: calls);
      await tester.pumpWidget(host(_dropdown(c)));
      await openSingle(tester);
      Focus.of(
        tester.element(
          find.descendant(
            of: rowTile<int>('Item 2'),
            matching: find.text('Item 2'),
          ),
        ),
      ).requestFocus();
      await tester.pump();

      await pressKey(tester, LogicalKeyboardKey.enter);

      expect(calls.map((e) => e?.label), <String?>['Item 2']);
      expect(c.selectedItem?.label, 'Item 2');
      expect(c.localSearchController.isOpen, isFalse);
    });

    testWidgets('Enter on the focused close button closes without selecting', (
      tester,
    ) async {
      final calls = <ValueItem<int>?>[];
      final c = _ctrl(numberedItems(4), calls: calls);
      await tester.pumpWidget(host(_dropdown(c)));
      await openSingle(tester);
      Focus.of(tester.element(find.byIcon(Icons.arrow_drop_up))).requestFocus();
      await tester.pump();

      await pressKey(tester, LogicalKeyboardKey.enter);

      expect(c.localSearchController.isOpen, isFalse);
      expect(c.selectedItem, isNull);
      expect(calls, isEmpty);
    });

    Future<SearchDropDownController<int>> openUnfocused(
      WidgetTester tester,
    ) async {
      final c = _ctrl(numberedItems(4));
      await tester.pumpWidget(host(_dropdown(c)));
      await openSingle(tester);
      // A desktop click outside the field leaves the route's scope focused.
      FocusManager.instance.primaryFocus!.unfocus();
      await tester.pump();
      expect(FocusManager.instance.primaryFocus, isA<FocusScopeNode>());
      return c;
    }

    testWidgets('an arrow still moves the highlight after the field lost the '
        'focus', (tester) async {
      final c = await openUnfocused(tester);

      await pressKey(tester, LogicalKeyboardKey.arrowDown);

      expect(c.highlightedIndex, 0);
    });

    testWidgets('Enter still submits after the field lost the focus', (
      tester,
    ) async {
      final c = await openUnfocused(tester);

      await pressKey(tester, LogicalKeyboardKey.enter);

      expect(c.selectedItem?.label, 'Item 0');
      expect(c.localSearchController.isOpen, isFalse);
    });
  });

  group(
    'N70: browsing with keys keeps the caret where typing replaces the label',
    () {
      Future<SearchDropDownController<int>> openWithBanana(
        WidgetTester tester,
      ) async {
        final List<ValueItem<int>> items = fruitItems();
        final c = _ctrl(items, initial: items[1]);
        await tester.pumpWidget(host(_dropdown(c)));
        await openSingle(tester);
        expect(
          c.localSearchController.selection,
          const TextSelection.collapsed(offset: 6),
        );
        return c;
      }

      testWidgets(
        'arrow and page keys keep it; typing then replaces the label',
        (tester) async {
          final c = await openWithBanana(tester);
          for (final LogicalKeyboardKey key in <LogicalKeyboardKey>[
            LogicalKeyboardKey.arrowDown,
            LogicalKeyboardKey.arrowDown,
            LogicalKeyboardKey.arrowUp,
            LogicalKeyboardKey.pageDown,
            LogicalKeyboardKey.pageUp,
          ]) {
            await tester.sendKeyEvent(key);
            await tester.pump();
            expect(c.highlightedIndex, isNot(-1), reason: '$key');
            expect(
              c.localSearchController.selection,
              const TextSelection.collapsed(offset: 6),
              reason: '$key',
            );
          }

          // Type at the selection the way the engine does.
          final TextEditingValue v = c.localSearchController.value;
          tester.testTextInput.updateEditingValue(
            v.replaced(v.selection, 'Uv'),
          );
          await tester.pump();

          expect(c.localSearchController.text, 'Uv');
          expect(c.filteredItems.map((e) => e.label), <String>['Uva']);
        },
      );

      testWidgets('a caret the user placed is left alone, and typing there '
          'edits the label', (tester) async {
        final c = await openWithBanana(tester);
        await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
        await tester.pump();
        const TextSelection caret = TextSelection.collapsed(offset: 5);
        expect(c.localSearchController.selection, caret);

        await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
        await tester.pump();

        expect(c.highlightedIndex, 1);
        expect(c.localSearchController.selection, caret);

        final TextEditingValue v = c.localSearchController.value;
        tester.testTextInput.updateEditingValue(v.replaced(v.selection, 'X'));
        await tester.pump();
        expect(c.localSearchController.text, 'BananXa');
      });
    },
  );
}
