# Simple Search Dropdown

Single and multiple selection dropdowns with search, built on Material 3.
Accent- and case-insensitive filtering, optional add / edit / delete of items,
keyboard navigation and Portuguese texts by default (any language via
`SearchDropDownStrings`).

[![Buy Me A Coffee](https://img.shields.io/badge/Buy%20Me%20a%20Coffee-FFDD00?style=flat)](https://buymeacoffee.com/gian.bettega)

| Add | Delete | Search |
|---|---|---|
| ![Add Mode](https://github.com/Lorenzobettega/simplesearchdropdown/assets/84482292/d3b61c7e-b4ac-4b53-867b-71daab10d687) | ![Delete Mode](https://github.com/Lorenzobettega/simplesearchdropdown/assets/84482292/ee4df7de-ec95-4804-a239-dc9ab8b5af9b) | ![Search](https://github.com/Lorenzobettega/simplesearchdropdown/assets/84482292/2e8360a7-9dd2-4b23-9431-d50b44cb7e07) |

## Install

```yaml
dependencies:
  simple_search_dropdown: ^8.0.0
```

```dart
import 'package:simple_search_dropdown/simple_search_dropdown.dart';
```

Requires Flutter 3.32 or newer.

## Single selection

All state lives in a `SearchDropDownController` (a `ChangeNotifier`): change it
from code and the widget updates, no `GlobalKey` needed.

```dart
class FruitPicker extends StatefulWidget {
  const FruitPicker({super.key});

  @override
  State<FruitPicker> createState() => _FruitPickerState();
}

class _FruitPickerState extends State<FruitPicker> {
  late final SearchDropDownController<String> controller =
      SearchDropDownController<String>(
    items: const [
      ValueItem(label: 'Maçã', value: 'apple'),
      ValueItem(label: 'Banana', value: 'banana'),
      ValueItem(label: 'Uva', value: 'grape'),
    ],
    addMode: false,
    deleteMode: false,
    updateSelectedItem: (item) => debugPrint('selected: ${item?.value}'),
  );

  @override
  Widget build(BuildContext context) {
    // The widget disposes the controller (disposeController: true).
    return SearchDropDown<String>(controller: controller);
  }
}
```

`SearchDropDown(disposeController: true)` (the default) disposes the controller
with the widget when the controller created its own `SearchController`. If you
pass `searchController:`, both are yours: dispose them together, in your own
`dispose`.

### Items

Both controllers take `items:` and keep their own copy (a multiple controller
copies `selectedItems` too); `controller.items` is a read-only view of it. Your
lists are never read again nor written:

- sorting orders the controller's copy (or, in the multiple dropdown, only the
  results);
- add/edit/delete change the copy only after your callback completes without
  throwing, so the callbacks are notifications (e.g. to persist);
- unmodifiable lists (`const`, `List.unmodifiable`, freezed) are fine.

To change the items from outside, call `controller.updateListItems(newList,
shouldReset)`; it copies `newList`. The single controller resets the selection
when `shouldReset` is `true` or an item is selected; the multiple controller
clears it when `shouldReset` is `true`, otherwise only the selected items that
are no longer in `newList` leave the selection. To keep two dropdowns on one
list, call `updateListItems` on the other controller from your callbacks.

A callback may apply a server copy with `updateListItems` on its own
controller (e.g. the saved item with its database id); the controller then
keeps the app's list instead of applying the change again: add selects the
matching item from it (equal, else the same label) and appends nothing, edit
selects the edited item from it and never brings back an item the list
dropped, and delete leaves it as it is.

### Add, edit and delete

```dart
SearchDropDownController<String> editableController(
        List<ValueItem<String>> db) =>
    SearchDropDownController<String>(
      items: db,
      newValueItem: (input) => ValueItem(label: input, value: input),
      onAddItem: (item) async => debugPrint('save $item'),
      editMode: true,
      onEditItem: (old, edited) async => debugPrint('$old -> $edited'),
      onDeleteItem: (item) async => debugPrint('delete $item'),
      confirmDelete: true,
      verifyInputItem: (item) => item.label.trim().isNotEmpty,
      sort: SortType.alphabetical,
    );
```

The "Criar" row appears when the typed text matches nothing. Callbacks may be
`async`; the row shows a spinner while they run. An error thrown by a callback
started from a row is reported with `FlutterError.reportError` and the item
stays as it was.

## Multiple selection

```dart
class TagPicker extends StatefulWidget {
  const TagPicker({super.key});

  @override
  State<TagPicker> createState() => _TagPickerState();
}

class _TagPickerState extends State<TagPicker> {
  final MultipleSearchDropDownController<int> controller =
      MultipleSearchDropDownController<int>(
    items: List.generate(20, (i) => ValueItem(label: 'Tag $i', value: i)),
    addMode: false,
    deleteMode: false,
  );

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Column(
        children: [
          MultipleSearchDropDown<int>(controller: controller),
          TextButton(
            onPressed: controller.resetSelection,
            child: const Text('Clear'),
          ),
        ],
      );
}
```

Selected items show as chips inside the box; the list opens below it with its
own search field. Items, selection, modes and callbacks live on its required
`controller:`. The widget never disposes the controller: dispose it in your
`State.dispose`, as above.

## Controller API

| Single (`SearchDropDownController`) | Multiple (`MultipleSearchDropDownController`) | What it does |
|---|---|---|
| `selectedItem` (get/set), `selectItem(item)` | `selectedItems`, `toggle(item)`, `forceMultipleSelection(values)` | read / change the selection (`selectItem` and `toggle` call your selection callback; the `selectedItem` setter and `forceMultipleSelection` do not) |
| `forceSelection(label)` | `forceSelection(label)` | select by label (exact first, then ignoring case and accents) |
| `resetSelection()` | `resetSelection()`, `clear()` | clear the selection (`clear` also calls `onClearList`) |
| `items`, `updateListItems(list, shouldReset)` | `items`, `updateListItems(list, shouldReset)` | the controller's own items (read-only); replace them |
| `filteredItems`, `onFilterUpdated` | `filteredItems`, `query`, `onFilterUpdated` | current results |
| `enabled` (get/set), `toggleEnabled()` | `enabled` (get/set), `toggleEnabled()` | enable / disable |
| `sort`, `sortBy(SortType)` | `sort` (get/set) | `none`, `alphabetical`, `reverseAlphabetical`, `selectedFirst` |
| `addMode`, `editMode`, `deleteMode`, `confirmDelete` (constructor) | `addMode`, `editMode`, `deleteMode`, `confirmDelete` (also settable later) | which row actions are offered |
| `addItem(text, context)`, `editItem(item, context)`, `deleteItem(item, context)` | `addItem(text, context)`, `addValue(item, context)`, `editItem(item, context)`, `deleteItem(item, context)` | run an add/edit/delete as a row would, with its dialogs |
| `latinize`, `caseSensitive`, `trim` (constructor) | `latinize`, `caseSensitive`, `trim` (constructor) | how text is matched |

Both are `ChangeNotifier`s: listen to them, and call `dispose()` when done
(calling it twice is safe).

## Look and texts

- `SimpleSearchbarSettings`: the bar/box: size, colors, border, hint, icons,
  `showClearIcon`, `clearOnClose`, keyboard type, chip style for the multiple
  dropdown.
- `SimpleOverlaySettings`: the list: height, row colors and text styles,
  keyboard highlight colors (`highlightedItemBackgroundColor`,
  `highlightedItemBorderColor`), custom `itemWidgetBuilder`, delete/edit
  icons, loading indicator, full screen.
- `DialogSettings`: delete confirmation, invalid item and edit dialogs.

Texts default to Portuguese. Use `SearchDropDownStrings.en()`, or your own
texts, per widget (`strings:`) or for the whole app:

```dart
Widget englishApp(Widget home) => MaterialApp(
      builder: (context, child) => SearchDropDownStringsScope(
        strings: const SearchDropDownStrings.en(),
        child: child!,
      ),
      home: home,
    );
```

A text set explicitly in a settings object (e.g. `SimpleSearchbarSettings.hint`)
wins over `strings`.

## Keyboard and accessibility

- Single: the list opens scrolled to the selected item and lists every item
  until you type. Arrow keys move the keyboard highlight (drawn apart from the
  selection), PageUp/PageDown jump to the first/last item and Enter selects
  the highlighted (or first) item; with the selected label untouched Enter
  keeps the selection. Tab and Shift+Tab move on to the next/previous field.
- Multiple: rows, chips and buttons are reached with Tab and activated with
  Enter or Space.
- A disabled dropdown (`enabled: false`) cannot take the focus.
- Buttons, rows, chips and loading indicators carry tooltips and semantics
  labels from `SearchDropDownStrings`; screen readers announce the selected
  row as selected.

## Migrating from 7.x

8.0 is a major release with no deprecation period: the 7.x members below were
removed. Replace them as the table shows (the CHANGELOG has the same table).

| 7.x | 8.0 |
|---|---|
| `addAditionalWidget` (`SearchDropDown`, `MultipleSearchDropDown`, `DefaultAddListItem`) | `addAdditionalWidget` |
| `defaultAditionalWidget` (`SearchDropDown`, `MultipleSearchDropDown`, `DefaultListTile`) | `defaultAdditionalWidget` |
| `SimpleOverlaySettings.aditionalWidgetSpacing` | `additionalWidgetSpacing` |
| `sortType: int` (`SearchDropDownController`, `MultipleSearchDropDown`) | `sort: SortType`: `0` → `SortType.none`, `1` → `alphabetical`, `2` → `reverseAlphabetical`, `3` → `selectedFirst`, any other value → `none` (as 7.x did; `SortType.values[n]` throws for those) |
| `SearchDropDownController.sortList(int)` | `sortBy(SortType)` |
| `SearchDropDownController(listItems: list)` and its `listItems` field (your list, read live and changed by the controller) | `items: list` (the controller keeps its own copy), the read-only `items` getter, and `updateListItems(list, shouldReset)` to replace them |
| add/edit/delete callbacks that changed your list, one list shared by two dropdowns, the single `sort` reordering your list in place | your lists are never read again nor written: the controller sorts its copy and applies add/edit/delete to it once the callback completes without throwing; keep another dropdown in step from your callbacks with its `updateListItems`; a callback may also apply a server copy to its own controller with `updateListItems`, and the controller then keeps the app's list |
| `MultipleSearchDropDown(listItems:, selectedItems:, updateSelectedItems:, addMode:, onAddItem:, newValueItem:, deleteMode:, onDeleteItem:, editMode:, onEditItem:, onClearItem:, onClearList:, sortType:, confirmDelete:, deleteDialogSettings:, verifyInputItem:, verifyDialogSettings:, enabled:)` | `MultipleSearchDropDown(controller: MultipleSearchDropDownController(items:, selectedItems:, ...))`: `controller:` is required and takes the same options (`onEditItem` gets `(old, edited)`; `editMode: true` also needs `newValueItem`, which builds the edited item) |
| `MultipleSearchDropDown(selectedItems: list)` (your list, changed in place and passed to `updateSelectedItems`) | `selectedItems:` is copied; `controller.selectedItems` is a read-only view and `updateSelectedItems` gets a copy |
| `SearchDropDownState.enableDisable()` (via `GlobalKey`) | `controller.toggleEnabled()` |
| `SearchDropDownState.resetSelection()` | `controller.resetSelection()` |
| `SearchDropDownState.updateList(list, shouldreset:)` | `controller.updateListItems(list, shouldReset)` |
| `MultipleSearchDropDownState.aberto = open` | tap the box to open, `hideOverlay()` to close (`aberto` is a read-only getter) |
| `MultipleSearchDropDownState.enabled` | `controller.enabled` |
| `MultipleSearchDropDownState.onItemSelected(item)` | `controller.toggle(item)` |
| `MultipleSearchDropDownState.resetSelection()` | `controller.resetSelection()` |
| `MultipleSearchDropDownState.forceSelection(label)` | `controller.forceSelection(label)` |
| `MultipleSearchDropDownState.forceMultipleSelection(values)` | `controller.forceMultipleSelection(values)` |
| `MultipleSearchDropDownState.enableDisable()` | `controller.toggleEnabled()` |
| `MultipleSearchDropDownState.handleAddItem(item, context)` | `controller.addValue(item, context)` |
| `MultipleSearchDropDownState.handleDeleteItem(item, context)` | `controller.deleteItem(item, context)` |
| `MultipleSearchDropDownState.onClear()` | `controller.clear()` |
| `MultipleSearchDropDownState.overlayScreen` and the exported `OverlayScreen` class | removed: close the list with `hideOverlay()`; show your own overlays with `Overlay.of(context)` |
| `MultipleListView` (exported; `listItens:`, `selectedItens:`, `onItemSelected:`, ...) | no longer exported: use `MultipleSearchDropDown` |

The package now also exports `SortType`, `SearchDropDownStrings`,
`SearchDropDownStringsScope` and `MultipleSearchDropDownController`. If your
file imports a type with one of these names from elsewhere, hide it
(`import 'package:simple_search_dropdown/simple_search_dropdown.dart' hide SortType;`)
or import the package with a prefix.

Behaviour changes worth knowing (see the CHANGELOG for all of them):

- Reopening the single dropdown lists every item, scrolled to the selection
  (it used to show only the selected one); Enter keeps the selection.
- Assigning `controller.selectedItem` updates the bar text and clear button
  (still without calling `updateSelectedItem`).
- Single keyboard: Tab moves on to the next field; Enter on the closed bar
  selects nothing; a disabled dropdown cannot be focused.
- A disabled multiple dropdown cannot be focused either (its box, chips and
  clear button) and closes its open list.
- A-Z / Z-A ignore case and accents (`abacaxi, Banana, Maçã`); digits still
  compare as text (`Item 10` before `Item 2`).
- An error thrown by `onAddItem`, `onEditItem` or `onDeleteItem` from a list
  row is reported with `FlutterError.reportError` (crash reporters see it);
  the item stays as it was.
- The clear button shows after a selection by default: the controller's
  `showClearIcon` now defaults to `true` (pass `false` to hide it), and
  `SimpleSearchbarSettings.showClearIcon: false` hides it in the open list too.
- Deleting an item in the multiple dropdown deselects only that item.
- `ValueItem.hashCode` changed (equal items still hash alike).

## License

[MIT](LICENSE)
