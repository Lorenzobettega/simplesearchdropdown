import 'dart:collection';

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
        _ownsSearchController = searchController == null,
        assert(
          (addMode && (newValueItem != null && onAddItem != null)) || !addMode,
          'addMode can only be used with newValueItem != null && onAddItem != null',
        ),
        assert(
          (deleteMode && onDeleteItem != null) || !deleteMode,
          'deleteMode can only be used with onDeleteItem != null',
        ),
        assert(
          (editMode && onEditItem != null && newValueItem != null) || !editMode,
          'editMode can only be used with onEditItem != null && newValueItem != null',
        ) {
    _suppressFiltering = true;
    _prevQuery = '';
    _rebuildCaches();
    if (initialSelectedItem != null && listItems.isNotEmpty) {
      selectedItem = initialSelectedItem;
      localSearchController.text = initialSelectedItem.label;
      _prevQuery = initialSelectedItem.label;
      if (showClearIcon) {
        clearVisible = true;
      }
    }
    if (sortType != 0) {
      sortList(sortType);
    }
    _setAll();
    localSearchController.addListener(() {
      if (_suppressFiltering) {
        return;
      }
      final q = localSearchController.text;
      if (q == _prevQuery) {
        return;
      }

      final List<ValueItem<T>> source =
          q.startsWith(_prevQuery) ? _filteredItems : listItems;

      _prevQuery = q;
      _filterFrom(source, q);
    });
  }

  /// The internal search controller for the SearchAnchor/SearchBar.
  final SearchController localSearchController;
  final bool _ownsSearchController;

  /// List of all items to be presented in the dropdown.
  final List<ValueItem<T>> listItems;

  /// Allow the user to add new items to the list.
  final bool addMode;

  /// Function to create a new `ValueItem<T>` from user input (required if [addMode] is true).
  final ValueItem<T> Function(String input)? newValueItem;

  /// Function to be executed after a new item is added to the list.
  final void Function(ValueItem<T>)? onAddItem;

  /// Allow the user to edit existing items in the list.
  final bool editMode;

  /// Function to be executed after an item is edited. Provides the original item and the new item.
  final void Function(ValueItem<T> originalItem, ValueItem<T> newValue)?
      onEditItem;

  /// Settings for the edit dialog (appearance, text, etc.).
  final DialogSettings? editDialogSettings;

  /// Allow the user to delete items from the list.
  final bool deleteMode;

  /// Function to be executed after an item is deleted.
  final void Function(ValueItem<T>)? onDeleteItem;

  /// Whether to require confirmation from the user before deleting an item.
  final bool confirmDelete;

  /// Settings for the delete confirmation dialog.
  final DialogSettings? deleteDialogSettings;

  /// Function to be executed after the selection is cleared.
  final VoidCallback? onClear;

  /// Callback to update the selected item in external state (called whenever an item is selected or cleared).
  final void Function(ValueItem<T>?)? updateSelectedItem;

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
  final List<ValueItem<T>> _filteredItems = <ValueItem<T>>[];
  late final UnmodifiableListView<ValueItem<T>> _filteredView =
      UnmodifiableListView(_filteredItems);
  UnmodifiableListView<ValueItem<T>> get filteredItems => _filteredView;

  /// Whether the dropdown is enabled for user interaction.
  bool enabled = true;

  /// Whether the clear button should be visible (true if there's a selection/text and [showClearIcon] is true).
  bool clearVisible = false;

  /// Optional callback triggered when filteredItems is updated.
  final void Function()? onFilterUpdated;

  // Internal state for filtering logic:
  bool _suppressFiltering = true;

  // Incremental (sem debounce)
  String _prevQuery = '';

  // Cache: normalização por item
  final Map<ValueItem<T>, String> _normLabel = <ValueItem<T>, String>{};
  // Lookup O(1) por label normalizada
  final Map<String, ValueItem<T>> _byLabel = <String, ValueItem<T>>{};
  // Caches pré‑ordenados e sort atual (lazy)
  int _currentSortType = 0;

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
    _currentSortType = sortType;
  }

  /// Filters the list based on the provided [text]. Normalizes accents and case.
  void filterList(String text) {
    if (text.isEmpty) {
      _setAll(); // fast‑path
      return;
    }
    _filterFrom(listItems, text);
  }

  /// Filtro a partir de uma fonte (lista completa ou resultado anterior).
  /// Notifica a UI apenas quando o resultado muda de fato.
  void _filterFrom(List<ValueItem<T>> source, String text) {
    final String q = _normalize(text);

    final int oldLen = _filteredItems.length;
    final ValueItem<T>? oldFirst = oldLen > 0 ? _filteredItems.first : null;
    final ValueItem<T>? oldLast = oldLen > 0 ? _filteredItems.last : null;

    final List<ValueItem<T>> result = <ValueItem<T>>[];
    final Iterable<ValueItem<T>> iterable =
        identical(source, _filteredItems) ? _filteredItems : source;

    for (final e in iterable) {
      if (_normLabel[e]!.contains(q)) {
        result.add(e);
      }
    }

    _filteredItems
      ..clear()
      ..addAll(result);

    final bool changed = _filteredItems.length != oldLen ||
        (oldLen > 0 &&
            (_filteredItems.isEmpty ||
                _filteredItems.first != oldFirst ||
                _filteredItems.last != oldLast));
    if (changed) {
      onFilterUpdated?.call();
    }
  }

  /// Resets the selection to its default state (clears the current selection and text).
  void resetSelection() {
    localSearchController.text = '';
    selectedItem = null;
    updateSelectedItem?.call(null);
    onClear?.call();
    clearVisible = false;
  }

  /// Selects the given item from the list. Updates the search text and notifies listeners.
  void selectItem(ValueItem<T> item) {
    _suppressFiltering = true;
    selectedItem = item;
    if (localSearchController.isOpen) {
      localSearchController.closeView(item.label);
    } else {
      localSearchController.text = item.label;
    }
    updateSelectedItem?.call(item);
    if (showClearIcon) {
      clearVisible = true;
    }
    _suppressFiltering = false;
    _prevQuery = localSearchController.text;
  }

  /// Clears the current selection and search field text, and notifies external callbacks.
  void clearSelectionAndNotify() {
    selectedItem = null;
    localSearchController.clear();
    if (showClearIcon) {
      clearVisible = false;
    }
    onClear?.call();
    updateSelectedItem?.call(null);
    _suppressFiltering = false;
    _prevQuery = '';
  }

  /// Clears the current selection and search field text without notifying external callbacks.
  void clearSelection() {
    selectedItem = null;
    localSearchController.clear();
    if (showClearIcon) {
      clearVisible = false;
    }
    _suppressFiltering = false;
    _prevQuery = '';
  }

  /// Forces the selection of an item by its label, if it exists in the list.
  void forceSelection(String label) {
    final item = _byLabel[_normalize(label)];
    if (item != null) {
      selectItem(item);
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
        localSearchController.clear();
        return;
      }
      _filteredItems.add(item);

      // Atualiza caches locais (fonte real é externa)
      _normLabel[item] = _normalize(item.label);
      _byLabel[_normLabel[item]!] = item;

      onAddItem?.call(item);
      selectItem(item);
    }
  }

  /// Handles deleting an item from the list. Shows a confirmation dialog if required.
  Future<void> deleteItem(ValueItem<T> item, BuildContext context) async {
    if (deleteMode) {
      if (confirmDelete) {
        await sendDialog(
          context,
          WarningDialog(
            returnFunction: (bool result) {
              if (result) {
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

              // Caches locais coerentes para a sessão
              final oldKey = _normLabel[item];
              if (oldKey != null && _byLabel[oldKey] == item) {
                _byLabel.remove(oldKey);
              }
              _normLabel.remove(item);
              _normLabel[newValue] = _normalize(newValue.label);
              _byLabel[_normLabel[newValue]!] = newValue;
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
    _suppressFiltering = false;
    filterList(localSearchController.text);
    // TODO: add scroll to item.
  }

  void onSearchClose(bool clearOnClose) {
    if (clearOnClose && localSearchController.text.isNotEmpty) {
      if (selectedItem != null) {
        if (localSearchController.text != selectedItem!.label) {
          localSearchController.text = selectedItem!.label;
        }
      } else {
        localSearchController.text = '';
      }
    }
  }

  /// Toggles the enabled/disabled state of the dropdown.
  void toggleEnabled() {
    enabled = !enabled;
  }

  /// Disposes the internal [SearchController]. Call this if the controller is no longer needed.
  void dispose() {
    if (_ownsSearchController) {
      localSearchController.dispose();
    }
  }

  // ===================== helpers de performance =====================

  String _normalize(String s) => s.latinize().toLowerCase();

  void _rebuildCaches() {
    _normLabel.clear();
    _byLabel.clear();
    for (var i = 0; i < listItems.length; i++) {
      final e = listItems[i];
      final n = _normalize(e.label);
      _normLabel[e] = n;
      _byLabel[n] = e;
    }
  }

  void _setAll() {
    _filteredItems.clear();
    if (_currentSortType == 1) {
      _filteredItems.addAll(List<ValueItem<T>>.from(listItems)
        ..sort((a, b) => a.label.compareTo(b.label)));
    } else if (_currentSortType == 2) {
      _filteredItems.addAll(List<ValueItem<T>>.from(listItems)
        ..sort((a, b) => b.label.compareTo(a.label)));
    } else {
      _filteredItems.addAll(listItems);
    }
  }
}