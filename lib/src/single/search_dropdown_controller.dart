import 'package:flutter/material.dart';
import 'package:simple_search_dropdown/simple_search_dropdown.dart';
import 'package:stringr/stringr.dart';

/// Controller for [SearchDropDown] that manages the list data, selection, and search text.
class SearchDropDownController<T> {
  SearchDropDownController({
    SearchController? searchController,
    required this.listItems,
    this.addMode = true,
    this.newValueItem,
    this.onAddItem,
    this.editMode = false,
    this.onEditItem,
    this.editDialogSettings,
    this.deleteMode = true,
    this.onDeleteItem,
    this.confirmDelete = false,
    this.deleteDialogSettings,
    this.onClear,
    this.updateSelectedItem,
    this.verifyInputItem,
    this.verifyDialogSettings,
    this.showClearIcon = false,
    ValueItem<T>? initialSelectedItem,
    int sortType = 0,
    this.enabled = true,
    this.onFilterUpdated,
  })  : localSearchController = searchController ?? SearchController(),
        assert(
            (addMode && (newValueItem != null && onAddItem != null)) ||
                !addMode,
            'addMode can only be used with newValueItem != null && onAddItem != null'),
        assert((deleteMode && onDeleteItem != null) || !deleteMode,
            'deleteMode can only be used with onDeleteItem != null'),
        assert((editMode && onEditItem != null) || !editMode,
            'editMode can only be used with onEditItem != null') {
    // Initial state
    _suppressFiltering = true;
    _previousText = '';
    filteredItems = <ValueItem<T>>[];

    // Sort the list if needed
    if (sortType != 0) {
      sortList(sortType);
    }
    // Set initial selection (if provided)
    if (initialSelectedItem != null && listItems.isNotEmpty) {
      selectedItem = initialSelectedItem;
      localSearchController.text = initialSelectedItem.label;
      _previousText = initialSelectedItem.label;
      if (showClearIcon) {
        clearVisible = true;
      }
      // Update the external selection callback for initial value (passing it here is optional).
    }
    // Initialize filtered list to full list
    filteredItems = List<ValueItem<T>>.from(listItems);
    // Listen for text changes to update filtering
    localSearchController.addListener(() {
      if (!_suppressFiltering && localSearchController.text != _previousText) {
        _previousText = localSearchController.text;
        filterList(localSearchController.text);
        onFilterUpdated?.call();
      }
    });
  }

  /// The internal search controller for the SearchAnchor/SearchBar.
  final SearchController localSearchController;

  /// List of all items to be presented in the dropdown.
  final List<ValueItem<T>> listItems;

  /// Allow the user to add new items to the list.
  final bool addMode;

  /// Function to create a new `ValueItem<T>` from user input (required if [addMode] is true).
  final ValueItem<T> Function(String input)? newValueItem;

  /// Function to be executed after a new item is added to the list.
  final Function(ValueItem<T>)? onAddItem;

  /// Allow the user to edit existing items in the list.
  final bool editMode;

  /// Function to be executed after an item is edited. Provides the original item and the new item.
  final Function(ValueItem<T> originalItem, ValueItem<T> newValue)? onEditItem;

  /// Settings for the edit dialog (appearance, text, etc.).
  final DialogSettings? editDialogSettings;

  /// Allow the user to delete items from the list.
  final bool deleteMode;

  /// Function to be executed after an item is deleted.
  final Function(ValueItem<T>)? onDeleteItem;

  /// Whether to require confirmation from the user before deleting an item.
  final bool confirmDelete;

  /// Settings for the delete confirmation dialog.
  final DialogSettings? deleteDialogSettings;

  /// Function to be executed after the selection is cleared.
  final Function()? onClear;

  /// Callback to update the selected item in external state (called whenever an item is selected or cleared).
  final Function(ValueItem<T>?)? updateSelectedItem;

  /// Function to check if a newly added item is valid. Returns `false` to reject the input.
  final bool Function(ValueItem<T>)? verifyInputItem;

  /// Settings for the "invalid input" dialog shown when [verifyInputItem] fails.
  final DialogSettings? verifyDialogSettings;

  /// Whether to show the clear ("X") icon when there is text or a selected value.
  /// This should typically match the `searchBarSettings.showClearIcon` in the widget.
  final bool showClearIcon;

  /// The currently selected item (if any).
  ValueItem<T>? selectedItem;

  /// The current filtered list of items based on the search query.
  late List<ValueItem<T>> filteredItems;

  /// Whether the dropdown is enabled for user interaction.
  bool enabled = true;

  /// Whether the clear button should be visible (true if there's a selection/text and [showClearIcon] is true).
  bool clearVisible = false;

  /// Optional callback triggered when filteredItems is updated.
  final void Function()? onFilterUpdated;

// Internal state for filtering logic:
  String _previousText = '';
  bool _suppressFiltering = true;

  /// Sorts the [listItems] based on the given sort type.
  ///
  /// `sortType`:
  /// - 0 = no sorting,
  /// - 1 = alphabetical,
  /// - 2 = reverse alphabetical,
  /// - 3 = move the selected item (if any) to the first position.
  void sortList(int sortType) {
    switch (sortType) {
      case 0:
        // No sorting
        break;
      case 1:
        listItems.sort((a, b) => a.label.compareTo(b.label));
        break;
      case 2:
        listItems.sort((a, b) => b.label.compareTo(a.label));
        break;
      case 3:
        if (selectedItem != null) {
          final int index = listItems.indexOf(selectedItem!);
          if (index != -1) {
            listItems
              ..removeAt(index)
              ..insert(0, selectedItem!);
          }
        }
        break;
    }
  }

