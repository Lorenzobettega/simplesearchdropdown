import 'dart:collection';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:simple_search_dropdown/simple_search_dropdown.dart';
import 'package:simple_search_dropdown/src/core/controller_base.dart';
import 'package:simple_search_dropdown/src/core/filter_engine.dart';
import 'package:simple_search_dropdown/src/core/item_list.dart';
import 'package:simple_search_dropdown/src/core/package_dialog.dart';
import 'package:simple_search_dropdown/src/core/run_outside_build.dart';

/// State of a [MultipleSearchDropDown]: items, selected items, search text and
/// filtering. Changes notify listeners, so the widget updates without a
/// `GlobalKey`.
///
/// The controller keeps its own copies of the `items` and `selectedItems` it
/// is created with ([items], [selectedItems]) and never reads or writes your
/// lists again: sorting orders only the results, and add/edit/delete change
/// the copy only after your callback completes without throwing. Replace the
/// items from outside with [updateListItems], the selection with
/// [forceSelection], [forceMultipleSelection], [toggle] or [clear]; follow the
/// selection with [updateSelectedItems] or a listener.
///
/// A callback may apply a server copy with [updateListItems] (e.g. the saved
/// item with its database id); the controller then keeps the app's list
/// instead of applying the change again: add selects the matching item from
/// it (equal, else the same label) and appends nothing, edit selects the
/// edited item from it and never brings back an item the list dropped, and
/// delete leaves it as it is.
class MultipleSearchDropDownController<T> extends DropDownControllerBase {
  /// Creates a controller over copies of [items] and [selectedItems].
  MultipleSearchDropDownController({
    required List<ValueItem<T>> items,
    List<ValueItem<T>>? selectedItems,
    this.updateSelectedItems,
    bool addMode = true,
    this.newValueItem,
    this.onAddItem,
    bool deleteMode = true,
    this.onDeleteItem,
    bool editMode = false,
    this.onEditItem,
    this.editDialogSettings,
    this.onClearItem,
    this.onClearList,
    this.confirmDelete = false,
    this.deleteDialogSettings,
    this.verifyInputItem,
    this.verifyDialogSettings,
    SortType sort = SortType.none,
    super.enabled = true,
    this.onFilterUpdated,
    bool latinize = true,
    bool caseSensitive = false,
    bool trim = true,
  }) : assert(
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
       _items = List<ValueItem<T>>.of(items),
       _selectedItems = List<ValueItem<T>>.of(selectedItems ?? const []),
       _addMode = addMode,
       _deleteMode = deleteMode,
       _editMode = editMode,
       _sort = sort,
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

  final List<ValueItem<T>> _items;
  final List<ValueItem<T>> _selectedItems;

  /// Bumped by [updateListItems]: a CRUD callback that changed it has
  /// applied its own list, which the controller then keeps.
  int _listGeneration = 0;

  /// The controller's own items (a read-only view of its copy).
  UnmodifiableListView<ValueItem<T>> get items =>
      UnmodifiableListView<ValueItem<T>>(_items);

  /// The selected items, in selection order (a read-only view of the
  /// controller's own list).
  UnmodifiableListView<ValueItem<T>> get selectedItems =>
      UnmodifiableListView<ValueItem<T>>(_selectedItems);

  /// Called with a copy of [selectedItems] whenever the user changes the
  /// selection.
  final void Function(List<ValueItem<T>>)? updateSelectedItems;

  bool _addMode;

  /// Allow the user to add new items. Can be changed later; `true` needs
  /// [newValueItem] and [onAddItem].
  bool get addMode => _addMode;
  set addMode(bool value) {
    assert(
      !value || (newValueItem != null && onAddItem != null),
      'addMode can only be used with newValueItem != null && onAddItem != null',
    );
    if (_addMode == value) {
      return;
    }
    _addMode = value;
    notifyListeners();
  }

  /// Creates a `ValueItem<T>` from user input.
  final ValueItem<T> Function(String input)? newValueItem;

  /// Called (and awaited) after the user creates an item.
  final Function(ValueItem<T>)? onAddItem;

  bool _deleteMode;

  /// Allow the user to delete items. Can be changed later; `true` needs
  /// [onDeleteItem].
  bool get deleteMode => _deleteMode;
  set deleteMode(bool value) {
    assert(
      !value || onDeleteItem != null,
      'deleteMode can only be used with onDeleteItem != null',
    );
    if (_deleteMode == value) {
      return;
    }
    _deleteMode = value;
    notifyListeners();
  }

  /// Called (and awaited) after the user deletes an item.
  final Function(ValueItem<T>)? onDeleteItem;

  bool _editMode;

  /// Allow the user to edit items. Can be changed later; `true` needs
  /// [onEditItem] and [newValueItem].
  bool get editMode => _editMode;
  set editMode(bool value) {
    assert(
      !value || (onEditItem != null && newValueItem != null),
      'editMode can only be used with onEditItem != null && newValueItem != null',
    );
    if (_editMode == value) {
      return;
    }
    _editMode = value;
    notifyListeners();
  }

  /// Called (and awaited) after the user edits `originalItem` into `newValue`.
  final Function(ValueItem<T> originalItem, ValueItem<T> newValue)? onEditItem;

  /// Settings of the edit dialog.
  DialogSettings? editDialogSettings;

  /// Called when the user deselects an item.
  final Function(ValueItem<T>)? onClearItem;

  /// Called when the user clears the whole selection.
  final Function()? onClearList;

  /// Ask for confirmation before deleting. Can be changed later.
  bool confirmDelete;

  /// Settings of the delete confirmation dialog.
  DialogSettings? deleteDialogSettings;

  /// Return `false` to reject an item the user is about to create.
  final bool Function(ValueItem<T>)? verifyInputItem;

  /// Settings of the dialog shown when [verifyInputItem] rejects an item.
  DialogSettings? verifyDialogSettings;

  /// Called when [filteredItems] changes.
  final void Function()? onFilterUpdated;

  final FilterEngine<T> _engine;
  SortType _sort;

  /// How items are ordered. [SortType.selectedFirst] moves the first
  /// selected item to the top. Setting it reorders [filteredItems], never
  /// [items].
  SortType get sort => _sort;
  set sort(SortType value) {
    if (_sort == value) {
      return;
    }
    _sort = value;
    if (!_refilter()) {
      notifyListeners();
    }
  }

  // ------------------------------------------------------------- filtering

  final List<ValueItem<T>> _base = <ValueItem<T>>[];
  final List<ValueItem<T>> _filtered = <ValueItem<T>>[];
  String _query = '';

  /// The items matching [query].
  UnmodifiableListView<ValueItem<T>> get filteredItems =>
      UnmodifiableListView<ValueItem<T>>(_filtered);

  /// The current search text.
  String get query => _query;

  /// Filters [items] by [text].
  void search(String text) {
    final bool queryChanged = text != _query;
    _query = text;
    // The add row reads the query, even when the results stay the same.
    if (!_applyFilter() && queryChanged) {
      notifyListeners();
    }
  }

  /// Clears the search and rebuilds the results (call when the list opens).
  void refresh() {
    _query = '';
    _refilter();
  }

  /// The selected item pinned to the top of [_base] (selectedFirst).
  ValueItem<T>? _basePinned;

  ValueItem<T>? get _pinned => _sort == SortType.selectedFirst
      ? (_selectedItems.isEmpty ? null : _selectedItems.first)
      : null;

  void _rebuildBase() {
    _engine.retainOnly(_items);
    _basePinned = _pinned;
    _base
      ..clear()
      ..addAll(_engine.sorted(_items, _sort, selected: _basePinned));
  }

  /// Rebuilds [_base] and refilters it; returns what [_applyFilter] does.
  bool _refilter() {
    _rebuildBase();
    return _applyFilter();
  }

  /// Refilters [_base] by [query]. Returns whether [filteredItems] changed
  /// (listeners were then notified). The same results with other instances
  /// (e.g. a refreshed item whose value `==` only compares an id) are swapped
  /// in without calling [onFilterUpdated].
  bool _applyFilter() {
    final List<ValueItem<T>> next = _engine.filter(_base, _query);
    final bool equal = listEquals(next, _filtered);
    if (equal && sameInstances(next, _filtered)) {
      return false;
    }
    _filtered
      ..clear()
      ..addAll(next);
    if (isDisposed) {
      return true;
    }
    final void Function()? onUpdated = onFilterUpdated;
    if (onUpdated != null && !equal) {
      // User callbacks often call setState; never run them during a build.
      runOutsideBuild(onUpdated, () => isDisposed);
    }
    notifyListeners();
    return true;
  }

  /// Whether the add row should be offered for the current [query].
  bool get canAdd => addMode && _query.isNotEmpty && _filtered.isEmpty;

  // ------------------------------------------------------------- selection

  /// Whether [item] is selected.
  bool isSelected(ValueItem<T> item) => _selectedItems.contains(item);

  /// Selects [item], or deselects it (calling [onClearItem]) when it is
  /// already selected. With [forced] an already selected item stays selected.
  void toggle(ValueItem<T> item, {bool forced = false}) {
    bool removed = false;
    if (_selectedItems.contains(item)) {
      if (!forced) {
        _selectedItems.remove(item);
        removed = true;
      }
    } else {
      _selectedItems.add(item);
    }
    _deliver((List<ValueItem<T>> selection) {
      if (removed) {
        onClearItem?.call(item);
      }
      updateSelectedItems?.call(selection);
    });
    _repin();
    notifyListeners();
  }

  /// Re-pins the selection for [SortType.selectedFirst].
  void _repin() {
    if (!identical(_pinned, _basePinned)) {
      _refilter();
    }
  }

  /// Selects the item whose label is [label] (exact first, then normalized).
  void forceSelection(String label) {
    final ValueItem<T>? match = _engine.findByLabel(_items, label);
    if (match != null) {
      toggle(match, forced: true);
    }
  }

  /// Replaces the selection with the [values] that exist in [items].
  void forceMultipleSelection(List<ValueItem<T>> values) {
    final Set<ValueItem<T>> known = _items.toSet();
    final List<ValueItem<T>> next = values
        .where(known.contains)
        .toList(growable: false);
    _selectedItems
      ..clear()
      ..addAll(next);
    _repin();
    notifyListeners();
  }

  /// Clears the selection and calls [updateSelectedItems].
  void resetSelection() {
    _selectedItems.clear();
    _deliver(
      (List<ValueItem<T>> selection) => updateSelectedItems?.call(selection),
    );
    _repin();
    notifyListeners();
  }

  /// Clears the selection like the clear button: calls [updateSelectedItems]
  /// and [onClearList].
  void clear() {
    _selectedItems.clear();
    _deliver((List<ValueItem<T>> selection) {
      updateSelectedItems?.call(selection);
      onClearList?.call();
    });
    _repin();
    notifyListeners();
  }

  /// Replaces the items with a copy of [newList]; the only way to change
  /// them from outside. [newList] itself is never changed.
  ///
  /// With [shouldReset] the selection is cleared; otherwise selected items
  /// that are no longer in [newList] leave it and the others become their
  /// [newList] instances. [updateSelectedItems] is called when the selection
  /// changes.
  void updateListItems(List<ValueItem<T>> newList, bool shouldReset) {
    // A copy first: [newList] may be [items], a view of [_items].
    final List<ValueItem<T>> copy = List<ValueItem<T>>.of(newList);
    _listGeneration++;
    _items
      ..clear()
      ..addAll(copy);
    _engine.clearCache();
    final Map<ValueItem<T>, ValueItem<T>> fresh =
        <ValueItem<T>, ValueItem<T>>{};
    if (!shouldReset) {
      for (final ValueItem<T> item in _items) {
        fresh.putIfAbsent(item, () => item);
      }
    }
    final List<ValueItem<T>> next = <ValueItem<T>>[
      for (final ValueItem<T> item in _selectedItems)
        if (fresh[item] case final ValueItem<T> kept) kept,
    ];
    final bool changed = !listEquals(next, _selectedItems);
    _selectedItems
      ..clear()
      ..addAll(next);
    if (changed) {
      _deliver(
        (List<ValueItem<T>> selection) => updateSelectedItems?.call(selection),
      );
    }
    if (!_refilter()) {
      notifyListeners();
    }
  }

  // ---------------------------------------------------- add / delete / edit

  /// Creates an item from [text] and adds it (see [addValue]).
  Future<void> addItem(
    String text,
    BuildContext context, {
    SearchDropDownStrings? strings,
  }) async {
    final ValueItem<T> Function(String)? create = newValueItem;
    if (!addMode || create == null) {
      return;
    }
    await addValue(create(text), context, strings: strings);
  }

  /// Verifies [item] with [verifyInputItem] and awaits [onAddItem]; once it
  /// completes without throwing, adds the item to [items] (unless an equal
  /// one is there), selects it and clears the search. A rejected item shows
  /// the warning dialog and is not added.
  /// When the callback applied its own list with [updateListItems], that
  /// list is kept and its matching item (equal, else the same label) is
  /// selected.
  /// Dialog texts come from `strings`, else the [SearchDropDownStringsScope]
  /// above [context].
  Future<void> addValue(
    ValueItem<T> item,
    BuildContext context, {
    SearchDropDownStrings? strings,
  }) async {
    if (!addMode) {
      return;
    }
    final bool Function(ValueItem<T>)? verify = verifyInputItem;
    if (verify != null && !verify(item)) {
      search('');
      await showRejectedItemWarning(context, verifyDialogSettings, strings);
      return;
    }
    final int generation = _listGeneration;
    await onAddItem?.call(item);
    if (isDisposed) {
      return;
    }
    final ValueItem<T>? added;
    if (generation != _listGeneration) {
      // The callback applied its own list: select its copy, add nothing.
      added = counterpartOf(_items, item, _engine);
    } else {
      added = item;
      if (!_items.contains(item)) {
        _items.add(item);
      }
    }
    _query = '';
    _rebuildBase();
    if (added != null) {
      toggle(added, forced: true);
    }
    _applyFilter();
  }

  /// Deletes [item] (after confirmation when [confirmDelete]): awaits
  /// [onDeleteItem] and, once it completes without throwing, removes the
  /// item from [items]. Only that item leaves the selection.
  /// Dialog texts come from `strings`, else the [SearchDropDownStringsScope]
  /// above [context].
  Future<void> deleteItem(
    ValueItem<T> item,
    BuildContext context, {
    SearchDropDownStrings? strings,
  }) async {
    if (!deleteMode) {
      return;
    }
    if (confirmDelete &&
        !await confirmDeletion(
          context,
          deleteDialogSettings,
          strings,
          itemLabel: item.label,
        )) {
      return;
    }
    await onDeleteItem?.call(item);
    if (isDisposed) {
      return;
    }
    _items.remove(item);
    _engine.forget(item);
    if (_selectedItems.remove(item)) {
      updateSelectedItems?.call(_selectionCopy());
    }
    _refilter();
    notifyListeners();
  }

  /// Opens the edit dialog for [item]; on confirm awaits [onEditItem] and,
  /// once it completes without throwing, replaces the item in [items] and
  /// [selectedItems] (an equal item already there is kept instead of a
  /// duplicate). A confirm with an unchanged label does nothing.
  /// When the callback applied its own list with [updateListItems], that
  /// list is kept: its edited item (equal, else the same label) takes the old
  /// one's place in the selection, and without one [item] is replaced only
  /// if the list still holds it.
  /// Dialog texts come from `strings`, else the [SearchDropDownStringsScope]
  /// above [context].
  Future<void> editItem(
    ValueItem<T> item,
    BuildContext context, {
    SearchDropDownStrings? strings,
  }) async {
    final ValueItem<T> Function(String)? create = newValueItem;
    if (!editMode || create == null) {
      return;
    }
    final String? text = await askNewLabel(
      context,
      item.label,
      editDialogSettings,
      strings,
    );
    if (text == null) {
      return;
    }
    final ValueItem<T> newValue = create(text);
    final int generation = _listGeneration;
    final int selectedAt = _selectedItems.indexOf(item);
    await onEditItem?.call(item, newValue);
    if (isDisposed) {
      return;
    }
    if (generation != _listGeneration) {
      _keepRefreshedEdit(item, newValue, selectedAt);
    } else {
      _replaceEverywhere(item, newValue);
    }
    _engine.forget(item);
    _refilter();
    notifyListeners();
  }

  /// Replaces [from] with [to] in the items and, when selected, in the
  /// selection (reporting it).
  void _replaceEverywhere(ValueItem<T> from, ValueItem<T> to) {
    final ValueItem<T> edited = replaceItem(_items, from, to);
    if (_selectedItems.contains(from)) {
      replaceItem(_selectedItems, from, edited);
      updateSelectedItems?.call(_selectionCopy());
    }
  }

  /// Finishes an edit whose callback applied its own list: an edited item
  /// that list holds stays as it is (and takes [from]'s place in the
  /// selection when [from] was selected at [selectedAt]); without one,
  /// [from] is replaced only if the list still holds it, so an item the
  /// list dropped never comes back.
  void _keepRefreshedEdit(ValueItem<T> from, ValueItem<T> to, int selectedAt) {
    final ValueItem<T>? kept = counterpartOf(_items, to, _engine);
    if (kept == null) {
      if (!_items.contains(from)) {
        return;
      }
      _replaceEverywhere(from, to);
      return;
    }
    if (selectedAt == -1 || _selectedItems.contains(kept)) {
      return;
    }
    final int at = _selectedItems.indexOf(from);
    if (at != -1) {
      _selectedItems[at] = kept;
    } else {
      _selectedItems.insert(selectedAt.clamp(0, _selectedItems.length), kept);
    }
    updateSelectedItems?.call(_selectionCopy());
  }

  /// A read-only copy of the selection, handed to [updateSelectedItems] so
  /// the caller never holds (or changes) the controller's own list.
  List<ValueItem<T>> _selectionCopy() =>
      List<ValueItem<T>>.unmodifiable(_selectedItems);

  /// Runs a selection callback outside a build, but also once the
  /// controller is disposed in that frame: the caller's state must still
  /// learn about the change (7.x ran these synchronously). [callback] gets a
  /// copy of the selection taken now, whatever happens later in that frame.
  void _deliver(void Function(List<ValueItem<T>> selection) callback) {
    final List<ValueItem<T>> selection = _selectionCopy();
    runOutsideBuild(() => callback(selection));
  }
}
