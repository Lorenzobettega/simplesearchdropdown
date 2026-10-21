# Simple Search Dropdown

Searchable single and multiple selection dropdowns for Flutter, built on
Material 3.

[![pub package](https://img.shields.io/pub/v/simple_search_dropdown.svg)](https://pub.dev/packages/simple_search_dropdown)
[![CI](https://github.com/Lorenzobettega/simplesearchdropdown/actions/workflows/ci.yml/badge.svg)](https://github.com/Lorenzobettega/simplesearchdropdown/actions/workflows/ci.yml)
[![License: MIT](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)

`SearchDropDown` picks one item and `MultipleSearchDropDown` picks several
(shown as chips). Both filter as you type, can let users create, edit and
delete items in place, and keep their whole state in a controller you own.
Use it when a plain `DropdownButton` is not enough: long lists, lists users
search more than scroll, or lists users maintain themselves.

## Features

- **Single and multiple selection**: `SearchDropDown` (built on
  `SearchAnchor`) and `MultipleSearchDropDown` (chips in the box, the list in
  an overlay with its own search field).
- **Forgiving search**: accent- and case-insensitive by default (`ca` finds
  `Lança`), with `latinize`, `caseSensitive` and `trim` to tune it.
- **Add, edit and delete** from the list, with `async` callbacks (the row
  shows a spinner while they run), input validation and an optional delete
  confirmation that names the item.
- **Controller-driven**: `SearchDropDownController` and
  `MultipleSearchDropDownController` are `ChangeNotifier`s; change the
  selection, items or enabled state from code and the widget follows. No
  `GlobalKey`. Controllers keep their own copy of your list and never write
  to yours.
- **Sorting**: `SortType.none`, `alphabetical`, `reverseAlphabetical`,
  `selectedFirst`.
- **Theming**: unset colors come from your `ColorScheme`, in light and dark
  themes, with AA text contrast; every color can be overridden.
- **Localizable texts**: Portuguese by default, English built in
  (`SearchDropDownStrings.en()`), any language via your own strings, per
  widget or app-wide.
- **Keyboard and accessibility**: arrow keys, PageUp/PageDown, Enter and Tab;
  tooltips and semantics labels on rows, chips, buttons and spinners.
- **Large lists**: rows are built lazily, and a selection or an arrow key
  rebuilds only the rows whose state changed.
- **Custom rows** with `itemWidgetBuilder`, any value type (`ValueItem<T>`).

## Screenshots

<p>
  <img src="https://raw.githubusercontent.com/Lorenzobettega/simplesearchdropdown/main/doc/screenshots/single_light.webp" width="260" title="Single selection" alt="Single dropdown open, the selected item highlighted">
  <img src="https://raw.githubusercontent.com/Lorenzobettega/simplesearchdropdown/main/doc/screenshots/search_accents.webp" width="260" title="Accent-insensitive search, custom rows" alt="Typing ca finds Lucas and Lança, custom rows">
  <img src="https://raw.githubusercontent.com/Lorenzobettega/simplesearchdropdown/main/doc/screenshots/multiple_light.webp" width="260" title="Multiple selection" alt="Multiple dropdown with three chips and the list open">
  <img src="https://raw.githubusercontent.com/Lorenzobettega/simplesearchdropdown/main/doc/screenshots/delete_dialog.webp" width="260" title="Delete confirmation" alt="Delete confirmation dialog naming the item">
  <img src="https://raw.githubusercontent.com/Lorenzobettega/simplesearchdropdown/main/doc/screenshots/single_dark.webp" width="260" title="Dark theme" alt="Single dropdown open in a dark theme">
  <img src="https://raw.githubusercontent.com/Lorenzobettega/simplesearchdropdown/main/doc/screenshots/multiple_dark.webp" width="260" title="Dark theme, multiple" alt="Multiple dropdown in a dark theme">
</p>

In order: single selection, accent-insensitive search with custom
rows, multiple selection, the delete confirmation, and both dropdowns in a
dark theme. All taken from the [example app](example/lib/main.dart)
(Material 3 theme seeded from `darkGreen`).

## Install

```yaml
dependencies:
  simple_search_dropdown: ^8.0.1
```

```dart
import 'package:simple_search_dropdown/simple_search_dropdown.dart';
```

Requires Flutter 3.32 or newer.

## Quick start: single selection

Create a `SearchDropDownController` with your items and hand it to
`SearchDropDown`:

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

Opening the list shows every item, scrolled to the selection. The caret sits
at the end of the selected label and the first key you type replaces it, so
you can start a new search right away; until you type, Enter keeps the
selection.

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

- The "Criar" row appears when the typed text matches nothing;
  `verifyInputItem` rejects invalid input with a warning dialog.
- Callbacks may be `async`; the row shows a spinner while they run. An error
  thrown by a callback started from a row is reported with
  `FlutterError.reportError` and the item stays as it was.
- The controller applies the change to its own copy only after your callback
  completes, so callbacks are notifications (for example, to persist).

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
`controller:`, which takes the same add/edit/delete options as the single
one. The widget never disposes this controller: dispose it in your
`State.dispose`, as above.

## Controller

All state lives in the controller. Both controllers are `ChangeNotifier`s:
listen to them, and call `dispose()` when done (calling it twice is safe).

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

### Items are copied

Both controllers take `items:` and keep their own copy (a multiple controller
copies `selectedItems` too); `controller.items` is a read-only view of it.
Your lists are never read again nor written:

- sorting orders the controller's copy (or, in the multiple dropdown, only the
  results);
- add/edit/delete change the copy only after your callback completes without
  throwing;
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

## Customization

Both widgets take `searchBarSettings:` and `overlayListSettings:`; dialogs are
configured on the controller (`editDialogSettings`, `deleteDialogSettings`,
`verifyDialogSettings`).

- `SimpleSearchbarSettings`: the bar/box: size, colors, border, hint, icons,
  `showClearIcon`, `clearOnClose`, keyboard type, chip style for the multiple
  dropdown (`boxMultiItemWidgetBuilder` for your own chips).
- `SimpleOverlaySettings`: the list: height, row colors and text styles,
  keyboard highlight colors (`highlightedItemBackgroundColor`,
  `highlightedItemBorderColor`), custom `itemWidgetBuilder`, delete/edit
  icons, loading indicator, `openFullScreen`.
- `DialogSettings`: delete confirmation, invalid item and edit dialogs.

### Dialogs

The three dialogs share one layout: a semibold title, supporting text in the
theme's `onSurfaceVariant`, and one row of equal-width buttons (48 high,
radius 12, 12 apart) that does not wrap on a phone. Editar and OK are filled
`darkGreen`, Apagar is filled red, Cancelar is outlined in the theme colors.
The edit dialog has one outlined field that starts with the label selected;
Enter confirms.

The delete confirmation names the item: `Apagar item?` and
`“label” será apagado.` (`SearchDropDownStrings.confirmDeleteItemTitle` and
`confirmDeleteItemContent`, where `{item}` becomes the label in bold). Set
`DialogSettings(showItemLabel: false)` for the generic `Tem certeza?` dialog;
if you customise `confirmDeleteTitle`, set `confirmDeleteItemTitle` too. When
you show the dialogs yourself, `WarningDialog`, `DefaultDialogTitle` and
`DefaultDialogContent` take the label as `itemLabel`.

### Theming

A color left unset in `SimpleSearchbarSettings` or `SimpleOverlaySettings`
comes from `Theme.of(context).colorScheme`, under a light theme and a dark one
alike (since 8.0.1; 8.0.0 drew fixed light colors under a light theme):

| Part | Default |
|---|---|
| bar, multiple box and list | `surfaceContainerLow` (light, the shadow shows the elevation) or `surfaceContainerHigh` (dark), 12 px corners |
| hint (a `hintStyle` without a color) | `onSurfaceVariant` |
| selected row | `secondaryContainer` with `onSecondaryContainer` text |
| other rows | `onSurface` text, `onSurface` at 8% on hover and keyboard highlight |
| keyboard highlight border | `outline` |
| edit / delete icons | `onSurfaceVariant` / `error` |
| row spinner | `primary` |
| chips of the multiple box | flat, 32 px high, 8 px corners, `secondaryContainer` with `onSecondaryContainer` label and remove icon, 8 px between them |

Every text pair keeps WCAG AA contrast (4.5:1) on Flutter's default light and
dark schemes and on ones seeded from `darkGreen`. A color you set always wins;
its `custom...` field (e.g. `SimpleSearchbarSettings.customBackgroundColor`)
tells whether one was set, and the getter returns the 8.0.0 value when it was
not. A text style equal to the stock one (`selectedItemTextStyle`,
`unselectedItemTextStyle`) counts as unset.

To keep the 8.0.0 light look, set its colors explicitly:

```dart
/// The 8.0.0 light look, for apps that want it back.
const SimpleSearchbarSettings classicBar = SimpleSearchbarSettings(
  backgroundColor: Colors.white,
  hoverColor: Color.fromRGBO(245, 245, 245, 1),
  boxMultiSelectedBackgroundColor: Color.fromRGBO(224, 224, 224, 1),
  border: RoundedRectangleBorder(
    borderRadius: BorderRadius.all(Radius.circular(10)),
  ),
);

/// The 8.0.0 light rows. A text style equal to the stock one follows the
/// theme, so these add the size the rows are drawn at (14).
const SimpleOverlaySettings classicList = SimpleOverlaySettings(
  selectedItemBackgroundColor: Colors.black38,
  selectedItemHoverColor: Color.fromRGBO(224, 224, 224, 1),
  unselectedItemHoverColor: Color.fromRGBO(245, 245, 245, 1),
  highlightedItemBackgroundColor: Color.fromRGBO(245, 245, 245, 1),
  highlightedItemBorderColor: Colors.black26,
  selectedItemTextStyle: TextStyle(color: Colors.black, fontSize: 14),
  unselectedItemTextStyle: TextStyle(color: Colors.black45, fontSize: 14),
  dialogEditIcon: Icon(Icons.edit, color: Colors.black, size: 20),
  dialogDeleteIcon: Icon(
    Icons.delete,
    color: Color.fromRGBO(183, 28, 28, 1),
    size: 20,
  ),
  loadingColor: darkGreen,
);
```

The 8.0.0 chips (grey cards with a shadow, label and icon in the theme's
text color) are not a setting: draw your own with `boxMultiItemWidgetBuilder`.

The row spinner is the size of the icons it replaces (`loadingSize: 24`,
`loadingStrokeWidth: 2.5`), and the row does not move while it shows.

### Texts and localization

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

The scope also reaches the controllers' dialogs. A text set explicitly in a
settings object (e.g. `SimpleSearchbarSettings.hint`) wins over `strings`.

## Keyboard and accessibility

- Single: the list opens scrolled to the selected item and lists every item
  until you type; the first key typed replaces the selected label. Arrow keys
  move the keyboard highlight (drawn apart from the selection), PageUp/PageDown
  jump to the first/last item and Enter selects the highlighted (or first)
  item; with the selected label untouched Enter keeps the selection. Tab and
  Shift+Tab move on to the next/previous field.
- Multiple: rows, chips and buttons are reached with Tab and activated with
  Enter or Space.
- A disabled dropdown (`enabled: false`) cannot take the focus.
- Buttons, rows, chips and loading indicators carry tooltips and semantics
  labels from `SearchDropDownStrings`; screen readers announce the selected
  row as selected.

## Migrating from 7.x

8.0 is a major release with no deprecation period. The main changes:

- `MultipleSearchDropDown` takes a required `controller:`
  (`MultipleSearchDropDownController`) that holds the items, selection, modes
  and callbacks formerly passed to the widget.
- `SearchDropDownController(listItems:)` became `items:`; controllers copy
  your list and never change it. Replace items with
  `updateListItems(list, shouldReset)`.
- `sortType: int` became `sort: SortType` (`0` → `none`, `1` →
  `alphabetical`, `2` → `reverseAlphabetical`, `3` → `selectedFirst`), and
  `sortList(int)` became `sortBy(SortType)`.
- `GlobalKey` state methods moved to the controllers (`toggleEnabled()`,
  `resetSelection()`, `forceSelection(label)`, `toggle(item)`, ...).
- Misspelled names were fixed: `addAdditionalWidget`,
  `defaultAdditionalWidget`, `additionalWidgetSpacing`.
- New exports (`SortType`, `SearchDropDownStrings`,
  `SearchDropDownStringsScope`, `MultipleSearchDropDownController`) may clash
  with your own names: use `hide` or a prefixed import.

The [CHANGELOG](CHANGELOG.md) has the full replacement table and every
behaviour change.

## Example

The [example app](example/lib/main.dart) shows a single and a multiple
dropdown sharing one list, slow async callbacks, a custom value type with a
custom row, and a dropdown inside a dialog. It follows the system light/dark
setting.

## Contributing and issues

Bug reports and feature requests are welcome on the
[issue tracker](https://github.com/Lorenzobettega/simplesearchdropdown/issues).
Pull requests should keep `flutter analyze` clean and `flutter test` green,
in the package and in `example/`.

If this package saves you time, you can
[buy the authors a coffee](https://buymeacoffee.com/gian.bettega).

## License

[MIT](LICENSE)
