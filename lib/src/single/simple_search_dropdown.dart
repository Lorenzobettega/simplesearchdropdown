import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:simple_search_dropdown/simple_search_dropdown.dart'; // For ValueItem, settings, etc.

/// This creates a single-selection dropdown widget.
/// The widget UI is defined here, while state management is handled by [SearchDropDownController].
class SearchDropDown<T> extends StatefulWidget {
  const SearchDropDown({
    super.key,
    required this.controller,
    this.searchBarSettings = defaultSearchBarSettings,
    this.overlayListSettings = defaultOverlaySettings,
    this.addAditionalWidget,
    this.defaultAditionalWidget,
    this.disposeController = true,
    this.removeFocus = true,
  });

  /// The external controller that manages state (text, selected item, etc.) for this dropdown.
  final SearchDropDownController<T> controller;

  /// The SearchBar settings (visual and behavioral configuration for the search bar).
  final SimpleSearchbarSettings searchBarSettings;

  /// The settings for the overlay list of items.
  final SimpleOverlaySettings overlayListSettings;

  /// A custom additional widget to be inserted on the add-item cell between the text and the create button.
  final Widget? addAditionalWidget;

  /// A custom additional widget to be inserted on the default item cell between the text and the delete button.
  final Widget? defaultAditionalWidget;

  /// If the controller will be disposed when this widget is disposed (default: `true`).
  final bool disposeController;

  /// If the focus from the text field will be removed after the search view is closed (default: `true`).
  final bool removeFocus;

  @override
  State<SearchDropDown<T>> createState() => SearchDropDownState<T>();
}

