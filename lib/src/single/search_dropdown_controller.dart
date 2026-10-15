import 'dart:collection';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:simple_search_dropdown/simple_search_dropdown.dart';
import 'package:simple_search_dropdown/src/core/filter_engine.dart';

/// State of a [SearchDropDown]: items, selection, search text and filtering.
///
/// It is a [ChangeNotifier]: selection, `enabled` and the item list notify
/// listeners, so changes made here update the widget without a `GlobalKey`.
/// Typing only updates [results] and [highlight], so the bar does not rebuild
/// on every keystroke.
///
/// Items come from either:
/// * [listItems] — your own list, shared by reference. Changes you make to it
///   show up the next time the list opens.
/// * `items` — copied once; the controller owns the copy.
///
/// Either way add/edit/delete keep the list in sync after your callback
/// returns: if the callback already changed the list nothing is done twice.
class SearchDropDownController<T> extends ChangeNotifier {
  /// Creates a controller. Pass exactly one of [listItems] or `items`.
  SearchDropDownController({
    SearchController? searchController,
    List<ValueItem<T>>? listItems,
    List<ValueItem<T>>? items,
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
    this.updateSelectedItem,
    this.verifyInputItem,
    this.verifyDialogSettings,
    this.showClearIcon,
    ValueItem<T>? initialSelectedItem,
    @Deprecated('Use sort. Will be removed in 9.0.0') int? sortType,
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
       localSearchController = searchController ?? SearchController(),
       _ownsSearchController = searchController == null,
       listItems = listItems ?? List<ValueItem<T>>.of(items ?? const []),
       _enabled = enabled,
       _sort = sortType != null ? SortType.fromLegacy(sortType) : sort,
       _engine = FilterEngine<T>(
         normalization: SearchNormalization(
           latinize: latinize,
           caseSensitive: caseSensitive,
           trim: trim,
         ),
       ) {
    if (initialSelectedItem != null && this.listItems.isNotEmpty) {
      _selectedItem = initialSelectedItem;
      localSearchController.text = initialSelectedItem.label;
      _clearVisible = showClearIcon ?? true;
    }
    _engine.sortInPlace(this.listItems, _sort, selected: _selectedItem);
    _rebuildBase();
    _filtered.addAll(_base);
    localSearchController.addListener(_onTextChanged);
  }

  /// The [SearchController] of the underlying `SearchAnchor`.
  final SearchController localSearchController;
  final bool _ownsSearchController;

  /// The items shown by the dropdown (your list when created with
  /// `listItems`, the controller's copy when created with `items`).
  final List<ValueItem<T>> listItems;

  /// Allow the user to add new items to the list.
  final bool addMode;

  /// Creates a `ValueItem<T>` from user input (required by [addMode] and
  /// [editMode]).
  final ValueItem<T> Function(String input)? newValueItem;

  /// Called (and awaited) after the user creates an item.
  final Function(ValueItem<T>)? onAddItem;

  /// Allow the user to edit existing items.
  final bool editMode;

  /// Called (and awaited) after the user edits `originalItem` into `newValue`.
  final Function(ValueItem<T> originalItem, ValueItem<T> newValue)? onEditItem;

  /// Settings of the edit dialog.
  final DialogSettings? editDialogSettings;

  /// Allow the user to delete items.
  final bool deleteMode;

  /// Called (and awaited) after the user deletes an item.
  final Function(ValueItem<T>)? onDeleteItem;

  /// Ask for confirmation before deleting.
  final bool confirmDelete;

  /// Settings of the delete confirmation dialog.
  final DialogSettings? deleteDialogSettings;

  /// Called whenever an item is selected or the selection is cleared.
  final void Function(ValueItem<T>?)? updateSelectedItem;

  /// Return `false` to reject an item the user is about to create.
  final bool Function(ValueItem<T>)? verifyInputItem;

  /// Settings of the dialog shown when [verifyInputItem] rejects an item.
  final DialogSettings? verifyDialogSettings;

  /// Whether a selection makes the clear ("X") button visible.
  ///
  /// `null` (default) follows `SimpleSearchbarSettings.showClearIcon`;
  /// `false` never shows it.
  final bool? showClearIcon;

  /// Called when [filteredItems] changes.
  final void Function()? onFilterUpdated;

  final FilterEngine<T> _engine;
  SortType _sort;
  bool _disposed = false;
  bool _viewOpen = false;

  /// Ignore accents when filtering.
  bool get latinize => _engine.normalization.latinize;

  /// Match case exactly when filtering.
  bool get caseSensitive => _engine.normalization.caseSensitive;

  /// Ignore leading and trailing whitespace when filtering.
  bool get trim => _engine.normalization.trim;

  /// How items are ordered.
  SortType get sort => _sort;

  // ----------------------------------------------------------------- state

  ValueItem<T>? _selectedItem;

  /// The selected item, if any. Setting it does not call [updateSelectedItem];
  /// use [selectItem] for a user-like selection.
  ValueItem<T>? get selectedItem => _selectedItem;
  set selectedItem(ValueItem<T>? value) {
    if (_selectedItem == value) {
      return;
    }
    _selectedItem = value;
    _notify();
  }

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

  bool _clearVisible = false;

  /// Whether the clear button is currently shown (a selection exists and
  /// [showClearIcon] is not `false`).
  bool get clearVisible => _clearVisible;
  set clearVisible(bool value) {
    if (_clearVisible == value) {
      return;
    }
    _clearVisible = value;
    _notify();
  }

  final List<ValueItem<T>> _base = <ValueItem<T>>[];
  final List<ValueItem<T>> _filtered = <ValueItem<T>>[];
  final _Signal _results = _Signal();
  final ValueNotifier<int> _highlight = ValueNotifier<int>(-1);

  /// The items matching the current search text.
  UnmodifiableListView<ValueItem<T>> get filteredItems =>
      UnmodifiableListView<ValueItem<T>>(_filtered);

  /// Notifies when [filteredItems] changes.
  Listenable get results => _results;

  /// The keyboard-highlighted index in [filteredItems] (-1 for none).
  ValueListenable<int> get highlight => _highlight;

  /// The keyboard-highlighted index in [filteredItems] (-1 for none).
  int get highlightedIndex => _highlight.value;

  /// Index of [selectedItem] in [filteredItems], or -1.
  int get selectedIndex {
    final ValueItem<T>? selected = _selectedItem;
    if (selected == null) {
      return -1;
    }
    final int index = _filtered.indexOf(selected);
    return index != -1
        ? index
        : _filtered.indexWhere((ValueItem<T> e) => e.label == selected.label);
  }

  /// Whether [item] is the selected item. Items whose values cannot be
  /// compared (no `==`) match by label, as in 7.x.
  bool isSelected(ValueItem<T> item) {
    final ValueItem<T>? selected = _selectedItem;
    return selected != null &&
        (item == selected || item.label == selected.label);
  }

  // ------------------------------------------------------------- filtering

  void _onTextChanged() {
    if (_viewOpen) {
      _applyFilter();
    }
  }

  /// The text used as query. Only filters while the view is open, and the
  /// selected label in the field is not a query.
  String get _query {
    if (!_viewOpen) {
      return '';
    }
    final String text = localSearchController.text;
    final ValueItem<T>? selected = _selectedItem;
    return selected != null && text == selected.label ? '' : text;
  }

  /// Rebuilds the sorted base from [listItems] and re-applies the filter.
  void _refresh() {
    _rebuildBase();
    _applyFilter();
  }

  void _rebuildBase() {
    _lastQuery = null;
    _base
      ..clear()
      ..addAll(switch (_sort) {
        SortType.alphabetical ||
        SortType.reverseAlphabetical => _engine.sorted(listItems, _sort),
        _ => listItems,
      });
  }

  void _applyFilter() => _filterBy(_query);

  /// Normalized query behind [_filtered]; `null` when it is not a narrowing
  /// base (e.g. after the items changed).
  String? _lastQuery;

  void _filterBy(String text) {
    final String query = _engine.normalize(text);
    final String? last = _lastQuery;
    // Typing more characters can only narrow the previous results.
    final List<ValueItem<T>> source =
        last != null && last.isNotEmpty && query.startsWith(last)
        ? List<ValueItem<T>>.of(_filtered)
        : _base;
    _show(_engine.filter(source, text));
    _lastQuery = query;
  }

  void _show(List<ValueItem<T>> next) {
    if (listEquals(next, _filtered)) {
      return;
    }
    _filtered
      ..clear()
      ..addAll(next);
    if (_disposed) {
      return;
    }
    _highlight.value = -1;
    _results.fire();
    final void Function()? onUpdated = onFilterUpdated;
    if (onUpdated != null) {
      _runOutsideBuild(onUpdated);
    }
  }

  /// Runs [callback] now, or after the frame when called during a build
  /// (user callbacks often call setState).
  void _runOutsideBuild(void Function() callback) {
    final SchedulerBinding binding = SchedulerBinding.instance;
    if (binding.schedulerPhase == SchedulerPhase.persistentCallbacks) {
      binding.addPostFrameCallback((_) {
        if (!_disposed) {
          callback();
        }
      });
    } else {
      callback();
    }
  }

  /// Filters by [text] immediately (ignores whether the view is open).
  void filterList(String text) => _filterBy(text);

  /// Sorts [listItems] in place by [sortType] (0 none, 1 A-Z, 2 Z-A,
  /// 3 selected first) and refreshes the results.
  void sortList(int sortType) => sortBy(SortType.fromLegacy(sortType));

  /// Sorts [listItems] in place by [type] and refreshes the results.
  void sortBy(SortType type) {
    _sort = type;
    _engine.sortInPlace(listItems, type, selected: _selectedItem);
    _refresh();
  }

  // ------------------------------------------------------------- highlight

  /// Clears the keyboard highlight.
  void resetHighlight() => _highlight.value = -1;

  /// Moves the highlight down (starting at the selected item), wrapping.
  void highlightNext() => _moveHighlight(1);

  /// Moves the highlight up (starting at the selected item), wrapping.
  void highlightPrevious() => _moveHighlight(-1);

  void _moveHighlight(int step) {
    final int length = _filtered.length;
    if (length == 0) {
      _highlight.value = -1;
      return;
    }
    final int current = _highlight.value;
    if (current < 0) {
      final int selected = selectedIndex;
      _highlight.value = selected != -1
          ? selected
          : (step > 0 ? 0 : length - 1);
      return;
    }
    _highlight.value = (current + step + length) % length;
  }

  /// Highlights the first (`last == false`) or the last item.
  void highlightEdge({required bool last}) {
    _highlight.value = _filtered.isEmpty
        ? -1
        : (last ? _filtered.length - 1 : 0);
  }

  /// Selects the highlighted item, if any.
  void selectHighlighted() {
    final int index = _highlight.value;
    if (index >= 0 && index < _filtered.length) {
      selectItem(_filtered[index]);
    }
  }

  /// Selects the first filtered item, if any.
  void handleEnterKey() {
    if (_filtered.isNotEmpty) {
      selectItem(_filtered.first);
    }
  }

  /// Enter: selects the highlighted item, or the first filtered one.
  void submit() {
    if (_highlight.value >= 0) {
      selectHighlighted();
    } else {
      handleEnterKey();
    }
  }

  // ------------------------------------------------------------- selection

  /// Selects [item] like a user would: fills the text, closes the view and
  /// calls [updateSelectedItem].
  void selectItem(ValueItem<T> item) {
    _selectedItem = item;
    // The view is closing: writing the label must not re-filter the list.
    _viewOpen = false;
    if (localSearchController.isAttached && localSearchController.isOpen) {
      localSearchController.closeView(item.label);
    } else {
      localSearchController.text = item.label;
    }
    updateSelectedItem?.call(item);
    _clearVisible = showClearIcon ?? true;
    _notify();
  }

  /// Clears the selection and the text, then calls [updateSelectedItem].
  void resetSelection({bool highlight = false}) {
    _clearSelection();
    if (highlight) {
      resetHighlight();
    }
    updateSelectedItem?.call(null);
  }

  /// Clears the selection and the text, then calls [updateSelectedItem].
  void clearSelectionAndNotify() {
    _clearSelection();
    updateSelectedItem?.call(null);
  }

  /// Clears the selection and the text without calling [updateSelectedItem].
  void clearSelection() => _clearSelection();

  void _clearSelection() {
    _selectedItem = null;
    _clearVisible = false;
    localSearchController.text = '';
    _applyFilter();
    _notify();
  }

  /// Selects the item whose label matches [label] (exact first, then
  /// normalized). Does nothing when no item matches.
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
      selectItem(match);
    }
  }

