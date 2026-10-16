import 'package:flutter/material.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';
import 'package:simple_search_dropdown/simple_search_dropdown.dart';

/// The open list of a [MultipleSearchDropDown]: a search field and the items.
class MultipleListView<T> extends StatefulWidget {
  /// Creates the list for [controller], or, without one, for the deprecated
  /// 7.x parameters ([listItens], [selectedItens] and the callbacks), which
  /// it only reads: taps, adds, edits and deletes just call your callbacks.
  const MultipleListView({
    super.key,
    this.controller,
    required this.overlayListSettings,
    required this.searchBarSettings,
    Widget? addAdditionalWidget,
    Widget? defaultAdditionalWidget,
    this.strings,
    @Deprecated(_legacyHint) bool? addMode,
    @Deprecated(_legacyHint) bool? editMode,
    @Deprecated(_legacyHint) bool? deleteMode,
    @Deprecated(_legacyHint) List<ValueItem<T>>? listItens,
    @Deprecated(_legacyHint) List<ValueItem<T>>? selectedItens,
    @Deprecated(_legacyHint) Function(ValueItem<T> value)? onAddItem,
    @Deprecated(_legacyHint) Function(ValueItem<T> value)? onDeleteItem,
    @Deprecated(_legacyHint) Function(ValueItem<T> value)? onEditItem,
    @Deprecated(_legacyHint) Function(ValueItem<T> value)? onItemSelected,
    @Deprecated(_legacyHint) int? sortType,
    @Deprecated(_legacyHint) ValueItem<T> Function(String input)? newValueItem,
    @Deprecated('Use addAdditionalWidget. Will be removed in 9.0.0')
    Widget? addAditionalWidget,
    @Deprecated('Use defaultAdditionalWidget. Will be removed in 9.0.0')
    Widget? defaultAditionalWidget,
  }) : assert(
         controller != null ||
             (listItens != null &&
                 selectedItens != null &&
                 onAddItem != null &&
                 onDeleteItem != null &&
                 onEditItem != null &&
                 onItemSelected != null),
         'Pass controller, or the 7.x listItens, selectedItens, onAddItem, '
         'onDeleteItem, onEditItem and onItemSelected',
       ),
       addAdditionalWidget = addAdditionalWidget ?? addAditionalWidget,
       defaultAdditionalWidget =
           defaultAdditionalWidget ?? defaultAditionalWidget,
       _addMode = addMode ?? false,
       _editMode = editMode ?? false,
       _deleteMode = deleteMode ?? false,
       _listItens = listItens,
       _selectedItens = selectedItens,
       _onAddItem = onAddItem,
       _onDeleteItem = onDeleteItem,
       _onEditItem = onEditItem,
       _onItemSelected = onItemSelected,
       _sortType = sortType ?? 0,
       _newValueItem = newValueItem;

  static const String _legacyHint =
      'Use MultipleSearchDropDown or pass controller. Will be removed in 9.0.0';

  /// Source of items, selection and filtering; `null` uses the deprecated
  /// 7.x parameters.
  final MultipleSearchDropDownController<T>? controller;

  /// The settings for the overlay list of items.
  final SimpleOverlaySettings overlayListSettings;

  /// The settings of the search bar.
  final SimpleSearchbarSettings searchBarSettings;

  /// Widget shown on the add-item row.
  final Widget? addAdditionalWidget;

  /// Widget shown on every item row.
  final Widget? defaultAdditionalWidget;

  /// Source of the default texts; `null` uses [SearchDropDownStringsScope]
  /// (Portuguese without one).
  final SearchDropDownStrings? strings;

  // The 7.x parameters, used only without a controller.
  final bool _addMode;
  final bool _editMode;
  final bool _deleteMode;
  final List<ValueItem<T>>? _listItens;
  final List<ValueItem<T>>? _selectedItens;
  final Function(ValueItem<T> value)? _onAddItem;
  final Function(ValueItem<T> value)? _onDeleteItem;
  final Function(ValueItem<T> value)? _onEditItem;
  final Function(ValueItem<T> value)? _onItemSelected;
  final int _sortType;
  final ValueItem<T> Function(String input)? _newValueItem;

