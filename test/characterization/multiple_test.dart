// Characterization tests exercise the legacy (deprecated) API on purpose.
// ignore_for_file: deprecated_member_use, deprecated_member_use_from_same_package

// Characterization tests for the MultipleSearchDropDown widget (v7.8.0).
// They lock the CURRENT behaviour before the 8.0 refactor, through the public
// API and the user-visible widgets. Tests named 'M<n>: ...' assert the
// CORRECT behaviour of a known bug and are skipped until the bug is fixed.
// testWidgets() only accepts a bool skip, so the reason "M<n>: fixed in 8.0"
// is the trailing comment.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:simple_search_dropdown/simple_search_dropdown.dart';

import '../support/harness.dart';

// A taller overlay so every row of the small fixtures is built and visible.
const SimpleOverlaySettings _tallOverlay =
    SimpleOverlaySettings(dialogHeight: 400);

// Records every callback the widget fires.
class _Probe {
  final List<List<ValueItem<int>>> updates = <List<ValueItem<int>>>[];
  final List<ValueItem<int>> clearedItems = <ValueItem<int>>[];
  final List<ValueItem<int>> added = <ValueItem<int>>[];
  final List<ValueItem<int>> deleted = <ValueItem<int>>[];
  final List<ValueItem<int>> edited = <ValueItem<int>>[];
  int clearList = 0;
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
  int sortType = 0,
  bool enabled = true,
  bool Function(ValueItem<int>)? verifyInputItem,
  SimpleSearchbarSettings settings = defaultSearchBarSettings,
  SimpleOverlaySettings overlay = _tallOverlay,
  Widget? addAditionalWidget,
  Widget? defaultAditionalWidget,
}) =>
    MultipleSearchDropDown<int>(
      key: key,
      listItems: items,
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
      onEditItem: probe.edited.add,
      confirmDelete: confirmDelete,
      sortType: sortType,
      enabled: enabled,
      verifyInputItem: verifyInputItem,
      searchBarSettings: settings,
      overlayListSettings: overlay,
      addAditionalWidget: addAditionalWidget,
      defaultAditionalWidget: defaultAditionalWidget,
    );

Finder get _box => find.byType(MultipleSearchDropDown<int>);
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

