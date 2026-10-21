import 'package:flutter/material.dart';
import 'package:simple_search_dropdown/src/helpers/dialog_settings.dart';

/// A button of the package dialogs, styled by [DialogButtonSettings].
class DialogButton extends StatelessWidget {
  /// Creates a dialog button.
  const DialogButton({
    super.key,
    required this.function,
    required this.buttonSettings,
  });

  /// Called when pressed.
  final Function function;

  /// Visual settings and label.
  final DialogButtonSettings buttonSettings;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final bool themed = buttonSettings.useThemeColors;
    final Color ink = themed ? scheme.onSurface : buttonSettings.textColor;
    final text = Text(
      buttonSettings.text,
      style: TextStyle(
        fontSize: buttonSettings.fontSize,
        color: ink,
        fontWeight: buttonSettings.mediumFont
            ? FontWeight.w500
            : FontWeight.normal,
      ),
    );
    return Container(
      width: buttonSettings.customWidth,
      height: buttonSettings.customHeight,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(buttonSettings.radius),
        border: buttonSettings.activeBorder
            ? Border.all(color: themed ? scheme.outline : ink)
            : null,
      ),
      child: TextButton(
        style: TextButton.styleFrom(
          padding: buttonSettings.padding,
          backgroundColor: buttonSettings.backgroundColor,
          foregroundColor: ink,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(
              Radius.circular(buttonSettings.radius),
            ),
          ),
        ),
        onPressed: () => function(),
        child: buttonSettings.icon == null
            ? text
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    buttonSettings.icon,
                    color: ink,
                    size: buttonSettings.iconsize,
                  ),
                  const SizedBox(width: 10),
                  text,
                ],
              ),
      ),
    );
  }
}
