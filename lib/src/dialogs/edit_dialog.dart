import 'package:flutter/material.dart';
import 'package:simple_search_dropdown/simple_search_dropdown.dart';

class EditDialog extends StatefulWidget {
  const EditDialog({
    super.key,
    required this.label,
    this.settings,
    required this.returnFunction,
    this.strings = const SearchDropDownStrings(),
  });

  /// Label of the item being edited.
  final String label;

  /// Visual customisation.
  final DialogSettings? settings;

  /// Called with `(true, newText)` on confirm or `(false, '')` on cancel.
  final void Function(bool, String) returnFunction;

  /// Source of the default texts.
  final SearchDropDownStrings strings;

  @override
  State<EditDialog> createState() => _EditDialogState();
}

class _EditDialogState extends State<EditDialog> {
  late TextEditingController controller;
  late final DialogSettings dialogSettings;

  @override
  void initState() {
    super.initState();
    controller = TextEditingController();
    dialogSettings = widget.settings ?? const DialogSettings();
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: dialogSettings.title ??
          Text(
            widget.strings.editTitle,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
            textAlign: TextAlign.center,
          ),
      content: dialogSettings.content ??
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
              const SizedBox(
                height: 20,
              ),
              InputField(
                controle: controller,
                hint: dialogSettings.editHint ?? widget.strings.editHint,
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
          buttonSettings: dialogSettings.cancelButton(widget.strings),
        ),
        DialogButton(
          function: () {
            if (controller.text.isNotEmpty) {
              widget.returnFunction(true, controller.text);
            }
          },
          buttonSettings: dialogSettings.editButton(widget.strings),
        ),
      ],
    );
  }
}
