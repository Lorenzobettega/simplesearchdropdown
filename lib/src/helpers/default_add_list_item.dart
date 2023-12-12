import 'package:flutter/material.dart';
import 'package:simple_search_dropdown/simple_search_dropdown.dart';

class DefaultAddListItem extends StatelessWidget {
  const DefaultAddListItem({
    required this.text,
    required this.overlayListSettings,
    required this.itemAdded,
    super.key,
  });

  ///Function to be executed after the item was added.
  final void Function(String value) itemAdded;

  ///The overlay list of items settings.
  final SimpleOverlaySettings overlayListSettings;

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Flexible(
              flex: 3,
              child: Text(
                text,
                overflow: TextOverflow.ellipsis,
                maxLines: 2,
              )),
          Flexible(
            flex: 1,
            child: TextButton(
              onPressed: () => itemAdded(text),
              child: Text(
                overlayListSettings.addItemHint,
                style: overlayListSettings.addItemHintStyle,
              ),
            ),
          )
        ],
      ),
    );
  }
}
