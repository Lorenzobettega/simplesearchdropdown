import 'package:flutter/material.dart';
import 'package:simple_search_dropdown/simple_search_dropdown.dart';

/// A multiple-selection dropdown: selected items show as chips in the box and
/// the list opens below it with a search field.
///
/// Drive it with a [MultipleSearchDropDownController], or with the 7.x
/// parameters ([listItems], [selectedItems], [updateSelectedItems], ...),
/// which build a controller internally.
class MultipleSearchDropDown<T> extends StatefulWidget {
  /// Creates a multiple-selection dropdown.
  const MultipleSearchDropDown({
    super.key,
    this.controller,
    this.listItems,
    this.addMode = true,
    this.onAddItem,
    this.newValueItem,
    this.deleteMode = true,
    this.onDeleteItem,
    this.editMode = false,
    this.onEditItem,
    this.onClearItem,
    this.onClearList,
    this.updateSelectedItems,
    @Deprecated('Use sort. Will be removed in 9.0.0') int? sortType,
    SortType sort = SortType.none,
    this.confirmDelete = false,
    this.selectedItems,
    this.deleteDialogSettings,
    this.verifyInputItem,
    this.verifyDialogSettings,
    this.searchBarSettings = defaultSearchBarSettings,
    this.overlayListSettings = defaultOverlaySettings,
    Widget? addAdditionalWidget,
    Widget? defaultAdditionalWidget,
    @Deprecated('Use addAdditionalWidget. Will be removed in 9.0.0')
    Widget? addAditionalWidget,
    @Deprecated('Use defaultAdditionalWidget. Will be removed in 9.0.0')
    Widget? defaultAditionalWidget,
    this.enabled = true,
    this.strings,
  }) : _legacySortType = sortType,
       _sort = sort,
       addAdditionalWidget = addAdditionalWidget ?? addAditionalWidget,
       defaultAdditionalWidget =
           defaultAdditionalWidget ?? defaultAditionalWidget,
       assert(
         controller != null ||
             (listItems != null &&
                 selectedItems != null &&
                 updateSelectedItems != null),
         'Pass a controller, or listItems + selectedItems + updateSelectedItems',
       ),
       assert(
         controller != null ||
             (addMode && (newValueItem != null && onAddItem != null)) ||
             !addMode,
         'addMode can only be used with newValueItem != null && onAddItem != null',
       ),
       assert(
         controller != null ||
             (deleteMode && onDeleteItem != null) ||
             !deleteMode,
         'deleteMode can only be used with onDeleteItem != null',
       ),
       assert(
         controller != null || (editMode && onEditItem != null) || !editMode,
         'editMode can only be used with onEditItem != null',
       );

  /// Holds items, selection and search. When set, the 7.x data parameters
  /// below are ignored.
  final MultipleSearchDropDownController<T>? controller;

  ///List of the items to be presented on the dropdown.
  final List<ValueItem<T>>? listItems;

  ///List of the items already selected on the dropdown (updated in place).
  final List<ValueItem<T>>? selectedItems;

  ///Function to update the list of selected items on change.
  final Function(List<ValueItem<T>>)? updateSelectedItems;

  ///Allow the user to add items to the list.
  final bool addMode;

  ///Function to be executed after the item was added.
  final Function(ValueItem<T>)? onAddItem;

  ///Function that defines how the user input transforms into a new ValueItem on the list.
  ///
  ///Ex:`newValueItem: (input) => ValueItem(label: input, value: input)`
  final ValueItem<T> Function(String input)? newValueItem;

  ///Allow the user to delete items of the list.
  final bool deleteMode;

  ///Function to be executed after the item was deleted.
  final Function(ValueItem<T>)? onDeleteItem;

  ///Allow the user to edit items of the list.
  final bool editMode;

  ///Function to be executed after an item was edited (receives the new item).
  final Function(ValueItem<T>)? onEditItem;

  ///Function to be executed after clear list.
  final Function()? onClearList;

  ///Function to be executed after clear an item.
  final Function(ValueItem<T>)? onClearItem;

  ///Force the user to confirm delete
  final bool confirmDelete;

  ///Visual delete dialog settings
  final DialogSettings? deleteDialogSettings;

  ///The SearchBarSettings.
  final SimpleSearchbarSettings searchBarSettings;

  ///The settings for the overlay list of items.
  final SimpleOverlaySettings overlayListSettings;

  final int? _legacySortType;
  final SortType _sort;

