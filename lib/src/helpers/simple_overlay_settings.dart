import 'package:flutter/material.dart';
import 'package:simple_search_dropdown/simple_search_dropdown.dart';

///default loading color
const Color darkGreen = Color.fromARGB(255, 0, 67, 0);

///Class to hold all the customizations of the simple search overlay list.
class SimpleOverlaySettings {
  /// Creates list settings; every field has a default.
  const SimpleOverlaySettings({
    this.dialogHeight = 200,
    this.dialogBackgroundColor,
    this.itemsPadding = const EdgeInsets.symmetric(horizontal: 4),
    this.selectedItemBackgroundColor = Colors.black38,
    this.selectedItemHoverColor = const Color.fromRGBO(224, 224, 224, 1),
    this.selectedItemTextStyle = const TextStyle(color: Colors.black),
    this.unselectedItemTextStyle = const TextStyle(color: Colors.black45),
    this.unselectedItemHoverColor = const Color.fromRGBO(245, 245, 245, 1),
    this.highlightedItemBackgroundColor,
    this.highlightedItemBorderColor = Colors.black26,
    this.dialogDeleteIcon = const Icon(
      Icons.delete,
      color: Color.fromRGBO(183, 28, 28, 1),
      size: 20,
    ),
    this.dialogEditIcon = const Icon(Icons.edit, color: Colors.black, size: 20),
    this.dialogActionWidget,
    this.separatorHeight = 1,
    this.animationDuration = const Duration(milliseconds: 100),
    String? addItemHint,
    this.addItemHintStyle,
    this.itemWidgetBuilder,
    this.reOpenedScrollDuration = const Duration(seconds: 1),
    this.offsetHeight = 3,
    this.offsetWidth = 0,
    double? additionalWidgetSpacing,
    @Deprecated('Use additionalWidgetSpacing. Will be removed in 9.0.0')
    double? aditionalWidgetSpacing,
    this.openFullScreen = false,
    this.loadingColor = darkGreen,
    this.loadingSize = 28,
  }) : customAddItemHint = addItemHint,
       additionalWidgetSpacing =
           additionalWidgetSpacing ?? aditionalWidgetSpacing ?? 5;

  ///Dropdown Container height (default:`200`).
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

  ///Background of the row highlighted with the keyboard arrows
  ///(default: [unselectedItemHoverColor]).
  final Color? highlightedItemBackgroundColor;

  ///Border of the row highlighted with the keyboard arrows (default: `Colors.black26`).
  final Color highlightedItemBorderColor;

  ///The delete Icon in dropdown listview (default:red trash)
  final Icon dialogDeleteIcon;

  ///The edit Icon in dropdown listview (default:black edit)
  final Icon dialogEditIcon;

  ///The delete Widget in dropdown listview (default:IconButton). It replaces the `dialogActionIcon`
  final Widget? dialogActionWidget;

  ///Separator between two items inside the droplist (default:`1`).
  final double separatorHeight;

  ///The duration of the dropdown opening animation (default:`Duration(milliseconds: 100)`).
  final Duration animationDuration;

  ///The add button text set explicitly, or `null` to use
  ///[SearchDropDownStrings.addItem].
  final String? customAddItemHint;

  ///The text of the add button (default: `'Criar'`).
  String get addItemHint =>
      customAddItemHint ?? const SearchDropDownStrings().addItem;

  ///The style of the add button when user is allowed to add items in the list.
  final TextStyle? addItemHintStyle;

  ///Custom droplist item widget.
  final Widget Function(ValueItem)? itemWidgetBuilder;

  ///Duration to scroll down when the drop is reopened (default: `Duration(seconds: 1)`)
  final Duration reOpenedScrollDuration;

  ///The height of the offset from the bottom of the search bar (default:`3`).
  final double offsetHeight;

  ///The width of the offset from the left of the search bar (default:`0`).
  final double offsetWidth;

  ///The width of the space between the additional widget and the delete one (default:`5`).
  final double additionalWidgetSpacing;

  ///The width of the space between the additional widget and the delete one.
  @Deprecated('Use additionalWidgetSpacing. Will be removed in 9.0.0')
  double get aditionalWidgetSpacing => additionalWidgetSpacing;

  ///Opens the list full screen (default: `false`).
  final bool openFullScreen;

  ///Loading widget default color (default:`Color.fromARGB(255, 0, 67, 0)`)
  final Color loadingColor;

  ///Loading widget default color (default:`28`)
  final double loadingSize;
}

///The default settings for the OverlayList.
const defaultOverlaySettings = SimpleOverlaySettings();
