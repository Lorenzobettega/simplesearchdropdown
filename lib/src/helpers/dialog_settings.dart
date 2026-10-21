import 'package:flutter/material.dart';
import 'package:simple_search_dropdown/src/core/search_dropdown_strings.dart';
import 'package:simple_search_dropdown/src/dialogs/dialog_layout.dart';
import 'package:simple_search_dropdown/src/helpers/simple_overlay_settings.dart';

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
    DialogButtonSettings? customCancelButtonSettings,
    DialogButtonSettings? customDeleteButtonSettings,
    DialogButtonSettings? customOkButtonSettings,
    DialogButtonSettings? customEditButtonSettings,
    this.insetPadding = const EdgeInsets.symmetric(
      horizontal: 40,
      vertical: 24,
    ),
    String? editHint,
    this.showItemLabel = true,
  }) : _cancel = customCancelButtonSettings,
       _delete = customDeleteButtonSettings,
       _ok = customOkButtonSettings,
       _edit = customEditButtonSettings,
       customEditHint = editHint;

  /// Replaces the default title.
  final Widget? title;

  /// Replaces the default content.
  final Widget? content;

  final DialogButtonSettings? _cancel;

  /// The cancel button (default: [defaultCancelButtonSettings]).
  DialogButtonSettings get customCancelButtonSettings =>
      _cancel ?? defaultCancelButtonSettings;

  final DialogButtonSettings? _delete;

  /// The delete button (default: [defaultDeleteButtonSettings]).
  DialogButtonSettings get customDeleteButtonSettings =>
      _delete ?? defaultDeleteButtonSettings;

  final DialogButtonSettings? _ok;

  /// The ok button (default: [defaultOKButtonSettings]).
  DialogButtonSettings get customOkButtonSettings =>
      _ok ?? defaultOKButtonSettings;

  final DialogButtonSettings? _edit;

  /// The edit button (default: [defaultEditButtonSettings]).
  DialogButtonSettings get customEditButtonSettings =>
      _edit ?? defaultEditButtonSettings;

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

  /// Whether the delete confirmation names the item being deleted
  /// ([SearchDropDownStrings.confirmDeleteItemTitle] and
  /// [SearchDropDownStrings.confirmDeleteItemContent]); `false` shows the
  /// generic [SearchDropDownStrings.confirmDeleteTitle] only.
  final bool showItemLabel;

  /// The edit hint set explicitly, or `null` to use
  /// [SearchDropDownStrings.editHint].
  final String? customEditHint;

  /// Hint of the edit field (default: `'Novo valor'`).
  String get editHint =>
      customEditHint ?? const SearchDropDownStrings().editHint;

  /// The cancel button resolved against [strings].
  DialogButtonSettings cancelButton(SearchDropDownStrings strings) =>
      _cancel ??
      defaultCancelButtonSettings.copyWith(text: strings.cancelButton);

  /// The delete button resolved against [strings].
  DialogButtonSettings deleteButton(SearchDropDownStrings strings) =>
      _delete ??
      defaultDeleteButtonSettings.copyWith(text: strings.deleteButton);

  /// The OK button resolved against [strings].
  DialogButtonSettings okButton(SearchDropDownStrings strings) =>
      _ok ?? defaultOKButtonSettings.copyWith(text: strings.okButton);

  /// The edit button resolved against [strings].
  DialogButtonSettings editButton(SearchDropDownStrings strings) =>
      _edit ?? defaultEditButtonSettings.copyWith(text: strings.editButton);
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
    this.useThemeColors = false,
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

  /// Paints the label in the theme's `onSurface` and the border in its
  /// `outline` instead of [textColor], so the button follows light and dark
  /// themes (the default cancel button).
  final bool useThemeColors;

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
    useThemeColors: useThemeColors,
  );
}

///Default settings for Delete button: filled red.
const defaultDeleteButtonSettings = DialogButtonSettings(
  'Apagar',
  backgroundColor: Color.fromARGB(255, 198, 0, 0),
  padding: _defaultButtonPadding,
  radius: _defaultButtonRadius,
  customHeight: _defaultButtonHeight,
);

///Default settings for Cancel button: outlined in the theme colours.
const defaultCancelButtonSettings = DialogButtonSettings(
  'Cancelar',
  textColor: Color.fromARGB(255, 66, 70, 76),
  activeBorder: true,
  useThemeColors: true,
  padding: _defaultButtonPadding,
  radius: _defaultButtonRadius,
  customHeight: _defaultButtonHeight,
);

///Default settings for OK button: filled [darkGreen].
const defaultOKButtonSettings = DialogButtonSettings(
  'OK',
  backgroundColor: darkGreen,
  padding: _defaultButtonPadding,
  radius: _defaultButtonRadius,
  customHeight: _defaultButtonHeight,
);

///Default settings for edit button: filled [darkGreen].
const defaultEditButtonSettings = DialogButtonSettings(
  'Editar',
  backgroundColor: darkGreen,
  padding: _defaultButtonPadding,
  radius: _defaultButtonRadius,
  customHeight: _defaultButtonHeight,
);

const EdgeInsets _defaultButtonPadding = EdgeInsets.symmetric(horizontal: 16);
const double _defaultButtonRadius = 12;
const double _defaultButtonHeight = 48;

///Default title for the dialog.
class DefaultDialogTitle extends StatelessWidget {
  /// Creates the default title.
  const DefaultDialogTitle({
    super.key,
    required this.confirmDialog,
    this.strings,
    this.itemLabel,
  });

  /// Label of the item a delete confirmation names; `null` shows the
  /// generic confirmation. Ignored by the invalid-item warning.
  final String? itemLabel;

  /// Confirmation (delete) title when `true`, invalid-item title otherwise.
  final bool confirmDialog;

  /// Source of the texts; `null` uses [SearchDropDownStringsScope]
  /// (Portuguese without one).
  final SearchDropDownStrings? strings;

  @override
  Widget build(BuildContext context) {
    final SearchDropDownStrings texts =
        strings ?? SearchDropDownStrings.of(context);
    final String title = !confirmDialog
        ? texts.invalidItemTitle
        : itemLabel == null
        ? texts.confirmDeleteTitle
        : texts.confirmDeleteItemTitle;
    return DialogTitleText(title);
  }
}

///Default content for the dialog.
class DefaultDialogContent extends StatelessWidget {
  /// Creates the default content.
  const DefaultDialogContent({
    super.key,
    required this.confirmDialog,
    this.strings,
    this.itemLabel,
  });

  /// Label of the item a delete confirmation names; `null` shows the
  /// generic confirmation. Ignored by the invalid-item warning.
  final String? itemLabel;

  /// Confirmation (delete) content when `true`, invalid-item content otherwise.
  final bool confirmDialog;

  /// Source of the texts; `null` uses [SearchDropDownStringsScope]
  /// (Portuguese without one).
  final SearchDropDownStrings? strings;

  @override
  Widget build(BuildContext context) {
    final SearchDropDownStrings texts =
        strings ?? SearchDropDownStrings.of(context);
    if (!confirmDialog) {
      return DialogSupportingText(texts.invalidItemContent);
    }
    final String? label = itemLabel;
    final Widget generic = DialogSupportingText(texts.confirmDeleteContent);
    if (label == null) {
      return generic;
    }
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        DialogSupportingText.withItem(texts.confirmDeleteItemContent, label),
        const SizedBox(height: 4),
        generic,
      ],
    );
  }
}
