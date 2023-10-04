import 'package:flutter/material.dart';

class OverlayScreen {
  /// Create an Overlay on the screen
  /// Declared [overlayEntrys] as List<OverlayEntry> because we might have
  /// more than one Overlay on the screen, so we keep it on a list and remove all at once
  BuildContext _context;
  late OverlayState overlayState;
  List<OverlayEntry> overlayEntrys = [];

  void closeAll() {
    for (final overlay in overlayEntrys) {
      overlay.remove();
    }
    overlayEntrys.clear();
  }

  void closeLast() {
    overlayEntrys.removeLast().remove();
  }

  void show(OverlayEntry entry) {
    overlayEntrys.add(entry);

    overlayState.insert(overlayEntrys.last);
  }

  OverlayScreen._create(this._context) {
    overlayState = Overlay.of(_context);
  }

  factory OverlayScreen.of(BuildContext context) {
    return OverlayScreen._create(context);
  }
}
