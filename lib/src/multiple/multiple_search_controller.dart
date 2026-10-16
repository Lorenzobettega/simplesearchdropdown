import 'dart:collection';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:simple_search_dropdown/simple_search_dropdown.dart';
import 'package:simple_search_dropdown/src/core/filter_engine.dart';
import 'package:simple_search_dropdown/src/core/run_outside_build.dart';

/// State of a [MultipleSearchDropDown]: items, selected items, search text and
/// filtering. Changes notify listeners, so the widget updates without a
/// `GlobalKey`.
///
/// Items come from [listItems] (your list, shared by reference) or `items`
/// (copied once). [selectedItems] is your list when passed (it is updated in
/// place, as in 7.x) or a list owned by the controller.
class MultipleSearchDropDownController<T> extends ChangeNotifier {
  /// Creates a controller. Pass exactly one of [listItems] or `items`.
  MultipleSearchDropDownController({
    List<ValueItem<T>>? listItems,
    List<ValueItem<T>>? items,
    List<ValueItem<T>>? selectedItems,
    this.updateSelectedItems,
    this.addMode = true,
    this.newValueItem,
    this.onAddItem,
    this.deleteMode = true,
    this.onDeleteItem,
    this.editMode = false,
    this.onEditItem,
    this.editDialogSettings,
    this.onClearItem,
    this.onClearList,
    this.confirmDelete = false,
    this.deleteDialogSettings,
    this.verifyInputItem,
    this.verifyDialogSettings,
    SortType sort = SortType.none,
    bool enabled = true,
    this.onFilterUpdated,
    bool latinize = true,
    bool caseSensitive = false,
    bool trim = true,
  }) : assert(
         (listItems == null) != (items == null),
         'Pass exactly one of listItems or items',
       ),
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
       ),
       _listItems = listItems ?? List<ValueItem<T>>.of(items ?? const []),
       _selectedItems = selectedItems ?? <ValueItem<T>>[],
       _sort = sort,
       _enabled = enabled,
       _engine = FilterEngine<T>(
         normalization: SearchNormalization(
           latinize: latinize,
           caseSensitive: caseSensitive,
           trim: trim,
         ),
       ) {
    _rebuildBase();
    _filtered.addAll(_base);
  }

  List<ValueItem<T>> _listItems;
  List<ValueItem<T>> _selectedItems;

  /// The items shown by the dropdown.
  List<ValueItem<T>> get listItems => _listItems;

  /// The selected items, in selection order. Updated in place.
  List<ValueItem<T>> get selectedItems => _selectedItems;

  /// Points the controller at other lists (shared by reference), keeping the
  /// search and enabled state. Used by [MultipleSearchDropDown] when its 7.x
  /// `listItems`/`selectedItems` parameters change.
  void replaceSources({
    List<ValueItem<T>>? listItems,
    List<ValueItem<T>>? selectedItems,
  }) {
    final bool changed =
        (listItems != null && !identical(listItems, _listItems)) ||
        (selectedItems != null && !identical(selectedItems, _selectedItems));
    if (!changed) {
      return;
    }
    _listItems = listItems ?? _listItems;
    _selectedItems = selectedItems ?? _selectedItems;
    _engine.clearCache();
    _rebuildBase();
    _applyFilter();
    _notify();
  }

  /// Called with [selectedItems] whenever the user changes the selection.
  final void Function(List<ValueItem<T>>)? updateSelectedItems;

  /// Allow the user to add new items.
  final bool addMode;

  /// Creates a `ValueItem<T>` from user input.
  final ValueItem<T> Function(String input)? newValueItem;

  /// Called (and awaited) after the user creates an item.
  final Function(ValueItem<T>)? onAddItem;

  /// Allow the user to delete items.
  final bool deleteMode;

  /// Called (and awaited) after the user deletes an item.
  final Function(ValueItem<T>)? onDeleteItem;

  /// Allow the user to edit items.
  final bool editMode;

  /// Called (and awaited) after the user edits `originalItem` into `newValue`.
  final Function(ValueItem<T> originalItem, ValueItem<T> newValue)? onEditItem;

  /// Settings of the edit dialog.
  DialogSettings? editDialogSettings;

  /// Called when the user deselects an item.
  final Function(ValueItem<T>)? onClearItem;

  /// Called when the user clears the whole selection.
  final Function()? onClearList;

  /// Ask for confirmation before deleting.
  final bool confirmDelete;

  /// Settings of the delete confirmation dialog.
  DialogSettings? deleteDialogSettings;

  /// Return `false` to reject an item the user is about to create.
  final bool Function(ValueItem<T>)? verifyInputItem;

  /// Settings of the dialog shown when [verifyInputItem] rejects an item.
  DialogSettings? verifyDialogSettings;

  /// Called when [filteredItems] changes.
  final void Function()? onFilterUpdated;

  final FilterEngine<T> _engine;
  final SortType _sort;
  bool _disposed = false;

  /// How items are ordered. [SortType.selectedFirst] moves the first
  /// selected item to the top.
  SortType get sort => _sort;

  bool _enabled;

  /// Whether the dropdown accepts interaction.
  bool get enabled => _enabled;
  set enabled(bool value) {
    if (_enabled == value) {
      return;
    }
    _enabled = value;
    _notify();
  }

  /// Toggles [enabled].
  void toggleEnabled() => enabled = !_enabled;

  // ------------------------------------------------------------- filtering

  final List<ValueItem<T>> _base = <ValueItem<T>>[];
  final List<ValueItem<T>> _filtered = <ValueItem<T>>[];
  String _query = '';

  /// The items matching [query].
  UnmodifiableListView<ValueItem<T>> get filteredItems =>
      UnmodifiableListView<ValueItem<T>>(_filtered);

  /// The current search text.
  String get query => _query;

  /// Filters the items by [text].
  void search(String text) {
    _query = text;
    _applyFilter();
  }

  /// Clears the search and re-reads [listItems] (call when the list opens).
  void refresh() {
    _query = '';
    _rebuildBase();
    _applyFilter();
  }

  void _rebuildBase() {
    _engine.retainOnly(listItems);
    _base
      ..clear()
      ..addAll(
        _engine.sorted(
          listItems,
          _sort,
          selected: selectedItems.isEmpty ? null : selectedItems.first,
        ),
      );
  }

  void _applyFilter() {
    final List<ValueItem<T>> next = _engine.filter(_base, _query);
    if (listEquals(next, _filtered)) {
      return;
    }
    _filtered
      ..clear()
      ..addAll(next);
    if (_disposed) {
      return;
    }
    final void Function()? onUpdated = onFilterUpdated;
    if (onUpdated != null) {
      // User callbacks often call setState; never run them during a build.
      _runOutsideBuild(onUpdated);
    }
    _notify();
  }

  /// Whether the add row should be offered for the current [query].
  bool get canAdd => addMode && _query.isNotEmpty && _filtered.isEmpty;

  // ------------------------------------------------------------- selection

  /// Whether [item] is selected.
  bool isSelected(ValueItem<T> item) => selectedItems.contains(item);

  /// Selects [item], or deselects it (calling [onClearItem]) when it is
  /// already selected. With [forced] an already selected item stays selected.
  void toggle(ValueItem<T> item, {bool forced = false}) {
    bool removed = false;
    if (selectedItems.contains(item)) {
      if (!forced) {
        selectedItems.remove(item);
        removed = true;
      }
    } else {
      selectedItems.add(item);
    }
    _runOutsideBuild(() {
      if (removed) {
        onClearItem?.call(item);
      }
      updateSelectedItems?.call(selectedItems);
    });
    if (_sort == SortType.selectedFirst) {
      _rebuildBase();
      _applyFilter();
    }
    _notify();
  }

  /// Selects the item whose label is [label] (exact first, then normalized).
  void forceSelection(String label) {
    ValueItem<T>? match;
    for (final ValueItem<T> item in listItems) {
      if (item.label == label) {
        match = item;
        break;
      }
    }
    match ??= _engine.findByLabel(listItems, label);
    if (match != null) {
      toggle(match, forced: true);
    }
  }

  /// Replaces the selection with the [values] that exist in [listItems].
  void forceMultipleSelection(List<ValueItem<T>> values) {
    final Set<ValueItem<T>> known = listItems.toSet();
    final List<ValueItem<T>> next = values
        .where(known.contains)
        .toList(growable: false);
    selectedItems
      ..clear()
      ..addAll(next);
    _notify();
  }

  /// Clears the selection and calls [updateSelectedItems].
  void resetSelection() {
    selectedItems.clear();
    _runOutsideBuild(() => updateSelectedItems?.call(selectedItems));
    _notify();
  }

  /// Clears the selection like the clear button: calls [updateSelectedItems]
  /// and [onClearList].
  void clear() {
    selectedItems.clear();
    _runOutsideBuild(() {
      updateSelectedItems?.call(selectedItems);
      onClearList?.call();
    });
    _notify();
  }

  // ---------------------------------------------------- add / delete / edit

  /// Creates an item from [text] and adds it (see [addValue]).
  Future<void> addItem(
    String text,
    BuildContext context, {
    SearchDropDownStrings strings = const SearchDropDownStrings(),
  }) async {
    final ValueItem<T> Function(String)? create = newValueItem;
    if (!addMode || create == null) {
      return;
    }
    await addValue(create(text), context, strings: strings);
  }

  /// Verifies [item] with [verifyInputItem], awaits [onAddItem], adds it to
  /// [listItems] if the callback did not, selects it and clears the search.
  /// A rejected item shows the warning dialog and is not added.
  Future<void> addValue(
    ValueItem<T> item,
    BuildContext context, {
    SearchDropDownStrings strings = const SearchDropDownStrings(),
  }) async {
    if (!addMode) {
      return;
    }
    final bool Function(ValueItem<T>)? verify = verifyInputItem;
    if (verify != null && !verify(item)) {
      search('');
      await sendDialog<void>(
        context,
        WarningDialog(
          confirmDialog: false,
          returnFunction: (_) {
            if (context.mounted) {
              Navigator.of(context).pop();
            }
          },
          settings: verifyDialogSettings,
          strings: strings,
        ),
      );
      return;
    }
    await onAddItem?.call(item);
    // Shared lists are updated even if a parent rebuild replaced this
    // controller while the callback ran; notifications are skipped then.
    if (!listItems.contains(item)) {
      listItems.add(item);
    }
    _query = '';
    _rebuildBase();
    toggle(item, forced: true);
    _applyFilter();
  }

  /// Deletes [item] (after confirmation when [confirmDelete]), awaiting
  /// [onDeleteItem]. Only that item leaves the selection.
  Future<void> deleteItem(
    ValueItem<T> item,
    BuildContext context, {
    SearchDropDownStrings strings = const SearchDropDownStrings(),
  }) async {
    if (!deleteMode) {
      return;
    }
    if (confirmDelete) {
      bool confirmed = false;
      await sendDialog<void>(
        context,
        WarningDialog(
          returnFunction: (bool result) {
            confirmed = result;
            if (context.mounted) {
              Navigator.of(context).pop();
            }
          },
          settings: deleteDialogSettings,
          strings: strings,
        ),
      );
      if (!confirmed) {
        return;
      }
    }
    await onDeleteItem?.call(item);
    // Shared lists are updated even if a parent rebuild replaced this
    // controller while the callback ran; notifications are skipped then.
    listItems.remove(item);
    _engine.forget(item);
    if (selectedItems.remove(item)) {
      updateSelectedItems?.call(selectedItems);
    }
    _rebuildBase();
    _applyFilter();
    _notify();
  }

  /// Opens the edit dialog for [item]; on confirm awaits [onEditItem] and
  /// replaces the item in [listItems] and [selectedItems].
  Future<void> editItem(
    ValueItem<T> item,
    BuildContext context, {
    SearchDropDownStrings strings = const SearchDropDownStrings(),
  }) async {
    final ValueItem<T> Function(String)? create = newValueItem;
    if (!editMode || create == null) {
      return;
    }
    String? newText;
    await sendDialog<void>(
      context,
      EditDialog(
        label: item.label,
        returnFunction: (bool ok, String text) {
          if (ok) {
            newText = text;
          }
          if (context.mounted) {
            Navigator.of(context).pop();
          }
        },
        settings: editDialogSettings,
        strings: strings,
      ),
    );
    final String? text = newText;
    if (text == null) {
      return;
    }
    final ValueItem<T> newValue = create(text);
    await onEditItem?.call(item, newValue);
    // Shared lists are updated even if a parent rebuild replaced this
    // controller while the callback ran; notifications are skipped then.
    _replace(listItems, item, newValue);
    final int selectedIndex = selectedItems.indexOf(item);
    if (selectedIndex != -1) {
      _replace(selectedItems, item, newValue);
      updateSelectedItems?.call(selectedItems);
    }
    _engine.forget(item);
    _rebuildBase();
    _applyFilter();
    _notify();
  }

  static void _replace<T>(
    List<ValueItem<T>> list,
    ValueItem<T> from,
    ValueItem<T> to,
  ) {
    final int index = list.indexOf(from);
    final bool hasNew = list.contains(to);
    if (index != -1 && (!hasNew || to == from)) {
      list[index] = to;
    } else if (index != -1) {
      list.removeAt(index);
    } else if (!hasNew) {
      list.add(to);
    }
  }

  // ------------------------------------------------------------- lifecycle

  /// Whether [dispose] was called.
  bool get isDisposed => _disposed;

  void _notify() {
    if (_disposed) {
      return;
    }
    _runOutsideBuild(notifyListeners);
  }

  /// Runs [callback] now, or after the frame when called during a build
  /// (user callbacks often call setState).
  void _runOutsideBuild(void Function() callback) =>
      runOutsideBuild(callback, () => _disposed);

  /// Releases resources. Safe to call more than once.
  @override
  void dispose() {
    if (_disposed) {
      return;
    }
    _disposed = true;
    super.dispose();
  }
}
