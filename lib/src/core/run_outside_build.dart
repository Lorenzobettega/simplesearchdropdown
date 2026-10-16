import 'package:flutter/scheduler.dart';

/// Runs [callback] now, or after the frame when called during a build (user
/// callbacks and listeners often call `setState`). A deferred [callback] is
/// skipped when [isDisposed] returns `true` by then; without [isDisposed]
/// (user selection callbacks, which 7.x ran synchronously) it always runs.
///
/// Without an initialized binding (a plain `test()`, code before `runApp`) no
/// frame can be building, so [callback] runs synchronously, as in 7.x.
void runOutsideBuild(VoidCallback callback, [bool Function()? isDisposed]) {
  if (isBuilding()) {
    SchedulerBinding.instance.addPostFrameCallback((_) {
      if (isDisposed == null || !isDisposed()) {
        callback();
      }
    });
  } else {
    callback();
  }
}

/// Whether a frame is being built, i.e. [runOutsideBuild] would defer.
bool isBuilding() =>
    _bindingOrNull()?.schedulerPhase == SchedulerPhase.persistentCallbacks;

SchedulerBinding? _bindingOrNull() {
  try {
    return SchedulerBinding.instance;
  } catch (_) {
    // Not initialized: a FlutterError in debug, a null-check error in
    // release. Only the getter is guarded, never user code.
    return null;
  }
}
