// Uses the 7.x API on purpose: this file must keep compiling until 9.0.0.
// ignore_for_file: deprecated_member_use, deprecated_member_use_from_same_package, avoid_redundant_argument_values

// 7.x source compatibility (F14, F10). Each test is mostly a compile check:
// if a 7.x member changes type or disappears, the whole file fails to load.

import 'dart:async';

import 'package:flutter/foundation.dart';
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
  group('7.x MultipleListView constructor (F14)', () {
    testWidgets('sorts like 7.x, never reorders the caller list and a tap '
        'only calls onItemSelected', (tester) async {
      final List<ValueItem<int>> items = _items();
      final List<ValueItem<int>> before = List<ValueItem<int>>.of(items);
      final List<ValueItem<int>> sel = <ValueItem<int>>[];
      final List<ValueItem<int>> tapped = <ValueItem<int>>[];
      await tester.pumpWidget(
        host(
          _legacyList(
            items: items,
            sel: sel,
            sortType: 1,
            onItemSelected: tapped.add,
          ),
        ),
      );
      expect(_rows(tester), <String>['abacaxi', 'Banana', 'Uva']);
      expect(items, before);
      await tester.tap(find.text('Banana'));
      await tester.pump();
      expect(tapped.map((ValueItem<int> v) => v.label), <String>['Banana']);
      // The 7.x list never changed the selection itself.
      expect(sel, isEmpty);
      expect(_tile(tester, 'Banana').selected, isFalse);
      expect(items, before);
      expect(find.byType(Dialog), findsNothing);
    });

    testWidgets('a callback that changes the selection is shown at once and '
        'selectedFirst re-pins', (tester) async {
      final List<ValueItem<int>> items = _items();
      final List<ValueItem<int>> before = List<ValueItem<int>>.of(items);
      final List<ValueItem<int>> sel = <ValueItem<int>>[];
      await tester.pumpWidget(
        host(
          _legacyList(
            items: items,
            sel: sel,
            sortType: 3,
            onItemSelected: (ValueItem<int> v) =>
                sel.contains(v) ? sel.remove(v) : sel.add(v),
          ),
        ),
      );
      expect(_rows(tester), <String>['Uva', 'Banana', 'abacaxi']);
      await tester.tap(find.text('Banana'));
      await tester.pump();
      expect(sel.map((ValueItem<int> v) => v.label), <String>['Banana']);
      expect(_tile(tester, 'Banana').selected, isTrue);
      expect(_rows(tester), <String>['Banana', 'Uva', 'abacaxi']);
      await tester.tap(find.text('Banana'));
      await tester.pump();
      expect(sel, isEmpty);
      expect(_tile(tester, 'Banana').selected, isFalse);
      expect(_rows(tester), <String>['Uva', 'Banana', 'abacaxi']);
      expect(items, before);
    });

    testWidgets('search keeps the 7.x matching (no trim) and the add row only '
        'calls onAddItem', (tester) async {
      final List<ValueItem<int>> items = _items();
      final List<ValueItem<int>> sel = <ValueItem<int>>[];
      final List<ValueItem<int>> added = <ValueItem<int>>[];
      await tester.pumpWidget(
        host(
          _legacyList(
            items: items,
            sel: sel,
            onAddItem: (ValueItem<int> v) {
              added.add(v);
              items.add(v);
            },
          ),
        ),
      );
      await tester.enterText(_field, 'BAN');
      await tester.pump();
      expect(_rows(tester), <String>['Banana']);
      await tester.enterText(_field, 'uva ');
      await tester.pump();
      expect(_rows(tester), isEmpty);
      expect(find.text('Criar'), findsOneWidget);
      await tester.enterText(_field, 'Kiwi');
      await tester.pump();
      await tester.tap(find.text('Criar'));
      await tester.pumpAndSettle();
      expect(added.map((ValueItem<int> v) => v.label), <String>['Kiwi']);
      // The view leaves the list to the callback and does not select.
      expect(
        items.where((ValueItem<int> v) => v.label == 'Kiwi'),
        hasLength(1),
      );
      expect(items, hasLength(4));
      expect(sel, isEmpty);
      expect(tester.widget<TextField>(_field).controller!.text, isEmpty);
      expect(_rows(tester), <String>['Uva', 'Banana', 'abacaxi', 'Kiwi']);
    });

    testWidgets('delete and edit call the callbacks directly: no dialog, no '
        'change to the lists', (tester) async {
      final List<ValueItem<int>> items = _items();
      final ValueItem<int> banana = items[1];
      final List<ValueItem<int>> sel = <ValueItem<int>>[banana];
      final List<ValueItem<int>> deleted = <ValueItem<int>>[];
      final List<ValueItem<int>> edited = <ValueItem<int>>[];
      bool remove = false;
      await tester.pumpWidget(
        host(
          _legacyList(
            items: items,
            sel: sel,
            editMode: true,
            onDeleteItem: (ValueItem<int> v) {
              deleted.add(v);
              if (remove) {
                items.remove(v);
              }
            },
            onEditItem: edited.add,
          ),
        ),
      );
      Finder button(String tooltip, String label) => find.descendant(
        of: find.ancestor(
          of: find.text(label),
          matching: find.byType(DefaultListTile<int>),
        ),
        matching: find.byTooltip(tooltip),
      );
      await tester.tap(button('Apagar item', 'Banana'));
      await tester.pumpAndSettle();
      expect(deleted, <ValueItem<int>>[banana]);
      expect(find.byType(Dialog), findsNothing);
      expect(items, hasLength(3));
      expect(sel, <ValueItem<int>>[banana]);
      expect(_rows(tester), <String>['Uva', 'Banana', 'abacaxi']);

      await tester.tap(button('Editar item', 'Uva'));
      await tester.pumpAndSettle();
      expect(edited.map((ValueItem<int> v) => v.label), <String>['Uva']);
      expect(find.byType(Dialog), findsNothing);
      expect(items, hasLength(3));

      // A callback that removes the item: the row goes, the search stays.
      await tester.enterText(_field, 'a');
      await tester.pump();
      remove = true;
      await tester.tap(button('Apagar item', 'Banana'));
      await tester.pumpAndSettle();
      expect(_rows(tester), <String>['Uva', 'abacaxi']);
      expect(tester.widget<TextField>(_field).controller!.text, 'a');
      expect(sel, <ValueItem<int>>[banana]);
    });

    testWidgets('modes off hide the buttons and the add row', (tester) async {
      await tester.pumpWidget(
        host(
          _legacyList(
            items: _items(),
            sel: <ValueItem<int>>[],
            addMode: false,
            deleteMode: false,
          ),
        ),
      );
      expect(find.byTooltip('Apagar item'), findsNothing);
      expect(find.byTooltip('Editar item'), findsNothing);
      await tester.enterText(_field, 'zz');
      await tester.pump();
      expect(find.text('Criar'), findsNothing);
    });

    testWidgets('parent rebuilds apply new lists, flags and sort; switching '
        'to and from a controller works', (tester) async {
      List<ValueItem<int>> items = _items();
      final List<ValueItem<int>> sel = <ValueItem<int>>[];
      int sortType = 0;
      bool deleteMode = true;
      final List<ValueItem<int>> first = <ValueItem<int>>[];
      final List<ValueItem<int>> second = <ValueItem<int>>[];
      Function(ValueItem<int>) onTap = first.add;
      MultipleSearchDropDownController<int>? controller;
      late StateSetter rebuild;
      final MultipleSearchDropDownController<int> c =
          MultipleSearchDropDownController<int>(
            items: <ValueItem<int>>[const ValueItem(label: 'Kiwi', value: 9)],
            addMode: false,
            deleteMode: false,
          );
      addTearDown(c.dispose);
      await tester.pumpWidget(
        host(
          StatefulBuilder(
            builder: (BuildContext context, StateSetter setState) {
              rebuild = setState;
              return SizedBox(
                height: 400,
                width: 300,
                child: MultipleListView<int>(
                  controller: controller,
                  addMode: false,
                  editMode: false,
                  deleteMode: deleteMode,
                  overlayListSettings: const SimpleOverlaySettings(
                    dialogHeight: 380,
                  ),
                  searchBarSettings: const SimpleSearchbarSettings(),
                  listItens: items,
                  selectedItens: sel,
                  onAddItem: (_) {},
                  onDeleteItem: (_) {},
                  onEditItem: (_) {},
                  onItemSelected: onTap,
                  sortType: sortType,
                  newValueItem: (String s) => ValueItem(label: s, value: 0),
                  addAditionalWidget: null,
                  defaultAditionalWidget: null,
                ),
              );
            },
          ),
        ),
      );
      expect(_rows(tester), <String>['Uva', 'Banana', 'abacaxi']);
      rebuild(() => sortType = 1);
      await tester.pump();
      expect(_rows(tester), <String>['abacaxi', 'Banana', 'Uva']);
      // The callbacks of the latest widget are the ones called.
      rebuild(() => onTap = second.add);
      await tester.pump();
      await tester.tap(find.text('Uva'));
      await tester.pump();
      expect(first, isEmpty);
      expect(second.map((ValueItem<int> v) => v.label), <String>['Uva']);
      rebuild(() {
        items = <ValueItem<int>>[const ValueItem(label: 'Pêra', value: 5)];
        deleteMode = false;
      });
      await tester.pump();
      expect(_rows(tester), <String>['Pêra']);
      expect(find.byTooltip('Apagar item'), findsNothing);

      rebuild(() => controller = c);
      await tester.pump();
      expect(_rows(tester), <String>['Kiwi']);
      rebuild(() => controller = null);
      await tester.pump();
      expect(_rows(tester), <String>['Pêra']);
      expect(tester.takeException(), isNull);
    });

    testWidgets('the 7.x Aditional widgets are shown', (tester) async {
      await tester.pumpWidget(
        host(
          _legacyList(
            items: _items(),
            sel: <ValueItem<int>>[],
            addAditionalWidget: const Text('ADD-W'),
            defaultAditionalWidget: const Text('ROW-W'),
          ),
        ),
      );
      expect(find.text('ROW-W'), findsNWidgets(3));
      await tester.enterText(_field, 'zz');
      await tester.pump();
      expect(find.text('ADD-W'), findsOneWidget);
    });

    testWidgets('opens scrolled to the first selected item', (tester) async {
      final List<ValueItem<int>> items = numberedItems(60);
      await tester.pumpWidget(
        host(_legacyList(items: items, sel: <ValueItem<int>>[items[45]])),
      );
      await tester.pumpAndSettle();
      expect(find.text('Item 45'), findsOneWidget);
      expect(find.text('Item 0'), findsNothing);
    });

    testWidgets('a callback that selects is shown without any sort', (
      tester,
    ) async {
      final List<ValueItem<int>> sel = <ValueItem<int>>[];
      await tester.pumpWidget(
        host(_legacyList(items: _items(), sel: sel, onItemSelected: sel.add)),
      );
      await tester.tap(find.text('Banana'));
      await tester.pump();
      expect(_tile(tester, 'Banana').selected, isTrue);
      expect(_rows(tester), <String>['Uva', 'Banana', 'abacaxi']);
    });

    testWidgets('an add whose callback does not store the item leaves the '
        'lists alone and selects nothing', (tester) async {
      final List<ValueItem<int>> items = _items();
      final List<ValueItem<int>> sel = <ValueItem<int>>[];
      final List<ValueItem<int>> added = <ValueItem<int>>[];
      final List<ValueItem<int>> tapped = <ValueItem<int>>[];
      await tester.pumpWidget(
        host(
          _legacyList(
            items: items,
            sel: sel,
            onAddItem: added.add,
            onItemSelected: tapped.add,
          ),
        ),
      );
      await tester.enterText(_field, 'Kiwi');
      await tester.pump();
      await tester.tap(find.text('Criar'));
      await tester.pumpAndSettle();
      expect(added, hasLength(1));
      expect(items, hasLength(3));
      expect(sel, isEmpty);
      expect(tapped, isEmpty);
      expect(_rows(tester), <String>['Uva', 'Banana', 'abacaxi']);
    });

    testWidgets('an async onAddItem is awaited before the list redraws', (
      tester,
    ) async {
      final List<ValueItem<int>> items = _items();
      final Completer<void> done = Completer<void>();
      await tester.pumpWidget(
        host(
          _legacyList(
            items: items,
            sel: <ValueItem<int>>[],
            onAddItem: (ValueItem<int> v) async {
              await done.future;
              items.add(v);
            },
          ),
        ),
      );
      await tester.enterText(_field, 'Kiwi');
      await tester.pump();
      await tester.tap(find.text('Criar'));
      await tester.pump();
      expect(tester.widget<TextField>(_field).controller!.text, 'Kiwi');
      done.complete();
      await tester.pumpAndSettle();
      expect(tester.widget<TextField>(_field).controller!.text, isEmpty);
      expect(_rows(tester), <String>['Uva', 'Banana', 'abacaxi', 'Kiwi']);
    });

    testWidgets('without newValueItem the add row does nothing', (
      tester,
    ) async {
      final List<ValueItem<int>> added = <ValueItem<int>>[];
      await tester.pumpWidget(
        host(
          SizedBox(
            height: 400,
            width: 300,
            child: MultipleListView<int>(
              addMode: true,
              editMode: false,
              deleteMode: false,
              overlayListSettings: const SimpleOverlaySettings(
                dialogHeight: 380,
              ),
              searchBarSettings: const SimpleSearchbarSettings(),
              listItens: _items(),
              selectedItens: _noSelection(),
              onAddItem: added.add,
              onDeleteItem: (_) {},
              onEditItem: (_) {},
              onItemSelected: (_) {},
              sortType: 0,
              newValueItem: null,
              addAditionalWidget: null,
              defaultAditionalWidget: null,
            ),
          ),
        ),
      );
      await tester.enterText(_field, 'Kiwi');
      await tester.pump();
      await tester.tap(find.text('Criar'));
      await tester.pumpAndSettle();
      expect(added, isEmpty);
      expect(tester.takeException(), isNull);
    });

    testWidgets('an edit callback that renames the item is shown', (
      tester,
    ) async {
      final List<ValueItem<int>> items = _items();
      await tester.pumpWidget(
        host(
          _legacyList(
            items: items,
            sel: <ValueItem<int>>[],
            editMode: true,
            onEditItem: (ValueItem<int> v) => items[items.indexOf(v)] =
                const ValueItem(label: 'Kiwi', value: 1),
          ),
        ),
      );
      await tester.tap(find.byTooltip('Editar item').first);
      await tester.pumpAndSettle();
      expect(_rows(tester), <String>['Kiwi', 'Banana', 'abacaxi']);
    });

    testWidgets('parent rebuilds apply addMode, editMode and a new selection '
        'list', (tester) async {
      bool addMode = true;
      bool editMode = false;
      List<ValueItem<int>> sel = <ValueItem<int>>[];
      final List<ValueItem<int>> items = _items();
      late StateSetter rebuild;
      await tester.pumpWidget(
        host(
          StatefulBuilder(
            builder: (BuildContext context, StateSetter setState) {
              rebuild = setState;
              return _legacyList(
                items: items,
                sel: sel,
                addMode: addMode,
                editMode: editMode,
              );
            },
          ),
        ),
      );
      await tester.enterText(_field, 'zz');
      await tester.pump();
      expect(find.text('Criar'), findsOneWidget);
      rebuild(() {
        addMode = false;
        editMode = true;
        sel = <ValueItem<int>>[items[1]];
      });
      await tester.pump();
      expect(find.text('Criar'), findsNothing);
      await tester.enterText(_field, '');
      await tester.pump();
      expect(find.byTooltip('Editar item'), findsNWidgets(3));
      expect(_tile(tester, 'Banana').selected, isTrue);
    });

    testWidgets('an async delete that ends after switching to a controller '
        'is harmless', (tester) async {
      final Completer<void> done = Completer<void>();
      MultipleSearchDropDownController<int>? controller;
      late StateSetter rebuild;
      final MultipleSearchDropDownController<int> c =
          MultipleSearchDropDownController<int>(
            items: <ValueItem<int>>[const ValueItem(label: 'Kiwi', value: 9)],
            addMode: false,
            deleteMode: false,
          );
      addTearDown(c.dispose);
      final List<ValueItem<int>> items = _items();
      final List<ValueItem<int>> sel = <ValueItem<int>>[];
      await tester.pumpWidget(
        host(
          StatefulBuilder(
            builder: (BuildContext context, StateSetter setState) {
              rebuild = setState;
              return SizedBox(
                height: 400,
                width: 300,
                child: MultipleListView<int>(
                  controller: controller,
                  addMode: false,
                  editMode: false,
                  deleteMode: true,
                  overlayListSettings: const SimpleOverlaySettings(
                    dialogHeight: 380,
                  ),
                  searchBarSettings: const SimpleSearchbarSettings(),
                  listItens: items,
                  selectedItens: sel,
                  onAddItem: (_) {},
                  onDeleteItem: (_) => done.future,
                  onEditItem: (_) {},
                  onItemSelected: (_) {},
                  sortType: 0,
                  newValueItem: null,
                  addAditionalWidget: null,
                  defaultAditionalWidget: null,
                ),
              );
            },
          ),
        ),
      );
      await tester.tap(find.byTooltip('Apagar item').first);
      await tester.pump();
      rebuild(() => controller = c);
      await tester.pump();
      done.complete();
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(_rows(tester), <String>['Kiwi']);
    });

    testWidgets('the legacy controller is disposed when replaced or removed', (
      tester,
    ) async {
      int created = 0;
      int disposed = 0;
      void track(ObjectEvent event) {
        if (!'${event.object.runtimeType}'.startsWith('_LegacyList')) {
          return;
        }
        event is ObjectCreated ? created++ : disposed++;
      }

      FlutterMemoryAllocations.instance.addListener(track);
      addTearDown(
        () => FlutterMemoryAllocations.instance.removeListener(track),
      );
      MultipleSearchDropDownController<int>? controller;
      bool shown = true;
      late StateSetter rebuild;
      final MultipleSearchDropDownController<int> c =
          MultipleSearchDropDownController<int>(
            items: _items(),
            addMode: false,
            deleteMode: false,
          );
      addTearDown(c.dispose);
      final List<ValueItem<int>> items = _items();
      final List<ValueItem<int>> sel = <ValueItem<int>>[];
      await tester.pumpWidget(
        host(
          StatefulBuilder(
            builder: (BuildContext context, StateSetter setState) {
              rebuild = setState;
              if (!shown) {
                return const SizedBox();
              }
              return SizedBox(
                height: 400,
                width: 300,
                child: MultipleListView<int>(
                  controller: controller,
                  addMode: false,
                  editMode: false,
                  deleteMode: false,
                  overlayListSettings: const SimpleOverlaySettings(
                    dialogHeight: 380,
                  ),
                  searchBarSettings: const SimpleSearchbarSettings(),
                  listItens: items,
                  selectedItens: sel,
                  onAddItem: (_) {},
                  onDeleteItem: (_) {},
                  onEditItem: (_) {},
                  onItemSelected: (_) {},
                  sortType: 0,
                  newValueItem: null,
                  addAditionalWidget: null,
                  defaultAditionalWidget: null,
                ),
              );
            },
          ),
        ),
      );
      expect(<int>[created, disposed], <int>[1, 0]);
      rebuild(() => controller = c);
      await tester.pump();
      expect(<int>[created, disposed], <int>[1, 1]);
      rebuild(() => controller = null);
      await tester.pump();
      expect(<int>[created, disposed], <int>[2, 1]);
      rebuild(() => shown = false);
      await tester.pump();
      expect(<int>[created, disposed], <int>[2, 2]);
    });

    test('without a controller the 7.x callbacks are required too', () {
      expect(
        () => MultipleListView<int>(
          overlayListSettings: const SimpleOverlaySettings(),
          searchBarSettings: const SimpleSearchbarSettings(),
          listItens: _items(),
          selectedItens: _noSelection(),
        ),
        throwsAssertionError,
      );
    });

    test('without a controller the 7.x lists and callbacks are required', () {
      expect(
        () => MultipleListView<int>(
          overlayListSettings: const SimpleOverlaySettings(),
          searchBarSettings: const SimpleSearchbarSettings(),
        ),
        throwsAssertionError,
      );
    });
  });
}

