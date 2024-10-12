import 'package:flutter/material.dart';
import 'package:simple_search_dropdown/simple_search_dropdown.dart';

///ListItem to be shown when a item will be added.
class DefaultAddListItem extends StatelessWidget {
  const DefaultAddListItem({
    required this.text,
    required this.overlayListSettings,
    required this.itemAdded,
    required this.addAditionalWidget,
    super.key,
  });

  ///Function to be executed after the item was added.
  final void Function(String value) itemAdded;

  ///The overlay list of items settings.
  final SimpleOverlaySettings overlayListSettings;

  final String text;

  final Widget? addAditionalWidget;

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
              text,
              overflow: TextOverflow.ellipsis,
              maxLines: 3,
            ),
          ),
          if (addAditionalWidget != null)
            Flexible(
              child: addAditionalWidget!,
            ),
          Flexible(
            child: TextButton(
              onPressed: () => itemAdded(text),
              child: Text(
                overlayListSettings.addItemHint,
                style: overlayListSettings.addItemHintStyle,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
