// Uses the 7.x API on purpose: this file must keep compiling until 9.0.0.
// ignore_for_file: deprecated_member_use, deprecated_member_use_from_same_package, avoid_redundant_argument_values

// 7.x source compatibility (F14, F10). Each test is mostly a compile check:
// if a 7.x member changes type or disappears, the whole file fails to load.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:simple_search_dropdown/simple_search_dropdown.dart';

import '../support/harness.dart';

void main() {
  group('7.x single API', () {
    test('controller.showClearIcon is a bool (default true) (F14)', () {
      final SearchDropDownController<int> c = SearchDropDownController<int>(
        listItems: <ValueItem<int>>[const ValueItem(label: 'A', value: 1)],
        addMode: false,
        deleteMode: false,
      );
      addTearDown(c.dispose);
      final bool v = c.showClearIcon;
      expect(v, isTrue);

      final SearchDropDownController<int> off = SearchDropDownController<int>(
        listItems: <ValueItem<int>>[],
        addMode: false,
        deleteMode: false,
        showClearIcon: false,
      );
      addTearDown(off.dispose);
      expect(off.showClearIcon ? 1 : 0, 0);
    });

    test('7.x controller fields and methods keep their types', () {
      final List<ValueItem<int>> items = fruitItems();
      final List<ValueItem<int>?> calls = <ValueItem<int>?>[];
      final SearchDropDownController<int> c = SearchDropDownController<int>(
        listItems: items,
        addMode: false,
        deleteMode: false,
        sortType: 1,
        showClearIcon: true,
        updateSelectedItem: calls.add,
        latinize: true,
        caseSensitive: false,
        trim: true,
      );
      addTearDown(c.dispose);
      final List<ValueItem<int>> l = c.listItems;
      final bool latinize = c.latinize;
      final bool caseSensitive = c.caseSensitive;
      final bool trim = c.trim;
      final int highlighted = c.highlightedIndex;
      expect(identical(l, items), isTrue);
      expect(<bool>[latinize, caseSensitive, trim], <bool>[true, false, true]);
      expect(highlighted, -1);
      c
        ..enabled = false
        ..enabled = true
        ..sortList(2)
        ..filterList('a')
        ..forceSelection('Uva');
      final ValueItem<int>? selected = c.selectedItem;
      final bool clear = c.clearVisible;
      expect(selected?.label, 'Uva');
      expect(clear, isTrue);
      c
        ..clearVisible = false
        ..selectedItem = null
        ..resetSelection()
        ..updateListItems(fruitItems(), true);
      expect(calls.last, isNull);
    });
  });

  group('7.x multiple API', () {
    test('MultipleSearchDropDown listItems/selectedItems/updateSelectedItems '
        'read as non-null (F14)', () {
      final List<ValueItem<int>> items = fruitItems();
      final List<ValueItem<int>> sel = <ValueItem<int>>[];
      final List<List<ValueItem<int>>> calls = <List<ValueItem<int>>>[];
      final MultipleSearchDropDown<int> w = MultipleSearchDropDown<int>(
        listItems: items,
        selectedItems: sel,
        updateSelectedItems: calls.add,
        addMode: false,
        deleteMode: false,
      );
      final List<ValueItem<int>> l = w.listItems;
      final List<ValueItem<int>> s = w.selectedItems;
      final Function(List<ValueItem<int>>) update = w.updateSelectedItems;
      expect(identical(l, items), isTrue);
      expect(identical(s, sel), isTrue);
      update(sel);
      expect(calls, hasLength(1));
      expect(w.selectedItems.isEmpty, isTrue);

      // Controller mode: the getters read the controller.
      final List<List<ValueItem<int>>> ctrlCalls = <List<ValueItem<int>>>[];
      final MultipleSearchDropDownController<int> mc =
          MultipleSearchDropDownController<int>(
            items: fruitItems(),
            updateSelectedItems: ctrlCalls.add,
            addMode: false,
            deleteMode: false,
          );
      addTearDown(mc.dispose);
      final MultipleSearchDropDown<int> cw = MultipleSearchDropDown<int>(
        controller: mc,
      );
      expect(identical(cw.listItems, mc.listItems), isTrue);
      expect(identical(cw.selectedItems, mc.selectedItems), isTrue);
      cw.updateSelectedItems(mc.selectedItems);
      expect(ctrlCalls, hasLength(1));
      // The controller wins over 7.x parameters passed alongside it.
      final MultipleSearchDropDown<int> both = MultipleSearchDropDown<int>(
        controller: mc,
        listItems: items,
        selectedItems: sel,
        updateSelectedItems: calls.add,
      );
      expect(identical(both.listItems, mc.listItems), isTrue);
      expect(identical(both.selectedItems, mc.selectedItems), isTrue);
      both.updateSelectedItems(mc.selectedItems);
      expect(ctrlCalls, hasLength(2));
      expect(calls, hasLength(1));
      // Without a callback the getter is a no-op, never null.
      final MultipleSearchDropDownController<int> silent =
          MultipleSearchDropDownController<int>(
            items: fruitItems(),
            addMode: false,
            deleteMode: false,
          );
      addTearDown(silent.dispose);
      MultipleSearchDropDown<int>(
        controller: silent,
      ).updateSelectedItems(silent.selectedItems);
    });

    testWidgets('7.x state members through a GlobalKey (F10)', (tester) async {
      final GlobalKey<MultipleSearchDropDownState<int>> key = GlobalKey();
      final List<ValueItem<int>> sel = <ValueItem<int>>[];
      await tester.pumpWidget(
        host(
          MultipleSearchDropDown<int>(
            key: key,
            listItems: fruitItems(),
            selectedItems: sel,
            updateSelectedItems: (_) {},
            addMode: false,
            deleteMode: false,
            sortType: 1,
          ),
        ),
      );
      final MultipleSearchDropDownState<int> state = key.currentState!;
      // 7.x `late OverlayScreen overlayScreen;` was an assignable field.
      final OverlayScreen original = state.overlayScreen;
      expect(identical(original, state.overlayScreen), isTrue);
      state.overlayScreen = original;
      final bool open = state.aberto;
      final bool enabled = state.enabled;
      expect(open, isFalse);
      expect(enabled, isTrue);
      state
        ..forceSelection('Uva')
        ..forceMultipleSelection(<ValueItem<int>>[sel.first])
        ..resetSelection()
        ..enableDisable()
        ..enableDisable()
        ..hideOverlay();
      await tester.pump();
      expect(sel, isEmpty);
    });
  });
}
