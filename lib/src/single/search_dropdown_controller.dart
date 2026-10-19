import 'dart:collection';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:simple_search_dropdown/simple_search_dropdown.dart';
import 'package:simple_search_dropdown/src/core/filter_engine.dart';
import 'package:simple_search_dropdown/src/core/package_dialog.dart';
import 'package:simple_search_dropdown/src/core/run_outside_build.dart';
import 'package:simple_search_dropdown/src/core/shared_list.dart';

/// State of a [SearchDropDown]: items, selection, search text and filtering.
///
/// It is a [ChangeNotifier]: selection, `enabled` and the item list notify
/// listeners, so changes made here update the widget without a `GlobalKey`.
/// Typing only updates [results] and [highlight], so the bar does not rebuild
/// on every keystroke.
///
/// Items come from either:
/// * [listItems] — your own list, shared by reference. Changes you make to it
///   show up on the next search, the next time the list opens or on
///   [filterList].
/// * `items` — copied once; the controller owns the copy.
///
/// Either way add/edit/delete keep the list in sync after your callback
/// returns, unless the callback already stored the item: the list holds it,
/// an equal item, or a new entry with the same label (e.g. your copy with a
/// server id), which is then kept and selected. An unmodifiable [listItems]
/// (`const`, `List.unmodifiable`, freezed) is never written; to keep such a
/// list in sync, use `items` and [updateListItems].
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
    bool? showClearIcon,
    ValueItem<T>? initialSelectedItem,
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
       localSearchController = searchController ?? _SingleViewController(),
       _ownsSearchController = searchController == null,
       showClearIcon = showClearIcon ?? true,
       listItems = listItems ?? List<ValueItem<T>>.of(items ?? const []),
       _enabled = enabled,
       _sort = sort,
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
      _clearVisible = this.showClearIcon;
    }
    _engine.sortInPlace(this.listItems, _sort, selected: _selectedItem);
    _rebuildBase();
    _filtered.addAll(_base);
    localSearchController.addListener(_onTextChanged);
  }

  /// The [SearchController] of the underlying `SearchAnchor`.
  ///
  /// The one created when no `searchController` is passed ignores
  /// `openView()` while the view is open, so keys typed into a focused bar
  /// before the view's first frame do not stack a second view. A
  /// `searchController` you pass is used as is.
  final SearchController localSearchController;
  final bool _ownsSearchController;

  /// Whether [localSearchController] was created here (no `searchController`
  /// passed) and is disposed with this controller.
  bool get ownsSearchController => _ownsSearchController;

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
  /// `true` (default) shows it where `SimpleSearchbarSettings.showClearIcon`
  /// allows it (the bar and the open list); `false` never shows it.
  final bool showClearIcon;

  /// Called when [filteredItems] changes; for changes made during a build,
  /// once after that frame however many there were.
  final void Function()? onFilterUpdated;

  final FilterEngine<T> _engine;
  SortType _sort;
  bool _disposed = false;
  bool _viewOpen = false;

  /// The selected label the open view started with, until the user edits
  /// the text. While it is shown it is no query: every item is listed (D1)
  /// and Enter keeps the selection.
  String? _untouchedLabel;

  /// Whether text changes filter while the view is closed: after the first
  /// open, selection or clear, as in 7.x.
  bool _filterArmed = false;

  /// Set while [selectItem] writes the label: the closing view keeps its
  /// results.
  bool _selecting = false;

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

  /// The selected item, if any.
  ///
  /// Setting it shows its label in the bar and updates the clear button (an
  /// open view stays open and lists every item); `null` clears the text only
  /// while it still shows the old label. It does not call
  /// [updateSelectedItem]; use [selectItem] for a user-like selection.
  ValueItem<T>? get selectedItem => _selectedItem;
  set selectedItem(ValueItem<T>? value) {
    if (_selectedItem == value) {
      return;
    }
    final ValueItem<T>? previous = _selectedItem;
    _selectedItem = value;
    _clearVisible = value != null && showClearIcon;
    _showSelectedLabel(value, previous, replaceTyped: true);
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
  /// [showClearIcon] is `true`); it is only built where
  /// `SimpleSearchbarSettings.showClearIcon` allows it.
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
  final _Highlight _highlight = _Highlight();

  /// The items matching the current search text (also while the view is
  /// closed, once it has opened); the selected label matches every item.
  ///
  /// Always up to date, even right after a change made during a build; the
  /// [results] and [highlight] listeners hear about such a change after that
  /// frame.
  UnmodifiableListView<ValueItem<T>> get filteredItems =>
      UnmodifiableListView<ValueItem<T>>(_filtered);

  /// Notifies when [filteredItems] changes. Changes made during a build are
  /// coalesced into one notification after that frame (so is a change made
  /// in a post-frame callback while that notification is still pending).
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

  /// Whether [item] is the selected item: it is `==` to it or, when no item
  /// in [filteredItems] is (values that cannot be compared, as in 7.x), has
  /// its label.
  bool isSelected(ValueItem<T> item) {
    final ValueItem<T>? selected = _selectedItem;
    return selected != null &&
        _selects(item, selected, exactInPool: _selectionInResults(selected));
  }

  /// The one selection rule, for rows and for edit; [selectedIndex] follows
  /// it too (`==` first, then the label).
  static bool _selects<E>(
    ValueItem<E> item,
    ValueItem<E> selected, {
    required bool exactInPool,
  }) => item == selected || (!exactInPool && item.label == selected.label);

  /// Bumped whenever [_filtered] changes.
  int _resultsVersion = 0;
  ValueItem<T>? _exactFor;
  int _exactVersion = -1;
  bool _exactInResults = false;

  /// Whether [_filtered] holds an item `==` to [selected]; cached per
  /// results and selection, so marking each row is O(1).
  bool _selectionInResults(ValueItem<T> selected) {
    if (!identical(selected, _exactFor) || _exactVersion != _resultsVersion) {
      _exactFor = selected;
      _exactVersion = _resultsVersion;
      _exactInResults = _filtered.contains(selected);
    }
    return _exactInResults;
  }

  // ------------------------------------------------------------- filtering

  void _onTextChanged() {
    final String? untouched = _untouchedLabel;
    if (untouched != null && localSearchController.text != untouched) {
      _untouchedLabel = null;
    }
    _followText();
  }

  /// Re-filters by the field text: in the open view, or while closed once
  /// filtering is armed (7.x), except for the label [selectItem] writes.
  void _followText() {
    if (_viewOpen) {
      _applyFilter();
    } else if (_filterArmed && !_selecting) {
      _filterBy(_textQuery);
    }
  }

  /// The field text as a query. The selected label is no query while the
  /// view is closed and, in the open view, until the user edits it.
  String get _textQuery {
    final String text = localSearchController.text;
    final ValueItem<T>? selected = _selectedItem;
    final bool showsSelection =
        selected != null &&
        text == selected.label &&
        (!_viewOpen || text == _untouchedLabel);
    return showsSelection ? '' : text;
  }

  /// Whether the open view still shows the selected label it opened with.
  bool get _showsUntouchedLabel =>
      _viewOpen && _textQuery.isEmpty && _untouchedLabel != null;

  /// The query of the open view (`''` while closed, for refreshes).
  String get _query => _viewOpen ? _textQuery : '';

  /// Rebuilds the sorted base from [listItems] and re-applies the filter.
  void _refresh() {
    _rebuildBase();
    _applyFilter();
  }

  /// The [listItems] entries behind [_base], by identity.
  final List<ValueItem<T>> _seen = <ValueItem<T>>[];

  /// Whether [listItems] changed since [_base] was built, compared by
  /// identity (O(n), without calling `==`).
  bool _sourceChanged() {
    if (listItems.length != _seen.length) {
      return true;
    }
    for (int i = 0; i < listItems.length; i++) {
      if (!identical(listItems[i], _seen[i])) {
        return true;
      }
    }
    return false;
  }

  void _rebuildBase() {
    _lastQuery = null;
    _engine.retainOnly(listItems);
    _seen
      ..clear()
      ..addAll(listItems);
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
  /// base (e.g. after the items changed). Invariant: when not `null`,
  /// [_filtered] is [_base] filtered by it, so anything that changes [_base]
  /// goes through [_rebuildBase], which resets it.
  String? _lastQuery;

  void _filterBy(String text) {
    // A shared list changed from outside: start again from it (7.x).
    if (_sourceChanged()) {
      _rebuildBase();
    }
    final String query = _engine.normalize(text);
    final String? last = _lastQuery;
    // Same query on the same items (caret, selection or IME composing
    // change): the results are already right (7.x skipped these too).
    if (query == last) {
      return;
    }
    // Typing more characters can only narrow the previous results.
    final List<ValueItem<T>> source =
        last != null && last.isNotEmpty && query.startsWith(last)
        ? List<ValueItem<T>>.of(_filtered)
        : _base;
    _show(_engine.filter(source, text));
    _lastQuery = query;
  }

  /// Whether a [results] notification is queued for after the frame.
  bool _resultsQueued = false;

  /// Whether the queued [results] notification carries new results (and so
  /// calls [onFilterUpdated]), not only fresh instances of the same ones.
  bool _resultsChanged = false;

  void _show(List<ValueItem<T>> next) {
    final bool equal = listEquals(next, _filtered);
    if (equal && _sameInstances(next, _filtered)) {
      return;
    }
    // Applied at once, as in 7.x: reads made in the same build (Enter,
    // filteredItems, selectedIndex) see the new list. The open view keeps a
    // copy taken on each results notification, which a build defers.
    _filtered
      ..clear()
      ..addAll(next);
    _resultsVersion++;
    // The same results with fresh instances (e.g. a refreshed item whose
    // value `==` only compares an id) are handed out without counting as new
    // results: the highlight stays and onFilterUpdated is not called (7.x).
    if (!equal) {
      _highlight.reset();
      _resultsChanged = true;
    }
    if (_resultsQueued) {
      return;
    }
    _resultsQueued = true;
    _runOutsideBuild(() {
      _resultsQueued = false;
      final bool changed = _resultsChanged;
      _resultsChanged = false;
      if (_disposed) {
        return;
      }
      _highlight.flush();
      _results.fire();
      if (changed) {
        onFilterUpdated?.call();
      }
    });
  }

  static bool _sameInstances<E>(List<E> a, List<E> b) {
    for (int i = 0; i < a.length; i++) {
      if (!identical(a[i], b[i])) {
        return false;
      }
    }
    return true;
  }

  /// Runs [callback] now, or after the frame when called during a build
  /// (user callbacks often call setState).
  void _runOutsideBuild(void Function() callback) =>
      runOutsideBuild(callback, () => _disposed);

  /// Calls [updateSelectedItem] with [item], outside a build; also when the
  /// controller is disposed in that frame (7.x called it synchronously).
  void _selectionChanged(ValueItem<T>? item) {
    final void Function(ValueItem<T>?)? callback = updateSelectedItem;
    if (callback != null) {
      runOutsideBuild(() => callback(item));
    }
  }

  /// Filters the current [listItems] by [text] immediately (ignores whether
  /// the view is open). Changes made to a shared `listItems:` list are picked
  /// up; an empty [text] shows every item.
  void filterList(String text) => _filterBy(text);

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

  /// Selects the first filtered item, if any. Right after the view opened
  /// with the selected label (every item listed), keeps the selection, or
  /// selects the first item matching its label (7.x).
  void handleEnterKey() {
    if (_showsUntouchedLabel) {
      final int index = selectedIndex;
      final List<ValueItem<T>> matches = index != -1
          ? <ValueItem<T>>[_filtered[index]]
          : _engine.filter(_base, localSearchController.text);
      if (matches.isNotEmpty) {
        selectItem(matches.first);
      }
      return;
    }
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
    final ValueItem<T>? previous = _selectedItem;
    _selectedItem = item;
    // The view is closing: writing the label must not re-filter the list.
    _viewOpen = false;
    _untouchedLabel = null;
    _selecting = true;
    try {
      if (localSearchController.isAttached && localSearchController.isOpen) {
        localSearchController.closeView(item.label);
      } else {
        _showSelectedLabel(item, previous, replaceTyped: true);
      }
    } finally {
      _selecting = false;
    }
    _filterArmed = true;
    _selectionChanged(item);
    _clearVisible = showClearIcon;
    _notify();
  }

  /// Clears the selection and the text, then calls [updateSelectedItem].
  void resetSelection({bool highlight = false}) {
    _clearSelection();
    if (highlight) {
      resetHighlight();
    }
    _selectionChanged(null);
  }

  /// Clears the selection and the text, then calls [updateSelectedItem].
  void clearSelectionAndNotify() {
    _clearSelection();
    _filterArmed = true;
    _selectionChanged(null);
  }

  /// Clears the selection and the text without calling [updateSelectedItem].
  void clearSelection() {
    _clearSelection();
    _filterArmed = true;
  }

  void _clearSelection() {
    _selectedItem = null;
    _clearVisible = false;
    localSearchController.text = '';
    _applyFilter();
    _notify();
  }

  /// Shows [item] (the new selection, [previous] the old one) in the field.
  /// Its label is no query, so an open view lists every item. Text the user
  /// typed is kept unless [replaceTyped]; without [item] only the old label
  /// is cleared.
  void _showSelectedLabel(
    ValueItem<T>? item,
    ValueItem<T>? previous, {
    required bool replaceTyped,
  }) {
    final bool showsPrevious =
        previous != null && localSearchController.text == previous.label;
    if (showsPrevious || (item != null && replaceTyped)) {
      final String label = item?.label ?? '';
      if (_viewOpen) {
        _untouchedLabel = item == null ? null : label;
      }
      localSearchController.text = label;
    }
    // Also when the text stayed: the new selection changes what is a query.
    _followText();
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
  /// [onAddItem], adds it to [listItems] unless the callback stored it, and
  /// selects it (or the copy the callback stored).
  /// Dialog texts come from `strings`, else the [SearchDropDownStringsScope]
  /// above [context].
  Future<void> addItem(
    String text,
    BuildContext context, {
    SearchDropDownStrings? strings,
  }) async {
    final ValueItem<T> Function(String)? create = newValueItem;
    if (!addMode || create == null) {
      return;
    }
    final ValueItem<T> item = create(text);
    final bool Function(ValueItem<T>)? verify = verifyInputItem;
    if (verify != null && !verify(item)) {
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
      if (_disposed) {
        return;
      }
      localSearchController.clear();
      return;
    }
    final Set<ValueItem<T>> before = _snapshot();
    await onAddItem?.call(item);
    if (_disposed) {
      return;
    }
    final ValueItem<T>? stored = _engine.storedFor(listItems, before, item);
    if (stored == null) {
      writeShared(() => listItems.add(item));
    }
    _refresh();
    selectItem(stored ?? item);
  }

  /// The current entries of [listItems], by identity, taken before a
  /// callback runs so its own copy of an item can be told apart.
  Set<ValueItem<T>> _snapshot() =>
      HashSet<ValueItem<T>>.identity()..addAll(listItems);

  Future<void> _proceedWithDeletion(ValueItem<T> item) async {
    await onDeleteItem?.call(item);
    if (_disposed) {
      return;
    }
    writeShared(() => listItems.remove(item));
    _engine.forget(item);
    _refresh();
    resetSelection(highlight: true);
  }

  /// Deletes [item] (after confirmation when [confirmDelete]), awaiting
  /// [onDeleteItem] and removing the item from [listItems] if the callback
  /// did not.
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
    if (!confirmDelete) {
      return _proceedWithDeletion(item);
    }
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
    if (confirmed) {
      await _proceedWithDeletion(item);
    }
  }

  // ------------------------------------------------------------------ edit

  /// Opens the edit dialog for [item]; on confirm awaits [onEditItem] and
  /// replaces the item in [listItems] unless the callback stored the new one
  /// (then the item the callback stored is the one selected). A confirm with
  /// an unchanged label does nothing.
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
    final Set<ValueItem<T>> before = _snapshot();
    await onEditItem?.call(item, newValue);
    if (_disposed) {
      return;
    }
    final ValueItem<T>? stored = _engine.storedFor(listItems, before, newValue);
    final int index = listItems.indexOf(item);
    final bool replace = index != -1 && (stored == null || newValue == item);
    // The row the user saw as selected, with the rule of [isSelected] over
    // the list before it is written.
    final ValueItem<T>? selected = _selectedItem;
    final bool wasSelected =
        selected != null &&
        _selects(item, selected, exactInPool: listItems.contains(selected));
    writeShared(() {
      if (replace) {
        listItems[index] = newValue;
      } else if (index != -1) {
        listItems.removeAt(index);
      } else if (stored == null) {
        listItems.add(newValue);
      }
    });
    _engine.forget(item);
    _refresh();
    if (wasSelected) {
      _reselectEdited(replace || stored == null ? newValue : stored);
    }
  }

  /// Selects the edited item in place of the old one; an open view stays
  /// open (as in 7.x) and keeps a query the user typed.
  void _reselectEdited(ValueItem<T> next) {
    if (!_viewOpen) {
      selectItem(next);
      return;
    }
    final ValueItem<T>? previous = _selectedItem;
    _selectedItem = next;
    _clearVisible = showClearIcon;
    _showSelectedLabel(next, previous, replaceTyped: false);
    _selectionChanged(next);
    _notify();
  }

  // ------------------------------------------------------------ open/close

  /// Prepares the list when the search view opens: refreshes it from
  /// [listItems] and shows every item (the selected label is not a query).
  void onSearchOpen() {
    _viewOpen = true;
    _filterArmed = true;
    _highlight.value = -1;
    final ValueItem<T>? selected = _selectedItem;
    final String text = localSearchController.text;
    final bool showsSelection = selected != null && text == selected.label;
    _untouchedLabel = showsSelection ? text : null;
    _refresh();
    if (showsSelection) {
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
    _untouchedLabel = null;
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
    _runOutsideBuild(notifyListeners);
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

/// The highlighted index. [reset] clears it at once but leaves the
/// notification to [flush], sent together with the results.
class _Highlight extends ChangeNotifier implements ValueListenable<int> {
  int _value = -1;
  bool _unsent = false;

  @override
  int get value => _value;
  set value(int next) {
    if (_value == next) {
      return;
    }
    _value = next;
    _unsent = false;
    notifyListeners();
  }

  void reset() {
    if (_value != -1) {
      _value = -1;
      _unsent = true;
    }
  }

  void flush() {
    if (_unsent) {
      _unsent = false;
      notifyListeners();
    }
  }
}

/// `SearchAnchor.bar` calls `openView()` on every change of the bar's text;
/// keys that arrive before the view's first frame (e.g. a barcode scanner
/// typing into a Tab-focused bar) would push one view per key.
class _SingleViewController extends SearchController {
  @override
  void openView() {
    if (isAttached && isOpen) {
      return;
    }
    super.openView();
  }
}
