import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';
import 'package:simple_search_dropdown/simple_search_dropdown.dart';

/// A single-selection dropdown with a search bar, built on [SearchAnchor].
///
/// All state lives in [controller]; this widget rebuilds when it notifies.
class SearchDropDown<T> extends StatefulWidget {
  /// Creates a single-selection dropdown driven by [controller].
  const SearchDropDown({
    super.key,
    required this.controller,
    this.searchBarSettings = defaultSearchBarSettings,
    this.overlayListSettings = defaultOverlaySettings,
    Widget? addAdditionalWidget,
    Widget? defaultAdditionalWidget,
    @Deprecated('Use addAdditionalWidget. Will be removed in 9.0.0')
    Widget? addAditionalWidget,
    @Deprecated('Use defaultAdditionalWidget. Will be removed in 9.0.0')
    Widget? defaultAditionalWidget,
    this.disposeController = true,
    this.removeFocus = true,
    this.strings,
  }) : addAdditionalWidget = addAdditionalWidget ?? addAditionalWidget,
       defaultAdditionalWidget =
           defaultAdditionalWidget ?? defaultAditionalWidget;

  /// Holds items, selection and search text.
  final SearchDropDownController<T> controller;

  /// Visual and behavioural settings of the search bar.
  final SimpleSearchbarSettings searchBarSettings;

  /// Visual and behavioural settings of the list.
  final SimpleOverlaySettings overlayListSettings;

  /// Widget shown on the add-item row, between the text and the create button.
  final Widget? addAdditionalWidget;

  /// Widget shown on every item row, between the text and the delete button.
  final Widget? defaultAdditionalWidget;

  /// Deprecated alias of [addAdditionalWidget].
  @Deprecated('Use addAdditionalWidget. Will be removed in 9.0.0')
  Widget? get addAditionalWidget => addAdditionalWidget;

  /// Deprecated alias of [defaultAdditionalWidget].
  @Deprecated('Use defaultAdditionalWidget. Will be removed in 9.0.0')
  Widget? get defaultAditionalWidget => defaultAdditionalWidget;

  /// Dispose [controller] together with this widget (default: `true`).
  final bool disposeController;

  /// Remove the focus from the bar after the list closes (default: `true`).
  final bool removeFocus;

  /// Texts used by this dropdown. Defaults to [SearchDropDownStrings.of].
  final SearchDropDownStrings? strings;

  @override
  State<SearchDropDown<T>> createState() => SearchDropDownState<T>();
}

/// State of [SearchDropDown].
///
/// Prefer the [SearchDropDownController] API; the methods here only forward
/// to it and remain for `GlobalKey` users.
class SearchDropDownState<T> extends State<SearchDropDown<T>> {
  final FocusScopeNode _focusNode = FocusScopeNode();
  Timer? _unfocusWindow;

  SearchDropDownController<T> get _controller => widget.controller;

  @override
  void dispose() {
    _unfocusWindow?.cancel();
    if (widget.disposeController) {
      // As in 7.x: only the current controller; a swapped-out one may still
      // be used by its owner (or by a view that is closing).
      _controller.dispose();
    }
    _focusNode.dispose();
    super.dispose();
  }

  /// Toggles enabled/disabled.
  @Deprecated('Use controller.toggleEnabled(). Will be removed in 9.0.0')
  void enableDisable() => _controller.toggleEnabled();

  /// Clears the selection.
  @Deprecated('Use controller.resetSelection(). Will be removed in 9.0.0')
  void resetSelection() => _controller.resetSelection();

  /// Replaces the items.
  @Deprecated('Use controller.updateListItems(). Will be removed in 9.0.0')
  void updateList(List<ValueItem<T>> newList, {bool shouldreset = true}) =>
      _controller.updateListItems(newList, shouldreset);

  void _onOpen() {
    _unfocusWindow?.cancel();
    _controller.onSearchOpen();
  }

  void _onClose() {
    _controller.onSearchClose(widget.searchBarSettings.clearOnClose);
    if (widget.removeFocus) {
      // Focus returns to the bar when the view's route pops; drop it then.
      _unfocusWindow?.cancel();
      _unfocusWindow = Timer(const Duration(milliseconds: 600), () {});
    }
  }

  void _onFocusChange(bool focused) {
    if (focused && (_unfocusWindow?.isActive ?? false)) {
      _unfocusWindow?.cancel();
      _focusNode.unfocus();
    }
  }

