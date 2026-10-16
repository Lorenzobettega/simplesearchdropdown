## [8.0.0] - 2026-10-15.
Requires Flutter 3.32+. 7.x code keeps compiling: renamed members are `@Deprecated` (removed in 9.0.0). See "Migrating from 7.x" in the README.

### Added
- `SearchDropDownController` is a `ChangeNotifier`: change selection, items or `enabled` from code and the widget updates, no `GlobalKey` needed (#45).
- `MultipleSearchDropDownController` (exported) and a `controller:` parameter on `MultipleSearchDropDown`.
- `items:` on both controllers: the controller keeps its own copy (`listItems:` still shares your list).
- The single list opens scrolled to the selected item (#46); PageUp/PageDown jump to the first/last item.
- `SearchDropDownStrings` (Portuguese defaults, `.en()`), per widget (`strings:`) or app-wide with `SearchDropDownStringsScope`.
- `SortType` enum (`sort:`), A-Z/Z-A ordering that ignores case, accents and surrounding spaces, whatever `caseSensitive`/`latinize`/`trim` (both dropdowns).
- Multiple dropdown: edit mode works (it was a stub); `latinize`/`caseSensitive`/`trim` apply there too.
- Keyboard highlight is distinct from the selection (`highlightedItemBackgroundColor`, `highlightedItemBorderColor`); tooltips and semantics on buttons, rows, chips and spinners.

### Changed
- Reopening the single dropdown lists every item instead of only the selected one; the text is selected so typing replaces it.
- The clear button follows `SimpleSearchbarSettings.showClearIcon` by default (controller `showClearIcon` is now `bool?`).
- After add/edit/delete callbacks the item list is kept in sync if the callback did not change it.
- `forceSelection` matches the exact label first, then ignoring case/accents (both dropdowns).
- The multiple list is drawn with `OverlayPortal`: it follows parent rebuilds, is removed with the widget and stays below dialogs (confirm/verify dialogs are now regular modal dialogs).
- Settings texts (`hint`, `addItemHint`, `editHint`, dialog button settings) still read as before, but a value you do not set now comes from `SearchDropDownStrings`; `customHint`, `customAddItemHint`, `customEditHint` tell whether one was set explicitly.
- `SearchDropDownController.dispose()` can be called more than once.
- A legacy `MultipleSearchDropDown` keeps its search and pending add/delete across parent rebuilds; new list instances or dialog settings are applied in place.
- `ValueItem.hashCode` is `Object.hash(label, value)`: hash values differ from 7.x (equal items still hash alike).
- Selection callbacks (`updateSelectedItem`, `updateSelectedItems`, `onClearItem`, `onClearList`) triggered during a build run right after that frame, like listeners and `onFilterUpdated` (safe to `setState` in them); outside a build they still run synchronously. They are delivered even if the controller is disposed in that frame; listeners and `onFilterUpdated` are then skipped.
- Items, sort or filter changes made to the single dropdown during a build: `filteredItems`, `selectedIndex`, `highlightedIndex` and Enter (`submit`, `handleEnterKey`) see the new list at once, as in 7.x, while the open list (left stale by 7.x), the `results`/`highlight` listeners and `onFilterUpdated` follow right after that frame.

### Breaking
- `MultipleListView` (exported helper) takes a `MultipleSearchDropDownController`; use `MultipleSearchDropDown` instead of building it directly.
- `SearchDropDownController.showClearIcon` is `bool?` (`null` = follow the search bar settings).
- `MultipleSearchDropDown.listItems`, `selectedItems` and `updateSelectedItems` are nullable (a `controller` can replace them); code reading them from the widget needs `!`.

### Fixed
- Crash when filtering after deleting/editing with a callback that does not change the list, or after the shared list grew from outside (e.g. an item added through the multiple dropdown).
- `updateListItems` with the same list instance emptied it.
- Opening the single list through the arrow did not filter while typing.
- Keyboard highlight could stay on a stale row; rows were marked selected just because the typed text equalled their label; Tab focus was dropped immediately.
- Delete spinner kept spinning after cancelling the confirmation; edit dialog now starts with the current label and only re-selects when the edited item was selected.
- `onFilterUpdated` missed changes with the same length/first/last item, and is never called during a build (safe to `setState` in it).
- Controllers work without an initialized binding (plain `test()`, code before `runApp`), as in 7.x.
- Keyboard highlight is cleared when the list reopens; selecting no longer re-filters the list while it closes; confirming the edit dialog unchanged keeps the item.
- Multiple: deleting an item cleared the whole selection; `resetSelection` did not notify; `forceMultipleSelection` did not rebuild; the arrow cleared instead of opening; `hideOverlay` toggled; sorting reordered the caller's list; the list leaked when the widget was removed; a rejected item stayed in the search field (#13); async callbacks were not awaited.

### Deprecated
- `SearchDropDownState.enableDisable/resetSelection/updateList` and the `MultipleSearchDropDownState` methods → use the controllers.
- `sortType` → `sort`; `addAditionalWidget`/`defaultAditionalWidget`/`aditionalWidgetSpacing` → `*Additional*` (also on `DefaultListTile` and `DefaultAddListItem`).
- `MultipleSearchDropDownState.aberto`/`enabled` setters and `overlayScreen`.

### Performance
- One shared filter engine with a lazy label cache; typing more characters narrows the previous results. Typing "Item 99" over 10,000 items rebuilds 20 rows instead of 63; the bar still does not rebuild while typing.
- Items whose label equals their value (e.g. `ValueItem.fromValue` on `String`) no longer all share one hash, so A-Z/Z-A sorting, filtering and `forceMultipleSelection` stay fast on large lists.
- A list that is already in A-Z/Z-A order is not sorted again when the dropdown opens; the label cache only keeps items still in the list (a `listItems:` list refreshed in place no longer grows it).

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