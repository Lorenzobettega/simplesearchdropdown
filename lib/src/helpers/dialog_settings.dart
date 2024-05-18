import 'package:flutter/material.dart';

///Class to hold all the customizations of the confirmation dialog.
class DialogSettings {
  const DialogSettings({
    this.title,
    this.content,
    this.contentPadding,
    this.titlePadding,
    this.actionsPadding,
    this.actionsAlignment,
    this.backgroundColor,
    this.elevation,
    this.shape,
    this.customCancelButtonSettings = defaultCancelButtonSettings,
    this.customDeleteButtonSettings = defaultDeleteButtonSettings,
    this.customVerifyButtonSettings = defaultVerifyButtonSettings,
    this.insetPadding = const EdgeInsets.symmetric(
      horizontal: 40,
      vertical: 24,
    ),
  });

  final Widget? title;
  final Widget? content;
  final DialogButtonSettings customCancelButtonSettings;
  final DialogButtonSettings customDeleteButtonSettings;
  final DialogButtonSettings customVerifyButtonSettings;
  final EdgeInsetsGeometry? contentPadding, titlePadding, actionsPadding;
  final EdgeInsets insetPadding;
  final MainAxisAlignment? actionsAlignment;
  final Color? backgroundColor;
  final double? elevation;
  final ShapeBorder? shape;
}

///Class to hold all the customizations of the buttons in the dialog.
class DialogButtonSettings {
  const DialogButtonSettings(
    this.text, {
    this.padding = const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
    this.textColor = Colors.white,
    this.activeBorder = false,
    this.mediumFont = true,
    this.radius = 10,
    this.customHeight = 50,
    this.fontSize = 16,
    this.iconsize,
    this.customWidth,
    this.backgroundColor,
    this.icon,
  });

  final String text;
  final Color? backgroundColor;
  final Color textColor;
  final bool activeBorder, mediumFont;
  final EdgeInsets padding;
  final double? customWidth, customHeight, iconsize;
  final IconData? icon;
  final double fontSize, radius;
}

///Default settings for Delete button.
const defaultDeleteButtonSettings = DialogButtonSettings(
  'Apagar',
  backgroundColor: Color.fromARGB(255, 198, 0, 0),
  customWidth: 160,
);

///Default settings for Cancel button.
const defaultCancelButtonSettings = DialogButtonSettings(
  'Cancelar',
  backgroundColor: Colors.white,
  textColor: Color.fromARGB(255, 66, 70, 76),
  customWidth: 160,
  activeBorder: true,
);

///Default settings for OK button.
const defaultVerifyButtonSettings = DialogButtonSettings(
  'OK',
  customWidth: 160,
);

///Default title for the dialog.
class DefaultDialogTitle extends StatelessWidget {
  const DefaultDialogTitle({super.key, required this.confirmDialog});
  final bool confirmDialog;
  @override
  Widget build(BuildContext context) {
    return Text(
      confirmDialog ? 'Tem certeza?' : 'Erro!',
      style: const TextStyle(
        fontWeight: FontWeight.bold,
        fontSize: 18,
      ),
      textAlign: TextAlign.center,
    );
  }
}

///Default content for the dialog.
class DefaultDialogContent extends StatelessWidget {
  const DefaultDialogContent({super.key, required this.confirmDialog});
  final bool confirmDialog;
  @override
  Widget build(BuildContext context) {
    return Text(
      confirmDialog
          ? 'Essa ação não poderá ser desfeita.'
          : 'O valor adicionado não é válido.',
      style: const TextStyle(
        fontSize: 16,
      ),
      textAlign: TextAlign.center,
    );
  }
}