  bool get _clearEnabled => widget.searchBarSettings.showClearIcon;

  @override
  Widget build(BuildContext context) {
    final SearchDropDownStrings strings =
        widget.strings ?? SearchDropDownStrings.of(context);
    return FocusScope(
      node: _focusNode,
      onFocusChange: _onFocusChange,
      child: ListenableBuilder(
        listenable: _controller,
        builder: (BuildContext context, _) => _buildAnchor(strings),
      ),
    );
  }

  Widget _buildAnchor(SearchDropDownStrings strings) {
    final SimpleSearchbarSettings bar = widget.searchBarSettings;
    final SimpleOverlaySettings list = widget.overlayListSettings;
    final SearchController search = _controller.localSearchController;
    final String hint = bar.customHint ?? strings.searchHint;
    final Color viewBackground =
        list.dialogBackgroundColor ?? bar.backgroundColor;
    return SizedBox(
      width: bar.dropdownWidth,
      height: bar.dropdownHeight,
      child: SearchAnchor.bar(
        enabled: _controller.enabled,
        searchController: search,
        viewConstraints: BoxConstraints(
          maxWidth: bar.dropdownWidth,
          maxHeight: list.dialogHeight,
        ),
        onOpen: _onOpen,
        onClose: _onClose,
        onSubmitted: (_) => _controller.submit(),
        viewHeaderHeight: bar.dropdownHeight,
        dividerColor: bar.showDivider ? null : viewBackground,
        viewTrailing: <Widget>[
          _ViewTrailing<T>(
            controller: _controller,
            settings: bar,
            strings: strings,
            showClear: _clearEnabled,
          ),
        ],
        barTrailing:
            bar.actions ??
            <Widget>[
              if (bar.showArrow && _controller.enabled)
                IconButton(
                  tooltip: strings.openTooltip,
                  onPressed: bar.dropdownClosedIconFunction ?? search.openView,
                  icon: Icon(
                    bar.dropdownClosedArrowIcon,
                    color: bar.outsideIconColor,
                    size: bar.outsideIconSize,
                  ),
                ),
              if (_clearEnabled)
                ClearButton(
                  visible: _controller.clearVisible,
                  onPressed: _controller.resetSelection,
                  iconColor: bar.clearIconColor,
                  iconSize: bar.outsideIconSize,
                  tooltip: strings.clearTooltip,
                ),
            ],
        barElevation: WidgetStatePropertyAll<double>(bar.elevation),
        barShape: WidgetStatePropertyAll<OutlinedBorder>(bar.border),
        viewShape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(10)),
        ),
        barBackgroundColor: WidgetStatePropertyAll<Color>(bar.backgroundColor),
        viewBackgroundColor: viewBackground,
        isFullScreen: list.openFullScreen,
        barHintStyle: WidgetStatePropertyAll<TextStyle?>(bar.hintStyle),
        barHintText: hint,
        barOverlayColor: WidgetStatePropertyAll<Color>(bar.hoverColor),
        barTextStyle: WidgetStatePropertyAll<TextStyle?>(
          bar.searchBarTextStyle,
        ),
        barPadding: WidgetStatePropertyAll<EdgeInsetsGeometry?>(
          bar.searchBarPadding,
        ),
        barLeading: const SizedBox.shrink(),
        viewSide: const BorderSide(style: BorderStyle.none),
        viewLeading: const SizedBox.shrink(),
        viewElevation: bar.elevation,
        viewHintText: hint,
        viewHeaderHintStyle: bar.hintStyle,
        viewHeaderTextStyle: bar.searchBarTextStyle,
        keyboardType: bar.showKeyboardOnTap
            ? bar.keyboardType
            : TextInputType.none,
        textInputAction: bar.textInputAction,
        // The list is built by viewBuilder from the controller; the
        // suggestions only tell SearchAnchor whether there is content.
        suggestionsBuilder: (BuildContext context, SearchController search) =>
            _controller.filteredItems.isNotEmpty || _showAddRow(search.text)
            ? const <Widget>[SizedBox.shrink()]
            : const <Widget>[],
        // SearchAnchor calls this on every frame of its open animation;
        // returning the same instance lets Flutter skip rebuilding the rows.
        viewBuilder: (Iterable<Widget> suggestions) => _viewList(strings),
      ),
    );
  }

  _ViewList<T>? _cachedViewList;

  _ViewList<T> _viewList(SearchDropDownStrings strings) {
    final _ViewList<T>? cached = _cachedViewList;
    if (cached != null &&
        identical(cached.controller, _controller) &&
        identical(cached.settings, widget.overlayListSettings) &&
        identical(cached.strings, strings) &&
        identical(cached.addAdditionalWidget, widget.addAdditionalWidget) &&
        identical(
          cached.defaultAdditionalWidget,
          widget.defaultAdditionalWidget,
        )) {
      return cached;
    }
    return _cachedViewList = _ViewList<T>(
      controller: _controller,
      settings: widget.overlayListSettings,
      strings: strings,
      showAddRow: _showAddRow,
      addAdditionalWidget: widget.addAdditionalWidget,
      defaultAdditionalWidget: widget.defaultAdditionalWidget,
    );
  }

  bool _showAddRow(String text) =>
      _controller.addMode &&
      text.isNotEmpty &&
      _controller.filteredItems.isEmpty;
}

