import 'package:flutter/material.dart';
import 'package:simple_search_dropdown/simple_search_dropdown.dart';

class ConfirmDeleteDialog extends StatelessWidget {
  const ConfirmDeleteDialog({
    super.key,
    this.settings,
    required this.returnFunction,
  });
  final DialogSettings? settings;
  final Function(bool) returnFunction;

  @override
  Widget build(BuildContext context) {
    final dialogSettings = settings ?? DialogSettings();
    return AlertDialog(
      title: dialogSettings.title ?? const DefaultDialogTitle(),
      content: dialogSettings.content ?? const DefaultDialogContent(),
      contentPadding: dialogSettings.contentPadding,
      titlePadding: dialogSettings.titlePadding,
      actionsPadding: dialogSettings.actionsPadding,
      actionsAlignment: dialogSettings.actionsAlignment,
      backgroundColor: dialogSettings.backgroundColor,
      elevation: dialogSettings.elevation,
      shape: dialogSettings.shape,
      insetPadding: dialogSettings.insetPadding,
      actions: [
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
      ],
    );
  }
}
