// Characterization tests for the MultipleSearchDropDown widget, through the
// public API and the user-visible widgets. Written against v7.8.0, they now
// lock the 8.0 behaviour; "(8.0)" marks a deliberate change from 7.x. Tests
// tagged 'M<n>' are regression tests for a 7.x bug fixed in 8.0.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:simple_search_dropdown/simple_search_dropdown.dart';
import 'package:simple_search_dropdown/src/multiple/multiple_listview.dart';

import '../support/harness.dart';

// A taller overlay so every row of the small fixtures is built and visible.
const SimpleOverlaySettings _tallOverlay = SimpleOverlaySettings(
  dialogHeight: 400,
);

// Records every callback the widget fires, and holds the controller that
// [_dropdown] built for it.
class _Probe {
  final List<List<ValueItem<int>>> updates = <List<ValueItem<int>>>[];
  final List<ValueItem<int>> clearedItems = <ValueItem<int>>[];
  final List<ValueItem<int>> added = <ValueItem<int>>[];
  final List<ValueItem<int>> deleted = <ValueItem<int>>[];
  final List<ValueItem<int>> edited = <ValueItem<int>>[];
  int clearList = 0;
  MultipleSearchDropDownController<int>? controller;

  /// The controller's selection (its own copy of the `selected` passed in).
  List<ValueItem<int>> get selection => controller!.selectedItems;

  /// The controller's items (its own copy of the `items` passed in).
  List<ValueItem<int>> get items => controller!.items;
}

// Deliberately unsorted and mixed case: 'Cherry', 'apple', 'Banana'.
List<ValueItem<int>> _items() => <ValueItem<int>>[
  const ValueItem(label: 'Cherry', value: 3),
  const ValueItem(label: 'apple', value: 1),
  const ValueItem(label: 'Banana', value: 2),
];

List<String> _labels(List<ValueItem<int>> list) =>
    list.map((e) => e.label).toList();

// Puts the dropdown at a known place (20, 20) at the top-left of the screen,
// so the overlay below it fits on the 800x600 test surface.
Widget _app(Widget child) => MaterialApp(
  home: Scaffold(
    body: Align(
      alignment: Alignment.topLeft,
      child: Padding(padding: const EdgeInsets.all(20), child: child),
    ),
  ),
);

// The 7.x widget parameters, now on a controller that [probe] keeps: a
// rebuild with the same probe reuses it (its parameters are taken once).
MultipleSearchDropDown<int> _dropdown({
  required List<ValueItem<int>> items,
  required List<ValueItem<int>> selected,
  required _Probe probe,
  Key? key,
  bool addMode = false,
  bool deleteMode = false,
  bool editMode = false,
  bool confirmDelete = false,
  bool addToList = true,
  SortType sort = SortType.none,
  bool enabled = true,
  bool trim = true,
  bool Function(ValueItem<int>)? verifyInputItem,
  SimpleSearchbarSettings settings = defaultSearchBarSettings,
  SimpleOverlaySettings overlay = _tallOverlay,
  Widget? addAdditionalWidget,
  Widget? defaultAdditionalWidget,
}) {
  final MultipleSearchDropDownController<int> controller =
      probe.controller ??
      _disposedAtEnd(
        MultipleSearchDropDownController<int>(
          items: items,
          selectedItems: selected,
          updateSelectedItems: probe.updates.add,
          onClearItem: probe.clearedItems.add,
          onClearList: () => probe.clearList++,
          addMode: addMode,
          newValueItem: (input) => ValueItem<int>(label: input, value: 99),
          onAddItem: (item) {
            probe.added.add(item);
            if (addToList) {
              items.add(item);
            }
          },
          deleteMode: deleteMode,
          onDeleteItem: (item) {
            probe.deleted.add(item);
            items.remove(item);
          },
          editMode: editMode,
          onEditItem: (_, edited) => probe.edited.add(edited),
          confirmDelete: confirmDelete,
          sort: sort,
          enabled: enabled,
          trim: trim,
          verifyInputItem: verifyInputItem,
        ),
      );
  probe.controller = controller;
  return MultipleSearchDropDown<int>(
    key: key,
    controller: controller,
    searchBarSettings: settings,
    overlayListSettings: overlay,
    addAdditionalWidget: addAdditionalWidget,
    defaultAdditionalWidget: defaultAdditionalWidget,
  );
}

MultipleSearchDropDownController<int> _disposedAtEnd(
  MultipleSearchDropDownController<int> controller,
) {
  addTearDown(controller.dispose);
  return controller;
}

// The same wiring as [_dropdown], on a controller the test drives directly.
MultipleSearchDropDownController<int> _controller({
  required List<ValueItem<int>> items,
  required List<ValueItem<int>> selected,
  required _Probe probe,
  bool enabled = true,
}) => probe.controller = MultipleSearchDropDownController<int>(
  items: items,
  selectedItems: selected,
  updateSelectedItems: probe.updates.add,
  onClearItem: probe.clearedItems.add,
  onClearList: () => probe.clearList++,
  addMode: false,
  deleteMode: false,
  enabled: enabled,
);

MultipleSearchDropDown<int> _controlled(
  MultipleSearchDropDownController<int> controller,
) => MultipleSearchDropDown<int>(
  controller: controller,
  overlayListSettings: _tallOverlay,
);

// The closed box only (8.0 draws the open list as an OverlayPortal child,
// which is part of the widget's subtree).
Finder get _box => find
    .descendant(
      of: find.byType(MultipleSearchDropDown<int>),
      matching: find.byType(Opacity),
    )
    .first;
Finder get _list => find.byType(MultipleListView<int>);
Finder get _searchField =>
    find.descendant(of: _list, matching: find.byType(TextField));
Finder _inBox(Finder f) => find.descendant(of: _box, matching: f);
Finder _inList(Finder f) => find.descendant(of: _list, matching: f);
Finder _row(String label) => find.widgetWithText(DefaultListTile<int>, label);

// Labels of the overlay rows, in list order.
List<String> _rowLabels(WidgetTester tester) => tester
    .widgetList<DefaultListTile<int>>(find.byType(DefaultListTile<int>))
    .map((t) => t.item.label)
    .toList();

bool _rowSelected(WidgetTester tester, String label) =>
    tester.widget<DefaultListTile<int>>(_row(label)).selected;

String _searchText(WidgetTester tester) =>
    tester.widget<TextField>(_searchField).controller!.text;

double _opacity(WidgetTester tester) => tester.widget<Opacity>(_box).opacity;

bool _ignoring(WidgetTester tester) => tester
    .widget<IgnorePointer>(_inBox(find.byType(IgnorePointer)).first)
    .ignoring;

Future<void> _tapRow(WidgetTester tester, String label) async {
  await tester.tap(_inList(find.text(label)));
  await tester.pump();
}

Future<void> _type(WidgetTester tester, String text) async {
  await tester.enterText(_searchField, text);
  await tester.pump();
}