/// Trailing icons of the open view; rebuilt from the controller because
/// [SearchAnchor] keeps the widgets it was opened with.
class _ViewTrailing<T> extends StatelessWidget {
  const _ViewTrailing({
    required this.controller,
    required this.settings,
    required this.strings,
    required this.showClear,
  });

  final SearchDropDownController<T> controller;
  final SimpleSearchbarSettings settings;
  final SearchDropDownStrings strings;
  final bool showClear;

  @override
  Widget build(BuildContext context) {
    final SearchController search = controller.localSearchController;
    return ListenableBuilder(
      listenable: controller,
      builder: (BuildContext context, _) => Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          if (settings.showArrow)
            IconButton(
              tooltip: strings.closeTooltip,
              onPressed:
                  settings.dropdownOpenedIconFunction ??
                  () => search.closeView(search.text),
              icon: Icon(
                settings.dropdownOpenedArrowIcon,
                color: settings.outsideIconColor,
                size: settings.outsideIconSize,
              ),
            ),
          if (showClear)
            ClearButton(
              visible: controller.clearVisible,
              onPressed: controller.resetSelection,
              iconColor: settings.clearIconColor,
              iconSize: settings.outsideIconSize,
              tooltip: strings.clearTooltip,
            ),
        ],
      ),
    );
  }
}

/// The list inside the open view: lazy, scrolled to the selection on open,
/// with keyboard navigation while this view is the current route.
class _ViewList<T> extends StatefulWidget {
  const _ViewList({
    required this.controller,
    required this.settings,
    required this.strings,
    required this.showAddRow,
    required this.addAdditionalWidget,
    required this.defaultAdditionalWidget,
  });

  final SearchDropDownController<T> controller;
  final SimpleOverlaySettings settings;
  final SearchDropDownStrings strings;
  final bool Function(String text) showAddRow;
  final Widget? addAdditionalWidget;
  final Widget? defaultAdditionalWidget;

  @override
  State<_ViewList<T>> createState() => _ViewListState<T>();
}

class _ViewListState<T> extends State<_ViewList<T>> {
  final ItemScrollController _scroll = ItemScrollController();
  final ItemPositionsListener _positions = ItemPositionsListener.create();
  late final int _initialIndex;

  /// The items shown: a copy of `filteredItems` taken on each results
  /// notification. A change made during a build updates `filteredItems` at
  /// once but notifies after the frame, and this frame's lazy layout must
  /// keep reading the list its item count came from.
  List<ValueItem<T>> _items = const [];

  /// Item rows by index. The list re-runs its item builder on every layout
  /// change (e.g. the view's open animation) and keystroke; handing back the
  /// same widget skips rebuilding the row. Cleared when the results change.
  final Map<int, Widget> _rows = <int, Widget>{};
  late Listenable _rowInputs;

  /// The list depends on the results and, for the add row, on the text.
  late Listenable _listInputs;

  /// The controller the listeners below are attached to.
  late SearchDropDownController<T> _bound;

  SearchDropDownController<T> get _controller => widget.controller;

  @override
  void initState() {
    super.initState();
    final int selected = _controller.selectedIndex;
    _initialIndex = selected < 0 ? 0 : selected;
    _bind(_controller);
    HardwareKeyboard.instance.addHandler(_handleKey);
  }

