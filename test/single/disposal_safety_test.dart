// The single dropdown never touches a disposed or inactive SearchController
// (#49, #52), and reopening scrolls to the selection every time (#46).

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';
import 'package:simple_search_dropdown/simple_search_dropdown.dart';

import '../support/harness.dart';

Finder get _viewList => find.byType(ScrollablePositionedList);

/// Pumps a host and returns a context under its navigator, for the
/// controller's dialogs.
Future<BuildContext> _context(WidgetTester tester) async {
  late BuildContext ctx;
  await tester.pumpWidget(
    host(
      Builder(
        builder: (BuildContext context) {
          ctx = context;
          return const SizedBox();
        },
      ),
    ),
  );
  return ctx;
}

/// A controller over `Item 0..n-1` with a pending (completer-driven)
/// add/edit/delete callback.
SearchDropDownController<int> _crud({
  required SearchController searchController,
  required Completer<void> pending,
  int n = 3,
  ValueItem<int>? initial,
  bool Function(ValueItem<int>)? verify,
}) => SearchDropDownController<int>(
  items: numberedItems(n),
  searchController: searchController,
  newValueItem: (String s) => ValueItem<int>(label: s, value: 99),
  onAddItem: (_) => pending.future,
  onDeleteItem: (_) => pending.future,
  editMode: true,
  onEditItem: (_, _) => pending.future,
  verifyInputItem: verify,
  initialSelectedItem: initial,
);

SearchDropDownController<int> _plain(
  List<ValueItem<int>> items, {
  SearchController? searchController,
  ValueItem<int>? initial,
}) => SearchDropDownController<int>(
  items: items,
  searchController: searchController,
  addMode: false,
  deleteMode: false,
  initialSelectedItem: initial,
);

/// Records the scheduler phase of every notification of [notifier].
List<SchedulerPhase> _recordPhases(ChangeNotifier notifier) {
  final List<SchedulerPhase> phases = <SchedulerPhase>[];
  notifier.addListener(
    () => phases.add(SchedulerBinding.instance.schedulerPhase),
  );
  return phases;
}

