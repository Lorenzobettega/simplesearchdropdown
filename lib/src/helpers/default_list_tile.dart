import 'package:flutter/material.dart';
import 'package:simple_search_dropdown/simple_search_dropdown.dart';
import 'package:simple_search_dropdown/src/core/busy_row.dart';
import 'package:simple_search_dropdown/src/core/theme_colors.dart';

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

class _DefaultListTileState<T> extends State<DefaultListTile<T>>
    with BusyRow<DefaultListTile<T>> {
  Future<void> _handleDeleteItem() =>
      runBusy(() => widget.onDelete(widget.item));

  Future<void> _handleEditItem() => runBusy(() => widget.onEdit(widget.item));

  @override
  Widget build(BuildContext context) {
    final SearchDropDownStrings texts =
        widget.strings ?? SearchDropDownStrings.of(context);
    final SimpleOverlaySettings settings = widget.overlayListSettings;
    final ListColors colors = ListColors.of(settings, Theme.of(context));
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
                    return colors.selectedBackground;
                  }
                  if (widget.highlighted) {
                    return colors.highlightedBackground;
                  }
                  return Colors.transparent;
                }),
                shape: WidgetStateProperty.all<OutlinedBorder>(
                  RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                    side: widget.highlighted
                        ? BorderSide(color: colors.highlightedBorder)
                        : BorderSide.none,
                  ),
                ),
                overlayColor: WidgetStateProperty.resolveWith<Color>((
                  Set<WidgetState> states,
                ) {
                  if (widget.selected) {
                    return colors.selectedHover;
                  }
                  return colors.unselectedHover;
                }),
              ),
              onPressed: () => widget.onPressed(widget.item),
              child: Semantics(
                selected: widget.selected,
                child: settings.itemWidgetBuilder != null
                    ? settings.itemWidgetBuilder!(widget.item)
                    : Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          widget.item.label,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: (widget.selected || widget.highlighted
                              ? colors.selectedTextStyle
                              : colors.unselectedTextStyle),
                        ),
                      ),
              ),
            ),
          ),
          if (widget.defaultAdditionalWidget != null) ...[
            widget.defaultAdditionalWidget!,
            SizedBox(width: settings.additionalWidgetSpacing),
          ],
          busyActions(
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (widget.editMode)
                  IconButton(
                    tooltip: texts.editItemTooltip,
                    onPressed: _handleEditItem,
                    icon: colors.editIcon,
                  ),
                if (widget.deleteMode)
                  settings.dialogActionWidget ??
                      IconButton(
                        tooltip: texts.deleteItemTooltip,
                        onPressed: _handleDeleteItem,
                        icon: colors.deleteIcon,
                      ),
              ],
            ),
            settings,
            texts,
          ),
        ],
      ),
    );
  }
}
