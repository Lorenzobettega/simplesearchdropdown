## [8.0.1] - 2026-10-21.
### Fixed
- Dialog buttons (edit, delete confirmation, invalid-item warning) sit on one row of equal-width buttons 48 high with radius 12, 12 apart, at any phone width; at 390 px they no longer wrap to two rows. The default `DialogButtonSettings` no longer have a fixed `customWidth: 160` (an explicit `customWidth` is still honoured, and `actionsAlignment` places such buttons).
- Editar and OK were white text on no background (invisible): they are now filled `darkGreen` (white text, 11.6:1). Apagar stays red (6.2:1). Cancelar is outlined in the theme's `outline` with `onSurface` text, so it follows light and dark themes.
- The edit dialog no longer shows the label twice: the label line above the field is gone; the field (a themed outlined `TextField`, full content width) starts with the label selected and focused, and Enter confirms. Its title is `Editar item` (`Edit item`), without the colon, and the field label is no longer repeated as its hint.
- Dialog titles are semibold 20 (`titleLarge`) and the supporting text `bodyMedium` in `onSurfaceVariant`, centred alike in the three dialogs, which share one layout.
- A row's edit/delete buttons (and the add row's Criar) are hidden behind the spinner instead of removed while a callback runs, so the label and the row no longer move sideways.
- Dark theme: the bar, the multiple box, the list and its rows kept light surfaces (white, grey, black icons, a light-grey hint on white) under a dark theme. A color left unset in `SimpleSearchbarSettings` / `SimpleOverlaySettings` now follows the theme: under a light theme it keeps its 8.0.0 value (the light goldens are unchanged), under a dark one it comes from the `ColorScheme` (`surfaceContainerHigh` surfaces, `onSurfaceVariant` hint and rows, `secondaryContainer` selected row and chips, `outline` highlight border, `error` delete icon, `primary` spinner), with every text pair at WCAG AA (4.5:1) or better. A color you set still wins.
- The row spinner was a 28 px ring with a 4 px stroke, bigger than the 20 px icons it replaces: it is now 24 px with a 2.5 stroke (`loadingSize`, new `loadingStrokeWidth`).

