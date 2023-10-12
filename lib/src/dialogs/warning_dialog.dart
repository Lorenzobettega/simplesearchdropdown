import 'package:flutter/material.dart';
import 'package:simple_search_dropdown/simple_search_dropdown.dart';

class WarningDialog extends StatelessWidget {
  const WarningDialog({
    super.key,
    this.settings,
    required this.returnFunction,
    this.confirmDialog = true,
  });
  final DialogSettings? settings;
  final Function(bool) returnFunction;
  final bool confirmDialog;

  @override
  Widget build(BuildContext context) {
    final dialogSettings = settings ?? DialogSettings();
    return AlertDialog(
      title: dialogSettings.title ??
          DefaultDialogTitle(confirmDialog: confirmDialog),
      content: dialogSettings.content ??
          DefaultDialogContent(confirmDialog: confirmDialog),
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
                buttonSettings: dialogSettings.customCancelButtonSettings ??
                    defaultCancelButtonSettings,
              ),
              DialogButton(
                function: () => returnFunction(true),
                buttonSettings: dialogSettings.customDeleteButtonSettings ??
                    defaultDeleteButtonSettings,
              ),
            ]
          : [
              DialogButton(
                function: () => returnFunction(true),
                buttonSettings: dialogSettings.customVerifyButtonSettings ??
                    defaultVerifyButtonSettings,
              ),
            ],
    );
  }
}
