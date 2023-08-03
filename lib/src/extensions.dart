import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

class MyCustomScrollBehavior extends MaterialScrollBehavior {
  // Override behavior methods and getters like dragDevices
  @override
  Set<PointerDeviceKind> get dragDevices => {
        PointerDeviceKind.touch,
        PointerDeviceKind.mouse,
      };
}

extension ConcatWithNullableExtension on String {
  String concatOrNull(String? other) => other == null ? this : '$this $other';
  String everythingBefore(String divider) => substring(0, indexOf(divider));
  String everythingBeforeOrAll(String divider) {
    try {
      return substring(0, indexOf(divider));
    } catch (_) {
      return this;
    }
  }

  String splitInPosition(String divider, int index) => split(divider)[index];
}
