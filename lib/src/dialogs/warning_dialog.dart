import 'package:flutter/material.dart';
import 'package:simple_search_dropdown/simple_search_dropdown.dart';

class WarningDialog extends StatelessWidget {
  const WarningDialog({
    super.key,
    this.settings,
    required this.returnFunction,
    this.confirmDialog = true,
    this.strings = const SearchDropDownStrings(),
  });

  /// Visual customisation.
  final DialogSettings? settings;

  /// Called with `true` (confirm/OK) or `false` (cancel).
  final Function(bool) returnFunction;

  /// Delete confirmation when `true`, invalid-item warning otherwise.
  final bool confirmDialog;

  /// Source of the default texts.
  final SearchDropDownStrings strings;

  @override
  Widget build(BuildContext context) {
    final dialogSettings = settings ?? const DialogSettings();
    return AlertDialog(
      title: dialogSettings.title ??
          DefaultDialogTitle(confirmDialog: confirmDialog, strings: strings),
      content: dialogSettings.content ??
          DefaultDialogContent(confirmDialog: confirmDialog, strings: strings),
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
                buttonSettings: dialogSettings.cancelButton(strings),
              ),
              DialogButton(
                function: () => returnFunction(true),
                buttonSettings: dialogSettings.deleteButton(strings),
              ),
            ]
          : [
              DialogButton(
                function: () => returnFunction(true),
                buttonSettings: dialogSettings.okButton(strings),
              ),
            ],
    );
  }
}