  ///How the items are ordered.
  SortType get sort {
    final int? legacy = _legacySortType;
    return legacy != null ? SortType.fromLegacy(legacy) : _sort;
  }

  ///The legacy `int` sort type (0-3).
  @Deprecated('Use sort. Will be removed in 9.0.0')
  int get sortType => sort.legacyValue;

  ///Function to check if the item added is valid or not.
  final bool Function(ValueItem<T>)? verifyInputItem;

  ///Visual verify dialog settings
  final DialogSettings? verifyDialogSettings;

  ///A custom additional widget to be inserted on the add item cell.
  final Widget? addAdditionalWidget;

  ///A custom additional widget to be inserted on the default item cell.
  final Widget? defaultAdditionalWidget;

  /// Deprecated alias of [addAdditionalWidget].
  @Deprecated('Use addAdditionalWidget. Will be removed in 9.0.0')
  Widget? get addAditionalWidget => addAdditionalWidget;

  /// Deprecated alias of [defaultAdditionalWidget].
  @Deprecated('Use defaultAdditionalWidget. Will be removed in 9.0.0')
  Widget? get defaultAditionalWidget => defaultAdditionalWidget;

  ///A parameter to define if the widget is enabled or disabled (default: `true`).
  final bool enabled;

  /// Texts used by this dropdown. Defaults to [SearchDropDownStrings.of].
  final SearchDropDownStrings? strings;

  @override
  State<MultipleSearchDropDown<T>> createState() =>
      MultipleSearchDropDownState<T>();
}

/// State of [MultipleSearchDropDown].
///
/// Prefer the [MultipleSearchDropDownController] API; the methods here only
/// forward to it and remain for `GlobalKey` users.
class MultipleSearchDropDownState<T> extends State<MultipleSearchDropDown<T>> {
  final LayerLink _layerLink = LayerLink();
  final OverlayPortalController _portal = OverlayPortalController();
  MultipleSearchDropDownController<T>? _ownController;

  MultipleSearchDropDownController<T> get _controller =>
      widget.controller ?? _ownController!;

  /// Whether the list is open.
  bool get aberto => _portal.isShowing;

  /// Whether the dropdown accepts interaction.
  bool get enabled => _controller.enabled;

  SearchDropDownStrings get _strings =>
      widget.strings ?? SearchDropDownStrings.of(context);

  @override
  void initState() {
    super.initState();
    _ownController = widget.controller == null ? _legacyController() : null;
    _controller.addListener(_onControllerChanged);
  }

  /// Builds the controller behind the 7.x parameters. Callbacks read the
  /// current widget when they run, so a parent rebuild with new closures
  /// does not need a new controller.
  MultipleSearchDropDownController<T> _legacyController() {
    final MultipleSearchDropDown<T> w = widget;
    final bool canCreate = w.newValueItem != null;
    return MultipleSearchDropDownController<T>(
      listItems: w.listItems,
      selectedItems: w.selectedItems,
      updateSelectedItems: (List<ValueItem<T>> selected) =>
          widget.updateSelectedItems?.call(selected),
      addMode: w.addMode,
      newValueItem: canCreate ? (String s) => widget.newValueItem!(s) : null,
      onAddItem: w.onAddItem == null
          ? null
          : (ValueItem<T> item) => widget.onAddItem?.call(item),
      deleteMode: w.deleteMode,
      onDeleteItem: w.onDeleteItem == null
          ? null
          : (ValueItem<T> item) => widget.onDeleteItem?.call(item),
      // 7.x never called onEditItem; 8.0 calls it with the edited item.
      editMode: w.editMode && canCreate,
      onEditItem: w.onEditItem == null
          ? null
          : (_, ValueItem<T> edited) => widget.onEditItem?.call(edited),
      onClearItem: (ValueItem<T> item) => widget.onClearItem?.call(item),
      onClearList: () => widget.onClearList?.call(),
      confirmDelete: w.confirmDelete,
      deleteDialogSettings: w.deleteDialogSettings,
      verifyInputItem: w.verifyInputItem == null
          ? null
          : (ValueItem<T> item) => widget.verifyInputItem?.call(item) ?? true,
      verifyDialogSettings: w.verifyDialogSettings,
      sort: w.sort,
      enabled: w.enabled,
    );
  }

