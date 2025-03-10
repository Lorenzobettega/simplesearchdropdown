import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

/// This allows the mouse to drag the scrollable content.
class CustomScrollBehavior extends MaterialScrollBehavior {
  @override
  Set<PointerDeviceKind> get dragDevices => {
        PointerDeviceKind.touch,
        PointerDeviceKind.mouse,
      };
}
