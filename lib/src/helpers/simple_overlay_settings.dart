import 'package:flutter/material.dart';
import 'package:simple_search_dropdown/simple_search_dropdown.dart';

///Class to hold all the customizations of the simple search overlay list.
class SimpleOverlaySettings {
  const SimpleOverlaySettings({
    this.dialogHeight = 200,
    this.dialogBackgroundColor,
    this.itemsPadding = const EdgeInsets.symmetric(horizontal: 4),
    this.selectedItemBackgroundColor = Colors.black38,
    this.selectedItemHoverColor = const Color.fromRGBO(224, 224, 224, 1),
    this.selectedItemTextStyle = const TextStyle(color: Colors.black),
    this.unselectedItemTextStyle = const TextStyle(color: Colors.black45),
    this.unselectedItemHoverColor = const Color.fromRGBO(245, 245, 245, 1),
    this.dialogDeleteIcon = const Icon(
      Icons.delete,
      color: Color.fromRGBO(183, 28, 28, 1),
      size: 20,
    ),
    this.dialogActionWidget,
    this.separatorHeight = 1,
    this.animationDuration = const Duration(milliseconds: 100),
    this.addItemHint = 'Criar',
    this.addItemHintStyle,
    this.itemWidgetBuilder,
  });

  ///Dropdown Container height
  final double dialogHeight;

  ///Dropdown Container color
  final Color? dialogBackgroundColor;

  ///The padding for the items of the list.
  ///
  ///default: `EdgeInsets.symmetric(horizontal: 4)`
  final EdgeInsets itemsPadding;

  ///The hover color of the selected item of the list.
  final Color selectedItemHoverColor;

  ///Selected item background color
  final Color selectedItemBackgroundColor;

  ///Selected item TextStyle
  final TextStyle? selectedItemTextStyle;

  ///Unselected droplist items TextStyle.
  final TextStyle? unselectedItemTextStyle;

  ///The hover color of the unselected items of the list.
  final Color unselectedItemHoverColor;

  ///The delete Icon in dropdown listview (default:red trash)
  final Icon dialogDeleteIcon;

  ///The delete Widget in dropdown listview (default:IconButton). It replaces the `dialogActionIcon`
  final Widget? dialogActionWidget;

  ///Separator between two items inside the droplist
  final double separatorHeight;

  ///The duration of the dropdown opening animation (default:100 milliseconds).
  final Duration animationDuration;

  ///The text of the add button when user is allowed to add items in the list.
  final String addItemHint;

  ///The style of the add button when user is allowed to add items in the list.
  final TextStyle? addItemHintStyle;

  ///Custom droplist item widget.
  final Widget Function(ValueItem)? itemWidgetBuilder;
}

///The default settings for the OverlayList.
const defaultOverlaySettings = SimpleOverlaySettings();
