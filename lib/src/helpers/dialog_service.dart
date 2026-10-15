import 'package:flutter/material.dart';

/// Shows [child] as a dialog (not dismissible by tapping outside by default).
Future<T?> sendDialog<T>(BuildContext context, Widget child,
    {barrierDismissible = false}) async {
  return showDialog(
    context: context,
    barrierDismissible: barrierDismissible,
    builder: (BuildContext context) {
      return child;
    },
  );
}
