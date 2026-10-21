import 'package:flutter/material.dart';
import 'package:simple_search_dropdown/simple_search_dropdown.dart';
import 'package:simple_search_dropdown/src/core/busy_row.dart';

/// The "create" row shown when the typed text matches no item.
class DefaultAddListItem extends StatefulWidget {
  /// Creates the add row for [text].
  const DefaultAddListItem({
    required this.text,
    required this.overlayListSettings,
    required this.itemAdded,
    this.addAdditionalWidget,
    this.strings,
    super.key,
  });

  ///Function to be executed after the item was added.
  final Function(String value) itemAdded;

  ///The overlay list of items settings.
  final SimpleOverlaySettings overlayListSettings;

  /// The typed text that would become the new item.
  final String text;

  /// Widget shown between the text and the create button.
  final Widget? addAdditionalWidget;

  /// Source of the default texts; `null` uses [SearchDropDownStringsScope]
  /// (Portuguese without one).
  final SearchDropDownStrings? strings;

  @override
  State<DefaultAddListItem> createState() => _DefaultAddListItemState();
}

class _DefaultAddListItemState extends State<DefaultAddListItem>
    with BusyRow<DefaultAddListItem> {
  Future<void> _handleItemAdded() =>
      runBusy(() => widget.itemAdded(widget.text));

  @override
  Widget build(BuildContext context) {
    final SearchDropDownStrings texts =
        widget.strings ?? SearchDropDownStrings.of(context);
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
          if (widget.addAdditionalWidget != null)
            Flexible(child: widget.addAdditionalWidget!),
          Flexible(
            child: busyActions(
              TextButton(
                onPressed: _handleItemAdded,
                child: Text(
                  widget.overlayListSettings.customAddItemHint ?? texts.addItem,
                  style: widget.overlayListSettings.addItemHintStyle,
                ),
              ),
              widget.overlayListSettings,
              texts,
            ),
          ),
        ],
      ),
    );
  }
}
