import 'dart:collection';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:simple_search_dropdown/simple_search_dropdown.dart';
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
class MultipleSearchDropDownController<T> extends ChangeNotifier {
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
    bool enabled = true,
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

  final List<ValueItem<T>> _items;
  final List<ValueItem<T>> _selectedItems;

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
    _notify();
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
    _notify();
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
    _notify();
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
  bool _disposed = false;

  /// How items are ordered. [SortType.selectedFirst] moves the first
  /// selected item to the top. Setting it reorders [filteredItems], never
  /// [items].
  SortType get sort => _sort;
  set sort(SortType value) {
    if (_sort == value) {
      return;
    }
    _sort = value;
    _rebuildBase();
    if (!_applyFilter()) {
      _notify();
    }
  }

  bool _enabled;

  /// Whether the user can interact with the dropdown. When `false` the box is
  /// dimmed and ignores pointer and keyboard input, and an open list closes;
  /// changes made from code (`toggle`, `clear`, ...) still apply.
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

  /// Filters [items] by [text].
  void search(String text) {
    final bool queryChanged = text != _query;
    _query = text;
    // The add row reads the query, even when the results stay the same.
    if (!_applyFilter() && queryChanged) {
      _notify();
    }
  }

  /// Clears the search and rebuilds the results (call when the list opens).
  void refresh() {
    _query = '';
    _rebuildBase();
    _applyFilter();
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

  /// Refilters [_base] by [query]. Returns whether [filteredItems] changed
  /// (listeners were then notified). The same results with other instances
  /// (e.g. a refreshed item whose value `==` only compares an id) are swapped
  /// in without calling [onFilterUpdated].
  bool _applyFilter() {
    final List<ValueItem<T>> next = _engine.filter(_base, _query);
    final bool equal = listEquals(next, _filtered);
    if (equal && _sameInstances(next, _filtered)) {
      return false;
    }
    _filtered
      ..clear()
      ..addAll(next);
    if (_disposed) {
      return true;
    }
    final void Function()? onUpdated = onFilterUpdated;
    if (onUpdated != null && !equal) {
      // User callbacks often call setState; never run them during a build.
      _runOutsideBuild(onUpdated);
    }
    _notify();
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
    _notify();
  }

  /// Re-pins the selection for [SortType.selectedFirst].
  void _repin() {
    if (!identical(_pinned, _basePinned)) {
      _rebuildBase();
      _applyFilter();
    }
  }

  /// Selects the item whose label is [label] (exact first, then normalized).
  void forceSelection(String label) {
    ValueItem<T>? match;
    for (final ValueItem<T> item in _items) {
      if (item.label == label) {
        match = item;
        break;
      }
    }
    match ??= _engine.findByLabel(_items, label);
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
    _notify();
  }

  /// Clears the selection and calls [updateSelectedItems].
  void resetSelection() {
    _selectedItems.clear();
    _deliver(
      (List<ValueItem<T>> selection) => updateSelectedItems?.call(selection),
    );
    _repin();
    _notify();
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
    _notify();
  }

  /// Replaces the items with a copy of [newList]; the only way to change
  /// them from outside. [newList] itself is never changed.
  ///
  /// With [shouldReset] the selection is cleared; otherwise selected items
  /// that are no longer in [newList] leave it and the others become their
  /// [newList] instances. [updateSelectedItems] is called when the selection
  /// changes.
  void updateListItems(List<ValueItem<T>> newList, bool shouldReset) {
    _items
      ..clear()
      ..addAll(newList);
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
    _rebuildBase();
    if (!_applyFilter()) {
      _notify();
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
      final SearchDropDownStrings texts =
          strings ?? SearchDropDownStrings.of(context);
      await showPackageDialog(
        context,
        (VoidCallback close) => WarningDialog(
          confirmDialog: false,
          returnFunction: (_) => close(),
          settings: verifyDialogSettings,
          strings: texts,
        ),
      );
      return;
    }
    await onAddItem?.call(item);
    if (_disposed) {
      return;
    }
    if (!_items.contains(item)) {
      _items.add(item);
    }
    _query = '';
    _rebuildBase();
    toggle(item, forced: true);
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
    if (confirmDelete) {
      bool confirmed = false;
      final SearchDropDownStrings texts =
          strings ?? SearchDropDownStrings.of(context);
      await showPackageDialog(
        context,
        (VoidCallback close) => WarningDialog(
          returnFunction: (bool result) {
            confirmed = result;
            close();
          },
          settings: deleteDialogSettings,
          strings: texts,
        ),
      );
      if (!confirmed) {
        return;
      }
    }
    await onDeleteItem?.call(item);
    if (_disposed) {
      return;
    }
    _items.remove(item);
    _engine.forget(item);
    if (_selectedItems.remove(item)) {
      updateSelectedItems?.call(_selectionCopy());
    }
    _rebuildBase();
    _applyFilter();
    _notify();
  }

  /// Opens the edit dialog for [item]; on confirm awaits [onEditItem] and,
  /// once it completes without throwing, replaces the item in [items] and
  /// [selectedItems] (an equal item already there is kept instead of a
  /// duplicate). A confirm with an unchanged label does nothing.
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
    String? newText;
    final SearchDropDownStrings texts =
        strings ?? SearchDropDownStrings.of(context);
    await showPackageDialog(
      context,
      (VoidCallback close) => EditDialog(
        label: item.label,
        returnFunction: (bool ok, String text) {
          if (ok) {
            newText = text;
          }
          close();
        },
        settings: editDialogSettings,
        strings: texts,
      ),
    );
    final String? text = newText;
    // An unchanged label is not an edit: the item and selection stay.
    if (text == null || text == item.label) {
      return;
    }
    final ValueItem<T> newValue = create(text);
    await onEditItem?.call(item, newValue);
    if (_disposed) {
      return;
    }
    final ValueItem<T> edited = replaceItem(_items, item, newValue);
    if (_selectedItems.contains(item)) {
      replaceItem(_selectedItems, item, edited);
      updateSelectedItems?.call(_selectionCopy());
    }
    _engine.forget(item);
    _rebuildBase();
    _applyFilter();
    _notify();
  }

  static bool _sameInstances<E>(List<E> a, List<E> b) {
    for (int i = 0; i < a.length; i++) {
      if (!identical(a[i], b[i])) {
        return false;
      }
    }
    return true;
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

  /// A read-only copy of the selection, handed to [updateSelectedItems] so
  /// the caller never holds (or changes) the controller's own list.
  List<ValueItem<T>> _selectionCopy() =>
      List<ValueItem<T>>.unmodifiable(_selectedItems);

  /// Runs a selection callback like [_runOutsideBuild], but also once the
  /// controller is disposed in that frame: the caller's state must still
  /// learn about the change (7.x ran these synchronously). [callback] gets a
  /// copy of the selection taken now, whatever happens later in that frame.
  void _deliver(void Function(List<ValueItem<T>> selection) callback) {
    final List<ValueItem<T>> selection = _selectionCopy();
    runOutsideBuild(() => callback(selection));
  }

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
