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