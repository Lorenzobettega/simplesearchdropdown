import 'package:flutter/material.dart';

/// The "X" button that clears the selection.
class ClearButton extends StatelessWidget {
  /// Creates a clear button; hidden (but laid out) when [visible] is false.
  const ClearButton({
    super.key,
    required this.visible,
    required this.onPressed,
    required this.iconColor,
    required this.iconSize,
    this.tooltip,
  });

  /// Whether the button is shown.
  final bool visible;

  /// Called on tap.
  final VoidCallback onPressed;

  /// Icon color.
  final Color? iconColor;

  /// Icon size.
  final double iconSize;

  /// Tooltip and semantics label.
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    return Visibility(
      visible: visible,
      child: IconButton(
        tooltip: tooltip,
        onPressed: onPressed,
        icon: Icon(Icons.clear, color: iconColor, size: iconSize),
      ),
    );
  }
}
