// import 'package:flutter/material.dart';
// import 'package:simple_search_dropdown/simple_search_dropdown.dart';

// class Simple<T> extends StatelessWidget {
//   const Simple({
//     super.key,
//     required this.listItems,
//     this.addMode = true,
//     this.onAddItem,
//     this.newValueItem,
//     this.editMode = false,
//     this.onEditItem,
//     this.deleteMode = true,
//     this.onDeleteItem,
//     required this.updateSelectedItem,
//     this.sortType = 0,
//     this.confirmDelete = false,
//     this.searchBarSettings = defaultSearchBarSettings,
//     this.overlayListSettings = defaultOverlaySettings,
//     this.selectedItem,
//     this.deleteDialogSettings,
//     this.verifyInputItem,
//     this.verifyDialogSettings,
//     this.addAditionalWidget,
//     this.defaultAditionalWidget,
//     this.enabled = true,
//     required this.controller,
//   });

//   ///List of the items to be presented on the dropdown.
//   final List<ValueItem<T>> listItems;

//   ///Allow the user to add items to the list.
//   final bool addMode;

//   ///Function to be executed after the item was added.
//   final Function(ValueItem<T>)? onAddItem;

//   ///Function that defines how the user input transforms into a new ValueItem on the list.
//   ///
//   ///Ex:`newValueItem: (input) => ValueItem(label: input, value: input)`
//   final ValueItem<T> Function(String input)? newValueItem;

//   ///Allow the user to delete items of the list.
//   final bool deleteMode;

//   ///Function to be executed after the item was deleted.
//   final Function(ValueItem<T>)? onDeleteItem;

//   ///Allow the user to edit items of the list.
//   final bool editMode;

//   ///Function to be executed after the item was edit.
//   final Function(ValueItem<T>)? onEditItem;

//   ///Force the user to confirm delete
//   final bool confirmDelete;

//   ///Visual delete dialog settings
//   final DialogSettings? deleteDialogSettings;

//   ///The SearchBarSettings.
//   final SimpleSearchbarSettings searchBarSettings;

//   ///The settings for the overlay list of items.
//   final SimpleOverlaySettings overlayListSettings;

//   ///Function to check if the item added is valid or not.
//   final bool Function(ValueItem<T>)? verifyInputItem;

//   ///Visual verify dialog settings
//   final DialogSettings? verifyDialogSettings;

//   ///The initial selected value of the dropdown.
//   final ValueItem<T>? selectedItem;

//   ///The function to be executed after the user selects a value.
//   final Function(ValueItem<T>?) updateSelectedItem;

//   ///The way the items should be sorted.
//   ///
//   ///If `0`(default), no sort will be applied
//   ///
//   ///If `1`, the items will be sorted on alphabetical order.
//   ///
//   ///If `2`, the items will be sorted on reverse alphabetical order.
//   ///
//   ///If `3`, the selected item will be put on first position.
//   final int sortType;

//   ///A custom aditional widget to be inserted on the add item cell between the text and the create button.
//   final Widget? addAditionalWidget;

//   ///A custom aditional widget to be inserted on the default item cell between the text and the delete button.
//   final Widget? defaultAditionalWidget;

//   ///A parameter to define if the widget is enabled or disabled (default: `true`).
//   final bool enabled;

//   final SearchController controller;

//   @override
//   Widget build(BuildContext context) {
//     return SearchAnchor.bar(
//       searchController: controller,
//       suggestionsBuilder: (BuildContext context, SearchController controller) {
//         return List<Widget>.generate(5, (int index) {
//           return DefaultListTile<T>(
//             deleteMode: deleteMode,
//             editMode: editMode,
//             item: listItems[index],
//             onDelete: (_) {},
//             onEdit: (_) {},
//             onPressed: (_) {},
//             overlayListSettings: overlayListSettings,
//             selected: controller.value == listItems[index].label,
//             defaultAditionalWidget: defaultAditionalWidget,
//           );
//         });
//       },

//     );
//   }
// }
