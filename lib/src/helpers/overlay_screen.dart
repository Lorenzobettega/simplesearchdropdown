import 'package:flutter/material.dart';

/// Controls the overlays on the screen.
class OverlayScreen {
  ///local init function.
  OverlayScreen._create(this._context, [this._closeList]) {
    overlayState = Overlay.of(_context);
  }

  ///exposed init function.
  factory OverlayScreen.of(BuildContext context) {
    return OverlayScreen._create(context);
  }

  /// The context of the dropdown.
  BuildContext _context;

  /// Closes a list drawn outside [overlayEntrys] (see [overlayScreenWithList]).
  final VoidCallback? _closeList;

  /// The overlay state of the dropdown.
  late OverlayState overlayState;

  /// Declared [overlayEntrys] as `List<OverlayEntry>` because we might have
  /// more than one Overlay on the screen, so we keep it on a list and remove all at once.
  List<OverlayEntry> overlayEntrys = [];

  ///Kill all the overlays.
  void closeAll() {
    for (final overlay in overlayEntrys) {
      overlay.remove();
    }
    overlayEntrys.clear();
    _closeList?.call();
  }

  ///Kill last presented overlay.
  void closeLast() {
    final VoidCallback? closeList = _closeList;
    if (overlayEntrys.isEmpty && closeList != null) {
      // The list sits below every entry: it is the last one left.
      return closeList();
    }
    overlayEntrys.removeLast().remove();
  }

  ///Update last presented overlay.
  void updateLast() {
    if (overlayEntrys.isEmpty && _closeList != null) {
      // The list rebuilds by itself.
      return;
    }
    overlayEntrys.last.markNeedsBuild();
  }

  ///Show a new overlay on top of others.
  void show(OverlayEntry entry) {
    overlayEntrys.add(entry);

    overlayState.insert(overlayEntrys.last);
  }
}

/// An [OverlayScreen] whose [OverlayScreen.closeAll], and
/// [OverlayScreen.closeLast] once its own entries are gone, also run
/// [closeList]. Package-internal (hidden from the public library): it keeps
/// the 7.x `MultipleSearchDropDownState.overlayScreen` able to close the list,
/// which is now an `OverlayPortal`.
OverlayScreen overlayScreenWithList(
  BuildContext context, {
  required VoidCallback closeList,
}) => OverlayScreen._create(context, closeList);