### Added
- The delete confirmation names the item: `Apagar item?` and `“label” será apagado.` above `Essa ação não poderá ser desfeita.` New `SearchDropDownStrings.confirmDeleteItemTitle` and `confirmDeleteItemContent` (`{item}` is replaced by the label, in bold), `DialogSettings.showItemLabel` (default `true`; `false` keeps the generic `Tem certeza?` dialog), and `itemLabel` on `WarningDialog`, `DefaultDialogTitle` and `DefaultDialogContent`; both controllers pass the label. If you customise `confirmDeleteTitle`, set `confirmDeleteItemTitle` too (or `showItemLabel: false`).
- `DialogButtonSettings.useThemeColors`: label in the theme's `onSurface` and border in its `outline` instead of `textColor` (used by the default cancel button).
- `custom...` fields that tell whether a color was set (`null` follows the theme): `SimpleSearchbarSettings.customBackgroundColor`, `customHoverColor`, `customBoxMultiSelectedBackgroundColor`; `SimpleOverlaySettings.customSelectedItemBackgroundColor`, `customSelectedItemHoverColor`, `customUnselectedItemHoverColor`, `customHighlightedItemBorderColor`, `customDialogDeleteIcon`, `customDialogEditIcon`, `customLoadingColor`. The constructor parameters of those colors are now nullable; the getters keep their types and light values, so existing code compiles unchanged.
- `SimpleOverlaySettings.loadingStrokeWidth` (default `2.5`) and `Loading.strokeWidth` (default: the indicator's own).
- The example app follows the system dark mode.

### Performance
Single dropdown (no behaviour change; counts from `test/single/rebuild_counts_test.dart`):
- A selection no longer rebuilds the bar (1 → 0 bar builds): the bar's clear button follows the controller on its own, and the bar rebuilds only when `enabled` changes.
- A row rebuilds only when its selected or highlighted state flips: a selection or an arrow key rebuilds at most 2 rows instead of every visible row.
- A closing view keeps the rows (and the add row) it showed: a re-filter on close (`clearOnClose`) no longer rebuilds them or jumps to the full list while it fades out (0 row builds instead of every visible row). `filteredItems` and `onFilterUpdated` are unchanged, and the next open still lists every item scrolled to the selection.
- The view's close arrow no longer writes the same text back into the field (1 → 0 text notifications).
- Selecting the item that is already selected no longer notifies the controller's listeners (1 → 0); `updateSelectedItem` is still called and the view still closes.
- `updateListItems` with a selection (or `shouldReset`) notifies once instead of twice and filters once; `updateSelectedItem(null)` is still called once.
- Both controllers send one notification per frame for any number of changes made during a build (was one per change).
- Opening the view no longer rebuilds (and re-sorts) the item list when it has not changed.

## [8.0.0] - 2026-10-15.
Requires Flutter 3.32+. A major release with no deprecation period: the 7.x members below are gone. Replace each one as the table shows (the same table is in the README, "Migrating from 7.x").

### Breaking
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

- New exported names `SortType`, `SearchDropDownStrings`, `SearchDropDownStringsScope` and `MultipleSearchDropDownController` clash (`ambiguous_import`) with a type of the same name that your file imports from elsewhere: `import 'package:simple_search_dropdown/simple_search_dropdown.dart' hide SortType;` (or the clashing name), or use a prefixed import.

### Added
- `SearchDropDownController` is a `ChangeNotifier`: change selection, items or `enabled` from code and the widget updates, no `GlobalKey` needed (#45).
- `MultipleSearchDropDownController` (exported), a `ChangeNotifier` holding the multiple dropdown's items, selection, modes and callbacks, with `toggle`, `forceSelection`, `forceMultipleSelection`, `resetSelection`, `clear`, `addValue`, `deleteItem`, `editItem` and `updateListItems(list, shouldReset)` (selected items no longer in the list leave the selection).
- The single list opens scrolled to the selected item (#46), on every reopening, until you type a search, whose results then list from the top; PageUp/PageDown jump to the first/last item.
- `SearchDropDownController.ownsSearchController`: whether the controller created its own `SearchController`.
- `SearchDropDownStrings` (Portuguese defaults, `.en()`), per widget (`strings:`) or app-wide with `SearchDropDownStringsScope`, which also reaches the controllers' `addItem`/`addValue`/`editItem`/`deleteItem` dialogs and the exported dialogs and rows when they get no `strings:`.
- `SortType` enum (`sort:`): A-Z/Z-A ordering ignores case, accents and surrounding spaces, whatever `caseSensitive`/`latinize`/`trim` (both dropdowns); digits still compare as text, as in 7.x (`Item 10` before `Item 2`).
- Multiple dropdown: edit mode works (it was a stub); `latinize`/`caseSensitive`/`trim` apply there too (`trim: false` keeps the 7.x multiple matching: `' ana'` finds `Maria Ana`, not `Mariana`).
- `MultipleSearchDropDownController.addMode`, `deleteMode`, `editMode`, `confirmDelete` and `sort` can be changed after creation (`sort` reorders the results, never `items`).
- Keyboard highlight is distinct from the selection (`highlightedItemBackgroundColor`, `highlightedItemBorderColor`); tooltips and semantics on buttons, rows, chips and spinners.

### Changed
- Reopening the single dropdown lists every item instead of only the selected one; the text is selected so typing replaces it. Until you edit it the label is not a search: Enter keeps the selection.
- Assigning `SearchDropDownController.selectedItem` shows the new label in the bar and updates the clear button (an open list stays open and lists every item); `null` clears the text only while it still shows the old label. It still does not call `updateSelectedItem` (7.x left the bar text stale).
- The clear button follows `SimpleSearchbarSettings.showClearIcon` by default: controller `showClearIcon` defaults to `true` (7.x: `false`).
- `forceSelection` matches the exact label first, then with the controller's `latinize`/`caseSensitive`/`trim` settings (default: ignoring case and accents) (both dropdowns).
- The multiple list is drawn with `OverlayPortal`: it follows parent rebuilds, is removed with the widget and stays below dialogs (confirm/verify dialogs are now regular modal dialogs).
- Settings texts (`hint`, `addItemHint`, `editHint`, dialog button settings) still read as before, but a value you do not set now comes from `SearchDropDownStrings`; `customHint`, `customAddItemHint`, `customEditHint` tell whether one was set explicitly.
- `SearchDropDownController.dispose()` can be called more than once.
- `SearchDropDown(disposeController: true)` (default) disposes the whole controller when the widget is removed, but only when the controller created its own `SearchController` (7.x disposed just that `SearchController`); a controller built with `searchController:` is left to you and can be mounted again. `MultipleSearchDropDown` never disposes its controller: dispose it in your `State.dispose`.
- An error thrown by `onAddItem`, `onEditItem` or `onDeleteItem` started from a list row is reported with `FlutterError.reportError` (library `simple_search_dropdown`, so crash reporters see it) instead of escaping as an uncaught error (7.x silently dropped delete errors); the item stays as it was and the row's button comes back. Awaiting the controller's `addItem`/`editItem`/`deleteItem` yourself still gets the error.
- Confirming the edit dialog with the label unchanged does nothing: `onEditItem` is not called and the original item stays in the list and the selection (7.x single called `onEditItem`).
- Multiple: `enabled = false` closes an open list, and the dimmed box, its chips and the clear button no longer take keyboard focus (7.x only blocked the pointer; Tab + Enter still opened it). Changes made from code still apply while disabled.
- Multiple: while an async `onAddItem` runs the search field keeps the typed text, matching the filter and the add row, and it clears when the add is done (7.x cleared it at once, as the callback was not awaited); a failing callback leaves both as they were.
- Multiple: deleting an item deselects only that item (7.x cleared the whole selection).
- Multiple: deleting a selected item calls `updateSelectedItems` once with the remaining selection (7.x did not call it); `onClearItem` is not called, as a delete is not a deselection.
- Multiple: `resetSelection` notifies listeners and calls `updateSelectedItems` once with the empty selection (7.x did neither); it does not call `onClearList` (use `clear` for that).
- `ValueItem.hashCode` is `Object.hash(label, value)`: hash values differ from 7.x (equal items still hash alike).
- Selection callbacks (`updateSelectedItem`, `updateSelectedItems`, `onClearItem`, `onClearList`) triggered during a build run right after that frame, like listeners and `onFilterUpdated` (safe to `setState` in them); outside a build they still run synchronously. They are delivered even if the controller is disposed in that frame; listeners and `onFilterUpdated` are then skipped.
- Items, sort or filter changes made to the single dropdown during a build: `filteredItems`, `selectedIndex`, `highlightedIndex` and Enter (`submit`, `handleEnterKey`) see the new list at once, as in 7.x, while the open list (left stale by 7.x), the `results`/`highlight` listeners and `onFilterUpdated` follow right after that frame, coalesced into one notification per frame (7.x called `onFilterUpdated` once per change).
- Single keyboard and focus: Tab/Shift+Tab move past the bar to the next field (with `removeFocus: false` 7.x cycled inside the bar); Enter or the keyboard's done key on the focused closed bar does nothing (7.x with `removeFocus: false` selected the first item); a disabled dropdown cannot take the focus and drops it when disabled.
- The example app uses the 8.0 API: controllers owned by the page, `sort: SortType.*`, controller methods instead of `GlobalKey`s, and one app-owned list kept in step between the dropdowns with their callbacks and `updateListItems`.

### Fixed
- Filtering after a delete or edit could crash (7.x, when the callback left the list unchanged).
- `updateListItems` with the same list instance emptied it.
- Multiple: `updateListItems(controller.items, …)` emptied the list (`items` is a view of the controller's own list).
- A CRUD callback that refreshed its own controller with `updateListItems` got the change applied twice: add appended a duplicate (and selected the app's instance instead of the server copy), edit brought back an item the new list had dropped. The controller now keeps the list the callback applied: add selects the matching item from it (equal, else same label) and appends nothing, edit selects the edited item from it and replaces the old one only while the list still holds it, delete leaves it as it is.
- Opening the single list through the arrow did not filter while typing.
- `SimpleSearchbarSettings.showClearIcon: false` hid the single clear button only in the bar; the open list showed it anyway.
- Keyboard highlight could stay on a stale row; rows were marked selected just because the typed text equalled their label; Tab focus was dropped immediately.
- Delete spinner kept spinning after cancelling the confirmation; the edit dialog now starts with the current label and only re-selects when the edited item was selected (also a row matched by label, e.g. values without `==`), keeping the list open as in 7.x.
- `onFilterUpdated` missed changes with the same length/first/last item, and is never called during a build (safe to `setState` in it).
- Keyboard highlight is cleared when the list reopens; selecting no longer re-filters the list while it closes.
- Multiple: an item rejected by `verifyInputItem` stayed in the search field; now it is never listed and the search is cleared (#13).
- Multiple: `forceMultipleSelection` did not rebuild; the arrow cleared instead of opening; `hideOverlay` toggled; the list leaked when the widget was removed; async callbacks were not awaited.
- Multiple: typing key by key froze the add row on the first text that matched nothing (it created that truncated item), and an empty list never offered the add row; `selectedFirst` did not re-pin after `resetSelection`, `clear` or `forceMultipleSelection`.
- Single: Enter or the keyboard's done action right after reopening with a selection selected the first item instead of keeping the selection, and typing the selected label again did not filter.
- Single: with duplicate labels every row with the selected label was marked selected; now only the row `==` to the selection is (the label still matches values without `==`).
- The confirm-delete, invalid-item and edit dialogs close their own route: under a nested navigator (go_router `ShellRoute`, `CupertinoTabView`) they popped the page behind them and stayed open, and a dialog opened from a row that left the list never closed.
- Single: several keys typed within one frame into a focused closed bar (e.g. a barcode scanner) opened stacked lists that stopped filtering and did not close on selection. Guarded on the controller's own `SearchController`; one you pass as `searchController` is used as is.
- Single: Enter on a Tab-focused row or button of the open list also selected the highlighted or first item; arrows, PageUp/PageDown and Enter drive the list only from its search field (or with no control focused).
- Single: arrows and PageUp/PageDown dropped the selection of the selected label, so typing appended to it instead of replacing it.
- A row's delete/edit spinner no longer moves to another item when the results change while the callback is pending (both dropdowns).
- Multiple: changing a mode flag or `sort` while an add/edit/delete was pending left the open list and the chips stale (the item could be offered again); the search field disagreed with the filter after a failed add or an `addValue` from code; swapping `controller:` while the list was open showed every item under the typed text.
- Single: the dropdown no longer uses a disposed `SearchController` (#49): an add/edit/delete (or a rejected-item warning) that finishes after you dispose the `SearchController` you passed still updates the items and selection but leaves the text alone; swapping `controller:` while the list is open closes that list at once (its search field kept editing the old controller's `SearchController` and filtering the old controller), and the old controller is told it closed; removing the dropdown with the list open tells its controller too (`clearOnClose` applies). Pass your own `SearchController` and you own it: dispose it after the dropdown controller, or together.
- Single: `SearchController` text written during a build (`selectedItem =` in an `initState`, or a controller created there with `searchController:` and `initialSelectedItem:`) waits for the end of that frame, together with the notification, so a field of a bar being replaced in that build is never told (#52: "Cannot get renderObject of inactive element"); `selectedItem` reads the new value at once.
- Rows: screen readers announce the selected row as selected (the flag sat on an unlabelled node); the keyboard highlight border also shows on the selected row; a highlighted row keeps your `selectedItemBackgroundColor` once you customise `selectedItemTextStyle` or `unselectedItemHoverColor` (dark palettes drew light text on the light hover fill), as in 7.x. Set `highlightedItemBackgroundColor` for a distinct fill.

### Performance
- One shared filter engine with a lazy label cache; typing more characters narrows the previous results. Typing "Item 99" over 10,000 items rebuilds 20 rows instead of 63; the bar still does not rebuild while typing.
- Items whose label equals their value (e.g. `ValueItem.fromValue` on `String`) no longer all share one hash, so A-Z/Z-A sorting, filtering and `forceMultipleSelection` stay fast on large lists.
- A list that is already in A-Z/Z-A order is not sorted again when the dropdown opens; the label cache only keeps items still in the list.

## [7.8.0] - 2026-04-03.
- Added `caseSensitive` parameter to the controller. It defines if the search should be case sensitive (default: `false`).
- Added `trim` parameter to the controller. It defines if leading and trailing whitespaces should be ignored when filtering the text (default: `true`).
- Updated stringr to 1.2.2

## [7.7.3] - 2026-02-21.
- Fix `updateListItems` function on simple search.
- Added sample on how to reset a custom list.

## [7.7.2] - 2026-02-17.
- Fix hide clear on both Multiple and simple search. 

## [7.7.1] - 2026-02-03.
- Hide dropdown arrow by default if disabled. 

## [7.7.0] - 2026-02-02.
- Added also the loading widget to the delete button on the list cell. 
- Removed `onClear` function from SimpleSearch controller. You can get the similar result by using `updateSelectedItem`.

## [7.6.0] - 2026-01-27.
- Added a loading widget to the list cell. 
- Added `loadingColor` and `loadingSize` parameters to `SimpleOverlaySettings`.

## [7.5.0] - 2026-01-19.
- Added `latinize` parameter to the controller. It defines if latin characters should be ignored when filtering the text (default: `true`).
- `onAddItem`, `onEditItem`, `onDeleteItem` can now be async functions.

## [7.4.1] - 2025-12-24.
- Updated `stringr` version.
- Mini change on `SimpleSearchbarSettings.border`.

## [7.4.0] - 2025-12-10.
- Added fromValue method to `ValueItem`.
- Added arrows control to SimpleSearch widget.

## [7.3.0] - 2025-12-05.
- Added the possibility to select the first item of the list after the user presses enter.
- Mini fix on the sample app.

## [7.2.1] - 2025-11-08.
- Added `forceMultipleSelection` function to MultipleSearch widget.

## [7.2.0] - 2025-10-13.
- Added `updateList` function to SimpleSearch widget.

## [7.1.0] - 2025-08-23.
- Performance improvements.
- Added tests to the package.
- Updated flutter_lints to 6.0.0

## [7.0.3] - 2025-05-22.
- Mini performance improvements.

## [7.0.2] - 2025-05-21.
- Check if context is mounted. Maybe will fix [52](https://github.com/Lorenzobettega/simplesearchdropdown/issues/52) 

## [7.0.1] - 2025-05-21.
- Fixed regression [18](https://github.com/Lorenzobettega/simplesearchdropdown/issues/18)

## [7.0.0] - 2025-05-21.
- Updated android sample.
- [Breaking] Remade `SearchDropDown` to use a controller
- Fixed enabled state of `SearchDropDown`
- This version requires flutter 3.32 to work.

## [6.3.0] - 2025-03-13.
-   Added `removeFocus` to `SearchDropDown`, it defines if the focus from the text field will be removed after the searchanchor is closed (default: `true`).

## [6.2.0] - 2025-03-03.
-   Added `disposeController` to `SearchDropDown`, it defines if the searchController will be disposed after the widget is disposed (default: `true`). If set to true, you should remove `searchController.dispose()` from your controller/widget code.

## [6.1.2] - 2025-02-01.
-   Add ios to sample.

## [6.1.1] - 2025-01-31.
-   Minor code improvements.

## [6.1.0] - 2025-01-31.
-   Add the necessity to pass the controller to the widget instead of creating it on the dropdown. Attempt to fix [41](https://github.com/Lorenzobettega/simplesearchdropdown/issues/41)

## [6.0.0] - 2024-12-25.
- [Breaking] Complete remake of `SearchDropDown` (still missing multiple search). Please report any issues/regressions.
- Added edit function to `SearchDropDown`.
- Added the possibility to block keyboard from appearing with `searchBarSettings.showKeyboardOnTap`.

## [5.3.0] - 2024-12-16.
- Fixed deprecation warning from flutter 3.27.
- Lowered dart constraint to 3.0.

## [5.2.1] - 2024-11-05.
-  Added `searchBarPadding` parameter to allow changing the internal padding of the single searchBar.
- Mini fix to search bar actions spacing.

## [5.2.0] - 2024-10-12.
-  Added missing docs.
-  Bumped flutter_lints to 5.0.0
-  Added `showClearIcon` parameter to single selection. It alows you to hide the searchbar clear Icon.

## [5.1.0] - 2024-08-11.
-  Added `showArrow` parameter to multiple and single selection. It alows you to hide the searchbar arrow.
-  Fixed clear button visibility.

## [5.0.1] - 2024-07-15.
-  Fixed latin characters search.

## [5.0.0] - 2024-05-18.
-  Now it is possible to enable/disable the search bar.
-  [Breaking] `enabled` property requires flutter 3.22.
-  Updated web sample.

## [4.4.1] - 2024-03-21.
-  Fixed deleting items in single search.

## [4.4.0] - 2024-02-28.
-   Added `addAditionalWidget` parameter to multiple and single selection. It alows you to put a widget between the text and the create button on the add item cell.
-   Added `defaultAditionalWidget` parameter to multiple and single selection. It alows you to put a widget between the text and the delete button on the default item cell.
-   Added `overlayListSettings.aditionalWidgetSpacing` to change the distance between the `defaultAditionalWidget` and the delete button on the default item cell.

## [4.3.0] - 2024-02-16.
-   Added `forceSelection()` function to multiple and single selection. It alows you to force the selected value from outside the widget. Nothing happens if there isn't a value with that label on the list. 
-   Fixed list refresh when item is deleted without a confirmation dialog.

## [4.2.0] - 2024-02-16.
-   Added `overlayListSettings.offsetWidth` and `.offsetHeight` to change the distance between the dropdown and the list of items.
-   Bumped flutter_lints to 3.0.1

## [4.1.1] - 2023-12-12.
-   Make searchbar lose focus after closing the overlay.[35] (https://github.com/Lorenzobettega/simplesearchdropdown/issues/35)

## [4.1.0] - 2023-12-10.
-   Fixed TextOverflow inside the list and on create item.
-   Fixed Single warning.
-   Fixed ScrollController that was bug the first item selection
-   Added `overlayListSettings.reOpenedScrollDuration ` parameter. It allows you to define the Duration of scroll down to selected item when list are reopened. Defaults to 1 second.

## [4.0.3] - 2023-12-04.
-   Added `searchBarSettings.searchBarTextStyle` parameter. It allows you to define the style of the text the user typed on the searchbar. Defaults to `searchBarSettings.hintStyle`.
- Fix readme.

## [4.0.2] - 2023-12-04.
-   Fixed `MultipleSearchDropDown` selection.
-   Fixed `SearchDropDown` ordering.

## [4.0.0] - 2023-12-01.
-   [Breaking] many visual parameters are now inside `SimpleOverlaySettings` and `SimpleSearchbarSettings`. Some of them received a new name to better represent what they do. 
- `onDeleteItem` and `onAddItem` are not required anymore. 
- Added `sortType` parameter to allow defining how the list of items should be sorted. 
- The drop list now scrolls to the selected item (if there is one). 
- Improved code documentation: many files and variables now have a text explaining a little more about them. Still some are missing and will be added on the future.
- Code cleanup and organization.
- Improved sample.
- Improved consistency between single and multiple search dropdowns.

## [3.1.1] - 2023-10-19.
-   Fixed a issue where an incomplete selection in `SearchDropDown` after a search, passed the impression that the selected value changed + added `clearOnClose` parameter to `SearchDropDown`. If it's true or `addMode` = `false`, after the user closes the overlay without selecting an option and nothing was previously selected, the textfield will be cleared.  [18](https://github.com/Lorenzobettega/simplesearchdropdown/issues/18)
-   Fixed an older incorrect implementation of `SearchDropDown`.

## [3.0.0] - 2023-10-12.
-   Made `addMode` and `deleteMode` true by default.
-   [Breaking] Added new parameter `newValueItem` to define how the text on the input transforms to a `ValueItem` of type `T`.
-   [Breaking] `ValueItem` now has a type.
-   Improved sample to show the usage with custom classes.

## [2.3.0] - 2023-10-12.
-   Added `verifyInputItem` property to single and multiple search widgets. It allows the dev to check if the item added is valid based on some rule.
-   Added `verifyDialogSettings` property to allow customizing the dialog that pops up after the user inserts some invalid value. To change the button on the dialog, use the `customVerifyButtonSettings` property. 

## [2.2.1] - 2023-10-10.
-   Mini fix in single search widget if the list is empty.

## [2.2.0] - 2023-10-06.
-   Fixed a issue where the dropdown didn't follow the textfield when the keyboard is open. [5](https://github.com/Lorenzobettega/simplesearchdropdown/issues/5)
-   Mini visual improvements.

## [2.0.0] - 2023-10-04.
-   Added `confirmDelete` property to single and multiple search widgets. It allows the dev to confirm the action before deleting the row. 
-   Added `deleteDialogSettings` property to allow customizing the delete confirmation dialog. 
-   Remake of the overlay handling system to improve the code. 
-   (breaking) Renamed `clearSelection` to `resetSelection`.
-   Fixed typo in single search `listItems` property.

## [1.8.2] - 2023-09-16.
-   Added `miniBoxIconColor` property to multiple search widget. It allows the dev to set inside mini boxes icons color. 
-   Added `padding` property to single and multiple search widgets. It allows the dev to set inside drop items padding. 
-   Added `separatorHeight` property to single and multiple search widgets. It allows the dev to set a size between to items inside the drop. 

## [1.8.1] - 2023-08-27.
-   Added `outsideIconColor` property to single and multiple search widgets. It allows the dev to set a color to the dropdown arrow. 
-   Added `outsideIconSize` property to single search widget. It allows the dev to set a size to the dropdown arrow. 

## [1.8.0] - 2023-08-27.
-   Added `selectedItem` property to single search widget. It allows the dev to set an initial value to the dropdown. 

## [1.7.0] - 2023-08-27.
-   Added `clearSelection()` function on multiple and single search widgets. It allows the dev to reset the dropdown to the initial state.
-   Improved sample.
-   Improved readme.

## [1.6.0] - 2023-08-27.
-   Made `onAddItem` parameter a `required` one.
-   Mini fix on searchbar Height

## [1.5.0] - 2023-08-03.
-   Convert `List<String>` to `List<ValueItem>`, allowing the devs to have anything as an object on the dropdown.

## [1.0.5] - 2023-08-02.
-   Fix clearing single search via outside button
-   Visual fixes

## [1.0.1] - 2023-07-27.
-   Fix multiple elevation
-   Option Action Icon

## [1.0.0] - 2023-07-26.
-   First release.