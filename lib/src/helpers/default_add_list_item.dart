import 'package:flutter/material.dart';
import 'package:simple_search_dropdown/simple_search_dropdown.dart';
import 'package:simple_search_dropdown/src/core/package_dialog.dart';

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

class _DefaultAddListItemState extends State<DefaultAddListItem> {
  bool _isLoading = false;

  Future<void> _handleItemAdded() async {
    setState(() => _isLoading = true);

    try {
      await widget.itemAdded(widget.text);
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
            child: _isLoading
                ? Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: SizedBox(
                      height: widget.overlayListSettings.loadingSize,
                      child: Loading(
                        cor: widget.overlayListSettings.loadingColor,
                        semanticsLabel: texts.loadingLabel,
                      ),
                    ),
                  )
                : TextButton(
                    onPressed: _handleItemAdded,
                    child: Text(
                      widget.overlayListSettings.customAddItemHint ??
                          texts.addItem,
                      style: widget.overlayListSettings.addItemHintStyle,
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