List<ValueItem<int>> _items() => <ValueItem<int>>[
  const ValueItem(label: 'Uva', value: 1),
  const ValueItem(label: 'Banana', value: 2),
  const ValueItem(label: 'abacaxi', value: 3),
];

Finder get _field => find.descendant(
  of: find.byType(MultipleListView<int>),
  matching: find.byType(TextField),
);

List<String> _rows(WidgetTester tester) => tester
    .widgetList<DefaultListTile<int>>(find.byType(DefaultListTile<int>))
    .map((DefaultListTile<int> t) => t.item.label)
    .toList();

DefaultListTile<int> _tile(WidgetTester tester, String label) =>
    tester.widget<DefaultListTile<int>>(
      find.ancestor(
        of: find.text(label),
        matching: find.byType(DefaultListTile<int>),
      ),
    );

/// A `MultipleListView` built the 7.x way, every parameter passed.
Widget _legacyList({
  required List<ValueItem<int>> items,
  required List<ValueItem<int>> sel,
  Function(ValueItem<int>)? onItemSelected,
  Function(ValueItem<int>)? onAddItem,
  Function(ValueItem<int>)? onDeleteItem,
  Function(ValueItem<int>)? onEditItem,
  bool addMode = true,
  bool deleteMode = true,
  bool editMode = false,
  int sortType = 0,
  Widget? addAditionalWidget,
  Widget? defaultAditionalWidget,
}) => SizedBox(
  height: 400,
  width: 300,
  child: MultipleListView<int>(
    addMode: addMode,
    editMode: editMode,
    overlayListSettings: const SimpleOverlaySettings(dialogHeight: 380),
    deleteMode: deleteMode,
    listItens: items,
    onAddItem: onAddItem ?? (_) {},
    onDeleteItem: onDeleteItem ?? (_) {},
    onEditItem: onEditItem ?? (_) {},
    onItemSelected: onItemSelected ?? (_) {},
    selectedItens: sel,
    sortType: sortType,
    newValueItem: (String s) => ValueItem(label: s, value: 99),
    searchBarSettings: const SimpleSearchbarSettings(),
    addAditionalWidget: addAditionalWidget,
    defaultAditionalWidget: defaultAditionalWidget,
  ),
);

/// A fresh, growable selection list.
List<ValueItem<int>> _noSelection() => <ValueItem<int>>[];
