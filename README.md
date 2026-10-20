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
from code and the widget updates — no `GlobalKey` needed.

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

The list opens scrolled to the selected item. Arrow keys move the highlight,
PageUp/PageDown jump to the first/last item and Enter selects.

### Items

Both controllers take `items:` and keep their own copy (a multiple controller
copies `selectedItems` too); `controller.items` is a read-only view of it. Your
lists are never read again nor written: sorting orders the copy, and
add/edit/delete change it only after your callback completes without throwing,
so the callbacks are notifications (e.g. to persist). Unmodifiable lists
(`const`, `List.unmodifiable`, freezed) are fine. To change the items from
outside, call `controller.updateListItems(newList, shouldReset)`; to keep two
dropdowns on one list, call it on the other controller from your callbacks.

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
`async`; the row shows a spinner while they run.

### Useful controller members

| Member | What it does |
|---|---|
| `selectedItem`, `selectItem(item)`, `forceSelection(label)` | read / set the selection |
| `resetSelection()` | clear selection and text (calls `updateSelectedItem(null)`) |
| `items` | the controller's own items (read-only) |
| `updateListItems(list, shouldReset)` | replace the items (the only way from outside) |
| `enabled`, `toggleEnabled()` | enable / disable |
| `sortBy(SortType)` | `none`, `alphabetical`, `reverseAlphabetical`, `selectedFirst` |
| `filteredItems`, `onFilterUpdated` | current results |
| `latinize`, `caseSensitive`, `trim` (constructor) | how text is matched |

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
`controller:`.

## Look and texts

- `SimpleSearchbarSettings` — the bar/box: size, colors, border, hint, icons,
  `showClearIcon`, `clearOnClose`, chip style for the multiple dropdown.
- `SimpleOverlaySettings` — the list: height, row colors and text styles,
  keyboard highlight colors, custom `itemWidgetBuilder`, delete/edit icons,
  loading indicator, full screen.
- `DialogSettings` — delete confirmation, invalid item and edit dialogs.

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

## Migrating from 7.x

8.0 is a major release: the 7.x members below were removed, so replace
them as the table shows. The package now also exports `SortType`, `SearchDropDownStrings`,
`SearchDropDownStringsScope` and `MultipleSearchDropDownController`. If your
app declares a type with one of these names, hide it from the import
(`import 'package:simple_search_dropdown/simple_search_dropdown.dart' hide SortType;`)
or import the package with a prefix.

| 7.x | 8.0 |
|---|---|
| `GlobalKey<SearchDropDownState>` + `resetSelection()` / `enableDisable()` / `updateList()` | `controller.resetSelection()` / `toggleEnabled()` / `updateListItems()` |
| `GlobalKey<MultipleSearchDropDownState>` methods | `MultipleSearchDropDownController` (`controller:` parameter) |
| `sortType: 0..3` | `sort: SortType.none / alphabetical / reverseAlphabetical / selectedFirst` |
| `addAditionalWidget`, `defaultAditionalWidget`, `aditionalWidgetSpacing` | `addAdditionalWidget`, `defaultAdditionalWidget`, `additionalWidgetSpacing` |
| `hint: 'Pesquisar'`, `addItemHint: 'Criar'`, dialog button texts | `SearchDropDownStrings` (settings texts still win when set) |
| `SearchDropDownController(listItems: list)` / `MultipleSearchDropDownController(listItems: list)` | `items: list` (a copy); read it back with `controller.items`, change it with `updateListItems` |
| `MultipleSearchDropDown(listItems:, selectedItems:, updateSelectedItems:, addMode:, ...)` | `MultipleSearchDropDown(controller: MultipleSearchDropDownController(items:, selectedItems:, updateSelectedItems:, addMode:, ...))` |
| `MultipleListView(listItens: ..., onItemSelected: ...)` | `MultipleSearchDropDown` (`MultipleListView` is no longer exported) |
| `multipleState.overlayScreen.closeAll()` / `overlayEntrys.isEmpty` | `multipleState.hideOverlay()` / `!multipleState.aberto` |

Behaviour changes worth knowing (see the CHANGELOG for all of them):

- Reopening the single dropdown lists every item, scrolled to the selection
  (it used to show only the selected one); Enter keeps the selection.
- Assigning `controller.selectedItem` updates the bar text and clear button
  (still without calling `updateSelectedItem`).
- Single keyboard: Tab into the bar keeps the focus and Tab moves on to the
  next field; Enter on the closed bar selects nothing; a disabled dropdown
  cannot be focused.
- A disabled multiple dropdown cannot be focused either (its box, chips and
  clear button) and closes its open list. Its controller's `addMode`,
  `deleteMode`, `editMode`, `confirmDelete` and `sort` can be changed after
  creation.
- A–Z / Z–A ignore case and accents (`abacaxi, Banana, Maçã`); digits still
  compare as text (`Item 10` before `Item 2`).
- Your lists are never sorted or written (7.x sorted the single list in place
  and read both live): see "Items" above.
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
