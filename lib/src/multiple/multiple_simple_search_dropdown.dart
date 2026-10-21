import 'package:flutter/material.dart';
import 'package:simple_search_dropdown/simple_search_dropdown.dart';
import 'package:simple_search_dropdown/src/core/item_list.dart';
import 'package:simple_search_dropdown/src/core/theme_colors.dart';
import 'package:simple_search_dropdown/src/multiple/multiple_listview.dart';

/// A multiple-selection dropdown: selected items show as chips in the box and
/// the list opens below it with a search field.
///
/// Items, selection, modes and callbacks live in its [controller].
class MultipleSearchDropDown<T> extends StatefulWidget {
  /// Creates a multiple-selection dropdown driven by [controller].
  const MultipleSearchDropDown({
    super.key,
    required this.controller,
    this.searchBarSettings = defaultSearchBarSettings,
    this.overlayListSettings = defaultOverlaySettings,
    this.addAdditionalWidget,
    this.defaultAdditionalWidget,
    this.strings,
  });

  /// Holds items, selection, search, modes and callbacks.
  final MultipleSearchDropDownController<T> controller;

  ///The SearchBarSettings.
  final SimpleSearchbarSettings searchBarSettings;

  ///The settings for the overlay list of items.
  final SimpleOverlaySettings overlayListSettings;

  ///A custom additional widget to be inserted on the add item cell.
  final Widget? addAdditionalWidget;

  ///A custom additional widget to be inserted on the default item cell.
  final Widget? defaultAdditionalWidget;

  /// Texts used by this dropdown. Defaults to [SearchDropDownStrings.of].
  final SearchDropDownStrings? strings;

  @override
  State<MultipleSearchDropDown<T>> createState() =>
      MultipleSearchDropDownState<T>();
}

/// State of [MultipleSearchDropDown]. Drive the dropdown through its
/// [MultipleSearchDropDownController]; the state only reports whether the
/// list is open ([aberto]) and can close it ([hideOverlay]).
class MultipleSearchDropDownState<T> extends State<MultipleSearchDropDown<T>> {
  final LayerLink _layerLink = LayerLink();
  final OverlayPortalController _portal = OverlayPortalController();

  MultipleSearchDropDownController<T> get _controller => widget.controller;

  /// Whether the list is open.
  bool get aberto => _portal.isShowing;

  SearchDropDownStrings get _strings =>
      widget.strings ?? SearchDropDownStrings.of(context);

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onControllerChanged);
  }

  @override
  void didUpdateWidget(covariant MultipleSearchDropDown<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    final MultipleSearchDropDownController<T> previous = oldWidget.controller;
    if (identical(previous, _controller)) {
      return;
    }
    previous.removeListener(_onControllerChanged);
    _controller.addListener(_onControllerChanged);
    // A swapped-in disabled controller sends no notification. The portal
    // cannot be hidden during a build.
    if (!_controller.enabled && _portal.isShowing) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && !_controller.enabled) {
          hideOverlay();
        }
      });
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_onControllerChanged);
    super.dispose();
  }

  void _onControllerChanged() {
    if (!mounted) {
      return;
    }
    final MultipleSearchDropDownController<T> controller = _controller;
    if (!controller.enabled && _portal.isShowing) {
      hideOverlay();
      return;
    }
    // The box shows only the selection and the enabled state: changes of the
    // results alone (typing) leave it alone, as in 7.x; the open list follows
    // them through its own ListenableBuilder. Anything else the box reads
    // from the controller must be compared here too.
    if (controller.enabled == _shownEnabled &&
        sameInstances(controller.selectedItems, _shownSelection)) {
      return;
    }
    setState(() {});
  }

  /// What the box last drew: the selection (by identity) and enabled state.
  final List<ValueItem<T>> _shownSelection = <ValueItem<T>>[];
  bool? _shownEnabled;

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
    if (_controller.enabled && !_portal.isShowing) {
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
    final BarColors colors = BarColors.of(bar, Theme.of(context));
    final MultipleSearchDropDownController<T> controller = _controller;
    final List<ValueItem<T>> selected = controller.selectedItems;
    final bool hasSelection = selected.isNotEmpty;
    final bool isEnabled = controller.enabled;
    final bool showClear = hasSelection && bar.showClearIcon;
    final bool showArrow = !hasSelection && bar.showArrow && isEnabled;
    _shownSelection
      ..clear()
      ..addAll(selected);
    _shownEnabled = isEnabled;
    return Opacity(
      opacity: isEnabled ? 1 : 0.38,
      // Disabled: no pointer and no keyboard (7.x only blocked the pointer).
      child: ExcludeFocus(
        excluding: !isEnabled,
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
                        borderRadius: dropdownRadius,
                        color: colors.background,
                        border: Border.all(style: BorderStyle.none),
                        boxShadow: <BoxShadow>[
                          BoxShadow(
                            color: colors.shadow.withAlpha(
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
                                  ? _buildChips(selected, colors)
                                  : Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: <Widget>[
                                        Text(
                                          bar.customHint ?? _strings.searchHint,
                                          textAlign: TextAlign.start,
                                          style: colors.hintStyle,
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

  Widget _buildChips(List<ValueItem<T>> selected, BarColors colors) {
    final SimpleSearchbarSettings bar = widget.searchBarSettings;
    return ScrollConfiguration(
      behavior: CustomScrollBehavior(),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        separatorBuilder: (BuildContext context, int index) =>
            const SizedBox(width: 8),
        itemCount: selected.length,
        itemBuilder: (BuildContext context, int index) {
          final ValueItem<T> item = selected[index];
          final Widget Function(ValueItem)? custom =
              bar.boxMultiItemWidgetBuilder;
          if (custom != null) {
            return custom(item);
          }
          // An M3 input chip: flat, 32 px tall, 8 px corners, 8 px between
          // the label and the remove icon.
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 5),
            child: Center(
              child: SizedBox(
                height: 32,
                child: Card(
                  margin: EdgeInsets.zero,
                  color: colors.chipBackground,
                  elevation: 0,
                  shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.all(Radius.circular(8)),
                  ),
                  child: Padding(
                    padding: const EdgeInsetsDirectional.only(
                      start: 12,
                      end: 8,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        Text(item.label, style: colors.chipTextStyle),
                        const SizedBox(width: 8),
                        Semantics(
                          button: true,
                          label: '${_strings.removeChipTooltip} ${item.label}',
                          child: InkWell(
                            onTap: () => _controller.toggle(item),
                            child: Icon(
                              Icons.close,
                              size: bar.boxMultiSelectedClearIconSize,
                              color: colors.chipIconColor,
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
        },
      ),
    );
  }
}
