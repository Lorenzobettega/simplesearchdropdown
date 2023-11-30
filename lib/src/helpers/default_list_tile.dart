import 'package:flutter/material.dart';
import 'package:simple_search_dropdown/simple_search_dropdown.dart';

class DefaultListTile<T> extends StatelessWidget {
  const DefaultListTile({
    required this.deleteMode,
    required this.item,
    required this.onDelete,
    required this.onPressed,
    required this.overlayListSettings,
    required this.selected,
    super.key,
  });
  
  ///The overlay list of items settings.
  final SimpleOverlaySettings? overlayListSettings;
  final bool deleteMode;
  final ValueItem<T> item;
  final Function(ValueItem<T> value) onDelete;
  final Function(ValueItem<T> value) onPressed;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: overlayListSettings?.itemsPadding ??
          const EdgeInsets.symmetric(horizontal: 4),
      child: Row(
        children: [
          Expanded(
            child: TextButton(
              style: ButtonStyle(
                backgroundColor: MaterialStateProperty.resolveWith<Color>(
                  (Set<MaterialState> states) {
                    if (selected) {
                      return overlayListSettings?.selectedItemBackgroundColor ??
                          Colors.black38;
                    }
                    return Colors.transparent;
                  },
                ),
                shape: MaterialStateProperty.all<OutlinedBorder>(
                  RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                overlayColor: MaterialStateProperty.resolveWith<Color>(
                  (Set<MaterialState> states) {
                    if (selected) {
                      return overlayListSettings?.selectedItemHoverColor ??
                          Colors.grey.shade300;
                    }
                    return overlayListSettings?.unselectedItemHoverColor ??
                        Colors.grey.shade100;
                  },
                ),
              ),
              onPressed: () => onPressed(item),
              child: overlayListSettings?.itemWidgetBuilder != null
                  ? overlayListSettings!.itemWidgetBuilder!(item)
                  : Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        item.label,
                        style: (selected
                            ? overlayListSettings?.selectedItemTextStyle ??
                                const TextStyle(color: Colors.black)
                            : overlayListSettings?.unselectedItemTextStyle ??
                                const TextStyle(color: Colors.black45)),
                      ),
                    ),
            ),
          ),
          deleteMode
              ? overlayListSettings?.dialogActionWidget ??
                  IconButton(
                    onPressed: () {
                      onDelete(item);
                    },
                    icon: overlayListSettings?.dialogActionIcon ??
                        Icon(
                          Icons.delete,
                          color: Colors.red.shade900,
                          size: 20,
                        ),
                  )
              : const SizedBox.shrink()
        ],
      ),
    );
  }
}
