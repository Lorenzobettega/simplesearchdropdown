import 'package:flutter/foundation.dart';
import 'package:simple_search_dropdown/src/core/run_outside_build.dart';

/// What the single and multiple controllers share: the enabled state and
/// notifications that are safe during a build and after [dispose].
abstract class DropDownControllerBase extends ChangeNotifier {
  /// Creates the shared state, [enabled] at first.
  DropDownControllerBase({required bool enabled}) : _enabled = enabled;

  bool _enabled;
  bool _disposed = false;

  /// Whether the user can interact with the dropdown. When `false` it
  /// ignores pointer and keyboard input (the multiple dropdown is also
  /// dimmed and closes its open list); changes made from code still apply.
  bool get enabled => _enabled;
  set enabled(bool value) {
    if (_enabled == value) {
      return;
    }
    _enabled = value;
    notifyListeners();
  }

  /// Toggles [enabled].
  void toggleEnabled() => enabled = !_enabled;

  /// Whether [dispose] was called.
  bool get isDisposed => _disposed;

  /// Notifies now, or after the frame when called during a build (listeners
  /// often call `setState`); does nothing once disposed.
  @override
  void notifyListeners() {
    if (_disposed) {
      return;
    }
    runOutsideBuild(super.notifyListeners, () => _disposed);
  }

  /// Releases resources. Safe to call more than once.
  @override
  void dispose() {
    if (_disposed) {
      return;
    }
    _disposed = true;
    super.dispose();
  }
}
