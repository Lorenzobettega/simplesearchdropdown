## [7.7.0] - 2026-01-27.
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