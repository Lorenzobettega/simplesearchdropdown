import 'package:flutter/material.dart';

/// Controls the overlays on the screen.
class OverlayScreen {
  ///local init function.
  OverlayScreen._create(this._context) {
    overlayState = Overlay.of(_context);
  }

  ///exposed init function.
  factory OverlayScreen.of(BuildContext context) {
    return OverlayScreen._create(context);
  }

  /// The context of the dropdown.
  BuildContext _context;

  /// The overlay state of the dropdown.
  late OverlayState overlayState;

  /// Declared [overlayEntrys] as List<OverlayEntry> because we might have
  /// more than one Overlay on the screen, so we keep it on a list and remove all at once.
  List<OverlayEntry> overlayEntrys = [];

  ///Kill all the overlays.
  void closeAll() {
    for (final overlay in overlayEntrys) {
      overlay.remove();
    }
    overlayEntrys.clear();
  }

  ///Kill last presented overlay.
  void closeLast() {
    overlayEntrys.removeLast().remove();
  }

  ///Update last presented overlay.
  void updateLast() {
    overlayEntrys.last.markNeedsBuild();
  }

  ///Show a new overlay on top of others.
  void show(OverlayEntry entry) {
    overlayEntrys.add(entry);

    overlayState.insert(overlayEntrys.last);
  }
}
