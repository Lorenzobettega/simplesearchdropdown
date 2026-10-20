import 'package:flutter/material.dart';
import 'package:simple_search_dropdown/simple_search_dropdown.dart';

/// Dialog that asks for a new label for an item (used by edit mode).
class EditDialog extends StatefulWidget {
  /// Creates an edit dialog for [label].
  const EditDialog({
    super.key,
    required this.label,
    this.settings,
    required this.returnFunction,
    this.strings,
  });

  /// Label of the item being edited.
  final String label;

  /// Visual customisation.
  final DialogSettings? settings;

  /// Called with `(true, newText)` on confirm or `(false, '')` on cancel.
  final void Function(bool, String) returnFunction;

  /// Source of the default texts; `null` uses [SearchDropDownStringsScope]
  /// (Portuguese without one).
  final SearchDropDownStrings? strings;

  @override
  State<EditDialog> createState() => _EditDialogState();
}

class _EditDialogState extends State<EditDialog> {
  late TextEditingController controller;
  late final DialogSettings dialogSettings;

  @override
  void initState() {
    super.initState();
    controller = TextEditingController(text: widget.label);
    dialogSettings = widget.settings ?? const DialogSettings();
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final SearchDropDownStrings texts =
        widget.strings ?? SearchDropDownStrings.of(context);
    return AlertDialog(
      title:
          dialogSettings.title ??
          Text(
            texts.editTitle,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            textAlign: TextAlign.center,
          ),
      content:
          dialogSettings.content ??
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                widget.label,
                style: const TextStyle(
                  fontWeight: FontWeight.w500,
                  fontSize: 16,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              InputField(
                controle: controller,
                hint: dialogSettings.customEditHint ?? texts.editHint,
              ),
            ],
          ),
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
          function: () => widget.returnFunction(false, ''),
          buttonSettings: dialogSettings.cancelButton(texts),
        ),
        DialogButton(
          function: () {
            if (controller.text.isNotEmpty) {
              widget.returnFunction(true, controller.text);
            }
          },
          buttonSettings: dialogSettings.editButton(texts),
        ),
      ],
    );
  }
}
