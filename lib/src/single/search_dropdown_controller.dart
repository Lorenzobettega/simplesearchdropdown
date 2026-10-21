import 'dart:collection';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:simple_search_dropdown/simple_search_dropdown.dart';
import 'package:simple_search_dropdown/src/core/controller_base.dart';
import 'package:simple_search_dropdown/src/core/filter_engine.dart';
import 'package:simple_search_dropdown/src/core/item_list.dart';
import 'package:simple_search_dropdown/src/core/package_dialog.dart';
import 'package:simple_search_dropdown/src/core/run_outside_build.dart';

/// State of a [SearchDropDown]: items, selection, search text and filtering.
///
/// It is a [ChangeNotifier]: selection, `enabled` and the item list notify
/// listeners, so changes made here update the widget without a `GlobalKey`.
/// Typing only updates [results] and [highlight], so the bar does not rebuild
/// on every keystroke.
///
/// The controller keeps its own copy of the `items` it is created with
/// ([items]) and never reads or writes your list again: sorting orders the
/// copy, and add/edit/delete change it only after your callback completes
/// without throwing. Replace the items from outside with [updateListItems].
///
/// A callback may apply a server copy with [updateListItems] (e.g. the saved
/// item with its database id); the controller then keeps the app's list
/// instead of applying the change again: add selects the matching item from
/// it (equal, else the same label) and appends nothing, edit selects the
/// edited item from it and never brings back an item the list dropped, and
/// delete leaves it as it is.
class SearchDropDownController<T> extends DropDownControllerBase {
  /// Creates a controller over a copy of [items].
  ///
  /// A [searchController] you pass stays yours: the controller never
  /// disposes it, so dispose it after this controller (or together, in the
  /// same `dispose`), never while the dropdown may still use it. Without
  /// one the controller creates its own ([ownsSearchController]).
  SearchDropDownController({
    SearchController? searchController,
    required List<ValueItem<T>> items,
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
       localSearchController = searchController ?? _SingleViewController(),
       _ownsSearchController = searchController == null,
       showClearIcon = showClearIcon ?? true,
       _items = List<ValueItem<T>>.of(items),
       _sort = sort,
       _engine = FilterEngine<T>(
         normalization: SearchNormalization(
           latinize: latinize,
           caseSensitive: caseSensitive,
           trim: trim,
         ),
       ) {
    if (initialSelectedItem != null && _items.isNotEmpty) {
      _selectedItem = initialSelectedItem;
      final String label = initialSelectedItem.label;
      if (_ownsSearchController) {
        // Brand new: no field listens to it yet, so no build can trip.
        localSearchController.text = label;
      } else {
        _editText(() => localSearchController.text = label);
      }
      _clearVisible = this.showClearIcon;
    }
    _engine.sortInPlace(_items, _sort, selected: _selectedItem);
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

  final List<ValueItem<T>> _items;

  /// The controller's own items (a read-only view of its copy), in the
  /// current sort order.
  UnmodifiableListView<ValueItem<T>> get items =>
      UnmodifiableListView<ValueItem<T>>(_items);

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
  bool _viewOpen = false;

  /// The selected label the open view started with, until the user edits
  /// the text. While it is shown it is no query: every item is listed (D1)
  /// and Enter keeps the selection.
  String? _untouchedLabel;

  /// Whether text changes filter while the view is closed: after the first
  /// open, selection or clear, as in 7.x.
  bool _filterArmed = false;

  /// Set while the controller writes the field itself without it being a
  /// query ([selectItem]'s label, [updateListItems]' cleared text): the
  /// text does not re-filter.
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

  /// Bumped by [updateListItems]: a CRUD callback that changed it has
  /// applied its own list, which the controller then keeps.
  int _listGeneration = 0;

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
    notifyListeners();
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
    notifyListeners();
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
    if (_selecting) {
      return;
    }
    if (_viewOpen) {
      _applyFilter();
    } else if (_filterArmed) {
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

  /// Rebuilds the sorted base from [items] and re-applies the filter.
  void _refresh() {
    _rebuildBase();
    _applyFilter();
  }

  void _rebuildBase() {
    _lastQuery = null;
    _engine.retainOnly(_items);
    _base
      ..clear()
      ..addAll(switch (_sort) {
        SortType.alphabetical ||
        SortType.reverseAlphabetical => _engine.sorted(_items, _sort),
        _ => _items,
      });
  }

  void _applyFilter() => _filterBy(_query);

  /// Normalized query behind [_filtered]; `null` when it is not a narrowing
  /// base (e.g. after the items changed). Invariant: when not `null`,
  /// [_filtered] is [_base] filtered by it, so anything that changes [_base]
  /// goes through [_rebuildBase], which resets it.
  String? _lastQuery;

  void _filterBy(String text) {
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
    if (equal && sameInstances(next, _filtered)) {
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
    runOutsideBuild(() {
      _resultsQueued = false;
      final bool changed = _resultsChanged;
      _resultsChanged = false;
      if (isDisposed) {
        return;
      }
      _highlight.flush();
      _results.fire();
      if (changed) {
        onFilterUpdated?.call();
      }
    }, () => isDisposed);
  }

  /// Calls [updateSelectedItem] with [item], outside a build; also when the
  /// controller is disposed in that frame (7.x called it synchronously).
  void _selectionChanged(ValueItem<T>? item) {
    final void Function(ValueItem<T>?)? callback = updateSelectedItem;
    if (callback != null) {
      runOutsideBuild(() => callback(item));
    }
  }

  /// Filters [items] by [text] immediately (ignores whether the view is
  /// open); an empty [text] shows every item.
  void filterList(String text) => _filterBy(text);

  /// Sorts the controller's [items] by [type] and refreshes the results.
  void sortBy(SortType type) {
    _sort = type;
    _engine.sortInPlace(_items, type, selected: _selectedItem);
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
    // Re-selecting the selected item changes nothing listeners show.
    final bool unchanged =
        previous == item &&
        previous?.label == item.label &&
        _clearVisible == showClearIcon;
    _selectedItem = item;
    // The view is closing: writing the label must not re-filter the list.
    _viewOpen = false;
    _untouchedLabel = null;
    _editText(() {
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
    });
    _filterArmed = true;
    _selectionChanged(item);
    _clearVisible = showClearIcon;
    if (!unchanged) {
      notifyListeners();
    }
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
    _editText(() => localSearchController.text = '', then: _applyFilter);
    notifyListeners();
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
    _editText(
      () {
        final bool showsPrevious =
            previous != null && localSearchController.text == previous.label;
        if (showsPrevious || (item != null && replaceTyped)) {
          final String label = item?.label ?? '';
          if (_viewOpen) {
            _untouchedLabel = item == null ? null : label;
          }
          localSearchController.text = label;
        }
      },
      // Also when the text stayed: the new selection changes what is a
      // query.
      then: _followText,
    );
  }

  /// Runs [edit], a write to [localSearchController], then [then]: now, or
  /// after the frame when called during a build, together with the
  /// notification (#52: every field on the SearchController hears the
  /// write, also one of a bar this build is replacing). Once this controller
  /// is disposed nothing runs; once the SearchController is (one passed in,
  /// disposed by its owner while a callback was pending, #49) [edit] is
  /// skipped.
  void _editText(VoidCallback edit, {VoidCallback? then}) {
    runOutsideBuild(() {
      if (isDisposed) {
        return;
      }
      if (isUsable(localSearchController)) {
        edit();
      }
      then?.call();
    }, () => isDisposed);
  }

  /// Selects the item whose label matches [label] (exact first, then
  /// normalized). Does nothing when no item matches.
  void forceSelection(String label) {
    final ValueItem<T>? match = _engine.findByLabel(_items, label);
    if (match != null) {
      selectItem(match);
    }
  }

  /// Replaces the items with a copy of [newList]; the only way to change
  /// them from outside. [newList] itself is never changed.
  ///
  /// The selection is reset when [shouldReset] is `true` or an item is
  /// selected.
  void updateListItems(List<ValueItem<T>> newList, bool shouldReset) {
    if (shouldReset || _selectedItem != null) {
      // As resetSelection, but the text write does not filter the old items
      // and the one notification below covers the cleared selection.
      _selectedItem = null;
      _clearVisible = false;
      final bool deferred = isBuilding();
      _editText(() {
        _selecting = true;
        try {
          localSearchController.text = '';
        } finally {
          _selecting = false;
        }
      }, then: deferred ? _applyFilter : null);
      _selectionChanged(null);
    }
    final List<ValueItem<T>> copy = List<ValueItem<T>>.of(newList);
    _listGeneration++;
    _items
      ..clear()
      ..addAll(copy);
    _engine
      ..clearCache()
      ..sortInPlace(_items, _sort, selected: _selectedItem);
    _refresh();
    notifyListeners();
  }

  // ---------------------------------------------------------- add / delete

  /// Creates an item from [text] (after [verifyInputItem]), awaits
  /// [onAddItem] and, once it completes without throwing, adds the item to
  /// [items] (unless an equal one is there) and selects it. When the
  /// callback applied its own list with [updateListItems], that list is kept
  /// and its matching item (equal, else the same label) is selected.
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
      await showRejectedItemWarning(context, verifyDialogSettings, strings);
      _editText(localSearchController.clear);
      return;
    }
    final int generation = _listGeneration;
    await onAddItem?.call(item);
    if (isDisposed) {
      return;
    }
    if (generation != _listGeneration) {
      // The callback applied its own list: select its copy, add nothing.
      final ValueItem<T>? added = counterpartOf(_items, item, _engine);
      if (added != null) {
        selectItem(added);
      }
      return;
    }
    if (!_items.contains(item)) {
      _items.add(item);
    }
    _refresh();
    selectItem(item);
  }

  /// Deletes [item] (after confirmation when [confirmDelete]): awaits
  /// [onDeleteItem] and, once it completes without throwing, removes the
  /// item from [items] and clears the selection.
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
    _refresh();
    resetSelection(highlight: true);
  }

  // ------------------------------------------------------------------ edit

  /// Opens the edit dialog for [item]; on confirm awaits [onEditItem] and,
  /// once it completes without throwing, replaces the item in [items] (an
  /// equal item already there is kept instead of a duplicate) and reselects
  /// it when it was selected. A confirm with an unchanged label does nothing.
  /// When the callback applied its own list with [updateListItems], that
  /// list is kept: its edited item (equal, else the same label) is reselected,
  /// and without one [item] is replaced only if the list still holds it.
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
    final bool selectedBefore = _isSelectedRow(item);
    await onEditItem?.call(item, newValue);
    if (isDisposed) {
      return;
    }
    if (generation != _listGeneration) {
      _keepRefreshedEdit(item, newValue, wasSelected: selectedBefore);
      return;
    }
    // The row the user saw as selected, with the rule of [isSelected] over
    // the list before it is written.
    final bool wasSelected = _isSelectedRow(item);
    final ValueItem<T> edited = replaceItem(_items, item, newValue);
    _engine.forget(item);
    _refresh();
    if (wasSelected) {
      _reselectEdited(edited);
    }
  }

  /// Whether [item] is the row shown as selected, with the rule of
  /// [isSelected] over the current list.
  bool _isSelectedRow(ValueItem<T> item) {
    final ValueItem<T>? selected = _selectedItem;
    return selected != null &&
        _selects(item, selected, exactInPool: _items.contains(selected));
  }

  /// Finishes an edit whose callback applied its own list: an edited item
  /// that list holds stays as it is (reselected when [from] was selected);
  /// without one, [from] is replaced only if the list still holds it, so an
  /// item the list dropped never comes back.
  void _keepRefreshedEdit(
    ValueItem<T> from,
    ValueItem<T> to, {
    required bool wasSelected,
  }) {
    _engine.forget(from);
    ValueItem<T>? edited = counterpartOf(_items, to, _engine);
    if (edited == null && _items.contains(from)) {
      edited = replaceItem(_items, from, to);
      _refresh();
    }
    if (wasSelected && edited != null) {
      _reselectEdited(edited);
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
    notifyListeners();
  }

  // ------------------------------------------------------------ open/close

  /// Prepares the list when the search view opens: shows every item of
  /// [items] (the selected label is not a query).
  void onSearchOpen() {
    _viewOpen = true;
    _filterArmed = true;
    _highlight.value = -1;
    final ValueItem<T>? selected = _selectedItem;
    final String text = localSearchController.text;
    final bool showsSelection = selected != null && text == selected.label;
    _untouchedLabel = showsSelection ? text : null;
    // Every change to [items] already rebuilt the base (see [_lastQuery]).
    _applyFilter();
    if (showsSelection) {
      // Typing replaces the selected label instead of appending to it.
      _editText(
        () => localSearchController.selection = TextSelection(
          baseOffset: 0,
          extentOffset: text.length,
        ),
      );
    }
  }

  /// Restores or clears the text when the search view closes.
  void onSearchClose(bool clearOnClose) {
    _viewOpen = false;
    _untouchedLabel = null;
    if (!isDisposed) {
      _highlight.value = -1;
    }
    if (!clearOnClose) {
      return;
    }
    _editText(() {
      final String text = localSearchController.text;
      if (text.isEmpty) {
        return;
      }
      final ValueItem<T>? selected = _selectedItem;
      if (selected == null) {
        localSearchController.text = '';
      } else if (text != selected.label) {
        localSearchController.text = selected.label;
      }
    });
  }

  // ------------------------------------------------------------- lifecycle

  @override
  void dispose() {
    if (isDisposed) {
      return;
    }
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