  /// Deprecated alias of [addAdditionalWidget].
  @Deprecated('Use addAdditionalWidget. Will be removed in 9.0.0')
  Widget? get addAditionalWidget => addAdditionalWidget;

  /// Deprecated alias of [defaultAdditionalWidget].
  @Deprecated('Use defaultAdditionalWidget. Will be removed in 9.0.0')
  Widget? get defaultAditionalWidget => defaultAdditionalWidget;

  /// The items: the controller's `listItems`, else the 7.x parameter.
  @Deprecated(_legacyHint)
  List<ValueItem<T>> get listItens =>
      controller?.listItems ?? _listItens ?? <ValueItem<T>>[];

  /// The selection: the controller's `selectedItems`, else the 7.x parameter.
  @Deprecated(_legacyHint)
  List<ValueItem<T>> get selectedItens =>
      controller?.selectedItems ?? _selectedItens ?? <ValueItem<T>>[];

  /// Whether items can be added (the controller's, else the 7.x parameter).
  @Deprecated(_legacyHint)
  bool get addMode => controller?.addMode ?? _addMode;

  /// Whether items can be edited (the controller's, else the 7.x parameter).
  @Deprecated(_legacyHint)
  bool get editMode => controller?.editMode ?? _editMode;

  /// Whether items can be deleted (the controller's, else the 7.x parameter).
  @Deprecated(_legacyHint)
  bool get deleteMode => controller?.deleteMode ?? _deleteMode;

  /// The add callback (the controller's, else the 7.x parameter); never null.
  @Deprecated(_legacyHint)
  Function(ValueItem<T> value) get onAddItem =>
      (controller == null ? _onAddItem : controller!.onAddItem) ?? _ignore;

  /// The delete callback (the controller's, else the 7.x parameter); never
  /// null.
  @Deprecated(_legacyHint)
  Function(ValueItem<T> value) get onDeleteItem =>
      (controller == null ? _onDeleteItem : controller!.onDeleteItem) ??
      _ignore;

  /// The 7.x edit callback; the controller's has another signature, so with
  /// a controller this is the 7.x parameter or a no-op.
  @Deprecated(_legacyHint)
  Function(ValueItem<T> value) get onEditItem => _onEditItem ?? _ignore;

  /// The 7.x tap callback; the controller has none, so with a controller
  /// this is the 7.x parameter or a no-op.
  @Deprecated(_legacyHint)
  Function(ValueItem<T> value) get onItemSelected => _onItemSelected ?? _ignore;

  /// The legacy `int` sort type (0-3): the controller's `sort`, else the 7.x
  /// parameter.
  @Deprecated(_legacyHint)
  int get sortType => controller?.sort.legacyValue ?? _sortType;

  /// Creates an item from input (the controller's, else the 7.x parameter).
  @Deprecated(_legacyHint)
  ValueItem<T> Function(String input)? get newValueItem =>
      controller == null ? _newValueItem : controller!.newValueItem;

  static void _ignore(Object? _) {}

  @override
  State<MultipleListView<T>> createState() => _MultipleListViewState<T>();
}

class _MultipleListViewState<T> extends State<MultipleListView<T>> {
  final TextEditingController _search = TextEditingController();
  final ItemScrollController _scroll = ItemScrollController();
  // The overlay lives outside any route, so the list brings its own storage.
  final PageStorageBucket _bucket = PageStorageBucket();

  /// Drives the list built with the 7.x parameters.
  _LegacyListController<T>? _legacy;

  MultipleSearchDropDownController<T> get _controller =>
      widget.controller ?? _legacy!;

  @override
  void initState() {
    super.initState();
    if (widget.controller == null) {
      _legacy = _LegacyListController<T>(widget);
    }
    _controller
      ..refresh()
      ..addListener(_syncField);
    WidgetsBinding.instance.addPostFrameCallback((_) => _goToSelected());
  }

