import 'package:flutter/material.dart';
import 'package:simple_search_dropdown/simple_search_dropdown.dart';

/// Delete confirmation (`confirmDialog: true`) or invalid-item warning.
class WarningDialog extends StatelessWidget {
  /// Creates a warning dialog.
  const WarningDialog({
    super.key,
    this.settings,
    required this.returnFunction,
    this.confirmDialog = true,
    this.strings,
  });

  /// Visual customisation.
  final DialogSettings? settings;

  /// Called with `true` (confirm/OK) or `false` (cancel).
  final Function(bool) returnFunction;

  /// Delete confirmation when `true`, invalid-item warning otherwise.
  final bool confirmDialog;

  /// Source of the default texts; `null` uses [SearchDropDownStringsScope]
  /// (Portuguese without one).
  final SearchDropDownStrings? strings;

  @override
  Widget build(BuildContext context) {
    final dialogSettings = settings ?? const DialogSettings();
    final SearchDropDownStrings texts =
        strings ?? SearchDropDownStrings.of(context);
    return AlertDialog(
      title:
          dialogSettings.title ??
          DefaultDialogTitle(confirmDialog: confirmDialog, strings: texts),
      content:
          dialogSettings.content ??
          DefaultDialogContent(confirmDialog: confirmDialog, strings: texts),
      contentPadding: dialogSettings.contentPadding,
      titlePadding: dialogSettings.titlePadding,
      actionsPadding: dialogSettings.actionsPadding,
      actionsAlignment: dialogSettings.actionsAlignment,
      backgroundColor: dialogSettings.backgroundColor,
      elevation: dialogSettings.elevation,
      shape: dialogSettings.shape,
      insetPadding: dialogSettings.insetPadding,
      actions: confirmDialog
          ? [
              DialogButton(
                function: () => returnFunction(false),
                buttonSettings: dialogSettings.cancelButton(texts),
              ),
              DialogButton(
                function: () => returnFunction(true),
                buttonSettings: dialogSettings.deleteButton(texts),
              ),
            ]
          : [
              DialogButton(
                function: () => returnFunction(true),
                buttonSettings: dialogSettings.okButton(texts),
              ),
            ],
    );
  }
}
