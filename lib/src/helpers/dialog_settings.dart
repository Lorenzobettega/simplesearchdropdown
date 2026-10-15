import 'package:flutter/material.dart';
import 'package:simple_search_dropdown/src/core/search_dropdown_strings.dart';

///Class to hold all the customizations of the confirmation dialog.
class DialogSettings {
  /// Creates dialog settings; every field is optional.
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
    this.customCancelButtonSettings,
    this.customDeleteButtonSettings,
    this.customOkButtonSettings,
    this.customEditButtonSettings,
    this.insetPadding = const EdgeInsets.symmetric(
      horizontal: 40,
      vertical: 24,
    ),
    this.editHint,
  });

  /// Replaces the default title.
  final Widget? title;

  /// Replaces the default content.
  final Widget? content;

  /// Cancel button. Defaults to [defaultCancelButtonSettings] with
  /// [SearchDropDownStrings.cancelButton].
  final DialogButtonSettings? customCancelButtonSettings;

  /// Delete button. Defaults to [defaultDeleteButtonSettings] with
  /// [SearchDropDownStrings.deleteButton].
  final DialogButtonSettings? customDeleteButtonSettings;

  /// OK button. Defaults to [defaultOKButtonSettings] with
  /// [SearchDropDownStrings.okButton].
  final DialogButtonSettings? customOkButtonSettings;

  /// Edit button. Defaults to [defaultEditButtonSettings] with
  /// [SearchDropDownStrings.editButton].
  final DialogButtonSettings? customEditButtonSettings;

  /// Paddings forwarded to the [AlertDialog].
  final EdgeInsetsGeometry? contentPadding, titlePadding, actionsPadding;

  /// Inset padding forwarded to the [AlertDialog].
  final EdgeInsets insetPadding;

  /// Actions alignment forwarded to the [AlertDialog].
  final MainAxisAlignment? actionsAlignment;

  /// Background color forwarded to the [AlertDialog].
  final Color? backgroundColor;

  /// Elevation forwarded to the [AlertDialog].
  final double? elevation;

  /// Shape forwarded to the [AlertDialog].
  final ShapeBorder? shape;

  /// Hint of the edit field. Defaults to [SearchDropDownStrings.editHint].
  final String? editHint;

  /// The cancel button resolved against [strings].
  DialogButtonSettings cancelButton(SearchDropDownStrings strings) =>
      customCancelButtonSettings ??
      defaultCancelButtonSettings.copyWith(text: strings.cancelButton);

  /// The delete button resolved against [strings].
  DialogButtonSettings deleteButton(SearchDropDownStrings strings) =>
      customDeleteButtonSettings ??
      defaultDeleteButtonSettings.copyWith(text: strings.deleteButton);

  /// The OK button resolved against [strings].
  DialogButtonSettings okButton(SearchDropDownStrings strings) =>
      customOkButtonSettings ??
      defaultOKButtonSettings.copyWith(text: strings.okButton);

  /// The edit button resolved against [strings].
  DialogButtonSettings editButton(SearchDropDownStrings strings) =>
      customEditButtonSettings ??
      defaultEditButtonSettings.copyWith(text: strings.editButton);
}

///Class to hold all the customizations of the buttons in the dialog.
class DialogButtonSettings {
  /// Creates button settings with label [text].
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

  /// Button label.
  final String text;

  /// Button background color.
  final Color? backgroundColor;

  /// Label (and border) color.
  final Color textColor;

  /// Draws a border in [textColor]; uses a medium font weight.
  final bool activeBorder, mediumFont;

  /// Inner padding.
  final EdgeInsets padding;

  /// Fixed sizes; `null` lets the button size itself.
  final double? customWidth, customHeight, iconsize;

  /// Optional leading icon.
  final IconData? icon;

  /// Label font size and corner radius.
  final double fontSize, radius;

  /// A copy with the given fields replaced.
  DialogButtonSettings copyWith({String? text}) => DialogButtonSettings(
    text ?? this.text,
    padding: padding,
    textColor: textColor,
    activeBorder: activeBorder,
    mediumFont: mediumFont,
    radius: radius,
    customHeight: customHeight,
    fontSize: fontSize,
    iconsize: iconsize,
    customWidth: customWidth,
    backgroundColor: backgroundColor,
    icon: icon,
  );
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
const defaultOKButtonSettings = DialogButtonSettings('OK', customWidth: 160);

///Default settings for edit button.
const defaultEditButtonSettings = DialogButtonSettings(
  'Editar',
  customWidth: 160,
);

///Default title for the dialog.
class DefaultDialogTitle extends StatelessWidget {
  /// Creates the default title.
  const DefaultDialogTitle({
    super.key,
    required this.confirmDialog,
    this.strings = const SearchDropDownStrings(),
  });

  /// Confirmation (delete) title when `true`, invalid-item title otherwise.
  final bool confirmDialog;

  /// Source of the texts.
  final SearchDropDownStrings strings;

  @override
  Widget build(BuildContext context) {
    return Text(
      confirmDialog ? strings.confirmDeleteTitle : strings.invalidItemTitle,
      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
      textAlign: TextAlign.center,
    );
  }
}

///Default content for the dialog.
class DefaultDialogContent extends StatelessWidget {
  /// Creates the default content.
  const DefaultDialogContent({
    super.key,
    required this.confirmDialog,
    this.strings = const SearchDropDownStrings(),
  });

  /// Confirmation (delete) content when `true`, invalid-item content otherwise.
  final bool confirmDialog;

  /// Source of the texts.
  final SearchDropDownStrings strings;

  @override
  Widget build(BuildContext context) {
    return Text(
      confirmDialog ? strings.confirmDeleteContent : strings.invalidItemContent,
      style: const TextStyle(fontSize: 16),
      textAlign: TextAlign.center,
    );
  }
}
