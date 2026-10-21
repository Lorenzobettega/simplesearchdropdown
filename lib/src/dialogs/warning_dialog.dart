import 'package:flutter/material.dart';
import 'package:simple_search_dropdown/simple_search_dropdown.dart';
import 'package:simple_search_dropdown/src/dialogs/dialog_layout.dart';

/// Delete confirmation (`confirmDialog: true`) or invalid-item warning.
class WarningDialog extends StatelessWidget {
  /// Creates a warning dialog.
  const WarningDialog({
    super.key,
    this.settings,
    required this.returnFunction,
    this.confirmDialog = true,
    this.strings,
    this.itemLabel,
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

  /// Label of the item being deleted, named by the delete confirmation
  /// unless [DialogSettings.showItemLabel] is `false`.
  final String? itemLabel;

  @override
  Widget build(BuildContext context) {
    final dialogSettings = settings ?? const DialogSettings();
    final SearchDropDownStrings texts =
        strings ?? SearchDropDownStrings.of(context);
    final String? label = confirmDialog && dialogSettings.showItemLabel
        ? itemLabel
        : null;
    return PackageDialogLayout(
      settings: dialogSettings,
      title: DefaultDialogTitle(
        confirmDialog: confirmDialog,
        strings: texts,
        itemLabel: label,
      ),
      content: DefaultDialogContent(
        confirmDialog: confirmDialog,
        strings: texts,
        itemLabel: label,
      ),
      actions: confirmDialog
          ? [
              (
                settings: dialogSettings.cancelButton(texts),
                onPressed: () => returnFunction(false),
              ),
              (
                settings: dialogSettings.deleteButton(texts),
                onPressed: () => returnFunction(true),
              ),
            ]
          : [
              (
                settings: dialogSettings.okButton(texts),
                onPressed: () => returnFunction(true),
              ),
            ],
    );
  }
}