  @override
  void didUpdateWidget(covariant MultipleListView<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    final MultipleSearchDropDownController<T> old =
        oldWidget.controller ?? _legacy!;
    if (widget.controller == null) {
      _legacy == null
          ? _legacy = _LegacyListController<T>(widget)
          : _legacy!.update(widget);
    }
    if (identical(old, _controller)) {
      return;
    }
    // The parent may have disposed the old controller already.
    if (!old.isDisposed) {
      old.removeListener(_syncField);
    }
    if (widget.controller != null && _legacy != null) {
      _legacy!.dispose();
      _legacy = null;
    }
    // A swapped-in controller opens fresh (re-reads its items, like
    // initState) but keeps what the user typed, so field and list agree.
    _controller
      ..refresh()
      ..addListener(_syncField);
    if (_search.text.isNotEmpty) {
      _controller.search(_search.text);
    }
    WidgetsBinding.instance.addPostFrameCallback((_) => _goToSelected());
  }

  @override
  void dispose() {
    if (!_controller.isDisposed) {
      _controller.removeListener(_syncField);
    }
    _legacy?.dispose();
    _search.dispose();
    super.dispose();
  }

  /// Shows the controller's query in the field: an add clears both once it
  /// is done (a rejected item at once, #13), a failed one keeps both.
  /// Assigning the value does not fire `onChanged`, and typing already makes
  /// them equal, so this never loops nor touches an IME composition.
  void _syncField() {
    final String query = _controller.query;
    if (_search.text != query) {
      _search.value = TextEditingValue(
        text: query,
        selection: TextSelection.collapsed(offset: query.length),
      );
    }
  }

  /// Scrolls to the first selected item when the list (re)opens.
  void _goToSelected() {
    if (!mounted || _controller.selectedItems.isEmpty || !_scroll.isAttached) {
      return;
    }
    final int index = _controller.filteredItems.indexOf(
      _controller.selectedItems.first,
    );
    if (index > 1) {
      _scroll.scrollTo(
        index: index,
        duration: widget.overlayListSettings.reOpenedScrollDuration,
        curve: Curves.ease,
      );
    }
  }

  Future<void> _add(String text) =>
      _controller.addItem(text, context, strings: widget.strings);