void main() {
  group('#49: the caller disposes its SearchController while a callback is '
      'pending', () {
    testWidgets('add: the item is still added and selected, the disposed '
        'SearchController is left alone', (tester) async {
      final BuildContext ctx = await _context(tester);
      final SearchController external = SearchController();
      final Completer<void> pending = Completer<void>();
      final SearchDropDownController<int> c = _crud(
        searchController: external,
        pending: pending,
      );
      addTearDown(c.dispose);

      final Future<void> done = c.addItem('Kiwi', ctx);
      external.dispose();
      pending.complete();
      await expectLater(done, completes);
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(c.items.map((ValueItem<int> e) => e.label), contains('Kiwi'));
      expect(c.selectedItem?.label, 'Kiwi');
    });

    testWidgets('delete: the item is still removed and the selection cleared', (
      tester,
    ) async {
      final BuildContext ctx = await _context(tester);
      final SearchController external = SearchController();
      final Completer<void> pending = Completer<void>();
      final List<ValueItem<int>> items = numberedItems(3);
      final SearchDropDownController<int> c = _crud(
        searchController: external,
        pending: pending,
        initial: items[1],
      );
      addTearDown(c.dispose);

      final Future<void> done = c.deleteItem(items[1], ctx);
      external.dispose();
      pending.complete();
      await expectLater(done, completes);
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(c.items, isNot(contains(items[1])));
      expect(c.selectedItem, isNull);
    });

    testWidgets('edit: the item is still replaced and reselected', (
      tester,
    ) async {
      final BuildContext ctx = await _context(tester);
      final SearchController external = SearchController();
      final Completer<void> pending = Completer<void>();
      final List<ValueItem<int>> items = numberedItems(3);
      final SearchDropDownController<int> c = _crud(
        searchController: external,
        pending: pending,
        initial: items[1],
      );
      addTearDown(c.dispose);

      final Future<void> done = c.editItem(items[1], ctx);
      await tester.pumpAndSettle();
      await tester.enterText(
        find.descendant(
          of: find.byType(EditDialog),
          matching: find.byType(TextField),
        ),
        'Edited',
      );
      await tester.tap(
        find.descendant(
          of: find.byType(AlertDialog),
          matching: find.text('Editar'),
        ),
      );
      await tester.pumpAndSettle();
      external.dispose();
      pending.complete();
      await expectLater(done, completes);
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(c.items.map((ValueItem<int> e) => e.label), contains('Edited'));
      expect(c.selectedItem?.label, 'Edited');
    });

    testWidgets('a rejected add whose warning closes after the '
        'SearchController is disposed leaves it alone', (tester) async {
      final BuildContext ctx = await _context(tester);
      final SearchController external = SearchController()..text = 'Kiwi';
      final SearchDropDownController<int> c = _crud(
        searchController: external,
        pending: Completer<void>(),
        verify: (_) => false,
      );
      addTearDown(c.dispose);

      final Future<void> done = c.addItem('Kiwi', ctx);
      await tester.pumpAndSettle();
      expect(find.byType(AlertDialog), findsOneWidget);
      external.dispose();
      await tester.tap(find.byType(TextButton).first);
      await tester.pumpAndSettle();
      await expectLater(done, completes);

      expect(tester.takeException(), isNull);
      expect(c.items, hasLength(3));
    });

    testWidgets('selection changes made after the SearchController is '
        'disposed still update the controller', (tester) async {
      final SearchController external = SearchController();
      final List<ValueItem<int>> items = numberedItems(3);
      final SearchDropDownController<int> c = _plain(
        items,
        searchController: external,
      );
      addTearDown(c.dispose);
      external.dispose();

      c
        ..selectedItem = items[2]
        ..selectItem(items[1])
        ..resetSelection()
        ..onSearchOpen()
        ..onSearchClose(true);
      await tester.pump();

      expect(tester.takeException(), isNull);
      expect(c.selectedItem, isNull);
    });
  });

  test('clearing the selection refilters even when the text is already '
      'empty', () {
    final SearchDropDownController<int> c = _plain(numberedItems(4));
    addTearDown(c.dispose);
    c
      ..filterList('Item 1')
      ..resetSelection();

    expect(c.filteredItems, hasLength(4));
  });

  group('#49: swapping the controller while the view is open', () {
    testWidgets('closes the old view, so typing filters the new controller '
        'once the old one is disposed', (tester) async {
      final SearchDropDownController<int> a = _plain(fruitItems());
      final SearchDropDownController<int> b = _plain(numberedItems(3));
      await tester.pumpWidget(host(SearchDropDown<int>(controller: a)));
      await openSingle(tester);

      await tester.pumpWidget(host(SearchDropDown<int>(controller: b)));
      await tester.pumpAndSettle();
      expect(_viewList, findsNothing);
      a.dispose();

      await openSingle(tester);
      await typeInSingle(tester, 'Item 1');
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(b.localSearchController.text, 'Item 1');
      expect(b.filteredItems.map((ValueItem<int> e) => e.label), <String>[
        'Item 1',
      ]);
      expect(rowTile('Item 1'), findsOneWidget);
    });

    testWidgets('with SearchControllers passed in, the old one can be '
        'disposed right after the swap', (tester) async {
      final SearchController oldSearch = SearchController();
      final SearchController newSearch = SearchController();
      addTearDown(newSearch.dispose);
      final SearchDropDownController<int> a = _plain(
        fruitItems(),
        searchController: oldSearch,
      );
      final SearchDropDownController<int> b = _plain(
        numberedItems(3),
        searchController: newSearch,
      );
      addTearDown(b.dispose);
      await tester.pumpWidget(host(SearchDropDown<int>(controller: a)));
      await openSingle(tester);
      await typeInSingle(tester, 'Ba');

      await tester.pumpWidget(host(SearchDropDown<int>(controller: b)));
      // The caller disposes the old controllers in the frame of the swap.
      a.dispose();
      oldSearch.dispose();
      await tester.pumpAndSettle();
      expect(_viewList, findsNothing);

      await openSingle(tester);
      await typeInSingle(tester, 'Item 2');
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(b.filteredItems.map((ValueItem<int> e) => e.label), <String>[
        'Item 2',
      ]);
    });

    testWidgets('the closing old view does not close (or clear) the new '
        'controller', (tester) async {
      final SearchDropDownController<int> a = _plain(fruitItems());
      addTearDown(a.dispose);
      final SearchDropDownController<int> b = _plain(numberedItems(3));
      b.localSearchController.text = 'Ite';
      const SimpleSearchbarSettings clearing = SimpleSearchbarSettings(
        clearOnClose: true,
      );
      await tester.pumpWidget(
        host(SearchDropDown<int>(controller: a, searchBarSettings: clearing)),
      );
      await openSingle(tester);
      await typeInSingle(tester, 'Ba');

      await tester.pumpWidget(
        host(SearchDropDown<int>(controller: b, searchBarSettings: clearing)),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(b.localSearchController.text, 'Ite');
      // The old controller closed its own view (clearOnClose).
      expect(a.localSearchController.text, '');
    });
  });

  group('#49: the controller that opened a removed view hears it closed '
      'after that frame', () {
    testWidgets('on a swap, with a highlighted row', (tester) async {
      final SearchDropDownController<int> a = _plain(numberedItems(5));
      addTearDown(a.dispose);
      final SearchDropDownController<int> b = _plain(numberedItems(3));
      await tester.pumpWidget(host(SearchDropDown<int>(controller: a)));
      await openSingle(tester);
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pumpAndSettle();
      expect(a.highlightedIndex, 0);

      await tester.pumpWidget(host(SearchDropDown<int>(controller: b)));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(a.highlightedIndex, -1);
    });

    testWidgets('on unmount, with a highlighted row', (tester) async {
      final SearchController external = SearchController();
      addTearDown(external.dispose);
      final SearchDropDownController<int> c = _plain(
        numberedItems(5),
        searchController: external,
      );
      addTearDown(c.dispose);
      await tester.pumpWidget(host(SearchDropDown<int>(controller: c)));
      await openSingle(tester);
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pumpAndSettle();
      expect(c.highlightedIndex, 0);

      await tester.pumpWidget(host(const SizedBox()));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(c.highlightedIndex, -1);
    });
  });

  group('#49: unmounting while the view is open', () {
    for (final bool clearOnClose in <bool>[false, true]) {
      testWidgets('controller with its own SearchController '
          '(clearOnClose: $clearOnClose)', (tester) async {
        final SearchDropDownController<int> c = _plain(
          numberedItems(5),
          initial: numberedItems(5)[3],
        );
        await tester.pumpWidget(
          host(
            SearchDropDown<int>(
              controller: c,
              searchBarSettings: SimpleSearchbarSettings(
                clearOnClose: clearOnClose,
              ),
            ),
          ),
        );
        await openSingle(tester);
        await typeInSingle(tester, 'Item');

        await tester.pumpWidget(host(const SizedBox()));
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
        expect(c.isDisposed, isTrue);
        expect(_viewList, findsNothing);
      });

      testWidgets('controller with a SearchController passed in, disposed '
          'with it (clearOnClose: $clearOnClose)', (tester) async {
        final SearchController external = SearchController();
        final SearchDropDownController<int> c = _plain(
          numberedItems(5),
          searchController: external,
        );
        await tester.pumpWidget(
          host(
            SearchDropDown<int>(
              controller: c,
              searchBarSettings: SimpleSearchbarSettings(
                clearOnClose: clearOnClose,
              ),
            ),
          ),
        );
        await openSingle(tester);
        await typeInSingle(tester, 'Item');

        await tester.pumpWidget(host(const SizedBox()));
        // The caller disposes both in its own dispose, in that frame.
        c.dispose();
        external.dispose();
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
        expect(_viewList, findsNothing);
      });

      testWidgets('a controller disposed in that frame leaves the kept '
          'SearchController alone (clearOnClose: $clearOnClose)', (
        tester,
      ) async {
        final SearchController external = SearchController();
        addTearDown(external.dispose);
        final SearchDropDownController<int> c = _plain(
          numberedItems(5),
          searchController: external,
        );
        await tester.pumpWidget(
          host(
            _DisposeOnUnmount(
              controller: c,
              child: SearchDropDown<int>(
                controller: c,
                searchBarSettings: SimpleSearchbarSettings(
                  clearOnClose: clearOnClose,
                ),
              ),
            ),
          ),
        );
        await openSingle(tester);
        await typeInSingle(tester, 'Item');

        await tester.pumpWidget(host(const SizedBox()));
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
        expect(c.isDisposed, isTrue);
        expect(external.text, 'Item');
      });

      testWidgets('a kept controller works when mounted again '
          '(clearOnClose: $clearOnClose)', (tester) async {
        final SearchController external = SearchController();
        addTearDown(external.dispose);
        final SearchDropDownController<int> c = _plain(
          numberedItems(5),
          searchController: external,
        );
        addTearDown(c.dispose);
        Widget dropdown() => host(
          SearchDropDown<int>(
            controller: c,
            searchBarSettings: SimpleSearchbarSettings(
              clearOnClose: clearOnClose,
            ),
          ),
        );
        await tester.pumpWidget(dropdown());
        await openSingle(tester);
        await typeInSingle(tester, 'Item 4');
        await tester.pumpWidget(host(const SizedBox()));
        await tester.pumpAndSettle();
        // The controller heard that its view closed.
        expect(c.localSearchController.text, clearOnClose ? '' : 'Item 4');

        await tester.pumpWidget(dropdown());
        await openSingle(tester);
        await typeInSingle(tester, 'Item 2');
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
        expect(c.filteredItems.map((ValueItem<int> e) => e.label), <String>[
          'Item 2',
        ]);
        expect(rowTile('Item 2'), findsOneWidget);
      });
    }
  });

  group('#52: SearchController writes requested during a build wait for the '
      'frame', () {
    testWidgets('selectedItem set in the initState of a subtree that '
        'replaces one with a focused bar', (tester) async {
      final List<ValueItem<int>> items = numberedItems(4);
      final SearchDropDownController<int> c = _plain(items);
      addTearDown(c.dispose);
      final List<SchedulerPhase> phases = _recordPhases(
        c.localSearchController,
      );
      final ValueNotifier<bool> second = ValueNotifier<bool>(false);
      addTearDown(second.dispose);
      await tester.pumpWidget(
        host(
          ValueListenableBuilder<bool>(
            valueListenable: second,
            builder: (BuildContext context, bool replaced, _) => replaced
                ? _SelectOnInit(controller: c, item: items[2])
                : SearchDropDown<int>(controller: c, disposeController: false),
          ),
        ),
      );
      tester
          .widget<EditableText>(find.byType(EditableText))
          .focusNode
          .requestFocus();
      await tester.pump();

      second.value = true;
      await tester.pump();
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(phases, isNot(contains(SchedulerPhase.persistentCallbacks)));
      expect(c.selectedItem, items[2]);
      expect(c.localSearchController.text, 'Item 2');
      expect(find.text('Item 2'), findsOneWidget);
    });

    testWidgets('a controller created during a build over a shared '
        'SearchController shows its initial selection after the frame', (
      tester,
    ) async {
      final SearchController shared = SearchController();
      addTearDown(shared.dispose);
      final List<ValueItem<int>> items = numberedItems(4);
      final SearchDropDownController<int> first = _plain(
        items,
        searchController: shared,
      );
      addTearDown(first.dispose);
      final List<SchedulerPhase> phases = _recordPhases(shared);
      final ValueNotifier<bool> second = ValueNotifier<bool>(false);
      addTearDown(second.dispose);
      SearchDropDownController<int>? created;
      await tester.pumpWidget(
        host(
          ValueListenableBuilder<bool>(
            valueListenable: second,
            builder: (BuildContext context, bool replaced, _) => replaced
                ? _CreateOnInit(
                    create: () => created = _plain(
                      items,
                      searchController: shared,
                      initial: items[1],
                    ),
                  )
                : SearchDropDown<int>(controller: first),
          ),
        ),
      );
      tester
          .widget<EditableText>(find.byType(EditableText))
          .focusNode
          .requestFocus();
      await tester.pump();

      second.value = true;
      await tester.pump();
      await tester.pumpAndSettle();
      addTearDown(() => created?.dispose());

      expect(tester.takeException(), isNull);
      expect(phases, isNot(contains(SchedulerPhase.persistentCallbacks)));
      expect(created?.selectedItem, items[1]);
      expect(shared.text, 'Item 1');
      expect(find.text('Item 1'), findsOneWidget);
    });

    testWidgets('a controller that creates its own SearchController shows '
        'its initial selection in the first frame', (tester) async {
      final List<ValueItem<int>> items = numberedItems(4);
      SearchDropDownController<int>? created;
      final List<String> textInBuild = <String>[];
      await tester.pumpWidget(
        host(
          _CreateOnInit(
            create: () => created = _plain(items, initial: items[3]),
            onBuild: (SearchDropDownController<int> c) =>
                textInBuild.add(c.localSearchController.text),
          ),
        ),
      );
      addTearDown(() => created?.dispose());

      expect(textInBuild.first, 'Item 3');
      expect(created?.localSearchController.text, 'Item 3');
      expect(find.text('Item 3'), findsOneWidget);
    });

    testWidgets('a write deferred from a build is dropped when the '
        'controller is disposed in that frame', (tester) async {
      final List<ValueItem<int>> items = numberedItems(4);
      final SearchDropDownController<int> c = _plain(items);
      final List<SchedulerPhase> phases = _recordPhases(
        c.localSearchController,
      );
      await tester.pumpWidget(
        host(
          Builder(
            builder: (BuildContext context) {
              c
                ..selectedItem = items[1]
                ..dispose();
              return const SizedBox();
            },
          ),
        ),
      );
      await tester.pump();

      expect(tester.takeException(), isNull);
      expect(phases, isEmpty);
    });

    testWidgets('the selection reads at once, the text follows after the '
        'frame', (tester) async {
      final List<ValueItem<int>> items = numberedItems(4);
      final SearchDropDownController<int> c = _plain(items);
      addTearDown(c.dispose);
      String? textInBuild;
      ValueItem<int>? selectedInBuild;
      await tester.pumpWidget(
        host(
          Builder(
            builder: (BuildContext context) {
              c.selectedItem = items[2];
              selectedInBuild = c.selectedItem;
              textInBuild = c.localSearchController.text;
              return const SizedBox();
            },
          ),
        ),
      );

      expect(selectedInBuild, items[2]);
      expect(textInBuild, '');
      expect(c.localSearchController.text, 'Item 2');
    });
  });

  group('#46: reopening scrolls to the selection', () {
    testWidgets('a selection near the end of the list does not render the '
        'first item', (tester) async {
      final List<ValueItem<int>> items = numberedItems(200);
      final SearchDropDownController<int> c = _plain(
        items,
        initial: items[195],
      );
      await tester.pumpWidget(host(SearchDropDown<int>(controller: c)));

      await openSingle(tester);
      expect(rowTile('Item 195'), findsOneWidget);
      expect(rowTile('Item 0'), findsNothing);

      await tester.tap(find.byIcon(Icons.arrow_drop_up));
      await tester.pumpAndSettle();
      await openSingle(tester);
      expect(rowTile('Item 195'), findsOneWidget);
      expect(rowTile('Item 0'), findsNothing);
    });

    testWidgets('every reopen scrolls to the selection again, also after the '
        'list was scrolled away or another item was selected', (tester) async {
      final List<ValueItem<int>> items = numberedItems(200);
      final SearchDropDownController<int> c = _plain(
        items,
        initial: items[150],
      );
      await tester.pumpWidget(host(SearchDropDown<int>(controller: c)));
      await openSingle(tester);
      expect(rowTile('Item 150'), findsOneWidget);

      // Scroll away to the top, then close without selecting.
      await tester.sendKeyEvent(LogicalKeyboardKey.pageUp);
      await tester.pumpAndSettle();
      expect(rowTile('Item 0'), findsOneWidget);
      expect(rowTile('Item 150'), findsNothing);
      await tester.tap(find.byIcon(Icons.arrow_drop_up));
      await tester.pumpAndSettle();

      await openSingle(tester);
      expect(rowTile('Item 150'), findsOneWidget);
      expect(rowTile('Item 0'), findsNothing);

      // Select another item far down, then reopen.
      await typeInSingle(tester, 'Item 120');
      await tester.pumpAndSettle();
      await tester.tap(rowTile('Item 120'));
      await tester.pumpAndSettle();
      expect(c.selectedItem, items[120]);

      await openSingle(tester);
      expect(rowTile('Item 120'), findsOneWidget);
      expect(rowTile('Item 0'), findsNothing);
    });
  });
}

/// Sets [controller]'s selection in `initState`, then shows a dropdown.
class _SelectOnInit extends StatefulWidget {
  const _SelectOnInit({required this.controller, required this.item});

  final SearchDropDownController<int> controller;
  final ValueItem<int> item;

  @override
  State<_SelectOnInit> createState() => _SelectOnInitState();
}

class _SelectOnInitState extends State<_SelectOnInit> {
  @override
  void initState() {
    super.initState();
    widget.controller.selectedItem = widget.item;
  }

  @override
  Widget build(BuildContext context) => SearchDropDown<int>(
    controller: widget.controller,
    disposeController: false,
  );
}

/// Creates a controller in `initState`, then shows a dropdown with it.
class _CreateOnInit extends StatefulWidget {
  const _CreateOnInit({required this.create, this.onBuild});

  final SearchDropDownController<int> Function() create;
  final void Function(SearchDropDownController<int> controller)? onBuild;

  @override
  State<_CreateOnInit> createState() => _CreateOnInitState();
}

class _CreateOnInitState extends State<_CreateOnInit> {
  late final SearchDropDownController<int> _controller = widget.create();

  @override
  Widget build(BuildContext context) {
    widget.onBuild?.call(_controller);
    return SearchDropDown<int>(
      controller: _controller,
      disposeController: false,
    );
  }
}

/// Disposes [controller] in its own `dispose`, like a page that owns it.
class _DisposeOnUnmount extends StatefulWidget {
  const _DisposeOnUnmount({required this.controller, required this.child});

  final SearchDropDownController<int> controller;
  final Widget child;

  @override
  State<_DisposeOnUnmount> createState() => _DisposeOnUnmountState();
}

class _DisposeOnUnmountState extends State<_DisposeOnUnmount> {
  @override
  void dispose() {
    widget.controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