  /// Whether a 7.x parameter that the controller captures changed.
  bool _legacyShapeChanged(MultipleSearchDropDown<T> old) =>
      old.controller != null ||
      !identical(old.listItems, widget.listItems) ||
      !identical(old.selectedItems, widget.selectedItems) ||
      old.addMode != widget.addMode ||
      old.deleteMode != widget.deleteMode ||
      old.editMode != widget.editMode ||
      old.confirmDelete != widget.confirmDelete ||
      old.sort != widget.sort ||
      (old.newValueItem == null) != (widget.newValueItem == null) ||
      (old.verifyInputItem == null) != (widget.verifyInputItem == null) ||
      (old.onAddItem == null) != (widget.onAddItem == null) ||
      (old.onDeleteItem == null) != (widget.onDeleteItem == null) ||
      (old.onEditItem == null) != (widget.onEditItem == null) ||
      !identical(old.deleteDialogSettings, widget.deleteDialogSettings) ||
      !identical(old.verifyDialogSettings, widget.verifyDialogSettings);

  @override
  void didUpdateWidget(covariant MultipleSearchDropDown<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    final MultipleSearchDropDownController<T> previous =
        oldWidget.controller ?? _ownController!;
    MultipleSearchDropDownController<T>? stale;
    if (widget.controller == null) {
      if (_legacyShapeChanged(oldWidget)) {
        stale = _ownController;
        _ownController = _legacyController();
      } else if (oldWidget.enabled != widget.enabled) {
        _ownController!.enabled = widget.enabled;
      }
    } else {
      stale = _ownController;
      _ownController = null;
    }
    if (!identical(previous, _controller)) {
      previous.removeListener(_onControllerChanged);
      _controller.addListener(_onControllerChanged);
    }
    stale?.dispose();
  }

  @override
  void dispose() {
    _controller.removeListener(_onControllerChanged);
    _ownController?.dispose();
    super.dispose();
  }

  void _onControllerChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  // ------------------------------------------------- deprecated forwards

  /// Toggles [val] in the selection.
  @Deprecated('Use controller.toggle(). Will be removed in 9.0.0')
  void onItemSelected(ValueItem<T> val, {bool forced = false}) =>
      _controller.toggle(val, forced: forced);

  /// Clears the selection.
  @Deprecated('Use controller.resetSelection(). Will be removed in 9.0.0')
  void resetSelection() => _controller.resetSelection();

  /// Selects the item with [label].
  @Deprecated('Use controller.forceSelection(). Will be removed in 9.0.0')
  void forceSelection(String label) => _controller.forceSelection(label);

  /// Replaces the selection with [values].
  @Deprecated(
    'Use controller.forceMultipleSelection(). Will be removed in 9.0.0',
  )
  void forceMultipleSelection(List<ValueItem<T>> values) =>
      _controller.forceMultipleSelection(values);

  /// Toggles enabled/disabled.
  @Deprecated('Use controller.toggleEnabled(). Will be removed in 9.0.0')
  void enableDisable() => _controller.toggleEnabled();

  /// Adds `item` (after verification) and selects it.
  @Deprecated('Use controller.addValue(). Will be removed in 9.0.0')
  void handleAddItem(ValueItem<T> item, BuildContext context) =>
      _controller.addValue(item, context, strings: _strings);

  /// Deletes `item` (after confirmation when enabled).
  @Deprecated('Use controller.deleteItem(). Will be removed in 9.0.0')
  void handleDeleteItem(ValueItem<T> item, BuildContext context) =>
      _controller.deleteItem(item, context, strings: _strings);

  /// Clears the selection like the clear button.
  @Deprecated('Use controller.clear(). Will be removed in 9.0.0')
  void onClear() => _controller.clear();

  // ---------------------------------------------------------------- overlay

  /// Closes the list. Does nothing when it is already closed.
  void hideOverlay() {
    if (!_portal.isShowing || !mounted) {
      return;
    }
    setState(_portal.hide);
    FocusScope.of(context).unfocus();
  }

  void _showOverlay() {
    if (!_portal.isShowing) {
      setState(_portal.show);
    }
  }

  void _toggleOverlay() => _portal.isShowing ? hideOverlay() : _showOverlay();