double _opacity(WidgetTester tester) =>
    tester.widget<Opacity>(_inBox(find.byType(Opacity)).first).opacity;

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
    testWidgets('shows the default hint "Pesquisar" and no chips',
        (tester) async {
      await tester.pumpWidget(
          _app(_dropdown(items: _items(), selected: [], probe: _Probe())));

      expect(_inBox(find.text('Pesquisar')), findsOneWidget);
      expect(_inBox(find.byType(Card)), findsNothing);
      expect(_list, findsNothing);
    });

    testWidgets('uses searchBarSettings.hint and hintStyle', (tester) async {
      const style = TextStyle(fontSize: 18, color: Colors.purple);
      await tester.pumpWidget(_app(_dropdown(
        items: _items(),
        selected: [],
        probe: _Probe(),
        settings:
            const SimpleSearchbarSettings(hint: 'Choose', hintStyle: style),
      )));

      final Text hint = tester.widget<Text>(_inBox(find.text('Choose')));
      expect(hint.style, style);
      expect(hint.textAlign, TextAlign.start);
    });

    testWidgets('hint is not shown when there is a selection', (tester) async {
      final items = _items();
      await tester.pumpWidget(
          _app(_dropdown(items: items, selected: [items[0]], probe: _Probe())));

      expect(_inBox(find.text('Pesquisar')), findsNothing);
    });
  });

  group('closed state: selected item chips (Card + label + close icon)', () {
    testWidgets('one Card chip per selected item, in selection order',
        (tester) async {
      final items = _items();
      await tester.pumpWidget(_app(_dropdown(
          items: items, selected: [items[1], items[0]], probe: _Probe())));

      expect(_inBox(find.byType(Card)), findsNWidgets(2));
      expect(_inBox(find.byIcon(Icons.close)), findsNWidgets(2));
      expect(_inBox(find.text('apple')), findsOneWidget);
      expect(_inBox(find.text('Cherry')), findsOneWidget);
      expect(
        tester.getTopLeft(_inBox(find.text('apple'))).dx,
        lessThan(tester.getTopLeft(_inBox(find.text('Cherry'))).dx),
      );
    });

    testWidgets('chips render selectedItems even if absent from listItems',
        (tester) async {
      await tester.pumpWidget(_app(_dropdown(
        items: _items(),
        selected: [const ValueItem(label: 'Ghost', value: 7)],
        probe: _Probe(),
      )));

      expect(_inBox(find.text('Ghost')), findsOneWidget);
      expect(_inBox(find.byType(Card)), findsOneWidget);
    });
  });

  group('closed state: boxMultiItemWidgetBuilder replaces the chip', () {
    testWidgets('builder output is used instead of Card + close icon',
        (tester) async {
      final items = _items();
      await tester.pumpWidget(_app(_dropdown(
        items: items,
        selected: [items[0], items[2]],
        probe: _Probe(),
        settings: SimpleSearchbarSettings(
          boxMultiItemWidgetBuilder: (item) => Text('custom ${item.label}'),
        ),
      )));

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
          _app(_dropdown(items: items, selected: [items[0]], probe: _Probe())));

      final Card card = tester.widget<Card>(_inBox(find.byType(Card)));
      expect(card.color, const Color.fromRGBO(224, 224, 224, 1));
      expect(card.elevation, 2);
      final Icon close = tester.widget<Icon>(_inBox(find.byIcon(Icons.close)));
      expect(close.size, 20);
      expect(close.color, isNull);
      expect(tester.widget<Text>(_inBox(find.text('Cherry'))).style, isNull);
    });

    testWidgets(
        'custom background, text style, close icon size/color and '
        'elevation', (tester) async {
      final items = _items();
      const textStyle = TextStyle(color: Colors.red);
      await tester.pumpWidget(_app(_dropdown(
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
      )));

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
    testWidgets('no selection: closed arrow with outsideIconSize default 20',
        (tester) async {
      await tester.pumpWidget(
          _app(_dropdown(items: _items(), selected: [], probe: _Probe())));

      final Icon arrow =
          tester.widget<Icon>(_inBox(find.byIcon(Icons.arrow_drop_down)));
      expect(arrow.size, 20);
      expect(arrow.color, isNull);
      expect(_inBox(find.byIcon(Icons.clear)), findsNothing);
    });

    testWidgets('outsideIconSize and outsideIconColor are applied',
        (tester) async {
      await tester.pumpWidget(_app(_dropdown(
        items: _items(),
        selected: [],
        probe: _Probe(),
        settings: const SimpleSearchbarSettings(
          outsideIconSize: 30,
          outsideIconColor: Colors.green,
        ),
      )));

      final Icon arrow =
          tester.widget<Icon>(_inBox(find.byIcon(Icons.arrow_drop_down)));
      expect(arrow.size, 30);
      expect(arrow.color, Colors.green);
    });

    testWidgets('showArrow false: no trailing icon at all', (tester) async {
      await tester.pumpWidget(_app(_dropdown(
        items: _items(),
        selected: [],
        probe: _Probe(),
        settings: const SimpleSearchbarSettings(showArrow: false),
      )));

      expect(_inBox(find.byType(Icon)), findsNothing);
    });

    testWidgets('custom closed/opened arrow icons follow the open state',
        (tester) async {
      await tester.pumpWidget(_app(_dropdown(
        items: _items(),
        selected: [],
        probe: _Probe(),
        settings: const SimpleSearchbarSettings(
          dropdownClosedArrowIcon: Icons.expand_more,
          dropdownOpenedArrowIcon: Icons.expand_less,
        ),
      )));
      expect(_inBox(find.byIcon(Icons.expand_more)), findsOneWidget);

      await openMultiple(tester);
      expect(_inBox(find.byIcon(Icons.expand_less)), findsOneWidget);
      expect(_inBox(find.byIcon(Icons.expand_more)), findsNothing);
    });

    testWidgets('with selection: clear icon instead of the arrow',
        (tester) async {
      final items = _items();
      await tester.pumpWidget(
          _app(_dropdown(items: items, selected: [items[0]], probe: _Probe())));

      expect(_inBox(find.byIcon(Icons.clear)), findsOneWidget);
      expect(_inBox(find.byIcon(Icons.arrow_drop_down)), findsNothing);
    });

    testWidgets('with selection and showClearIcon false: no clear, no arrow',
        (tester) async {
      final items = _items();
      await tester.pumpWidget(_app(_dropdown(
        items: items,
        selected: [items[0]],
        probe: _Probe(),
        settings: const SimpleSearchbarSettings(showClearIcon: false),
      )));

      expect(_inBox(find.byIcon(Icons.clear)), findsNothing);
      expect(_inBox(find.byIcon(Icons.arrow_drop_down)), findsNothing);
      expect(_inBox(find.byIcon(Icons.close)), findsOneWidget);
    });

    testWidgets(
        'tapping the arrow (no selection) runs onClear and does not open',
        (tester) async {
      final probe = _Probe();
      final List<ValueItem<int>> selected = [];
      await tester.pumpWidget(
          _app(_dropdown(items: _items(), selected: selected, probe: probe)));

      await tester.tap(_inBox(find.byIcon(Icons.arrow_drop_down)));
      await tester.pumpAndSettle();

      expect(_list, findsNothing);
      expect(probe.updates, hasLength(1));
      expect(probe.updates.single, same(selected));
      expect(probe.clearList, 1);
      expect(_inBox(find.byIcon(Icons.arrow_drop_down)), findsOneWidget);
    });

    testWidgets('M5: tapping the arrow when nothing is selected opens overlay',
        (tester) async {
      final probe = _Probe();
      await tester.pumpWidget(
          _app(_dropdown(items: _items(), selected: [], probe: probe)));

      await tester.tap(_inBox(find.byIcon(Icons.arrow_drop_down)));
      await tester.pumpAndSettle();

      expect(_list, findsOneWidget);
    }, skip: true); // M5: fixed in 8.0
  });

  group('overlay: open/close by tapping the box', () {
    testWidgets('tapping the box opens the list overlay with a search bar',
        (tester) async {
      await tester.pumpWidget(
          _app(_dropdown(items: _items(), selected: [], probe: _Probe())));

      await openMultiple(tester);

      expect(_list, findsOneWidget);
      expect(_searchField, findsOneWidget);
      expect(_inList(find.text('Pesquisar')), findsOneWidget);
      expect(_rowLabels(tester), ['Cherry', 'apple', 'Banana']);
      expect(_inBox(find.byIcon(Icons.arrow_drop_up)), findsOneWidget);
      expect(_inBox(find.byIcon(Icons.arrow_drop_down)), findsNothing);
    });

    testWidgets('tapping the box again closes it, and it can be reopened',
        (tester) async {
      await tester.pumpWidget(
          _app(_dropdown(items: _items(), selected: [], probe: _Probe())));

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
          _app(_dropdown(items: _items(), selected: selected, probe: probe)));

      await openMultiple(tester);

      expect(selected, isEmpty);
      expect(probe.updates, isEmpty);
    });
  });

  group('overlay: tapping outside closes (hideOverlay barrier)', () {
    testWidgets('tap far outside the list closes the overlay', (tester) async {
      await tester.pumpWidget(
          _app(_dropdown(items: _items(), selected: [], probe: _Probe())));
      await openMultiple(tester);

      await tester.tapAt(const Offset(780, 580));
      await tester.pumpAndSettle();

      expect(_list, findsNothing);
      expect(_inBox(find.byIcon(Icons.arrow_drop_down)), findsOneWidget);
    });

    testWidgets('tapping inside the list (search field) keeps it open',
        (tester) async {
      await tester.pumpWidget(
          _app(_dropdown(items: _items(), selected: [], probe: _Probe())));
      await openMultiple(tester);

      await tester.tap(_searchField);
      await tester.pumpAndSettle();

      expect(_list, findsOneWidget);
    });
  });

  group('overlay: positioned below the box (offsetHeight/offsetWidth)', () {
    testWidgets('default: box height + 3 below, same left, same width',
        (tester) async {
      await tester.pumpWidget(
          _app(_dropdown(items: _items(), selected: [], probe: _Probe())));
      await openMultiple(tester);

      expect(tester.getTopLeft(_box), const Offset(20, 20));
      expect(tester.getTopLeft(_list) - tester.getTopLeft(_box),
          const Offset(0, 53));
      expect(tester.getSize(_list).width, 300);
    });

    testWidgets('custom offsets and box size', (tester) async {
      await tester.pumpWidget(_app(_dropdown(
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
      )));
      await openMultiple(tester);

      expect(tester.getSize(_box), const Size(250, 40));
      expect(tester.getTopLeft(_list) - tester.getTopLeft(_box),
          const Offset(10, 60));
      expect(tester.getSize(_list).width, 250);
    });
  });

  group('overlay search: accent and case insensitive filter', () {
    testWidgets('filters by latinized, lower-cased contains', (tester) async {
      await tester.pumpWidget(
          _app(_dropdown(items: fruitItems(), selected: [], probe: _Probe())));
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

    testWidgets('filtered rows keep the sortType ordering', (tester) async {
      await tester.pumpWidget(_app(_dropdown(
          items: fruitItems(), selected: [], probe: _Probe(), sortType: 1)));
      await openMultiple(tester);

      await _type(tester, 'a');
      expect(_rowLabels(tester), ['Banana', 'Maçã', 'Pêra', 'Uva', 'abacaxi']);
    });

    testWidgets('selected rows stay highlighted while filtering',
        (tester) async {
      final items = fruitItems();
      await tester.pumpWidget(
          _app(_dropdown(items: items, selected: [items[1]], probe: _Probe())));
      await openMultiple(tester);

      await _type(tester, 'ban');
      expect(_rowLabels(tester), ['Banana']);
      expect(_rowSelected(tester, 'Banana'), isTrue);
    });
  });

  group('overlay sortType ordering (0/1/2/3)', () {
    Future<List<ValueItem<int>>> openWith(
      WidgetTester tester,
      int sortType, {
      List<int> selectedIdx = const <int>[],
    }) async {
      final items = _items();
      final selected = [for (final i in selectedIdx) items[i]];
      await tester.pumpWidget(_app(_dropdown(
          items: items,
          selected: selected,
          probe: _Probe(),
          sortType: sortType)));
      await openMultiple(tester);
      return items;
    }

    testWidgets('0: original order, caller list untouched', (tester) async {
      final items = await openWith(tester, 0);
      expect(_rowLabels(tester), ['Cherry', 'apple', 'Banana']);
      expect(_labels(items), ['Cherry', 'apple', 'Banana']);
    });

    testWidgets('1: String.compareTo order (uppercase before lowercase)',
        (tester) async {
      await openWith(tester, 1);
      expect(_rowLabels(tester), ['Banana', 'Cherry', 'apple']);
    });

    testWidgets('1: sorts the caller listItems in place (current behaviour)',
        (tester) async {
      final items = await openWith(tester, 1);
      expect(_labels(items), ['Banana', 'Cherry', 'apple']);
    });

    testWidgets('M7: sortType 1 must not reorder the caller listItems',
        (tester) async {
      final items = await openWith(tester, 1);
      expect(_labels(items), ['Cherry', 'apple', 'Banana']);
    }, skip: true); // M7: fixed in 8.0

    testWidgets('2: reverse String.compareTo order', (tester) async {
      await openWith(tester, 2);
      expect(_rowLabels(tester), ['apple', 'Cherry', 'Banana']);
    });

    testWidgets('3 without selection: original order', (tester) async {
      await openWith(tester, 3);
      expect(_rowLabels(tester), ['Cherry', 'apple', 'Banana']);
    });

    testWidgets('3: first selected item moved to the top (caller list too)',
        (tester) async {
      final items = await openWith(tester, 3, selectedIdx: [2, 1]);
      expect(_rowLabels(tester), ['Banana', 'Cherry', 'apple']);
      expect(_labels(items), ['Banana', 'Cherry', 'apple']);
    });

    testWidgets('3: tapping a row re-sorts immediately', (tester) async {
      await openWith(tester, 3);
      await _tapRow(tester, 'Banana');
      expect(_rowLabels(tester), ['Banana', 'Cherry', 'apple']);
    });
  });

  group('selection: tapping a row toggles selection', () {
    testWidgets('select: adds, passes the SAME list instance, overlay stays',
        (tester) async {
      final probe = _Probe();
      final items = _items();
      final List<ValueItem<int>> selected = [];
      await tester.pumpWidget(
          _app(_dropdown(items: items, selected: selected, probe: probe)));
      await openMultiple(tester);

      await _tapRow(tester, 'apple');

      expect(selected, [items[1]]);
      expect(probe.updates, hasLength(1));
      expect(probe.updates.single, same(selected));
      expect(probe.clearedItems, isEmpty);
      expect(_list, findsOneWidget);
      expect(_rowSelected(tester, 'apple'), isTrue);
      expect(_rowSelected(tester, 'Cherry'), isFalse);
      expect(_inBox(find.text('apple')), findsOneWidget);
    });

    testWidgets('multiple taps accumulate in tap order', (tester) async {
      final probe = _Probe();
      final items = _items();
      final List<ValueItem<int>> selected = [];
      await tester.pumpWidget(
          _app(_dropdown(items: items, selected: selected, probe: probe)));
      await openMultiple(tester);

      await _tapRow(tester, 'Banana');
      await _tapRow(tester, 'Cherry');

      expect(_labels(selected), ['Banana', 'Cherry']);
      expect(probe.updates, hasLength(2));
      expect(probe.updates.every((l) => identical(l, selected)), isTrue);
    });

    testWidgets('deselect: removes, calls onClearItem and updateSelectedItems',
        (tester) async {
      final probe = _Probe();
      final items = _items();
      final List<ValueItem<int>> selected = [items[1]];
      await tester.pumpWidget(
          _app(_dropdown(items: items, selected: selected, probe: probe)));
      await openMultiple(tester);

      await _tapRow(tester, 'apple');

      expect(selected, isEmpty);
      expect(probe.clearedItems, [items[1]]);
      expect(probe.updates.single, same(selected));
      expect(_rowSelected(tester, 'apple'), isFalse);
      expect(_inBox(find.text('Pesquisar')), findsOneWidget);
    });

    testWidgets('selection uses ValueItem equality (equal const instance)',
        (tester) async {
      final probe = _Probe();
      final List<ValueItem<int>> selected = [
        const ValueItem(label: 'apple', value: 1),
      ];
      await tester.pumpWidget(
          _app(_dropdown(items: _items(), selected: selected, probe: probe)));
      await openMultiple(tester);

      expect(_rowSelected(tester, 'apple'), isTrue);
      await _tapRow(tester, 'apple');
      expect(selected, isEmpty);
    });
  });

  group('selection: chip close icon deselects', () {
    testWidgets('removes that item, calls onClearItem, does not open',
        (tester) async {
      final probe = _Probe();
      final items = _items();
      final List<ValueItem<int>> selected = [items[0], items[1]];
      await tester.pumpWidget(
          _app(_dropdown(items: items, selected: selected, probe: probe)));

      await tester.tap(_inBox(find.byIcon(Icons.close)).first);
      await tester.pumpAndSettle();

      expect(selected, [items[1]]);
      expect(probe.clearedItems, [items[0]]);
      expect(probe.updates.single, same(selected));
      expect(_inBox(find.text('Cherry')), findsNothing);
      expect(_inBox(find.byType(Card)), findsOneWidget);
      expect(_list, findsNothing);
    });
  });

  group('clear icon: onClear clears all selections', () {
    testWidgets('clears in place, calls updateSelectedItems and onClearList',
        (tester) async {
      final probe = _Probe();
      final items = _items();
      final List<ValueItem<int>> selected = [items[0], items[2]];
      await tester.pumpWidget(
          _app(_dropdown(items: items, selected: selected, probe: probe)));

      await tester.tap(_inBox(find.byIcon(Icons.clear)));
      await tester.pumpAndSettle();

      expect(selected, isEmpty);
      expect(probe.updates, hasLength(1));
      expect(probe.updates.single, same(selected));
      expect(probe.clearList, 1);
      expect(probe.clearedItems, isEmpty);
      expect(_list, findsNothing);
      expect(_inBox(find.text('Pesquisar')), findsOneWidget);
      expect(_inBox(find.byIcon(Icons.arrow_drop_down)), findsOneWidget);
    });
  });

  group('State API: forceSelection(label)', () {
    testWidgets('selects by exact label, notifies and rebuilds chips',
        (tester) async {
      final key = GlobalKey<MultipleSearchDropDownState<int>>();
      final probe = _Probe();
      final items = _items();
      final List<ValueItem<int>> selected = [];
      await tester.pumpWidget(_app(
          _dropdown(key: key, items: items, selected: selected, probe: probe)));

      key.currentState!.forceSelection('apple');
      await tester.pump();

      expect(selected, [items[1]]);
      expect(probe.updates.single, same(selected));
      expect(_inBox(find.text('apple')), findsOneWidget);
    });

    testWidgets('already selected: no duplicate but still notifies',
        (tester) async {
      final key = GlobalKey<MultipleSearchDropDownState<int>>();
      final probe = _Probe();
      final items = _items();
      final List<ValueItem<int>> selected = [items[1]];
      await tester.pumpWidget(_app(
          _dropdown(key: key, items: items, selected: selected, probe: probe)));

      key.currentState!.forceSelection('apple');
      await tester.pump();

      expect(selected, [items[1]]);
      expect(probe.updates, hasLength(1));
      expect(probe.clearedItems, isEmpty);
    });

    testWidgets('unknown or differently-cased label is ignored',
        (tester) async {
      final key = GlobalKey<MultipleSearchDropDownState<int>>();
      final probe = _Probe();
      final List<ValueItem<int>> selected = [];
      await tester.pumpWidget(_app(_dropdown(
          key: key, items: _items(), selected: selected, probe: probe)));

      key.currentState!
        ..forceSelection('Kiwi')
        ..forceSelection('Apple');
      await tester.pump();

      expect(selected, isEmpty);
      expect(probe.updates, isEmpty);
    });
  });

  group('State API: forceMultipleSelection(values)', () {
    testWidgets(
        'replaces selection in place with values found in listItems, '
        'without notify and without rebuild', (tester) async {
      final key = GlobalKey<MultipleSearchDropDownState<int>>();
      final probe = _Probe();
      final items = _items();
      final List<ValueItem<int>> selected = [items[0]];
      await tester.pumpWidget(_app(
          _dropdown(key: key, items: items, selected: selected, probe: probe)));

      key.currentState!.forceMultipleSelection([
        const ValueItem(label: 'Banana', value: 2),
        const ValueItem(label: 'Ghost', value: 7),
        items[1],
      ]);
      await tester.pump();

      expect(_labels(selected), ['Banana', 'apple']);
      expect(probe.updates, isEmpty);
      expect(probe.clearList, 0);
      // No setState: the box still shows the previous chip.
      expect(_inBox(find.text('Cherry')), findsOneWidget);
      expect(_inBox(find.text('Banana')), findsNothing);

      // Any later rebuild reveals the new selection.
      key.currentState!
        ..enableDisable()
        ..enableDisable();
      await tester.pump();
      expect(_inBox(find.text('Cherry')), findsNothing);
      expect(_inBox(find.text('Banana')), findsOneWidget);
      expect(_inBox(find.text('apple')), findsOneWidget);
    });

    testWidgets('M3: forceMultipleSelection rebuilds chips immediately',
        (tester) async {
      final key = GlobalKey<MultipleSearchDropDownState<int>>();
      final items = _items();
      await tester.pumpWidget(_app(
          _dropdown(key: key, items: items, selected: [], probe: _Probe())));

      key.currentState!.forceMultipleSelection([items[0], items[2]]);
      await tester.pump();

      expect(_inBox(find.text('Cherry')), findsOneWidget);
      expect(_inBox(find.text('Banana')), findsOneWidget);
    }, skip: true); // M3: fixed in 8.0
  });

  group('State API: resetSelection()', () {
    testWidgets('clears in place and rebuilds, without any callback',
        (tester) async {
      final key = GlobalKey<MultipleSearchDropDownState<int>>();
      final probe = _Probe();
      final items = _items();
      final List<ValueItem<int>> selected = [items[0], items[1]];
      await tester.pumpWidget(_app(
          _dropdown(key: key, items: items, selected: selected, probe: probe)));

      key.currentState!.resetSelection();
      await tester.pump();

      expect(selected, isEmpty);
      expect(probe.updates, isEmpty);
      expect(probe.clearList, 0);
      expect(probe.clearedItems, isEmpty);
      expect(_inBox(find.byType(Card)), findsNothing);
      expect(_inBox(find.text('Pesquisar')), findsOneWidget);
    });

    testWidgets('M2: resetSelection calls updateSelectedItems', (tester) async {
      final key = GlobalKey<MultipleSearchDropDownState<int>>();
      final probe = _Probe();
      final items = _items();
      await tester.pumpWidget(_app(_dropdown(
          key: key, items: items, selected: [items[0]], probe: probe)));

      key.currentState!.resetSelection();
      await tester.pump();

      expect(probe.updates, hasLength(1));
      expect(probe.updates.single, isEmpty);
    }, skip: true); // M2: fixed in 8.0
  });

  group('State API: enableDisable() (opacity 0.38 + IgnorePointer)', () {
    testWidgets('toggles opacity and pointer ignoring', (tester) async {
      final key = GlobalKey<MultipleSearchDropDownState<int>>();
      await tester.pumpWidget(_app(
          _dropdown(key: key, items: _items(), selected: [], probe: _Probe())));
      expect(_opacity(tester), 1);
      expect(_ignoring(tester), isFalse);

      key.currentState!.enableDisable();
      await tester.pump();
      expect(_opacity(tester), 0.38);
      expect(_ignoring(tester), isTrue);
      expect(key.currentState!.enabled, isFalse);

      await tester.tap(_inBox(find.byType(InkWell)).first, warnIfMissed: false);
      await tester.pumpAndSettle();
      expect(_list, findsNothing);
      // The arrow depends on widget.enabled, not on the toggled state.
      expect(_inBox(find.byIcon(Icons.arrow_drop_down)), findsOneWidget);

      key.currentState!.enableDisable();
      await tester.pump();
      expect(_opacity(tester), 1);
      expect(_ignoring(tester), isFalse);
      await openMultiple(tester);
      expect(_list, findsOneWidget);
    });
  });

  group('State API: hideOverlay()', () {
    testWidgets('closes an open overlay and restores the closed arrow',
        (tester) async {
      final key = GlobalKey<MultipleSearchDropDownState<int>>();
      await tester.pumpWidget(_app(
          _dropdown(key: key, items: _items(), selected: [], probe: _Probe())));
      await openMultiple(tester);
      expect(key.currentState!.aberto, isTrue);

      key.currentState!.hideOverlay();
      await tester.pumpAndSettle();

      expect(_list, findsNothing);
      expect(key.currentState!.aberto, isFalse);
      expect(_inBox(find.byIcon(Icons.arrow_drop_down)), findsOneWidget);
    });

    testWidgets('on a closed dropdown it toggles the arrow to "opened"',
        (tester) async {
      final key = GlobalKey<MultipleSearchDropDownState<int>>();
      await tester.pumpWidget(_app(
          _dropdown(key: key, items: _items(), selected: [], probe: _Probe())));

      key.currentState!.hideOverlay();
      await tester.pumpAndSettle();

      expect(_list, findsNothing);
      expect(key.currentState!.aberto, isTrue);
      expect(_inBox(find.byIcon(Icons.arrow_drop_up)), findsOneWidget);

      // The next tap opens the overlay but flips the arrow back to "closed".
      await openMultiple(tester);
      expect(_list, findsOneWidget);
      expect(_inBox(find.byIcon(Icons.arrow_drop_down)), findsOneWidget);
    });

    testWidgets('M8: hideOverlay twice leaves the arrow closed',
        (tester) async {
      final key = GlobalKey<MultipleSearchDropDownState<int>>();
      await tester.pumpWidget(_app(
          _dropdown(key: key, items: _items(), selected: [], probe: _Probe())));
      await openMultiple(tester);

      key.currentState!
        ..hideOverlay()
        ..hideOverlay();
      await tester.pumpAndSettle();

      expect(_list, findsNothing);
      expect(_inBox(find.byIcon(Icons.arrow_drop_down)), findsOneWidget);
    }, skip: true); // M8: fixed in 8.0
  });

  group('add mode: add row (newValueItem/onAddItem)', () {
    testWidgets('text matching nothing shows the add row with "Criar"',
        (tester) async {
      await tester.pumpWidget(_app(_dropdown(
          items: _items(), selected: [], probe: _Probe(), addMode: true)));
      await openMultiple(tester);

      await _type(tester, 'Kiwi');

      expect(_rowLabels(tester), isEmpty);
      expect(find.byType(DefaultAddListItem), findsOneWidget);
      expect(
          tester
              .widget<DefaultAddListItem>(find.byType(DefaultAddListItem))
              .text,
          'Kiwi');
      expect(_inList(find.text('Criar')), findsOneWidget);
    });

    testWidgets('a partial match hides the add row', (tester) async {
      await tester.pumpWidget(_app(_dropdown(
          items: _items(), selected: [], probe: _Probe(), addMode: true)));
      await openMultiple(tester);

      await _type(tester, 'APP');

      expect(_rowLabels(tester), ['apple']);
      expect(find.byType(DefaultAddListItem), findsNothing);
    });

    testWidgets('empty search shows no add row', (tester) async {
      await tester.pumpWidget(_app(_dropdown(
          items: _items(), selected: [], probe: _Probe(), addMode: true)));
      await openMultiple(tester);

      expect(find.byType(DefaultAddListItem), findsNothing);
    });

    testWidgets('addMode false never shows the add row', (tester) async {
      await tester.pumpWidget(
          _app(_dropdown(items: _items(), selected: [], probe: _Probe())));
      await openMultiple(tester);

      await _type(tester, 'Kiwi');

      expect(_rowLabels(tester), isEmpty);
      expect(find.byType(DefaultAddListItem), findsNothing);
    });

    testWidgets(
        'tapping Criar: newValueItem -> onAddItem, item selected, search '
        'cleared', (tester) async {
      final probe = _Probe();
      final items = _items();
      final List<ValueItem<int>> selected = [];
      await tester.pumpWidget(_app(_dropdown(
          items: items, selected: selected, probe: probe, addMode: true)));
      await openMultiple(tester);
      await _type(tester, 'Kiwi');

      await tester.tap(_inList(find.text('Criar')));
      await tester.pumpAndSettle();

      const kiwi = ValueItem<int>(label: 'Kiwi', value: 99);
      expect(probe.added, [kiwi]);
      expect(selected, [kiwi]);
      expect(probe.updates.single, same(selected));
      expect(_searchText(tester), '');
      expect(_list, findsOneWidget);
      expect(_rowLabels(tester), ['Cherry', 'apple', 'Banana', 'Kiwi']);
      expect(_rowSelected(tester, 'Kiwi'), isTrue);
      expect(_inBox(find.text('Kiwi')), findsOneWidget);
    });

    testWidgets('if onAddItem does not grow listItems, item is only selected',
        (tester) async {
      final probe = _Probe();
      final List<ValueItem<int>> selected = [];
      await tester.pumpWidget(_app(_dropdown(
        items: _items(),
        selected: selected,
        probe: probe,
        addMode: true,
        addToList: false,
      )));
      await openMultiple(tester);
      await _type(tester, 'Kiwi');

      await tester.tap(_inList(find.text('Criar')));
      await tester.pumpAndSettle();

      expect(_labels(selected), ['Kiwi']);
      expect(_rowLabels(tester), ['Cherry', 'apple', 'Banana']);
    });
  });

  group('add mode: verifyInputItem warning dialog', () {
    testWidgets(
        'false: shows the "Erro!" WarningDialog, does not add nor select',
        (tester) async {
      final probe = _Probe();
      final List<ValueItem<int>> selected = [];
      final List<ValueItem<int>> verified = [];
      await tester.pumpWidget(_app(_dropdown(
        items: _items(),
        selected: selected,
        probe: probe,
        addMode: true,
        verifyInputItem: (item) {
          verified.add(item);
          return false;
        },
      )));
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
      expect(selected, isEmpty);
      expect(probe.updates, isEmpty);

      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();
      expect(find.byType(WarningDialog), findsNothing);
      expect(_list, findsOneWidget);
    });

    testWidgets('true: item is added and selected', (tester) async {
      final probe = _Probe();
      final List<ValueItem<int>> selected = [];
      await tester.pumpWidget(_app(_dropdown(
        items: _items(),
        selected: selected,
        probe: probe,
        addMode: true,
        verifyInputItem: (_) => true,
      )));
      await openMultiple(tester);
      await _type(tester, 'Good');

      await tester.tap(_inList(find.text('Criar')));
      await tester.pumpAndSettle();

      expect(find.byType(WarningDialog), findsNothing);
      expect(_labels(probe.added), ['Good']);
      expect(_labels(selected), ['Good']);
    });

    testWidgets(
        'M4 (not reproduced): #13 invalid item is not listed and the search '
        'is cleared', (tester) async {
      await tester.pumpWidget(_app(_dropdown(
        items: _items(),
        selected: [],
        probe: _Probe(),
        addMode: true,
        verifyInputItem: (_) => false,
      )));
      await openMultiple(tester);
      await _type(tester, 'Bad');

      await tester.tap(_inList(find.text('Criar')));
      await tester.pump();

      expect(_rowLabels(tester), ['Cherry', 'apple', 'Banana']);
      expect(_inList(find.text('Bad')), findsNothing);
      expect(_searchText(tester), '');
    });
  });

  group('delete mode: delete icon calls onDeleteItem', () {
    testWidgets('rows show a delete icon only when deleteMode is true',
        (tester) async {
      await tester.pumpWidget(
          _app(_dropdown(items: _items(), selected: [], probe: _Probe())));
      await openMultiple(tester);
      expect(_inList(find.byIcon(Icons.delete)), findsNothing);

      // Rebuilding the widget with deleteMode true while open does NOT
      // update the already-open overlay entry (it is stale)...
      await tester.pumpWidget(_app(_dropdown(
          items: _items(), selected: [], probe: _Probe(), deleteMode: true)));
      await tester.pumpAndSettle();
      expect(_inList(find.byIcon(Icons.delete)), findsNothing);

      // ...only closing and reopening picks up the new parameters.
      await tester.tapAt(const Offset(780, 580));
      await tester.pumpAndSettle();
      await openMultiple(tester);
      expect(_inList(find.byIcon(Icons.delete)), findsNWidgets(3));
    });

    testWidgets(
        'no confirm: calls onDeleteItem, clears ALL selections silently, '
        'refreshes the list', (tester) async {
      final probe = _Probe();
      final items = _items();
      final List<ValueItem<int>> selected = [items[0], items[1]];
      await tester.pumpWidget(_app(_dropdown(
          items: items, selected: selected, probe: probe, deleteMode: true)));
      await openMultiple(tester);

      await tester.tap(find.descendant(
          of: _row('Banana'), matching: find.byIcon(Icons.delete)));
      // The tile shows an endless spinner afterwards, so no pumpAndSettle.
      await tester.pump();

      expect(probe.deleted, [const ValueItem<int>(label: 'Banana', value: 2)]);
      expect(selected, isEmpty);
      expect(probe.updates, isEmpty);
      expect(probe.clearedItems, isEmpty);
      expect(_rowLabels(tester), ['Cherry', 'apple']);
      expect(_list, findsOneWidget);
      expect(_inBox(find.byType(Card)), findsNothing);
    });

    testWidgets('the tapped tile stays in loading state after delete',
        (tester) async {
      final items = _items();
      await tester.pumpWidget(_app(_dropdown(
          items: items, selected: [], probe: _Probe(), deleteMode: true)));
      await openMultiple(tester);

      await tester.tap(find.descendant(
          of: _row('Cherry'), matching: find.byIcon(Icons.delete)));
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      expect(_rowLabels(tester), ['apple', 'Banana']);
      expect(_inList(find.byType(CircularProgressIndicator)), findsOneWidget);
      expect(_inList(find.byIcon(Icons.delete)), findsOneWidget);
    });

    testWidgets('M1: deleting one item keeps the other selections',
        (tester) async {
      final items = _items();
      final List<ValueItem<int>> selected = [items[0], items[1]];
      await tester.pumpWidget(_app(_dropdown(
          items: items,
          selected: selected,
          probe: _Probe(),
          deleteMode: true)));
      await openMultiple(tester);

      await tester.tap(find.descendant(
          of: _row('Cherry'), matching: find.byIcon(Icons.delete)));
      await tester.pump();

      expect(_labels(selected), ['apple']);
    }, skip: true); // M1: fixed in 8.0
  });

  group('delete mode: confirmDelete shows a WarningDialog in the overlay', () {
    testWidgets('dialog content; Cancelar closes it without deleting',
        (tester) async {
      final probe = _Probe();
      final items = _items();
      final List<ValueItem<int>> selected = [items[1]];
      await tester.pumpWidget(_app(_dropdown(
        items: items,
        selected: selected,
        probe: probe,
        deleteMode: true,
        confirmDelete: true,
      )));
      await openMultiple(tester);

      await tester.tap(find.descendant(
          of: _row('Cherry'), matching: find.byIcon(Icons.delete)));
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
      expect(selected, [items[1]]);
      expect(_list, findsOneWidget);
      expect(_rowLabels(tester), ['Cherry', 'apple', 'Banana']);
      // The cancelled tile keeps its spinner (no delete icon any more).
      expect(_inList(find.byType(CircularProgressIndicator)), findsOneWidget);
    });

    testWidgets('Apagar deletes, clears the selection and closes the dialog',
        (tester) async {
      final probe = _Probe();
      final items = _items();
      final List<ValueItem<int>> selected = [items[1]];
      await tester.pumpWidget(_app(_dropdown(
        items: items,
        selected: selected,
        probe: probe,
        deleteMode: true,
        confirmDelete: true,
      )));
      await openMultiple(tester);

      await tester.tap(find.descendant(
          of: _row('Cherry'), matching: find.byIcon(Icons.delete)));
      await tester.pump();
      await tester.tap(find.text('Apagar'));
      await tester.pump();

      expect(find.byType(WarningDialog), findsNothing);
      expect(probe.deleted, [const ValueItem<int>(label: 'Cherry', value: 3)]);
      expect(selected, isEmpty);
      expect(probe.updates, isEmpty);
      expect(_list, findsOneWidget);
      expect(_inBox(find.text('Pesquisar')), findsOneWidget);
    });

    testWidgets('custom deleteDialogSettings title is used', (tester) async {
      final List<ValueItem<int>> selected = [];
      await tester.pumpWidget(_app(MultipleSearchDropDown<int>(
        listItems: _items(),
        selectedItems: selected,
        updateSelectedItems: (_) {},
        addMode: false,
        onDeleteItem: (_) {},
        confirmDelete: true,
        overlayListSettings: _tallOverlay,
        deleteDialogSettings: const DialogSettings(title: Text('Sure?')),
      )));
      await openMultiple(tester);

      await tester.tap(find.descendant(
          of: _row('apple'), matching: find.byIcon(Icons.delete)));
      await tester.pump();

      expect(find.text('Sure?'), findsOneWidget);
      expect(find.text('Tem certeza?'), findsNothing);
    });
  });

  group('edit mode: edit icon is a no-op', () {
    testWidgets('edit icon shown; tapping it never calls onEditItem',
        (tester) async {
      final probe = _Probe();
      await tester.pumpWidget(_app(_dropdown(
          items: _items(), selected: [], probe: probe, editMode: true)));
      await openMultiple(tester);
      expect(_inList(find.byIcon(Icons.edit)), findsNWidgets(3));

      await tester.tap(_inList(find.byIcon(Icons.edit)).first);
      await tester.pump();
      await tester.pump();

      expect(probe.edited, isEmpty);
      expect(find.byType(EditDialog), findsNothing);
      expect(_inList(find.byIcon(Icons.edit)), findsNWidgets(3));
    });
  });

  group('overlay: additional widgets (default/add rows)', () {
    testWidgets('defaultAditionalWidget per row, addAditionalWidget on add row',
        (tester) async {
      await tester.pumpWidget(_app(_dropdown(
        items: _items(),
        selected: [],
        probe: _Probe(),
        addMode: true,
        defaultAditionalWidget: const Text('extra'),
        addAditionalWidget: const Text('extra-add'),
      )));
      await openMultiple(tester);
      expect(_inList(find.text('extra')), findsNWidgets(3));
      expect(_inList(find.text('extra-add')), findsNothing);

      await _type(tester, 'Kiwi');
      expect(_inList(find.text('extra')), findsNothing);
      expect(_inList(find.text('extra-add')), findsOneWidget);
    });
  });

  group('enabled=false constructor param', () {
    testWidgets('dimmed, ignores taps, hides the arrow', (tester) async {
      await tester.pumpWidget(_app(_dropdown(
          items: _items(), selected: [], probe: _Probe(), enabled: false)));

      expect(_opacity(tester), 0.38);
      expect(_ignoring(tester), isTrue);
      expect(_inBox(find.byIcon(Icons.arrow_drop_down)), findsNothing);

      await tester.tap(_inBox(find.byType(InkWell)).first, warnIfMissed: false);
      await tester.pumpAndSettle();
      expect(_list, findsNothing);
    });

    testWidgets('with a selection the clear icon is still rendered',
        (tester) async {
      final items = _items();
      await tester.pumpWidget(_app(_dropdown(
          items: items,
          selected: [items[0]],
          probe: _Probe(),
          enabled: false)));

      expect(_inBox(find.byIcon(Icons.clear)), findsOneWidget);
      expect(_inBox(find.text('Cherry')), findsOneWidget);
    });

    testWidgets('enableDisable() re-enables taps but the arrow stays hidden',
        (tester) async {
      final key = GlobalKey<MultipleSearchDropDownState<int>>();
      await tester.pumpWidget(_app(_dropdown(
          key: key,
          items: _items(),
          selected: [],
          probe: _Probe(),
          enabled: false)));

      key.currentState!.enableDisable();
      await tester.pump();

      expect(_opacity(tester), 1);
      expect(_ignoring(tester), isFalse);
      expect(_inBox(find.byType(Icon)), findsNothing);
      await openMultiple(tester);
      expect(_list, findsOneWidget);
    });
  });

  group('constructor asserts (addMode/deleteMode/editMode)', () {
    test('addMode (default true) requires newValueItem and onAddItem', () {
      expect(
        () => MultipleSearchDropDown<int>(
          listItems: const [],
          selectedItems: const [],
          updateSelectedItems: (_) {},
          deleteMode: false,
          onAddItem: (_) {},
        ),
        throwsAssertionError,
      );
      expect(
        () => MultipleSearchDropDown<int>(
          listItems: const [],
          selectedItems: const [],
          updateSelectedItems: (_) {},
          deleteMode: false,
          newValueItem: (s) => ValueItem(label: s),
        ),
        throwsAssertionError,
      );
    });

    test('deleteMode (default true) requires onDeleteItem', () {
      expect(
        () => MultipleSearchDropDown<int>(
          listItems: const [],
          selectedItems: const [],
          updateSelectedItems: (_) {},
          addMode: false,
        ),
        throwsAssertionError,
      );
    });

    test('editMode requires onEditItem', () {
      expect(
        () => MultipleSearchDropDown<int>(
          listItems: const [],
          selectedItems: const [],
          updateSelectedItems: (_) {},
          addMode: false,
          deleteMode: false,
          editMode: true,
        ),
        throwsAssertionError,
      );
    });

    test('all modes off needs no callbacks', () {
      expect(
        () => MultipleSearchDropDown<int>(
          listItems: const [],
          selectedItems: const [],
          updateSelectedItems: (_) {},
          addMode: false,
          deleteMode: false,
        ),
        returnsNormally,
      );
    });
  });

  group('lifecycle: widget removed while the overlay is open', () {
    testWidgets('the overlay entry is left behind (current behaviour)',
        (tester) async {
      await tester.pumpWidget(
          _app(_dropdown(items: _items(), selected: [], probe: _Probe())));
      await openMultiple(tester);

      await tester.pumpWidget(_app(const SizedBox()));

      expect(_box, findsNothing);
      expect(_list, findsOneWidget);

      // Its full-screen barrier calls hideOverlay on the disposed State.
      await tester.tapAt(const Offset(780, 580));
      expect(tester.takeException(), isFlutterError);
    });

    testWidgets('M6: removing the widget removes the overlay entry',
        (tester) async {
      await tester.pumpWidget(
          _app(_dropdown(items: _items(), selected: [], probe: _Probe())));
      await openMultiple(tester);

      await tester.pumpWidget(_app(const SizedBox()));

      expect(_list, findsNothing);
    }, skip: true); // M6: fixed in 8.0
  });
}