  void _bind(SearchDropDownController<T> controller) {
    _bound = controller;
    _rowInputs = Listenable.merge(<Listenable>[
      controller.highlight,
      controller,
    ]);
    _listInputs = Listenable.merge(<Listenable>[
      controller.results,
      controller.localSearchController,
    ]);
    controller.highlight.addListener(_revealHighlight);
    controller.results.addListener(_onResults);
    _onResults();
  }

  void _onResults() {
    _items = List<ValueItem<T>>.of(_bound.filteredItems);
    _rows.clear();
  }

  void _unbind() {
    if (!_bound.isDisposed) {
      _bound.highlight.removeListener(_revealHighlight);
      _bound.results.removeListener(_onResults);
    }
  }

  @override
  void didUpdateWidget(covariant _ViewList<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    _rows.clear();
    if (!identical(_bound, widget.controller)) {
      _unbind();
      _bind(widget.controller);
    }
  }

  @override
  void dispose() {
    HardwareKeyboard.instance.removeHandler(_handleKey);
    _unbind();
    super.dispose();
  }

  bool _handleKey(KeyEvent event) {
    if (event is! KeyDownEvent || !mounted) {
      return false;
    }
    if (!(ModalRoute.of(context)?.isCurrent ?? false)) {
      return false;
    }
    if (_controller.localSearchController.value.composing.isValid) {
      return false;
    }
    final LogicalKeyboardKey key = event.logicalKey;
    if (key == LogicalKeyboardKey.arrowDown) {
      _controller.highlightNext();
    } else if (key == LogicalKeyboardKey.arrowUp) {
      _controller.highlightPrevious();
    } else if (key == LogicalKeyboardKey.pageDown) {
      _controller.highlightEdge(last: true);
    } else if (key == LogicalKeyboardKey.pageUp) {
      _controller.highlightEdge(last: false);
    } else if (key == LogicalKeyboardKey.enter ||
        key == LogicalKeyboardKey.numpadEnter) {
      _controller.submit();
    } else {
      return false;
    }
    return true;
  }

  void _revealHighlight() {
    final int index = _controller.highlightedIndex;
    if (index < 0 || !_scroll.isAttached) {
      return;
    }
    final bool visible = _positions.itemPositions.value.any(
      (ItemPosition p) =>
          p.index == index && p.itemLeadingEdge >= 0 && p.itemTrailingEdge <= 1,
    );
    if (!visible) {
      _scroll.scrollTo(
        index: index,
        alignment: 0.5,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return MediaQuery.removePadding(
      context: context,
      removeTop: true,
      child: ListenableBuilder(
        listenable: _listInputs,
        builder: (BuildContext context, _) {
          final List<ValueItem<T>> items = _items;
          final String text = _controller.localSearchController.text;
          final bool addRow = items.isEmpty && widget.showAddRow(text);
          return ScrollablePositionedList.builder(
            itemScrollController: _scroll,
            itemPositionsListener: _positions,
            initialScrollIndex: _initialIndex < items.length
                ? _initialIndex
                : 0,
            padding: EdgeInsets.only(
              bottom: MediaQuery.viewInsetsOf(context).bottom,
            ),
            itemCount: items.length + (addRow ? 1 : 0),
            itemBuilder: (BuildContext context, int index) =>
                index == items.length
                ? _buildAddRow(context, text)
                : _rows[index] ??= _buildRow(context, items[index], index),
          );
        },
      ),
    );
  }

  Widget _buildAddRow(BuildContext context, String text) => DefaultAddListItem(
    text: text,
    addAdditionalWidget: widget.addAdditionalWidget,
    overlayListSettings: widget.settings,
    strings: widget.strings,
    itemAdded: (String input) =>
        _controller.addItem(input, context, strings: widget.strings),
  );

  Widget _buildRow(BuildContext context, ValueItem<T> item, int index) {
    return ListenableBuilder(
      listenable: _rowInputs,
      builder: (BuildContext context, _) => DefaultListTile<T>(
        deleteMode: _controller.deleteMode,
        editMode: _controller.editMode,
        item: item,
        overlayListSettings: widget.settings,
        defaultAdditionalWidget: widget.defaultAdditionalWidget,
        strings: widget.strings,
        onDelete: (ValueItem<T> value) =>
            _controller.deleteItem(value, context, strings: widget.strings),
        onEdit: (ValueItem<T> value) =>
            _controller.editItem(value, context, strings: widget.strings),
        onPressed: _controller.selectItem,
        selected: _controller.isSelected(item),
        highlighted: index == _controller.highlightedIndex,
      ),
    );
  }
}
