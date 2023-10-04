import 'package:flutter/material.dart';
import 'package:simple_search_dropdown/src/delete_dialog/dialog_settings.dart';

class DialogButton extends StatelessWidget {
  const DialogButton({
    super.key,
    required this.function,
    required this.buttonSettings,
  });
  final Function function;
  final DialogButtonSettings buttonSettings;

  @override
  Widget build(BuildContext context) {
    final text = Text(
      buttonSettings.text,
      style: TextStyle(
        fontSize: buttonSettings.fontSize,
        color: buttonSettings.textColor,
        fontWeight:
            buttonSettings.mediumFont ? FontWeight.w500 : FontWeight.normal,
      ),
    );
    return Container(
      width: buttonSettings.customWidth,
      height: buttonSettings.customHeight,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(buttonSettings.radius),
        border: buttonSettings.activeBorder
            ? Border.all(color: buttonSettings.textColor, width: 1)
            : null,
      ),
      child: TextButton(
        style: TextButton.styleFrom(
          padding: buttonSettings.padding,
          backgroundColor: buttonSettings.backgroundColor,
          shape: RoundedRectangleBorder(
            borderRadius:
                BorderRadius.all(Radius.circular(buttonSettings.radius)),
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
                    color: buttonSettings.textColor,
                    size: buttonSettings.iconsize,
                  ),
                  const SizedBox(
                    width: 10,
                  ),
                  text,
                ],
              ),
      ),
    );
  }
}
