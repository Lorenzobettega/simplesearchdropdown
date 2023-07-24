import 'package:flutter/material.dart';

class OverlayWidget extends StatelessWidget {
  final Widget child;
  final double top;
  final double left;

  const OverlayWidget({super.key, required this.child, required this.top, required this.left});

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: top,
      left: left,
      child: Material(
        color: Colors.transparent,
        child: child,
      ),
    );
  }
}