import 'package:flutter/material.dart';
import 'package:simple_search_dropdown/simple_search_dropdown.dart';

///The default widget that will be presented on the list.
class DefaultListTile<T> extends StatelessWidget {
  const DefaultListTile({
    required this.deleteMode,
    required this.editMode,
    required this.item,
    required this.onDelete,
    required this.onEdit,
    required this.onPressed,
    required this.overlayListSettings,
    required this.selected,
    required this.defaultAditionalWidget,
    super.key,
  });

  ///The overlay list of items settings.
  final SimpleOverlaySettings overlayListSettings;
  final bool deleteMode;
  final bool editMode;
  final ValueItem<T> item;
  final Function(ValueItem<T> value) onEdit;
  final Function(ValueItem<T> value) onDelete;
  final Function(ValueItem<T> value) onPressed;
  final bool selected;
  final Widget? defaultAditionalWidget;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: overlayListSettings.itemsPadding,
      child: Row(
        children: [
          Expanded(
            child: TextButton(
              style: ButtonStyle(
                backgroundColor: WidgetStateProperty.resolveWith<Color>(
                  (Set<WidgetState> states) {
                    if (selected) {
                      return overlayListSettings.selectedItemBackgroundColor;
                    }
                    return Colors.transparent;
                  },
                ),
                shape: WidgetStateProperty.all<OutlinedBorder>(
                  RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                overlayColor: WidgetStateProperty.resolveWith<Color>(
                  (Set<WidgetState> states) {
                    if (selected) {
                      return overlayListSettings.selectedItemHoverColor;
                    }
                    return overlayListSettings.unselectedItemHoverColor;
                  },
                ),
              ),
              onPressed: () => onPressed(item),
              child: overlayListSettings.itemWidgetBuilder != null
                  ? overlayListSettings.itemWidgetBuilder!(item)
                  : Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        item.label,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: (selected
                            ? overlayListSettings.selectedItemTextStyle
                            : overlayListSettings.unselectedItemTextStyle),
                      ),
                    ),
            ),
          ),
          if (defaultAditionalWidget != null) ...[
            defaultAditionalWidget!,
            SizedBox(width: overlayListSettings.aditionalWidgetSpacing)
          ],
          if (editMode)
            IconButton(
              onPressed: () {
                onEdit(item);
              },
              icon: overlayListSettings.dialogEditIcon,
            ),
          if (deleteMode)
            overlayListSettings.dialogActionWidget ??
                IconButton(
                  onPressed: () {
                    onDelete(item);
                  },
                  icon: overlayListSettings.dialogDeleteIcon,
                )
          else
            const SizedBox.shrink()
        ],
      ),
    );
  }
}
