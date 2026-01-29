import 'package:flutter/material.dart';
import 'package:simple_search_dropdown/simple_search_dropdown.dart';

///The default widget that will be presented on the list.
class DefaultListTile<T> extends StatefulWidget {
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
  State<DefaultListTile<T>> createState() => _DefaultListTileState<T>();
}

class _DefaultListTileState<T> extends State<DefaultListTile<T>> {
  bool _isLoading = false;

  Future<void> _handleDeleteItem() async {
    setState(() => _isLoading = true);
    try {
      await widget.onDelete(widget.item);
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _handleEditItem() async {
    setState(() => _isLoading = true);
    try {
      await widget.onEdit(widget.item);
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: widget.overlayListSettings.itemsPadding,
      child: Row(
        children: [
          Expanded(
            child: TextButton(
              style: ButtonStyle(
                backgroundColor: WidgetStateProperty.resolveWith<Color>(
                  (Set<WidgetState> states) {
                    if (widget.selected) {
                      return widget
                          .overlayListSettings.selectedItemBackgroundColor;
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
                    if (widget.selected) {
                      return widget.overlayListSettings.selectedItemHoverColor;
                    }
                    return widget.overlayListSettings.unselectedItemHoverColor;
                  },
                ),
              ),
              onPressed: () => widget.onPressed(widget.item),
              child: widget.overlayListSettings.itemWidgetBuilder != null
                  ? widget.overlayListSettings.itemWidgetBuilder!(widget.item)
                  : Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        widget.item.label,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: (widget.selected
                            ? widget.overlayListSettings.selectedItemTextStyle
                            : widget
                                .overlayListSettings.unselectedItemTextStyle),
                      ),
                    ),
            ),
          ),
          if (widget.defaultAditionalWidget != null) ...[
            widget.defaultAditionalWidget!,
            SizedBox(width: widget.overlayListSettings.aditionalWidgetSpacing)
          ],
          if (_isLoading)
            Padding(
              padding: const EdgeInsets.only(left: 6,right: 6),
              child: SizedBox(
                height: widget.overlayListSettings.loadingSize,
                child: Loading(cor: widget.overlayListSettings.loadingColor),
              ),
            )
          else ...[
            if (widget.editMode)
              IconButton(
                onPressed: _handleEditItem,
                icon: widget.overlayListSettings.dialogEditIcon,
              ),
            if (widget.deleteMode)
              widget.overlayListSettings.dialogActionWidget ??
                  IconButton(
                    onPressed: _handleDeleteItem,
                    icon: widget.overlayListSettings.dialogDeleteIcon,
                  )
            else
              const SizedBox.shrink()
          ],
        ],
      ),
    );
  }
}
