import 'package:flutter/material.dart';
import 'package:simple_search_dropdown/simple_search_dropdown.dart';

class DefaultAddListItem extends StatefulWidget {
  const DefaultAddListItem({
    required this.text,
    required this.overlayListSettings,
    required this.itemAdded,
    required this.addAditionalWidget,
    super.key,
  });

  ///Function to be executed after the item was added.
  final Function(String value) itemAdded;

  ///The overlay list of items settings.
  final SimpleOverlaySettings overlayListSettings;
  final String text;
  final Widget? addAditionalWidget;

  @override
  State<DefaultAddListItem> createState() => _DefaultAddListItemState();
}

class _DefaultAddListItemState extends State<DefaultAddListItem> {
  bool _isLoading = false;

  Future<void> _handleItemAdded() async {
    setState(() => _isLoading = true);

    try {
      await widget.itemAdded(widget.text);
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Flexible(
            flex: 2,
            child: Text(
              widget.text,
              overflow: TextOverflow.ellipsis,
              maxLines: 3,
            ),
          ),
          if (widget.addAditionalWidget != null)
            Flexible(
              child: widget.addAditionalWidget!,
            ),
          Flexible(
            child: _isLoading
                ? Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: SizedBox(
                      height: widget.overlayListSettings.loadingSize,
                      child:
                          Loading(cor: widget.overlayListSettings.loadingColor),
                    ),
                  )
                : TextButton(
                    onPressed: _handleItemAdded,
                    child: Text(
                      widget.overlayListSettings.addItemHint,
                      style: widget.overlayListSettings.addItemHintStyle,
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