  /// Filters the list items based on the given text query (case-insensitive, ignoring accents).
  void filterList(String text) {
    if (text.isNotEmpty) {
      final String normalizedQuery = text.latinize().toLowerCase();
      filteredItems = listItems
          .where((element) => element.label
              .toLowerCase()
              .latinize()
              .contains(normalizedQuery))
          .toList();
    } else {
      filteredItems = List<ValueItem<T>>.from(listItems);
    }
  }

  /// Resets the selection to its default state (clears the current selection and text).
  void resetSelection() {
    // Clear the search text and selected item
    localSearchController.text = '';
    selectedItem = null;
    // Notify external listener that selection is cleared
    updateSelectedItem?.call(null);
    onClear?.call();
    // Hide the clear button
    clearVisible = false;
  }

  /// Selects the given item from the list. Updates the search text and notifies listeners.
  void selectItem(ValueItem<T> item) {
    // Prevent filtering while selecting to avoid interfering with text change
    _suppressFiltering = true;
    selectedItem = item;
    if (localSearchController.isOpen) {
      // Close the search view and fill the search bar with the selected label
      localSearchController.closeView(item.label);
    } else {
      localSearchController.text = item.label;
    }
    _previousText = localSearchController.text;
    // Notify external selection callback
    updateSelectedItem?.call(item);
    // Show the clear icon if enabled
    if (showClearIcon) {
      clearVisible = true;
    }
    // Re-enable filtering after selection
    _suppressFiltering = false;
  }

  /// Forces the selection of an item by its label, if it exists in the list.
  void forceSelection(String label) {
    final ValueItem<T>? found = listItems.cast<ValueItem<T>?>().firstWhere(
          (element) => element!.label == label,
          orElse: () => null,
        );
    if (found != null) {
      selectItem(found);
    }
  }

  /// Handles adding a new item to the list from the given input text.
  /// Returns a Future that completes after the operation (and any dialog) is handled.
  Future<void> addItem(String text, BuildContext context) async {
    if (addMode && newValueItem != null) {
      final ValueItem<T> item = newValueItem!(text);
      // Verify the new item if a verifier is provided
      if (verifyInputItem != null && !verifyInputItem!(item)) {
        // Show warning dialog if the item is not valid
        await sendDialog(
          context,
          WarningDialog(
            confirmDialog: false,
            returnFunction: (_) {
              if (context.mounted) {
                Navigator.of(context).pop();
              }
            },
            settings: verifyDialogSettings,
          ),
        );
        // Clear the search text and exit (item not added)
        localSearchController.clear();
        return;
      }
      // Add the new item to the filtered list (so it appears in suggestions immediately)
      filteredItems.add(item);
      // Invoke the external callback for item added
      onAddItem?.call(item);
      // Select the new item (this will update text, close the view, etc.)
      selectItem(item);
    }
  }

  /// Handles deleting an item from the list. Shows a confirmation dialog if required.
  Future<void> deleteItem(ValueItem<T> item, BuildContext context) async {
    if (deleteMode) {
      if (confirmDelete) {
        // Ask for delete confirmation
        await sendDialog(
          context,
          WarningDialog(
            returnFunction: (bool result) {
              if (result) {
                // User confirmed deletion
                onDeleteItem?.call(item);
                resetSelection();
              }
              if (context.mounted) {
                Navigator.of(context).pop();
              }
            },
            settings: deleteDialogSettings,
          ),
        );
      } else {
        // Delete without confirmation
        onDeleteItem?.call(item);
        resetSelection();
      }
    }
  }

  /// Handles editing (modifying) an existing item in the list.
  /// Opens an edit dialog and updates the item via the provided callback if confirmed.
  Future<void> editItem(ValueItem<T> item, BuildContext context) async {
    if (editMode && newValueItem != null) {
      await sendDialog(
        context,
        EditDialog(
          label: item.label,
          returnFunction: (bool ok, String newText) {
            if (ok) {
              final ValueItem<T> newValue = newValueItem!(newText);
              onEditItem?.call(item, newValue);
              resetSelection();
            }
            if (context.mounted) {
              Navigator.of(context).pop();
            }
          },
          settings: editDialogSettings,
        ),
      );
    }
  }

  /// Prepares the controller state when the search view is opened.
  /// (Resets the filtered list to show all items and enables filtering.)
  void onSearchOpen() {
    // Reset filtered list to all items
    filteredItems = List<ValueItem<T>>.from(listItems);
    // Allow filtering on text changes
    _suppressFiltering = false;
    // TODO: add scroll to item.
  }

  void onSearchClose(bool clearOnClose) {
    if (clearOnClose && localSearchController.text.isNotEmpty) {
      if (selectedItem != null) {
        // Restore the text to the selected item's label if it was changed during search
        if (localSearchController.text != selectedItem!.label) {
          localSearchController.text = selectedItem!.label;
        }
      } else {
        // No item selected, so clear the text field
        localSearchController.text = '';
      }
    }
    // No need to explicitly set _suppressFiltering here; onSearchOpen will re-enable filtering when reopened
  }

  /// Toggles the enabled/disabled state of the dropdown.
  void toggleEnabled() {
    enabled = !enabled;
    // (UI can read [enabled] to adjust interaction if needed.)
  }

  /// Disposes the internal [SearchController]. Call this if the controller is no longer needed.
  void dispose() {
    localSearchController.dispose();
  }
}
