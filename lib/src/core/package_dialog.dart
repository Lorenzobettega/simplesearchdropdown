import 'package:flutter/widgets.dart';
import 'package:simple_search_dropdown/simple_search_dropdown.dart';

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

/// Shows the warning for an item `verifyInputItem` rejected. Texts come
/// from [strings], else the [SearchDropDownStringsScope] above [context].
Future<void> showRejectedItemWarning(
  BuildContext context,
  DialogSettings? settings,
  SearchDropDownStrings? strings,
) {
  final SearchDropDownStrings texts =
      strings ?? SearchDropDownStrings.of(context);
  return showPackageDialog(
    context,
    (VoidCallback close) => WarningDialog(
      confirmDialog: false,
      returnFunction: (_) => close(),
      settings: settings,
      strings: texts,
    ),
  );
}

/// Asks the user to confirm deleting the item labelled [itemLabel]; `true`
/// when confirmed. Texts as in [showRejectedItemWarning].
Future<bool> confirmDeletion(
  BuildContext context,
  DialogSettings? settings,
  SearchDropDownStrings? strings, {
  String? itemLabel,
}) async {
  bool confirmed = false;
  final SearchDropDownStrings texts =
      strings ?? SearchDropDownStrings.of(context);
  await showPackageDialog(
    context,
    (VoidCallback close) => WarningDialog(
      returnFunction: (bool result) {
        confirmed = result;
        close();
      },
      settings: settings,
      strings: texts,
      itemLabel: itemLabel,
    ),
  );
  return confirmed;
}

/// Asks for a new label for an item labelled [label]. `null` when the user
/// cancels or confirms [label] unchanged (that is not an edit). Texts as in
/// [showRejectedItemWarning].
Future<String?> askNewLabel(
  BuildContext context,
  String label,
  DialogSettings? settings,
  SearchDropDownStrings? strings,
) async {
  String? newText;
  final SearchDropDownStrings texts =
      strings ?? SearchDropDownStrings.of(context);
  await showPackageDialog(
    context,
    (VoidCallback close) => EditDialog(
      label: label,
      returnFunction: (bool ok, String text) {
        if (ok) {
          newText = text;
        }
        close();
      },
      settings: settings,
      strings: texts,
    ),
  );
  return newText == label ? null : newText;
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
