import 'package:flutter/material.dart';
import 'package:simple_search_dropdown/simple_search_dropdown.dart';
import 'package:simple_search_dropdown/src/core/package_dialog.dart';

/// The stock settings, to tell a customised selected style from the default.
const SimpleOverlaySettings _stock = SimpleOverlaySettings();

///The default widget that will be presented on the list.
class DefaultListTile<T> extends StatefulWidget {
  /// Creates a row for [item].
  const DefaultListTile({
    required this.deleteMode,
    required this.editMode,
    required this.item,
    required this.onDelete,
    required this.onEdit,
    required this.onPressed,
    required this.overlayListSettings,
    required this.selected,
    this.defaultAdditionalWidget,
    this.strings,
    this.highlighted = false,
    super.key,
  });

  ///The overlay list of items settings.
  final SimpleOverlaySettings overlayListSettings;

  /// Shows the delete button.
  final bool deleteMode;

  /// Shows the edit button.
  final bool editMode;

  /// The item this row displays.
  final ValueItem<T> item;

  /// Called when the edit button is pressed.
  final Function(ValueItem<T> value) onEdit;

  /// Called when the delete button is pressed.
  final Function(ValueItem<T> value) onDelete;

  /// Called when the row is tapped.
  final Function(ValueItem<T> value) onPressed;

  /// Whether [item] is the selected item.
  final bool selected;

  /// Whether the row is highlighted by keyboard navigation.
  final bool highlighted;

  /// Widget shown between the label and the action buttons.
  final Widget? defaultAdditionalWidget;

  /// Source of tooltips and semantics labels; `null` uses [SearchDropDownStringsScope]
  /// (Portuguese without one).
  final SearchDropDownStrings? strings;

  @override
  State<DefaultListTile<T>> createState() => _DefaultListTileState<T>();
}

class _DefaultListTileState<T> extends State<DefaultListTile<T>> {
  bool _isLoading = false;

  Future<void> _handleDeleteItem() => _run(widget.onDelete);

  Future<void> _handleEditItem() => _run(widget.onEdit);

  /// Shows the spinner while [action] runs. An error it throws is reported
  /// and the row stays as it was.
  Future<void> _run(Function(ValueItem<T> value) action) async {
    setState(() => _isLoading = true);
    try {
      await action(widget.item);
    } catch (exception, stack) {
      reportCallbackError(exception, stack);
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final SearchDropDownStrings texts =
        widget.strings ?? SearchDropDownStrings.of(context);
    final SimpleOverlaySettings settings = widget.overlayListSettings;
    return Padding(
      padding: settings.itemsPadding,
      child: Row(
        children: [
          Expanded(
            child: TextButton(
              style: ButtonStyle(
                backgroundColor: WidgetStateProperty.resolveWith<Color>((
                  Set<WidgetState> states,
                ) {
                  if (widget.selected) {
                    return widget
                        .overlayListSettings
                        .selectedItemBackgroundColor;
                  }
                  if (widget.highlighted) {
                    // The stock text style pairs with the hover fill; a
                    // customised one keeps the selected background (7.x).
                    final bool stockPair =
                        settings.selectedItemTextStyle ==
                            _stock.selectedItemTextStyle &&
                        settings.unselectedItemHoverColor ==
                            _stock.unselectedItemHoverColor;
                    return settings.highlightedItemBackgroundColor ??
                        (stockPair
                            ? settings.unselectedItemHoverColor
                            : settings.selectedItemBackgroundColor);
                  }
                  return Colors.transparent;
                }),
                shape: WidgetStateProperty.all<OutlinedBorder>(
                  RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                    side: widget.highlighted
                        ? BorderSide(
                            color: widget
                                .overlayListSettings
                                .highlightedItemBorderColor,
                          )
                        : BorderSide.none,
                  ),
                ),
                overlayColor: WidgetStateProperty.resolveWith<Color>((
                  Set<WidgetState> states,
                ) {
                  if (widget.selected) {
                    return widget.overlayListSettings.selectedItemHoverColor;
                  }
                  return widget.overlayListSettings.unselectedItemHoverColor;
                }),
              ),
              onPressed: () => widget.onPressed(widget.item),
              child: Semantics(
                selected: widget.selected,
                child: widget.overlayListSettings.itemWidgetBuilder != null
                    ? widget.overlayListSettings.itemWidgetBuilder!(widget.item)
                    : Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          widget.item.label,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: (widget.selected || widget.highlighted
                              ? widget.overlayListSettings.selectedItemTextStyle
                              : widget
                                    .overlayListSettings
                                    .unselectedItemTextStyle),
                        ),
                      ),
              ),
            ),
          ),
          if (widget.defaultAdditionalWidget != null) ...[
            widget.defaultAdditionalWidget!,
            SizedBox(width: widget.overlayListSettings.additionalWidgetSpacing),
          ],
          if (_isLoading)
            Padding(
              padding: const EdgeInsets.only(left: 6, right: 6),
              child: SizedBox(
                height: widget.overlayListSettings.loadingSize,
                child: Loading(
                  cor: widget.overlayListSettings.loadingColor,
                  semanticsLabel: texts.loadingLabel,
                ),
              ),
            )
          else ...[
            if (widget.editMode)
              IconButton(
                tooltip: texts.editItemTooltip,
                onPressed: _handleEditItem,
                icon: widget.overlayListSettings.dialogEditIcon,
              ),
            if (widget.deleteMode)
              widget.overlayListSettings.dialogActionWidget ??
                  IconButton(
                    tooltip: texts.deleteItemTooltip,
                    onPressed: _handleDeleteItem,
                    icon: widget.overlayListSettings.dialogDeleteIcon,
                  )
            else
              const SizedBox.shrink(),
          ],
        ],
      ),
    );
  }
}