  // The list is an OverlayPortal child: drawn above this page but below the
  // routes pushed later (dialogs), rebuilt with this widget and removed with
  // it.
  Widget _buildOverlay(BuildContext context) {
    final SimpleSearchbarSettings bar = widget.searchBarSettings;
    final SimpleOverlaySettings list = widget.overlayListSettings;
    final Size size =
        _layerLink.leaderSize ?? Size(bar.dropdownWidth, bar.dropdownHeight);
    return Stack(
      children: <Widget>[
        Positioned.fill(
          child: GestureDetector(
            onTap: hideOverlay,
            child: Container(color: Colors.transparent),
          ),
        ),
        Positioned(
          width: size.width,
          child: CompositedTransformFollower(
            link: _layerLink,
            showWhenUnlinked: false,
            offset: Offset(list.offsetWidth, size.height + list.offsetHeight),
            child: Material(
              color: Colors.transparent,
              child: MultipleListView<T>(
                controller: _controller,
                overlayListSettings: list,
                searchBarSettings: bar,
                addAdditionalWidget: widget.addAdditionalWidget,
                defaultAdditionalWidget: widget.defaultAdditionalWidget,
                strings: _strings,
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ------------------------------------------------------------------ build

  @override
  Widget build(BuildContext context) {
    return OverlayPortal(
      controller: _portal,
      overlayChildBuilder: _buildOverlay,
      child: _buildBox(),
    );
  }

  Widget _buildBox() {
    final SimpleSearchbarSettings bar = widget.searchBarSettings;
    final MultipleSearchDropDownController<T> controller = _controller;
    final List<ValueItem<T>> selected = controller.selectedItems;
    final bool hasSelection = selected.isNotEmpty;
    final bool isEnabled = controller.enabled;
    final bool showClear = hasSelection && bar.showClearIcon;
    final bool showArrow = !hasSelection && bar.showArrow && isEnabled;
    return Opacity(
      opacity: isEnabled ? 1 : 0.38,
      child: IgnorePointer(
        ignoring: !isEnabled,
        child: CompositedTransformTarget(
          link: _layerLink,
          child: SizedBox(
            height: bar.dropdownHeight,
            width: bar.dropdownWidth,
            child: InkWell(
              onTap: _toggleOverlay,
              child: Stack(
                children: <Widget>[
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: const BorderRadius.all(Radius.circular(10)),
                      color: bar.backgroundColor,
                      border: Border.all(style: BorderStyle.none),
                      boxShadow: <BoxShadow>[
                        BoxShadow(
                          color: Colors.grey.withAlpha(
                            bar.elevation != 0 ? 125 : 0,
                          ),
                          spreadRadius: 0.5,
                          blurRadius: bar.elevation,
                          offset: Offset(0, 0.5 * bar.elevation),
                        ),
                      ],
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      child: Row(
                        children: <Widget>[
                          Expanded(
                            child: hasSelection
                                ? _buildChips(selected)
                                : Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: <Widget>[
                                      Text(
                                        bar.hint ?? _strings.searchHint,
                                        textAlign: TextAlign.start,
                                        style: bar.hintStyle,
                                      ),
                                    ],
                                  ),
                          ),
                          if (showClear)
                            _trailing(
                              Icons.clear,
                              controller.clear,
                              _strings.clearTooltip,
                            )
                          else if (showArrow)
                            _trailing(
                              aberto
                                  ? bar.dropdownOpenedArrowIcon
                                  : bar.dropdownClosedArrowIcon,
                              _toggleOverlay,
                              aberto
                                  ? _strings.closeTooltip
                                  : _strings.openTooltip,
                            ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _trailing(IconData icon, VoidCallback onTap, String label) {
    final SimpleSearchbarSettings bar = widget.searchBarSettings;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        const SizedBox(width: 5),
        Semantics(
          button: true,
          label: label,
          child: InkWell(
            onTap: onTap,
            child: Icon(
              icon,
              size: bar.outsideIconSize,
              color: bar.outsideIconColor,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildChips(List<ValueItem<T>> selected) {
    final SimpleSearchbarSettings bar = widget.searchBarSettings;
    return ScrollConfiguration(
      behavior: CustomScrollBehavior(),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        separatorBuilder: (BuildContext context, int index) =>
            const SizedBox(width: 5),
        itemCount: selected.length,
        itemBuilder: (BuildContext context, int index) {
          final ValueItem<T> item = selected[index];
          final Widget Function(ValueItem)? custom =
              bar.boxMultiItemWidgetBuilder;
          if (custom != null) {
            return custom(item);
          }
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 5),
            child: Card(
              color: bar.boxMultiSelectedBackgroundColor,
              elevation: bar.elevation,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: <Widget>[
                    Text(item.label, style: bar.boxMultiSelectedTextStyle),
                    Semantics(
                      button: true,
                      label: '${_strings.removeChipTooltip} ${item.label}',
                      child: InkWell(
                        onTap: () => _controller.toggle(item),
                        child: Icon(
                          Icons.close,
                          size: bar.boxMultiSelectedClearIconSize,
                          color: bar.boxMultiSelectedClearIconColor,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