  /// Replaces the items with [newList] (written into [listItems]).
  ///
  /// The selection is reset when [shouldReset] is `true` or an item is
  /// selected.
  void updateListItems(List<ValueItem<T>> newList, bool shouldReset) {
    if (shouldReset || _selectedItem != null) {
      resetSelection();
    }
    final List<ValueItem<T>> copy = List<ValueItem<T>>.of(newList);
    listItems
      ..clear()
      ..addAll(copy);
    _engine
      ..clearCache()
      ..sortInPlace(listItems, _sort, selected: _selectedItem);
    _refresh();
    _notify();
  }

  // ---------------------------------------------------------- add / delete

  /// Creates an item from [text] (after [verifyInputItem]), awaits
  /// [onAddItem], adds it to [listItems] if the callback did not, and selects
  /// it.
  Future<void> addItem(
    String text,
    BuildContext context, {
    SearchDropDownStrings strings = const SearchDropDownStrings(),
  }) async {
    final ValueItem<T> Function(String)? create = newValueItem;
    if (!addMode || create == null) {
      return;
    }
    final ValueItem<T> item = create(text);
    final bool Function(ValueItem<T>)? verify = verifyInputItem;
    if (verify != null && !verify(item)) {
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
      localSearchController.clear();
      return;
    }
    await onAddItem?.call(item);
    if (_disposed) {
      return;
    }
    if (!listItems.contains(item)) {
      listItems.add(item);
    }
    _refresh();
    selectItem(item);
  }

