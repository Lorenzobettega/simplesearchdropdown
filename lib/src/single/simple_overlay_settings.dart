import 'package:flutter/material.dart';

///Class to hold all the customizations of the simple search overlay list.
class SimpleOverlaySettings {
  SimpleOverlaySettings({
    this.dialogHeight,
    this.itemsPadding,
    this.selectedItemBackgroundColor,
    this.selectedItemHoverColor,
    this.selectedItemTextStyle,
    this.unselectedItemTextStyle,
    this.unselectedItemHoverColor,
    this.dialogActionIcon,
    this.dialogActionWidget,
    this.separatorHeight,
    this.animationDuration,
  });

  ///Dropdown Container height
  final double? dialogHeight;

  ///The padding for the items of the list.
  ///
  ///default: `EdgeInsets.symmetric(horizontal: 4)`
  final EdgeInsets? itemsPadding;

  ///The hover color of the selected item of the list.
  final Color? selectedItemHoverColor;

  ///Selected item background color
  final Color? selectedItemBackgroundColor;

  ///Selected item TextStyle
  final TextStyle? selectedItemTextStyle;

  ///Unselected droplist items TextStyle.
  final TextStyle? unselectedItemTextStyle;

  ///The hover color of the unselected items of the list.
  final Color? unselectedItemHoverColor;

  ///The delete Icon in dropdown listview (default:red trash)
  final Icon? dialogActionIcon;

  ///The delete Widget in dropdown listview (default:IconButton). It replaces the `dialogActionIcon`
  final Widget? dialogActionWidget;

  ///Separator between two items inside the droplist
  final double? separatorHeight;

  ///The duration of the dropdown opening animation.
  final Duration? animationDuration;
}
