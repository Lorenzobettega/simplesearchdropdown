import 'package:flutter/material.dart';

class ClearButton extends StatelessWidget {
  const ClearButton({
    super.key,
    required this.visible,
    required this.onPressed,
    required this.iconColor,
    required this.iconSize,
  });

  final bool visible;
  final VoidCallback onPressed;
  final Color? iconColor;
  final double iconSize;

  @override
  Widget build(BuildContext context) {
    return Visibility(
      visible: visible,
      child: IconButton(
        onPressed: onPressed,
        icon: Icon(Icons.clear, color: iconColor, size: iconSize),
      ),
    );
  }
}