  @override
  Widget build(BuildContext context) {
    final SimpleSearchbarSettings bar = widget.searchBarSettings;
    final SimpleOverlaySettings list = widget.overlayListSettings;
    final Color background = list.dialogBackgroundColor ?? bar.backgroundColor;
    final SearchDropDownStrings texts =
        widget.strings ?? SearchDropDownStrings.of(context);
    return Card(
      surfaceTintColor: background,
      color: background,
      elevation: bar.elevation,
      child: AnimatedContainer(
        duration: list.animationDuration,
        height: list.dialogHeight,
        width: bar.dropdownWidth,
        child: Column(
          children: <Widget>[
            SearchBar(
              controller: _search,
              backgroundColor: WidgetStatePropertyAll<Color>(
                bar.backgroundColor,
              ),
              overlayColor: WidgetStatePropertyAll<Color>(
                list.unselectedItemHoverColor,
              ),
              constraints: BoxConstraints(
                minHeight: bar.dropdownHeight,
                maxWidth: bar.dropdownWidth,
              ),
              surfaceTintColor: WidgetStatePropertyAll<Color>(
                bar.backgroundColor,
              ),
              shape: WidgetStatePropertyAll<OutlinedBorder>(bar.border),
              hintText: bar.customHint ?? texts.searchHint,
              hintStyle: WidgetStatePropertyAll<TextStyle?>(bar.hintStyle),
              textStyle: WidgetStatePropertyAll<TextStyle?>(
                bar.searchBarTextStyle ?? bar.hintStyle,
              ),
              side: const WidgetStatePropertyAll<BorderSide>(
                BorderSide(style: BorderStyle.none),
              ),
              onChanged: _controller.search,
              elevation: WidgetStatePropertyAll<double>(bar.elevation),
            ),
            const SizedBox(height: 5),
            Expanded(
              child: PageStorage(
                bucket: _bucket,
                child: ListenableBuilder(
                  listenable: _controller,
                  builder: (BuildContext context, _) {
                    final List<ValueItem<T>> items = _controller.filteredItems;
                    return ScrollablePositionedList.separated(
                      itemScrollController: _scroll,
                      padding: EdgeInsets.zero,
                      itemCount: items.length + (_controller.addMode ? 1 : 0),
                      separatorBuilder: (BuildContext context, int index) =>
                          SizedBox(height: list.separatorHeight),
                      itemBuilder: (BuildContext context, int index) {
                        if (index == items.length) {
                          return _controller.canAdd
                              ? DefaultAddListItem(
                                  itemAdded: _add,
                                  overlayListSettings: list,
                                  text: _controller.query,
                                  addAdditionalWidget:
                                      widget.addAdditionalWidget,
                                  strings: texts,
                                )
                              : const SizedBox.shrink();
                        }
                        final ValueItem<T> item = items[index];
                        return DefaultListTile<T>(
                          // The row state (its spinner) belongs to the
                          // item, not the index.
                          key: ValueKey<ValueItem<T>>(item),
                          deleteMode: _controller.deleteMode,
                          editMode: _controller.editMode,
                          item: item,
                          onDelete: (ValueItem<T> value) =>
                              _controller.deleteItem(
                                value,
                                context,
                                strings: widget.strings,
                              ),
                          onEdit: (ValueItem<T> value) => _controller.editItem(
                            value,
                            context,
                            strings: widget.strings,
                          ),
                          onPressed: _controller.toggle,
                          overlayListSettings: list,
                          selected: _controller.isSelected(item),
                          defaultAdditionalWidget:
                              widget.defaultAdditionalWidget,
                          strings: texts,
                        );
                      },
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The controller of a [MultipleListView] built with the 7.x parameters.
///
/// It shares the caller's lists and only reads them, like 7.x: a tap, add,
/// edit or delete calls the widget's callback (no dialog, no write to the
/// lists) and then redraws from the lists the callback may have changed.
/// Matching does not trim, as in 7.x.
class _LegacyListController<T> extends MultipleSearchDropDownController<T> {
  _LegacyListController(this._view)
    : super(
        listItems: _view._listItens!,
        selectedItems: _view._selectedItens!,
        addMode: _view._addMode,
        deleteMode: _view._deleteMode,
        editMode: _view._editMode,
        sort: SortType.fromLegacy(_view._sortType),
        // Never called (the overrides below use the widget's callbacks);
        // they only satisfy the mode asserts.
        newValueItem: (String text) => ValueItem<T>(label: text),
        onAddItem: (ValueItem<T> _) {},
        onDeleteItem: (ValueItem<T> _) {},
        onEditItem: (ValueItem<T> a, ValueItem<T> b) {},
        trim: false,
      );

  MultipleListView<T> _view;

  /// Applies a rebuilt [view]: its lists, modes and sort.
  void update(MultipleListView<T> view) {
    _view = view;
    replaceSources(
      listItems: view._listItens,
      selectedItems: view._selectedItens,
    );
    addMode = view._addMode;
    deleteMode = view._deleteMode;
    editMode = view._editMode;
    sort = SortType.fromLegacy(view._sortType);
  }

  /// Re-reads the lists the callback may have changed, keeping the search
  /// unless [clearSearch], and redraws (the selection may have changed).
  void _redraw({bool clearSearch = false}) {
    if (isDisposed) {
      return;
    }
    clearSearch ? refresh() : search(query);
    notifyListeners();
  }

  @override
  void toggle(ValueItem<T> item, {bool forced = false}) {
    _view._onItemSelected!(item);
    _redraw();
  }

  @override
  Future<void> addItem(
    String text,
    BuildContext context, {
    SearchDropDownStrings? strings,
  }) async {
    final ValueItem<T> Function(String)? create = _view._newValueItem;
    if (create == null) {
      return;
    }
    await _view._onAddItem!(create(text));
    _redraw(clearSearch: true);
  }

  @override
  Future<void> deleteItem(
    ValueItem<T> item,
    BuildContext context, {
    SearchDropDownStrings? strings,
  }) async {
    await _view._onDeleteItem!(item);
    _redraw();
  }

  @override
  Future<void> editItem(
    ValueItem<T> item,
    BuildContext context, {
    SearchDropDownStrings? strings,
  }) async {
    await _view._onEditItem!(item);
    _redraw();
  }
}
