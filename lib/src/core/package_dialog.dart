import 'package:flutter/widgets.dart';

import '../helpers/dialog_service.dart';

/// Shows the dialog [build] returns with [sendDialog]. Its `close` callback
/// pops the route that holds the dialog, through the dialog's own context:
/// the caller's [context] may sit under a nested navigator (the dialog goes
/// on the root one) or unmount while the dialog is open.
Future<void> showPackageDialog(
  BuildContext context,
  Widget Function(VoidCallback close) build,
) {
  bool closed = false;
  return sendDialog<void>(
    context,
    Builder(
      builder: (BuildContext dialogContext) => build(() {
        if (!closed) {
          closed = true;
          Navigator.of(dialogContext).pop();
        }
      }),
    ),
  );
}

/// Reports an error thrown by a user callback started from a list row (add,
/// edit or delete) without letting it escape as an uncaught error.
void reportCallbackError(Object exception, StackTrace stack) {
  FlutterError.reportError(
    FlutterErrorDetails(
      exception: exception,
      stack: stack,
      library: 'simple_search_dropdown',
      context: ErrorDescription('while running a list row callback'),
    ),
  );
}