class SearchDropDownState<T> extends State<SearchDropDown<T>> {
  late final FocusScopeNode _focusNode;
  late final ValueNotifier<int> _highlightIndexNotifier;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusScopeNode();
    _highlightIndexNotifier = ValueNotifier<int>(-1);
    HardwareKeyboard.instance.addHandler(_handleKeyEvent);
  }

  bool _handleKeyEvent(KeyEvent event) {
    if (!mounted) {
      return false;
    }
    if (event is! KeyDownEvent) {
      return false;
    }

    final key = event.logicalKey;
    final searchController = widget.controller.localSearchController;
    if (!searchController.isOpen) {
      return false;
    }

    if (key == LogicalKeyboardKey.arrowDown) {
      widget.controller.highlightNext();
      _highlightIndexNotifier.value = widget.controller.highlightedIndex;
      return true;
    }

    if (key == LogicalKeyboardKey.arrowUp) {
      widget.controller.highlightPrevious();
      _highlightIndexNotifier.value = widget.controller.highlightedIndex;
      return true;
    }

    if (key == LogicalKeyboardKey.enter ||
        key == LogicalKeyboardKey.numpadEnter) {
      if (widget.controller.highlightedIndex >= 0) {
        widget.controller.selectHighlighted();
      } else {
        widget.controller.handleEnterKey();
      }
      return true;
    }

    return false;
  }

  @override
  void dispose() {
    if (widget.disposeController) {
      widget.controller.dispose();
    }
    HardwareKeyboard.instance.removeHandler(_handleKeyEvent);
    _highlightIndexNotifier.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  /// Toggles the enabled/disabled state of the dropdown.
  void enableDisable() {
    if (mounted) {
      setState(() {
        widget.controller.toggleEnabled();
      });
    }
  }

  /// Resets the selection to its default state, clearing the current value.
  void resetSelection() {
    if (mounted) {
      widget.controller.resetSelection();
    }
  }

  /// updates the current list of the widget
  void updateList(List<ValueItem<T>> newList) {
    if (mounted) {
      widget.controller.updateListItems(newList);
    }
  }

  /// Builds the trailing widgets for the opened overlay view (e.g., clear button and opened dropdown arrow).
  Widget _buildViewTrailing() {
    return Row(mainAxisSize: MainAxisSize.min, children: [
      if (widget.searchBarSettings.showArrow)
        IconButton(
          onPressed: widget.searchBarSettings.dropdownOpenedIconFunction ??
              () => widget.controller.localSearchController
                  .closeView(widget.controller.localSearchController.text),
          icon: Icon(
            widget.searchBarSettings.dropdownOpenedArrowIcon,
            color: widget.searchBarSettings.outsideIconColor,
            size: widget.searchBarSettings.outsideIconSize,
          ),
        ),
      ClearButton(
        visible: widget.controller.clearVisible,
        onPressed: resetSelection,
        iconColor: widget.searchBarSettings.clearIconColor,
        iconSize: widget.searchBarSettings.outsideIconSize,
      ),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    return FocusScope(
      node: _focusNode,
      onFocusChange: (isFocused) {
        // Remove focus from text field after the search view is closed, if configured.
        if (isFocused && widget.removeFocus) {
          _focusNode.unfocus();
        }
      },
      child: SizedBox(
        width: widget.searchBarSettings.dropdownWidth,
        height: widget.searchBarSettings.dropdownHeight,
        child: SearchAnchor.bar(
          enabled: widget.controller.enabled,
          viewConstraints: BoxConstraints(
            maxWidth: widget.searchBarSettings.dropdownWidth,
            maxHeight: widget.overlayListSettings.dialogHeight,
          ),
          onTap: () {
            // Prepare the list when the search view is opened (reset filter).
            widget.controller.onSearchOpen();
          },
          onClose: () {
            // Delega ao controller a lógica ao fechar o dropdown (restaurar/limpar texto conforme necessário)
            widget.controller
                .onSearchClose(widget.searchBarSettings.clearOnClose);
          },
          onSubmitted: (String value) {
            widget.controller.handleEnterKey();
          },
          searchController: widget.controller.localSearchController,
          viewHeaderHeight: widget.searchBarSettings.dropdownHeight,
          dividerColor: widget.searchBarSettings.showDivider
              ? null
              : (widget.overlayListSettings.dialogBackgroundColor ??
                  widget.searchBarSettings.backgroundColor),
          viewTrailing: [_buildViewTrailing()],
          barTrailing: widget.searchBarSettings.actions ??
              [
                if (widget.searchBarSettings.showArrow &&
                    widget.controller.enabled)
                  IconButton(
                    onPressed:
                        widget.searchBarSettings.dropdownClosedIconFunction ??
                            widget.controller.localSearchController.openView,
                    icon: Icon(
                      widget.searchBarSettings.dropdownClosedArrowIcon,
                      color: widget.searchBarSettings.outsideIconColor,
                      size: widget.searchBarSettings.outsideIconSize,
                    ),
                  ),
                if (widget.searchBarSettings.showClearIcon)
                  ClearButton(
                    visible: widget.controller.clearVisible,
                    onPressed: resetSelection,
                    iconColor: widget.searchBarSettings.clearIconColor,
                    iconSize: widget.searchBarSettings.outsideIconSize,
                  ),
              ],
          barElevation:
              WidgetStatePropertyAll(widget.searchBarSettings.elevation),
          barShape: WidgetStatePropertyAll(widget.searchBarSettings.border),
          viewShape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(10)),
          ),
          barBackgroundColor:
              WidgetStatePropertyAll(widget.searchBarSettings.backgroundColor),
          viewBackgroundColor:
              widget.overlayListSettings.dialogBackgroundColor ??
                  widget.searchBarSettings.backgroundColor,
          isFullScreen: widget.overlayListSettings.openFullScreen,
          barHintStyle:
              WidgetStatePropertyAll(widget.searchBarSettings.hintStyle),
          barHintText: widget.searchBarSettings.hint,
          barOverlayColor:
              WidgetStatePropertyAll(widget.searchBarSettings.hoverColor),
          barTextStyle: WidgetStatePropertyAll(
              widget.searchBarSettings.searchBarTextStyle),
          barPadding:
              WidgetStatePropertyAll(widget.searchBarSettings.searchBarPadding),
          barLeading: const SizedBox.shrink(),
          viewSide: const BorderSide(style: BorderStyle.none),
          viewLeading: const SizedBox.shrink(),
          viewElevation: widget.searchBarSettings.elevation,
          viewHintText: widget.searchBarSettings.hint,
          viewHeaderHintStyle: widget.searchBarSettings.hintStyle,
          viewHeaderTextStyle: widget.searchBarSettings.searchBarTextStyle,
          keyboardType: widget.searchBarSettings.showKeyboardOnTap
              ? widget.searchBarSettings.keyboardType
              : TextInputType.none,
          textInputAction: widget.searchBarSettings.textInputAction,
          suggestionsBuilder:
              (BuildContext context, SearchController controller) {
            // Calcula número de itens a exibir (incluindo opção "adicionar" se aplicável)
            final bool showAddItemOption = widget.controller.addMode &&
                controller.text.isNotEmpty &&
                widget.controller.filteredItems.isEmpty;
            final int length = widget.controller.filteredItems.length +
                (showAddItemOption ? 1 : 0);
            return List<Widget>.generate(length, (int index) {
              if (showAddItemOption &&
                  index == widget.controller.filteredItems.length) {
                // Add new item option at the end
                return DefaultAddListItem(
                  text: controller.text,
                  addAditionalWidget: widget.addAditionalWidget,
                  overlayListSettings: widget.overlayListSettings,
                  itemAdded: (String input) =>
                      widget.controller.addItem(input, context),
                );
              } else {
                final item = widget.controller.filteredItems[index];
                return ValueListenableBuilder<int>(
                  valueListenable: _highlightIndexNotifier,
                  builder: (context, highlightedIndex, _) {
                    final bool isHighlighted = index == highlightedIndex;
                    final bool isSelected = controller.text == item.label;

                    if (isHighlighted) {
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        if (!context.mounted) {
                          return;
                        }
                        final renderObject = context.findRenderObject();
                        if (renderObject != null && renderObject.attached) {
                          Scrollable.ensureVisible(
                            context,
                            alignment: 0.5,
                            duration: const Duration(milliseconds: 120),
                            curve: Curves.easeOut,
                          );
                        }
                      });
                    }
                    return DefaultListTile<T>(
                      key: ValueKey(item.label),
                      deleteMode: widget.controller.deleteMode,
                      editMode: widget.controller.editMode,
                      item: item,
                      overlayListSettings: widget.overlayListSettings,
                      defaultAditionalWidget: widget.defaultAditionalWidget,
                      onDelete: (ValueItem<T> val) =>
                          widget.controller.deleteItem(val, context),
                      onEdit: (ValueItem<T> val) =>
                          widget.controller.editItem(val, context),
                      onPressed: (ValueItem<T> val) =>
                          widget.controller.selectItem(val),
                      selected: isHighlighted || isSelected,
                    );
                  },
                );
              }
            });
          },
        ),
      ),
    );
  }
}
