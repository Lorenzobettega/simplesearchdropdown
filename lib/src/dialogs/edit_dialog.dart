import 'package:flutter/material.dart';
import 'package:simple_search_dropdown/simple_search_dropdown.dart';

class EditDialog extends StatelessWidget {
  const EditDialog({
    super.key,
    required this.label,
    this.settings,
    required this.returnFunction,
  });

  final String label;
  final DialogSettings? settings;
  final Function(bool, String retorno) returnFunction;

  @override
  Widget build(BuildContext context) {
    final dialogSettings = settings ?? const DialogSettings();
    final TextEditingController controller = TextEditingController();

    return AlertDialog(
      title: dialogSettings.title ??
          Text(
            'Editar o item:',
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
                label,
                style: const TextStyle(
                  fontWeight: FontWeight.w500,
                  fontSize: 16,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(
                height: 20,
              ),
              InputField(
                controle: controller,
                hint: dialogSettings.editHint,
              )
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
          function: () => returnFunction(false, ''),
          buttonSettings: dialogSettings.customCancelButtonSettings,
        ),
        DialogButton(
          function: () {
            if (controller.text.isNotEmpty) {
              returnFunction(true, controller.text);
            }
          },
          buttonSettings: dialogSettings.customEditButtonSettings,
        ),
      ],
    );
  }
}
