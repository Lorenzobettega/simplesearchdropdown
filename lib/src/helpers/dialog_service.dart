import 'package:flutter/material.dart';

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