void main() {
  group('closed state: hint when nothing is selected', () {
    testWidgets('shows the default hint "Pesquisar" and no chips', (
      tester,
    ) async {
      await tester.pumpWidget(
        _app(_dropdown(items: _items(), selected: [], probe: _Probe())),
      );

      expect(_inBox(find.text('Pesquisar')), findsOneWidget);
      expect(_inBox(find.byType(Card)), findsNothing);
      expect(_list, findsNothing);
    });

    testWidgets('uses searchBarSettings.hint and hintStyle', (tester) async {
      const style = TextStyle(fontSize: 18, color: Colors.purple);
      await tester.pumpWidget(
        _app(
          _dropdown(
            items: _items(),
            selected: [],
            probe: _Probe(),
            settings: const SimpleSearchbarSettings(
              hint: 'Choose',
              hintStyle: style,
            ),
          ),
        ),
      );

      final Text hint = tester.widget<Text>(_inBox(find.text('Choose')));
      expect(hint.style, style);
      expect(hint.textAlign, TextAlign.start);
    });

    testWidgets('hint is not shown when there is a selection', (tester) async {
      final items = _items();
      await tester.pumpWidget(
        _app(_dropdown(items: items, selected: [items[0]], probe: _Probe())),
      );

      expect(_inBox(find.text('Pesquisar')), findsNothing);
    });
  });

  group('closed state: selected item chips (Card + label + close icon)', () {
    testWidgets('one Card chip per selected item, in selection order', (
      tester,
    ) async {
      final items = _items();
      await tester.pumpWidget(
        _app(
          _dropdown(
            items: items,
            selected: [items[1], items[0]],
            probe: _Probe(),
          ),
        ),
      );

      expect(_inBox(find.byType(Card)), findsNWidgets(2));
      expect(_inBox(find.byIcon(Icons.close)), findsNWidgets(2));
      expect(_inBox(find.text('apple')), findsOneWidget);
      expect(_inBox(find.text('Cherry')), findsOneWidget);
      expect(
        tester.getTopLeft(_inBox(find.text('apple'))).dx,
        lessThan(tester.getTopLeft(_inBox(find.text('Cherry'))).dx),
      );
    });

    testWidgets('chips render selectedItems even if absent from listItems', (
      tester,
    ) async {
      await tester.pumpWidget(
        _app(
          _dropdown(
            items: _items(),
            selected: [const ValueItem(label: 'Ghost', value: 7)],
            probe: _Probe(),
          ),
        ),
      );

      expect(_inBox(find.text('Ghost')), findsOneWidget);
      expect(_inBox(find.byType(Card)), findsOneWidget);
    });
  });

  group('closed state: boxMultiItemWidgetBuilder replaces the chip', () {
    testWidgets('builder output is used instead of Card + close icon', (
      tester,
    ) async {
      final items = _items();
      await tester.pumpWidget(
        _app(
          _dropdown(
            items: items,
            selected: [items[0], items[2]],
            probe: _Probe(),
            settings: SimpleSearchbarSettings(
              boxMultiItemWidgetBuilder: (item) => Text('custom ${item.label}'),
            ),
          ),
        ),
      );

      expect(_inBox(find.text('custom Cherry')), findsOneWidget);
      expect(_inBox(find.text('custom Banana')), findsOneWidget);
      expect(_inBox(find.byType(Card)), findsNothing);
      expect(_inBox(find.byIcon(Icons.close)), findsNothing);
    });
  });

  group('closed state: boxMultiSelected* chip styling', () {
    testWidgets('default chip styling', (tester) async {
      final items = _items();
      await tester.pumpWidget(
        _app(_dropdown(items: items, selected: [items[0]], probe: _Probe())),
      );

      final Card card = tester.widget<Card>(_inBox(find.byType(Card)));
      expect(card.color, const Color.fromRGBO(224, 224, 224, 1));
      expect(card.elevation, 2);
      final Icon close = tester.widget<Icon>(_inBox(find.byIcon(Icons.close)));
      expect(close.size, 20);
      expect(close.color, isNull);
      expect(tester.widget<Text>(_inBox(find.text('Cherry'))).style, isNull);
    });

    testWidgets('custom background, text style, close icon size/color and '
        'elevation', (tester) async {
      final items = _items();
      const textStyle = TextStyle(color: Colors.red);
      await tester.pumpWidget(
        _app(
          _dropdown(
            items: items,
            selected: [items[0]],
            probe: _Probe(),
            settings: const SimpleSearchbarSettings(
              elevation: 6,
              boxMultiSelectedBackgroundColor: Colors.amber,
              boxMultiSelectedTextStyle: textStyle,
              boxMultiSelectedClearIconSize: 12,
              boxMultiSelectedClearIconColor: Colors.blue,
            ),
          ),
        ),
      );

      final Card card = tester.widget<Card>(_inBox(find.byType(Card)));
      expect(card.color, Colors.amber);
      expect(card.elevation, 6);
      final Icon close = tester.widget<Icon>(_inBox(find.byIcon(Icons.close)));
      expect(close.size, 12);
      expect(close.color, Colors.blue);
      expect(tester.widget<Text>(_inBox(find.text('Cherry'))).style, textStyle);
    });
  });

  group('closed state: trailing icon (arrow / clear)', () {
    testWidgets('no selection: closed arrow with outsideIconSize default 20', (
      tester,
    ) async {
      await tester.pumpWidget(
        _app(_dropdown(items: _items(), selected: [], probe: _Probe())),
      );

      final Icon arrow = tester.widget<Icon>(
        _inBox(find.byIcon(Icons.arrow_drop_down)),
      );
      expect(arrow.size, 20);
      expect(arrow.color, isNull);
      expect(_inBox(find.byIcon(Icons.clear)), findsNothing);
    });

    testWidgets('outsideIconSize and outsideIconColor are applied', (
      tester,
    ) async {
      await tester.pumpWidget(
        _app(
          _dropdown(
            items: _items(),
            selected: [],
            probe: _Probe(),
            settings: const SimpleSearchbarSettings(
              outsideIconSize: 30,
              outsideIconColor: Colors.green,
            ),
          ),
        ),
      );

      final Icon arrow = tester.widget<Icon>(
        _inBox(find.byIcon(Icons.arrow_drop_down)),
      );
      expect(arrow.size, 30);
      expect(arrow.color, Colors.green);
    });

    testWidgets('showArrow false: no trailing icon at all', (tester) async {
      await tester.pumpWidget(
        _app(
          _dropdown(
            items: _items(),
            selected: [],
            probe: _Probe(),
            settings: const SimpleSearchbarSettings(showArrow: false),
          ),
        ),
      );

      expect(_inBox(find.byType(Icon)), findsNothing);
    });

    testWidgets('custom closed/opened arrow icons follow the open state', (
      tester,
    ) async {
      await tester.pumpWidget(
        _app(
          _dropdown(
            items: _items(),
            selected: [],
            probe: _Probe(),
            settings: const SimpleSearchbarSettings(
              dropdownClosedArrowIcon: Icons.expand_more,
              dropdownOpenedArrowIcon: Icons.expand_less,
            ),
          ),
        ),
      );
      expect(_inBox(find.byIcon(Icons.expand_more)), findsOneWidget);

      await openMultiple(tester);
      expect(_inBox(find.byIcon(Icons.expand_less)), findsOneWidget);
      expect(_inBox(find.byIcon(Icons.expand_more)), findsNothing);
    });

    testWidgets('with selection: clear icon instead of the arrow', (
      tester,
    ) async {
      final items = _items();
      await tester.pumpWidget(
        _app(_dropdown(items: items, selected: [items[0]], probe: _Probe())),
      );

      expect(_inBox(find.byIcon(Icons.clear)), findsOneWidget);
      expect(_inBox(find.byIcon(Icons.arrow_drop_down)), findsNothing);
    });

    testWidgets('with selection and showClearIcon false: no clear, no arrow', (
      tester,
    ) async {
      final items = _items();
      await tester.pumpWidget(
        _app(
          _dropdown(
            items: items,
            selected: [items[0]],
            probe: _Probe(),
            settings: const SimpleSearchbarSettings(showClearIcon: false),
          ),
        ),
      );

      expect(_inBox(find.byIcon(Icons.clear)), findsNothing);
      expect(_inBox(find.byIcon(Icons.arrow_drop_down)), findsNothing);
      expect(_inBox(find.byIcon(Icons.close)), findsOneWidget);
    });

    testWidgets('tapping the arrow (no selection) opens the list (M5, 8.0)', (
      tester,
    ) async {
      final probe = _Probe();
      final List<ValueItem<int>> selected = [];
      await tester.pumpWidget(
        _app(_dropdown(items: _items(), selected: selected, probe: probe)),
      );

      await tester.tap(_inBox(find.byIcon(Icons.arrow_drop_down)));
      await tester.pumpAndSettle();

      expect(_list, findsOneWidget);
      expect(probe.updates, isEmpty);
      expect(probe.clearList, 0);
      expect(_inBox(find.byIcon(Icons.arrow_drop_up)), findsOneWidget);
    });
  });

  group('overlay: open/close by tapping the box', () {
    testWidgets('tapping the box opens the list overlay with a search bar', (
      tester,
    ) async {
      await tester.pumpWidget(
        _app(_dropdown(items: _items(), selected: [], probe: _Probe())),
      );

      await openMultiple(tester);

      expect(_list, findsOneWidget);
      expect(_searchField, findsOneWidget);
      expect(_inList(find.text('Pesquisar')), findsOneWidget);
      expect(_rowLabels(tester), ['Cherry', 'apple', 'Banana']);
      expect(_inBox(find.byIcon(Icons.arrow_drop_up)), findsOneWidget);
      expect(_inBox(find.byIcon(Icons.arrow_drop_down)), findsNothing);
    });

    testWidgets('tapping the box again closes it, and it can be reopened', (
      tester,
    ) async {
      await tester.pumpWidget(
        _app(_dropdown(items: _items(), selected: [], probe: _Probe())),
      );

      await openMultiple(tester);
      // The overlay barrier covers the box, so this tap lands on it.
      await tester.tapAt(tester.getCenter(_box));
      await tester.pumpAndSettle();
      expect(_list, findsNothing);
      expect(_inBox(find.byIcon(Icons.arrow_drop_down)), findsOneWidget);

      await openMultiple(tester);
      expect(_list, findsOneWidget);
      expect(_inBox(find.byIcon(Icons.arrow_drop_up)), findsOneWidget);
    });

    testWidgets('opening does not select or notify anything', (tester) async {
      final probe = _Probe();
      final List<ValueItem<int>> selected = [];
      await tester.pumpWidget(
        _app(_dropdown(items: _items(), selected: selected, probe: probe)),
      );

      await openMultiple(tester);

      expect(probe.selection, isEmpty);
      expect(probe.updates, isEmpty);
    });
  });

  group('overlay: reopens scrolled to the first selected item', () {
    Future<List<ValueItem<int>>> openScrolled(
      WidgetTester tester, {
      required List<int> selectedIdx,
      SortType sort = SortType.none,
    }) async {
      final items = numberedItems(50);
      await tester.pumpWidget(
        _app(
          _dropdown(
            items: items,
            selected: [for (final i in selectedIdx) items[i]],
            probe: _Probe(),
            sort: sort,
          ),
        ),
      );
      await openMultiple(tester);
      return items;
    }

    void expectScrolledTo(WidgetTester tester, String label) {
      expect(_row(label), findsOneWidget);
      expect(_rowSelected(tester, label), isTrue);
      final Rect list = tester.getRect(_list);
      final double top = tester.getRect(_row(label)).top;
      expect(top >= list.top && top < list.bottom, isTrue, reason: '$top');
      expect(_row('Item 0'), findsNothing);
    }

    testWidgets('a selection far down the list is visible on open', (
      tester,
    ) async {
      await openScrolled(tester, selectedIdx: [40]);
      expectScrolledTo(tester, 'Item 40');
    });

    testWidgets('scrolls again on every reopen', (tester) async {
      await openScrolled(tester, selectedIdx: [40]);
      await tester.tapAt(tester.getCenter(_box));
      await tester.pumpAndSettle();
      expect(_list, findsNothing);

      await openMultiple(tester);
      expectScrolledTo(tester, 'Item 40');
    });

    testWidgets('uses the FIRST selected item', (tester) async {
      await openScrolled(tester, selectedIdx: [40, 3]);
      expectScrolledTo(tester, 'Item 40');
    });

    testWidgets('index <= 1 does not scroll', (tester) async {
      await openScrolled(tester, selectedIdx: [1]);
      expect(_row('Item 0'), findsOneWidget);
      expect(tester.getRect(_row('Item 0')).top, greaterThan(0));
    });

    testWidgets('selectedFirst puts the selection at index 0: no scroll', (
      tester,
    ) async {
      await openScrolled(
        tester,
        selectedIdx: [40],
        sort: SortType.selectedFirst,
      );
      expect(_rowLabels(tester).take(2), ['Item 40', 'Item 0']);
    });
  });

  group('overlay: tapping outside closes (hideOverlay barrier)', () {
    testWidgets('tap far outside the list closes the overlay', (tester) async {
      await tester.pumpWidget(
        _app(_dropdown(items: _items(), selected: [], probe: _Probe())),
      );
      await openMultiple(tester);

      await tester.tapAt(const Offset(780, 580));
      await tester.pumpAndSettle();

      expect(_list, findsNothing);
      expect(_inBox(find.byIcon(Icons.arrow_drop_down)), findsOneWidget);
    });

    testWidgets('tapping inside the list (search field) keeps it open', (
      tester,
    ) async {
      await tester.pumpWidget(
        _app(_dropdown(items: _items(), selected: [], probe: _Probe())),
      );
      await openMultiple(tester);

      await tester.tap(_searchField);
      await tester.pumpAndSettle();

      expect(_list, findsOneWidget);
    });
  });

  group('overlay: positioned below the box (offsetHeight/offsetWidth)', () {
    testWidgets('default: box height + 3 below, same left, same width', (
      tester,
    ) async {
      await tester.pumpWidget(
        _app(_dropdown(items: _items(), selected: [], probe: _Probe())),
      );
      await openMultiple(tester);

      expect(tester.getTopLeft(_box), const Offset(20, 20));
      expect(
        tester.getTopLeft(_list) - tester.getTopLeft(_box),
        const Offset(0, 53),
      );
      expect(tester.getSize(_list).width, 300);
    });

    testWidgets('custom offsets and box size', (tester) async {
      await tester.pumpWidget(
        _app(
          _dropdown(
            items: _items(),
            selected: [],
            probe: _Probe(),
            settings: const SimpleSearchbarSettings(
              dropdownWidth: 250,
              dropdownHeight: 40,
            ),
            overlay: const SimpleOverlaySettings(
              dialogHeight: 400,
              offsetHeight: 20,
              offsetWidth: 10,
            ),
          ),
        ),
      );
      await openMultiple(tester);

      expect(tester.getSize(_box), const Size(250, 40));
      expect(
        tester.getTopLeft(_list) - tester.getTopLeft(_box),
        const Offset(10, 60),
      );
      expect(tester.getSize(_list).width, 250);
    });
  });

  group('overlay search: accent and case insensitive filter', () {
    testWidgets('filters by latinized, lower-cased contains', (tester) async {
      await tester.pumpWidget(
        _app(_dropdown(items: fruitItems(), selected: [], probe: _Probe())),
      );
      await openMultiple(tester);

      await _type(tester, 'MACA');
      expect(_rowLabels(tester), ['Maçã']);
      await _type(tester, 'pera');
      expect(_rowLabels(tester), ['Pêra']);
      await _type(tester, 'AB');
      expect(_rowLabels(tester), ['abacaxi']);
      await _type(tester, 'ã');
      expect(_rowLabels(tester), ['Maçã', 'Banana', 'Uva', 'abacaxi', 'Pêra']);
      await _type(tester, 'zzz');
      expect(_rowLabels(tester), isEmpty);
      await _type(tester, '');
      expect(_rowLabels(tester), ['Maçã', 'Banana', 'Uva', 'abacaxi', 'Pêra']);
    });

    testWidgets('filtered rows keep the sort ordering', (tester) async {
      await tester.pumpWidget(
        _app(
          _dropdown(
            items: fruitItems(),
            selected: [],
            probe: _Probe(),
            sort: SortType.alphabetical,
          ),
        ),
      );
      await openMultiple(tester);

      await _type(tester, 'a');
      // D2 (8.0): case and accents are ignored when sorting.
      expect(_rowLabels(tester), ['abacaxi', 'Banana', 'Maçã', 'Pêra', 'Uva']);
    });

    testWidgets('selected rows stay highlighted while filtering', (
      tester,
    ) async {
      final items = fruitItems();
      await tester.pumpWidget(
        _app(_dropdown(items: items, selected: [items[1]], probe: _Probe())),
      );
      await openMultiple(tester);

      await _type(tester, 'ban');
      expect(_rowLabels(tester), ['Banana']);
      expect(_rowSelected(tester, 'Banana'), isTrue);
    });
  });

  group('overlay search: with trim: false surrounding whitespace is '
      'significant (7.x matching)', () {
    List<ValueItem<int>> names() => <ValueItem<int>>[
      const ValueItem(label: 'Maria Ana', value: 1),
      const ValueItem(label: 'Mariana', value: 2),
      const ValueItem(label: 'Ana', value: 3),
      const ValueItem(label: 'Ana Paula', value: 4),
    ];

    testWidgets('a leading or trailing space narrows to word boundaries', (
      tester,
    ) async {
      await tester.pumpWidget(
        _app(
          _dropdown(items: names(), selected: [], probe: _Probe(), trim: false),
        ),
      );
      await openMultiple(tester);

      await _type(tester, ' ana');
      expect(_rowLabels(tester), ['Maria Ana']);
      await _type(tester, 'Ana ');
      expect(_rowLabels(tester), ['Ana Paula']);
      await _type(tester, ' ');
      expect(_rowLabels(tester), ['Maria Ana', 'Ana Paula']);
    });

    testWidgets('a lone space with no spaced label offers the add row', (
      tester,
    ) async {
      await tester.pumpWidget(
        _app(
          _dropdown(
            items: _items(),
            selected: [],
            probe: _Probe(),
            trim: false,
            addMode: true,
          ),
        ),
      );
      await openMultiple(tester);

      await _type(tester, ' ');
      expect(_rowLabels(tester), isEmpty);
      expect(
        tester.widget<DefaultAddListItem>(find.byType(DefaultAddListItem)).text,
        ' ',
      );
    });
  });

  group('overlay sort ordering (0 none/1 A-Z/2 Z-A/3 selectedFirst)', () {
    Future<List<ValueItem<int>>> openWith(
      WidgetTester tester,
      SortType sort, {
      List<int> selectedIdx = const <int>[],
    }) async {
      final items = _items();
      final selected = [for (final i in selectedIdx) items[i]];
      await tester.pumpWidget(
        _app(
          _dropdown(
            items: items,
            selected: selected,
            probe: _Probe(),
            sort: sort,
          ),
        ),
      );
      await openMultiple(tester);
      return items;
    }

    testWidgets('0: original order, caller list untouched', (tester) async {
      final items = await openWith(tester, SortType.none);
      expect(_rowLabels(tester), ['Cherry', 'apple', 'Banana']);
      expect(_labels(items), ['Cherry', 'apple', 'Banana']);
    });

    testWidgets('1: A-Z ignoring case and accents (D2, 8.0)', (tester) async {
      await openWith(tester, SortType.alphabetical);
      expect(_rowLabels(tester), ['apple', 'Banana', 'Cherry']);
    });

    testWidgets('1: the caller listItems is not reordered (M7, 8.0)', (
      tester,
    ) async {
      final items = await openWith(tester, SortType.alphabetical);
      expect(_labels(items), ['Cherry', 'apple', 'Banana']);
    });

    testWidgets('2: Z-A ignoring case and accents (D2, 8.0)', (tester) async {
      final items = await openWith(tester, SortType.reverseAlphabetical);
      expect(_rowLabels(tester), ['Cherry', 'Banana', 'apple']);
      // M7 (8.0): the caller list keeps its order.
      expect(_labels(items), ['Cherry', 'apple', 'Banana']);
    });

    testWidgets('3 without selection: original order', (tester) async {
      await openWith(tester, SortType.selectedFirst);
      expect(_rowLabels(tester), ['Cherry', 'apple', 'Banana']);
    });

    testWidgets(
      '3: first selected item moved to the top (not the caller list)',
      (tester) async {
        final items = await openWith(
          tester,
          SortType.selectedFirst,
          selectedIdx: [2, 1],
        );
        expect(_rowLabels(tester), ['Banana', 'Cherry', 'apple']);
        // M7 (8.0): the caller list keeps its order.
        expect(_labels(items), ['Cherry', 'apple', 'Banana']);
      },
    );

    testWidgets('3: tapping a row re-sorts immediately', (tester) async {
      await openWith(tester, SortType.selectedFirst);
      await _tapRow(tester, 'Banana');
      expect(_rowLabels(tester), ['Banana', 'Cherry', 'apple']);
    });
  });

  group('selection: tapping a row toggles selection', () {
    testWidgets(
      'select: adds, reports a copy of the selection, overlay stays',
      (tester) async {
        final probe = _Probe();
        final items = _items();
        final List<ValueItem<int>> selected = [];
        await tester.pumpWidget(
          _app(_dropdown(items: items, selected: selected, probe: probe)),
        );
        await openMultiple(tester);

        await _tapRow(tester, 'apple');

        expect(probe.selection, [items[1]]);
        expect(probe.updates, hasLength(1));
        expect(probe.updates.single, probe.selection);
        expect(probe.clearedItems, isEmpty);
        expect(_list, findsOneWidget);
        expect(_rowSelected(tester, 'apple'), isTrue);
        expect(_rowSelected(tester, 'Cherry'), isFalse);
        expect(_inBox(find.text('apple')), findsOneWidget);
      },
    );

    testWidgets('multiple taps accumulate in tap order', (tester) async {
      final probe = _Probe();
      final items = _items();
      final List<ValueItem<int>> selected = [];
      await tester.pumpWidget(
        _app(_dropdown(items: items, selected: selected, probe: probe)),
      );
      await openMultiple(tester);

      await _tapRow(tester, 'Banana');
      await _tapRow(tester, 'Cherry');

      expect(_labels(probe.selection), ['Banana', 'Cherry']);
      expect(probe.updates, hasLength(2));
      expect(probe.updates.last, probe.selection);
    });

    testWidgets(
      'deselect: removes, calls onClearItem and updateSelectedItems',
      (tester) async {
        final probe = _Probe();
        final items = _items();
        final List<ValueItem<int>> selected = [items[1]];
        await tester.pumpWidget(
          _app(_dropdown(items: items, selected: selected, probe: probe)),
        );
        await openMultiple(tester);

        await _tapRow(tester, 'apple');

        expect(probe.selection, isEmpty);
        expect(probe.clearedItems, [items[1]]);
        expect(probe.updates.single, probe.selection);
        expect(_rowSelected(tester, 'apple'), isFalse);
        expect(_inBox(find.text('Pesquisar')), findsOneWidget);
      },
    );

    testWidgets('selection uses ValueItem equality (equal const instance)', (
      tester,
    ) async {
      final probe = _Probe();
      final List<ValueItem<int>> selected = [
        const ValueItem(label: 'apple', value: 1),
      ];
      await tester.pumpWidget(
        _app(_dropdown(items: _items(), selected: selected, probe: probe)),
      );
      await openMultiple(tester);

      expect(_rowSelected(tester, 'apple'), isTrue);
      await _tapRow(tester, 'apple');
      expect(probe.selection, isEmpty);
    });
  });

  group('selection: chip close icon deselects', () {
    testWidgets('removes that item, calls onClearItem, does not open', (
      tester,
    ) async {
      final probe = _Probe();
      final items = _items();
      final List<ValueItem<int>> selected = [items[0], items[1]];
      await tester.pumpWidget(
        _app(_dropdown(items: items, selected: selected, probe: probe)),
      );

      await tester.tap(_inBox(find.byIcon(Icons.close)).first);
      await tester.pumpAndSettle();

      expect(probe.selection, [items[1]]);
      expect(probe.clearedItems, [items[0]]);
      expect(probe.updates.single, probe.selection);
      expect(_inBox(find.text('Cherry')), findsNothing);
      expect(_inBox(find.byType(Card)), findsOneWidget);
      expect(_list, findsNothing);
    });
  });

  group('clear icon: onClear clears all selections', () {
    testWidgets(
      'clears the selection, calls updateSelectedItems and onClearList',
      (tester) async {
        final probe = _Probe();
        final items = _items();
        final List<ValueItem<int>> selected = [items[0], items[2]];
        await tester.pumpWidget(
          _app(_dropdown(items: items, selected: selected, probe: probe)),
        );

        await tester.tap(_inBox(find.byIcon(Icons.clear)));
        await tester.pumpAndSettle();

        expect(probe.selection, isEmpty);
        expect(probe.updates, hasLength(1));
        expect(probe.updates.single, probe.selection);
        expect(probe.clearList, 1);
        expect(probe.clearedItems, isEmpty);
        expect(_list, findsNothing);
        expect(_inBox(find.text('Pesquisar')), findsOneWidget);
        expect(_inBox(find.byIcon(Icons.arrow_drop_down)), findsOneWidget);
      },
    );
  });

  group('controller API: forceSelection(label)', () {
    testWidgets('selects by exact label, notifies and rebuilds chips', (
      tester,
    ) async {
      final probe = _Probe();
      final items = _items();
      final List<ValueItem<int>> selected = [];
      final controller = _controller(
        items: items,
        selected: selected,
        probe: probe,
      );
      addTearDown(controller.dispose);
      await tester.pumpWidget(_app(_controlled(controller)));

      controller.forceSelection('apple');
      await tester.pump();

      expect(probe.selection, [items[1]]);
      expect(probe.updates.single, probe.selection);
      expect(_inBox(find.text('apple')), findsOneWidget);
    });

    testWidgets('already selected: no duplicate but still notifies', (
      tester,
    ) async {
      final probe = _Probe();
      final items = _items();
      final List<ValueItem<int>> selected = [items[1]];
      final controller = _controller(
        items: items,
        selected: selected,
        probe: probe,
      );
      addTearDown(controller.dispose);
      await tester.pumpWidget(_app(_controlled(controller)));

      controller.forceSelection('apple');
      await tester.pump();

      expect(probe.selection, [items[1]]);
      expect(probe.updates, hasLength(1));
      expect(probe.clearedItems, isEmpty);
    });

    testWidgets(
      'unknown label is ignored; a differently-cased one matches (8.0)',
      (tester) async {
        final probe = _Probe();
        final List<ValueItem<int>> selected = [];
        final controller = _controller(
          items: _items(),
          selected: selected,
          probe: probe,
        );
        addTearDown(controller.dispose);
        await tester.pumpWidget(_app(_controlled(controller)));

        controller.forceSelection('Kiwi');
        await tester.pump();
        expect(probe.selection, isEmpty);
        expect(probe.updates, isEmpty);

        // Like the single dropdown: exact first, then case/accent-insensitive.
        controller.forceSelection('Apple');
        await tester.pump();
        expect(_labels(probe.selection), ['apple']);
      },
    );
  });

  group('controller API: forceMultipleSelection(values)', () {
    testWidgets(
      'replaces the selection with the values found in items and rebuilds '
      'the chips (M3, 8.0), without notify',
      (tester) async {
        final probe = _Probe();
        final items = _items();
        final List<ValueItem<int>> selected = [items[0]];
        final controller = _controller(
          items: items,
          selected: selected,
          probe: probe,
        );
        addTearDown(controller.dispose);
        await tester.pumpWidget(_app(_controlled(controller)));

        controller.forceMultipleSelection([
          const ValueItem(label: 'Banana', value: 2),
          const ValueItem(label: 'Ghost', value: 7),
          items[1],
        ]);
        await tester.pump();

        expect(_labels(probe.selection), ['Banana', 'apple']);
        expect(probe.updates, isEmpty);
        expect(probe.clearList, 0);
        // M3 (8.0): the chips follow right away.
        expect(_inBox(find.text('Cherry')), findsNothing);
        expect(_inBox(find.text('Banana')), findsOneWidget);
        expect(_inBox(find.text('apple')), findsOneWidget);
      },
    );
  });

  group('controller API: resetSelection()', () {
    testWidgets(
      'clears the selection, rebuilds and calls updateSelectedItems (M2)',
      (tester) async {
        final probe = _Probe();
        final items = _items();
        final List<ValueItem<int>> selected = [items[0], items[1]];
        final controller = _controller(
          items: items,
          selected: selected,
          probe: probe,
        );
        addTearDown(controller.dispose);
        await tester.pumpWidget(_app(_controlled(controller)));

        controller.resetSelection();
        await tester.pump();

        expect(probe.selection, isEmpty);
        expect(probe.updates, hasLength(1));
        expect(probe.updates.single, isEmpty);
        expect(probe.clearList, 0);
        expect(probe.clearedItems, isEmpty);
        expect(_inBox(find.byType(Card)), findsNothing);
        expect(_inBox(find.text('Pesquisar')), findsOneWidget);
      },
    );
  });

  group('controller API: toggleEnabled() (opacity 0.38 + IgnorePointer)', () {
    testWidgets('toggles opacity and pointer ignoring', (tester) async {
      final controller = _controller(
        items: _items(),
        selected: [],
        probe: _Probe(),
      );
      addTearDown(controller.dispose);
      await tester.pumpWidget(_app(_controlled(controller)));
      expect(_opacity(tester), 1);
      expect(_ignoring(tester), isFalse);

      controller.toggleEnabled();
      await tester.pump();
      expect(_opacity(tester), 0.38);
      expect(_ignoring(tester), isTrue);
      expect(controller.enabled, isFalse);

      await tester.tap(_inBox(find.byType(InkWell)).first, warnIfMissed: false);
      await tester.pumpAndSettle();
      expect(_list, findsNothing);
      // 8.0: the arrow follows the enabled state.
      expect(_inBox(find.byIcon(Icons.arrow_drop_down)), findsNothing);

      controller.toggleEnabled();
      await tester.pump();
      expect(_opacity(tester), 1);
      expect(_ignoring(tester), isFalse);
      await openMultiple(tester);
      expect(_list, findsOneWidget);
    });
  });

  group('State API: hideOverlay()', () {
    testWidgets('closes an open overlay and restores the closed arrow', (
      tester,
    ) async {
      final key = GlobalKey<MultipleSearchDropDownState<int>>();
      await tester.pumpWidget(
        _app(
          _dropdown(key: key, items: _items(), selected: [], probe: _Probe()),
        ),
      );
      await openMultiple(tester);
      expect(key.currentState!.aberto, isTrue);

      key.currentState!.hideOverlay();
      await tester.pumpAndSettle();

      expect(_list, findsNothing);
      expect(key.currentState!.aberto, isFalse);
      expect(_inBox(find.byIcon(Icons.arrow_drop_down)), findsOneWidget);
    });

    testWidgets('on a closed dropdown it does nothing (M8, 8.0)', (
      tester,
    ) async {
      final key = GlobalKey<MultipleSearchDropDownState<int>>();
      await tester.pumpWidget(
        _app(
          _dropdown(key: key, items: _items(), selected: [], probe: _Probe()),
        ),
      );

      key.currentState!.hideOverlay();
      await tester.pumpAndSettle();

      expect(_list, findsNothing);
      expect(key.currentState!.aberto, isFalse);
      expect(_inBox(find.byIcon(Icons.arrow_drop_down)), findsOneWidget);

      await openMultiple(tester);
      expect(_list, findsOneWidget);
      expect(_inBox(find.byIcon(Icons.arrow_drop_up)), findsOneWidget);
    });

    testWidgets('M8: hideOverlay twice leaves the arrow closed', (
      tester,
    ) async {
      final key = GlobalKey<MultipleSearchDropDownState<int>>();
      await tester.pumpWidget(
        _app(
          _dropdown(key: key, items: _items(), selected: [], probe: _Probe()),
        ),
      );
      await openMultiple(tester);

      key.currentState!
        ..hideOverlay()
        ..hideOverlay();
      await tester.pumpAndSettle();

      expect(_list, findsNothing);
      expect(_inBox(find.byIcon(Icons.arrow_drop_down)), findsOneWidget);
    }); // M8: fixed in 8.0
  });

  group('data: updateListItems while the list is open (N31)', () {
    testWidgets('typing filters the new items', (tester) async {
      final items = _items();
      final probe = _Probe();
      await tester.pumpWidget(
        _app(
          _dropdown(items: items, selected: [], probe: probe, addMode: true),
        ),
      );
      await openMultiple(tester);

      probe.controller!.updateListItems(
        List<ValueItem<int>>.of(items)
          ..add(const ValueItem(label: 'Kiwi', value: 4))
          ..removeWhere((e) => e.label == 'Banana'),
        false,
      );
      await _type(tester, 'kiwi');

      expect(_rowLabels(tester), ['Kiwi']);
      expect(find.byType(DefaultAddListItem), findsNothing);
      expect(_inList(find.text('Criar')), findsNothing);
      await _type(tester, '');
      expect(_rowLabels(tester), ['Cherry', 'apple', 'Kiwi']);
      expect(_labels(items), ['Cherry', 'apple', 'Banana']);
    });
  });

  group('add mode: typing key by key (N29)', () {
    // Types like a keyboard: one change (and one frame) per key.
    Future<void> typeKeys(WidgetTester tester, String text) async {
      for (var i = 1; i <= text.length; i++) {
        await tester.enterText(_searchField, text.substring(0, i));
        await tester.pump();
      }
    }

    testWidgets('the add row follows the full text', (tester) async {
      final probe = _Probe();
      final items = _items();
      await tester.pumpWidget(
        _app(
          _dropdown(items: items, selected: [], probe: probe, addMode: true),
        ),
      );
      await openMultiple(tester);

      await typeKeys(tester, 'Kiwi');
      expect(
        tester.widget<DefaultAddListItem>(find.byType(DefaultAddListItem)).text,
        'Kiwi',
      );
      await tester.tap(_inList(find.text('Criar')));
      await tester.pumpAndSettle();
      expect(probe.added, [const ValueItem<int>(label: 'Kiwi', value: 99)]);
    });

    testWidgets('an empty list still offers the add row', (tester) async {
      final probe = _Probe();
      final items = <ValueItem<int>>[];
      final selected = <ValueItem<int>>[];
      await tester.pumpWidget(
        _app(
          _dropdown(
            items: items,
            selected: selected,
            probe: probe,
            addMode: true,
          ),
        ),
      );
      await openMultiple(tester);

      await typeKeys(tester, 'Ki');
      expect(find.byType(DefaultAddListItem), findsOneWidget);
      expect(
        tester.widget<DefaultAddListItem>(find.byType(DefaultAddListItem)).text,
        'Ki',
      );
      await tester.tap(_inList(find.text('Criar')));
      await tester.pumpAndSettle();
      expect(probe.added, [const ValueItem<int>(label: 'Ki', value: 99)]);
      expect(items, hasLength(1));
      expect(probe.selection, hasLength(1));
    });
  });

  group('add mode: add row (newValueItem/onAddItem)', () {
    testWidgets('text matching nothing shows the add row with "Criar"', (
      tester,
    ) async {
      await tester.pumpWidget(
        _app(
          _dropdown(
            items: _items(),
            selected: [],
            probe: _Probe(),
            addMode: true,
          ),
        ),
      );
      await openMultiple(tester);

      await _type(tester, 'Kiwi');

      expect(_rowLabels(tester), isEmpty);
      expect(find.byType(DefaultAddListItem), findsOneWidget);
      expect(
        tester.widget<DefaultAddListItem>(find.byType(DefaultAddListItem)).text,
        'Kiwi',
      );
      expect(_inList(find.text('Criar')), findsOneWidget);
    });

    testWidgets('a partial match hides the add row', (tester) async {
      await tester.pumpWidget(
        _app(
          _dropdown(
            items: _items(),
            selected: [],
            probe: _Probe(),
            addMode: true,
          ),
        ),
      );
      await openMultiple(tester);

      await _type(tester, 'APP');

      expect(_rowLabels(tester), ['apple']);
      expect(find.byType(DefaultAddListItem), findsNothing);
    });

    testWidgets('empty search shows no add row', (tester) async {
      await tester.pumpWidget(
        _app(
          _dropdown(
            items: _items(),
            selected: [],
            probe: _Probe(),
            addMode: true,
          ),
        ),
      );
      await openMultiple(tester);

      expect(find.byType(DefaultAddListItem), findsNothing);
    });

    testWidgets('addMode false never shows the add row', (tester) async {
      await tester.pumpWidget(
        _app(_dropdown(items: _items(), selected: [], probe: _Probe())),
      );
      await openMultiple(tester);

      await _type(tester, 'Kiwi');

      expect(_rowLabels(tester), isEmpty);
      expect(find.byType(DefaultAddListItem), findsNothing);
    });

    testWidgets(
      'tapping Criar: newValueItem -> onAddItem, item selected, search '
      'cleared',
      (tester) async {
        final probe = _Probe();
        final items = _items();
        final List<ValueItem<int>> selected = [];
        await tester.pumpWidget(
          _app(
            _dropdown(
              items: items,
              selected: selected,
              probe: probe,
              addMode: true,
            ),
          ),
        );
        await openMultiple(tester);
        await _type(tester, 'Kiwi');

        await tester.tap(_inList(find.text('Criar')));
        await tester.pumpAndSettle();

        const kiwi = ValueItem<int>(label: 'Kiwi', value: 99);
        expect(probe.added, [kiwi]);
        expect(probe.selection, [kiwi]);
        expect(probe.updates.single, probe.selection);
        expect(_searchText(tester), '');
        expect(_list, findsOneWidget);
        expect(_rowLabels(tester), ['Cherry', 'apple', 'Banana', 'Kiwi']);
        expect(_rowSelected(tester, 'Kiwi'), isTrue);
        expect(_inBox(find.text('Kiwi')), findsOneWidget);
      },
    );

    testWidgets(
      'the controller adds the item itself; onAddItem need not (8.0)',
      (tester) async {
        final probe = _Probe();
        final List<ValueItem<int>> selected = [];
        await tester.pumpWidget(
          _app(
            _dropdown(
              items: _items(),
              selected: selected,
              probe: probe,
              addMode: true,
              addToList: false,
            ),
          ),
        );
        await openMultiple(tester);
        await _type(tester, 'Kiwi');

        await tester.tap(_inList(find.text('Criar')));
        await tester.pumpAndSettle();

        expect(_labels(probe.selection), ['Kiwi']);
        expect(_rowLabels(tester), ['Cherry', 'apple', 'Banana', 'Kiwi']);
      },
    );
  });

  group('add mode: verifyInputItem warning dialog', () {
    testWidgets(
      'false: shows the "Erro!" WarningDialog, does not add nor select',
      (tester) async {
        final probe = _Probe();
        final List<ValueItem<int>> selected = [];
        final List<ValueItem<int>> verified = [];
        await tester.pumpWidget(
          _app(
            _dropdown(
              items: _items(),
              selected: selected,
              probe: probe,
              addMode: true,
              verifyInputItem: (item) {
                verified.add(item);
                return false;
              },
            ),
          ),
        );
        await openMultiple(tester);
        await _type(tester, 'Bad');

        await tester.tap(_inList(find.text('Criar')));
        await tester.pumpAndSettle();

        expect(verified, [const ValueItem<int>(label: 'Bad', value: 99)]);
        expect(find.byType(WarningDialog), findsOneWidget);
        expect(find.text('Erro!'), findsOneWidget);
        expect(find.text('O valor adicionado não é válido.'), findsOneWidget);
        expect(find.text('OK'), findsOneWidget);
        expect(probe.added, isEmpty);
        expect(probe.selection, isEmpty);
        expect(probe.updates, isEmpty);

        await tester.tap(find.text('OK'));
        await tester.pumpAndSettle();
        expect(find.byType(WarningDialog), findsNothing);
        expect(_list, findsOneWidget);
      },
    );

    testWidgets('true: item is added and selected', (tester) async {
      final probe = _Probe();
      final List<ValueItem<int>> selected = [];
      await tester.pumpWidget(
        _app(
          _dropdown(
            items: _items(),
            selected: selected,
            probe: probe,
            addMode: true,
            verifyInputItem: (_) => true,
          ),
        ),
      );
      await openMultiple(tester);
      await _type(tester, 'Good');

      await tester.tap(_inList(find.text('Criar')));
      await tester.pumpAndSettle();

      expect(find.byType(WarningDialog), findsNothing);
      expect(_labels(probe.added), ['Good']);
      expect(_labels(probe.selection), ['Good']);
    });

    testWidgets(
      'M4 (not reproduced): #13 invalid item is not listed and the search '
      'is cleared',
      (tester) async {
        await tester.pumpWidget(
          _app(
            _dropdown(
              items: _items(),
              selected: [],
              probe: _Probe(),
              addMode: true,
              verifyInputItem: (_) => false,
            ),
          ),
        );
        await openMultiple(tester);
        await _type(tester, 'Bad');

        await tester.tap(_inList(find.text('Criar')));
        await tester.pump();

        expect(_rowLabels(tester), ['Cherry', 'apple', 'Banana']);
        expect(_inList(find.text('Bad')), findsNothing);
        expect(_searchText(tester), '');
      },
    );
  });

  group('delete mode: delete icon calls onDeleteItem', () {
    testWidgets('rows show a delete icon only when deleteMode is true', (
      tester,
    ) async {
      await tester.pumpWidget(
        _app(_dropdown(items: _items(), selected: [], probe: _Probe())),
      );
      await openMultiple(tester);
      expect(_inList(find.byIcon(Icons.delete)), findsNothing);

      // 8.0: the open list follows the new parameters right away.
      await tester.pumpWidget(
        _app(
          _dropdown(
            items: _items(),
            selected: [],
            probe: _Probe(),
            deleteMode: true,
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(_inList(find.byIcon(Icons.delete)), findsNWidgets(3));
    });

    testWidgets(
      'no confirm: calls onDeleteItem, deselects only that item (M1), '
      'refreshes the list',
      (tester) async {
        final probe = _Probe();
        final items = _items();
        final List<ValueItem<int>> selected = [items[0], items[1]];
        await tester.pumpWidget(
          _app(
            _dropdown(
              items: items,
              selected: selected,
              probe: probe,
              deleteMode: true,
            ),
          ),
        );
        await openMultiple(tester);

        await tester.tap(
          find.descendant(
            of: _row('Banana'),
            matching: find.byIcon(Icons.delete),
          ),
        );
        await tester.pump();

        expect(probe.deleted, [
          const ValueItem<int>(label: 'Banana', value: 2),
        ]);
        // Banana was not selected: the selection is untouched.
        expect(_labels(probe.selection), ['Cherry', 'apple']);
        expect(probe.updates, isEmpty);
        expect(probe.clearedItems, isEmpty);
        expect(_rowLabels(tester), ['Cherry', 'apple']);
        expect(_list, findsOneWidget);
        expect(_inBox(find.byType(Card)), findsNWidgets(2));
      },
    );

    testWidgets('no tile is left loading after a delete (8.0, B5 class)', (
      tester,
    ) async {
      final items = _items();
      await tester.pumpWidget(
        _app(
          _dropdown(
            items: items,
            selected: [],
            probe: _Probe(),
            deleteMode: true,
          ),
        ),
      );
      await openMultiple(tester);

      await tester.tap(
        find.descendant(
          of: _row('Cherry'),
          matching: find.byIcon(Icons.delete),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      expect(_rowLabels(tester), ['apple', 'Banana']);
      expect(_inList(find.byType(CircularProgressIndicator)), findsNothing);
      expect(_inList(find.byIcon(Icons.delete)), findsNWidgets(2));
    });

    testWidgets('M1: deleting one item keeps the other selections', (
      tester,
    ) async {
      final items = _items();
      final probe = _Probe();
      final List<ValueItem<int>> selected = [items[0], items[1]];
      await tester.pumpWidget(
        _app(
          _dropdown(
            items: items,
            selected: selected,
            probe: probe,
            deleteMode: true,
          ),
        ),
      );
      await openMultiple(tester);

      await tester.tap(
        find.descendant(
          of: _row('Cherry'),
          matching: find.byIcon(Icons.delete),
        ),
      );
      await tester.pump();

      expect(_labels(probe.selection), ['apple']);
    }); // M1: fixed in 8.0
  });

  group('delete mode: confirmDelete shows a WarningDialog in the overlay', () {
    testWidgets('dialog content; Cancelar closes it without deleting', (
      tester,
    ) async {
      final probe = _Probe();
      final items = _items();
      final List<ValueItem<int>> selected = [items[1]];
      await tester.pumpWidget(
        _app(
          _dropdown(
            items: items,
            selected: selected,
            probe: probe,
            deleteMode: true,
            confirmDelete: true,
          ),
        ),
      );
      await openMultiple(tester);

      await tester.tap(
        find.descendant(
          of: _row('Cherry'),
          matching: find.byIcon(Icons.delete),
        ),
      );
      await tester.pump();

      expect(find.byType(WarningDialog), findsOneWidget);
      expect(find.text('Tem certeza?'), findsOneWidget);
      expect(find.text('Essa ação não poderá ser desfeita.'), findsOneWidget);
      expect(find.text('Cancelar'), findsOneWidget);
      expect(find.text('Apagar'), findsOneWidget);
      expect(probe.deleted, isEmpty);

      await tester.tap(find.text('Cancelar'));
      await tester.pump();

      expect(find.byType(WarningDialog), findsNothing);
      expect(probe.deleted, isEmpty);
      expect(probe.selection, [items[1]]);
      expect(_list, findsOneWidget);
      expect(_rowLabels(tester), ['Cherry', 'apple', 'Banana']);
      // 8.0 (B5 class): the cancelled tile gets its delete icon back.
      expect(_inList(find.byType(CircularProgressIndicator)), findsNothing);
    });

    testWidgets(
      'Apagar deletes, keeps the other selections (M1) and closes the dialog',
      (tester) async {
        final probe = _Probe();
        final items = _items();
        final List<ValueItem<int>> selected = [items[1]];
        await tester.pumpWidget(
          _app(
            _dropdown(
              items: items,
              selected: selected,
              probe: probe,
              deleteMode: true,
              confirmDelete: true,
            ),
          ),
        );
        await openMultiple(tester);

        await tester.tap(
          find.descendant(
            of: _row('Cherry'),
            matching: find.byIcon(Icons.delete),
          ),
        );
        await tester.pump();
        await tester.tap(find.text('Apagar'));
        await tester.pump();

        expect(find.byType(WarningDialog), findsNothing);
        expect(probe.deleted, [
          const ValueItem<int>(label: 'Cherry', value: 3),
        ]);
        expect(_labels(probe.selection), ['apple']);
        expect(probe.updates, isEmpty);
        expect(_list, findsOneWidget);
        expect(_inBox(find.text('apple')), findsOneWidget);
      },
    );

    testWidgets('custom deleteDialogSettings title is used', (tester) async {
      final controller = MultipleSearchDropDownController<int>(
        items: _items(),
        addMode: false,
        onDeleteItem: (_) {},
        confirmDelete: true,
        deleteDialogSettings: const DialogSettings(title: Text('Sure?')),
      );
      addTearDown(controller.dispose);
      await tester.pumpWidget(_app(_controlled(controller)));
      await openMultiple(tester);

      await tester.tap(
        find.descendant(of: _row('apple'), matching: find.byIcon(Icons.delete)),
      );
      await tester.pump();

      expect(find.text('Sure?'), findsOneWidget);
      expect(find.text('Tem certeza?'), findsNothing);
    });
  });

  group('edit mode: edit icon opens EditDialog (8.0; 7.x was a stub)', () {
    testWidgets('edit icon opens the edit dialog; confirming calls onEditItem '
        '(8.0)', (tester) async {
      final probe = _Probe();
      await tester.pumpWidget(
        _app(
          _dropdown(
            items: _items(),
            selected: [],
            probe: probe,
            editMode: true,
          ),
        ),
      );
      await openMultiple(tester);
      expect(_inList(find.byIcon(Icons.edit)), findsNWidgets(3));

      await tester.tap(_inList(find.byIcon(Icons.edit)).first);
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.byType(EditDialog), findsOneWidget);

      await tester.enterText(
        find.descendant(
          of: find.byType(EditDialog),
          matching: find.byType(TextField),
        ),
        'Cherry2',
      );
      await tester.tap(find.text('Editar'));
      await tester.pump(const Duration(milliseconds: 400));

      expect(find.byType(EditDialog), findsNothing);
      expect(_labels(probe.edited), ['Cherry2']);
      expect(_rowLabels(tester), contains('Cherry2'));
    });

    testWidgets('editing a selected item replaces it in the controller items '
        'and selectedItems and fires updateSelectedItems (8.0)', (
      tester,
    ) async {
      final probe = _Probe();
      final items = _items();
      final List<ValueItem<int>> selected = [items[1]]; // 'apple'
      await tester.pumpWidget(
        _app(
          _dropdown(
            items: items,
            selected: selected,
            probe: probe,
            editMode: true,
          ),
        ),
      );
      await openMultiple(tester);

      await tester.tap(
        find.descendant(of: _row('apple'), matching: find.byIcon(Icons.edit)),
      );
      await tester.pump(const Duration(milliseconds: 400));
      await tester.enterText(
        find.descendant(
          of: find.byType(EditDialog),
          matching: find.byType(TextField),
        ),
        'apple2',
      );
      await tester.tap(find.text('Editar'));
      await tester.pump(const Duration(milliseconds: 400));

      // Replaced in place: same position; the caller list is untouched.
      expect(_labels(probe.items), ['Cherry', 'apple2', 'Banana']);
      expect(_labels(items), ['Cherry', 'apple', 'Banana']);
      expect(_labels(probe.selection), ['apple2']);
      expect(
        probe.selection.single,
        const ValueItem(label: 'apple2', value: 99),
      );
      expect(probe.selection.every(probe.items.contains), isTrue);
      expect(probe.updates, hasLength(1));
      expect(probe.updates.single, probe.selection);
      expect(_labels(probe.edited), ['apple2']);
      expect(_rowSelected(tester, 'apple2'), isTrue);
      // The chip is relabelled.
      expect(_inBox(find.text('apple2')), findsOneWidget);
      expect(_inBox(find.text('apple')), findsNothing);
    });
  });

  group('overlay: additional widgets (default/add rows)', () {
    testWidgets(
      'defaultAdditionalWidget per row, addAdditionalWidget on add row',
      (tester) async {
        await tester.pumpWidget(
          _app(
            _dropdown(
              items: _items(),
              selected: [],
              probe: _Probe(),
              addMode: true,
              defaultAdditionalWidget: const Text('extra'),
              addAdditionalWidget: const Text('extra-add'),
            ),
          ),
        );
        await openMultiple(tester);
        expect(_inList(find.text('extra')), findsNWidgets(3));
        expect(_inList(find.text('extra-add')), findsNothing);

        await _type(tester, 'Kiwi');
        expect(_inList(find.text('extra')), findsNothing);
        expect(_inList(find.text('extra-add')), findsOneWidget);
      },
    );
  });

  group('enabled=false constructor param', () {
    testWidgets('dimmed, ignores taps, hides the arrow', (tester) async {
      await tester.pumpWidget(
        _app(
          _dropdown(
            items: _items(),
            selected: [],
            probe: _Probe(),
            enabled: false,
          ),
        ),
      );

      expect(_opacity(tester), 0.38);
      expect(_ignoring(tester), isTrue);
      expect(_inBox(find.byIcon(Icons.arrow_drop_down)), findsNothing);

      await tester.tap(_inBox(find.byType(InkWell)).first, warnIfMissed: false);
      await tester.pumpAndSettle();
      expect(_list, findsNothing);
    });

    testWidgets('with a selection the clear icon is still rendered', (
      tester,
    ) async {
      final items = _items();
      await tester.pumpWidget(
        _app(
          _dropdown(
            items: items,
            selected: [items[0]],
            probe: _Probe(),
            enabled: false,
          ),
        ),
      );

      expect(_inBox(find.byIcon(Icons.clear)), findsOneWidget);
      expect(_inBox(find.text('Cherry')), findsOneWidget);
    });

    testWidgets('toggleEnabled() re-enables taps and shows the arrow (8.0)', (
      tester,
    ) async {
      final controller = _controller(
        items: _items(),
        selected: [],
        probe: _Probe(),
        enabled: false,
      );
      addTearDown(controller.dispose);
      await tester.pumpWidget(_app(_controlled(controller)));

      controller.toggleEnabled();
      await tester.pump();

      expect(_opacity(tester), 1);
      expect(_ignoring(tester), isFalse);
      expect(_inBox(find.byIcon(Icons.arrow_drop_down)), findsOneWidget);
      await openMultiple(tester);
      expect(_list, findsOneWidget);
    });
  });

  group('constructor asserts (addMode/deleteMode/editMode)', () {
    test('addMode (default true) requires newValueItem and onAddItem', () {
      expect(
        () => MultipleSearchDropDownController<int>(
          items: const [],
          deleteMode: false,
          onAddItem: (_) {},
        ),
        throwsAssertionError,
      );
      expect(
        () => MultipleSearchDropDownController<int>(
          items: const [],
          deleteMode: false,
          newValueItem: (s) => ValueItem(label: s),
        ),
        throwsAssertionError,
      );
    });

    test('deleteMode (default true) requires onDeleteItem', () {
      expect(
        () => MultipleSearchDropDownController<int>(
          items: const [],
          addMode: false,
        ),
        throwsAssertionError,
      );
    });

    test('editMode requires onEditItem and newValueItem', () {
      expect(
        () => MultipleSearchDropDownController<int>(
          items: const [],
          addMode: false,
          deleteMode: false,
          editMode: true,
          newValueItem: (s) => ValueItem(label: s),
        ),
        throwsAssertionError,
      );
      expect(
        () => MultipleSearchDropDownController<int>(
          items: const [],
          addMode: false,
          deleteMode: false,
          editMode: true,
          onEditItem: (_, _) {},
        ),
        throwsAssertionError,
      );
    });

    test('all modes off needs no callbacks', () {
      expect(
        () => MultipleSearchDropDownController<int>(
          items: const [],
          addMode: false,
          deleteMode: false,
        ).dispose(),
        returnsNormally,
      );
    });
  });

  group('lifecycle: controller dispose', () {
    MultipleSearchDropDownController<int> create() =>
        MultipleSearchDropDownController<int>(
          items: _items(),
          addMode: false,
          deleteMode: false,
        );

    test('dispose can be called twice', () {
      final c = create()..dispose();
      expect(c.isDisposed, isTrue);
      expect(c.dispose, returnsNormally);
      expect(c.isDisposed, isTrue);
    });

    test('a change after dispose is kept but notifies nobody', () {
      final c = create();
      int calls = 0;
      c
        ..addListener(() => calls++)
        ..dispose()
        ..enabled = false;
      expect(c.enabled, isFalse);
      c.toggleEnabled();
      expect(c.enabled, isTrue);
      expect(calls, 0);
    });
  });

  group('lifecycle: widget removed while the overlay is open', () {
    testWidgets('the list goes away with the widget (M6, 8.0)', (tester) async {
      await tester.pumpWidget(
        _app(_dropdown(items: _items(), selected: [], probe: _Probe())),
      );
      await openMultiple(tester);

      await tester.pumpWidget(_app(const SizedBox()));

      expect(find.byType(MultipleSearchDropDown<int>), findsNothing);
      expect(_list, findsNothing);
      await tester.tapAt(const Offset(780, 580));
      expect(tester.takeException(), isNull);
    });
  });

  group('overlay host: follows the box and drops focus (#5, #35)', () {
    testWidgets('#5: the list follows the box when the page scrolls', (
      tester,
    ) async {
      final ScrollController scroll = ScrollController();
      addTearDown(scroll.dispose);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              controller: scroll,
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    _dropdown(items: _items(), selected: [], probe: _Probe()),
                    const SizedBox(height: 2000),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
      await openMultiple(tester);
      expect(tester.getTopLeft(_box), const Offset(20, 20));

      // The barrier takes every pointer, so the page moves programmatically
      // (as with a keyboard resize or a controller-driven scroll).
      scroll.jumpTo(15);
      await tester.pump();

      expect(tester.getTopLeft(_box), const Offset(20, 5));
      expect(_list, findsOneWidget);
      expect(
        tester.getTopLeft(_list) - tester.getTopLeft(_box),
        const Offset(0, 53),
      );
    });

    testWidgets('#5: the list follows the box when the keyboard resizes', (
      tester,
    ) async {
      addTearDown(tester.view.resetViewInsets);
      await tester.pumpWidget(
        host(_dropdown(items: _items(), selected: [], probe: _Probe())),
      );
      await openMultiple(tester);
      final Offset before = tester.getTopLeft(_box);

      tester.view.viewInsets = FakeViewPadding(
        bottom: 200 * tester.view.devicePixelRatio,
      );
      await tester.pump();

      expect(tester.getTopLeft(_box).dy, before.dy - 100);
      expect(
        tester.getTopLeft(_list) - tester.getTopLeft(_box),
        const Offset(0, 53),
      );
    });

    testWidgets('#35: closing the list removes the focus', (tester) async {
      final FocusNode page = FocusNode();
      addTearDown(page.dispose);
      await tester.pumpWidget(
        _app(
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              _dropdown(items: _items(), selected: [], probe: _Probe()),
              SizedBox(
                width: 300,
                child: TextField(key: const Key('page'), focusNode: page),
              ),
            ],
          ),
        ),
      );
      await tester.tap(find.byKey(const Key('page')));
      await tester.pump();
      expect(page.hasFocus, isTrue);

      await openMultiple(tester);
      await tester.tap(_searchField);
      await tester.pump();
      expect(focusedField(), findsOneWidget);
      expect(page.hasFocus, isFalse);

      await tester.tapAt(const Offset(780, 580));
      await tester.pumpAndSettle();

      expect(_list, findsNothing);
      // Without the unfocus, detaching the list field gives the focus back
      // to the page field (and the keyboard comes back).
      expect(page.hasFocus, isFalse);
      expect(focusedField(), findsNothing);
    });
  });
}