  Future<void> _proceedWithDeletion(ValueItem<T> item) async {
    await onDeleteItem?.call(item);
    if (_disposed) {
      return;
    }
    listItems.remove(item);
    _engine.forget(item);
    _refresh();
    resetSelection(highlight: true);
  }

  /// Deletes [item] (after confirmation when [confirmDelete]), awaiting
  /// [onDeleteItem] and removing the item from [listItems] if the callback
  /// did not.
  Future<void> deleteItem(
    ValueItem<T> item,
    BuildContext context, {
    SearchDropDownStrings strings = const SearchDropDownStrings(),
  }) async {
    if (!deleteMode) {
      return;
    }
    if (!confirmDelete) {
      return _proceedWithDeletion(item);
    }
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
    if (confirmed) {
      await _proceedWithDeletion(item);
    }
  }

  // ------------------------------------------------------------------ edit

  /// Opens the edit dialog for [item]; on confirm awaits [onEditItem] and
  /// replaces the item in [listItems] if the callback did not.
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
    if (_disposed) {
      return;
    }
    final int index = listItems.indexOf(item);
    final bool hasNew = listItems.contains(newValue);
    if (index != -1 && (!hasNew || newValue == item)) {
      listItems[index] = newValue;
    } else if (index != -1) {
      listItems.removeAt(index);
    } else if (!hasNew) {
      listItems.add(newValue);
    }
    _engine.forget(item);
    final bool wasSelected = _selectedItem == item;
    _refresh();
    if (wasSelected) {
      selectItem(newValue);
    }
  }

  // ------------------------------------------------------------ open/close

  /// Prepares the list when the search view opens: refreshes it from
  /// [listItems] and shows every item (the selected label is not a query).
  void onSearchOpen() {
    _viewOpen = true;
    _highlight.value = -1;
    _refresh();
    final ValueItem<T>? selected = _selectedItem;
    final String text = localSearchController.text;
    if (selected != null && text == selected.label) {
      // Typing replaces the selected label instead of appending to it.
      localSearchController.selection = TextSelection(
        baseOffset: 0,
        extentOffset: text.length,
      );
    }
  }

  /// Restores or clears the text when the search view closes.
  void onSearchClose(bool clearOnClose) {
    _viewOpen = false;
    if (!_disposed) {
      _highlight.value = -1;
    }
    final String text = localSearchController.text;
    if (clearOnClose && text.isNotEmpty) {
      final ValueItem<T>? selected = _selectedItem;
      if (selected != null) {
        if (text != selected.label) {
          localSearchController.text = selected.label;
        }
      } else {
        localSearchController.text = '';
      }
    }
  }

  /// Toggles [enabled].
  void toggleEnabled() => enabled = !_enabled;

  // ------------------------------------------------------------- lifecycle

  /// Whether [dispose] was called.
  bool get isDisposed => _disposed;

  void _notify() {
    if (_disposed) {
      return;
    }
    final SchedulerBinding binding = SchedulerBinding.instance;
    if (binding.schedulerPhase == SchedulerPhase.persistentCallbacks) {
      binding.addPostFrameCallback((_) {
        if (!_disposed) {
          notifyListeners();
        }
      });
    } else {
      notifyListeners();
    }
  }

  /// Releases resources. Safe to call more than once.
  @override
  void dispose() {
    if (_disposed) {
      return;
    }
    _disposed = true;
    localSearchController.removeListener(_onTextChanged);
    if (_ownsSearchController) {
      localSearchController.dispose();
    }
    _highlight.dispose();
    _results.dispose();
    super.dispose();
  }
}

/// A [ChangeNotifier] that can be fired from outside.
class _Signal extends ChangeNotifier {
  void fire() => notifyListeners();
}
