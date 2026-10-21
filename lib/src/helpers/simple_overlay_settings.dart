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
    Color? selectedItemBackgroundColor,
    Color? selectedItemHoverColor,
    this.selectedItemTextStyle = const TextStyle(color: Colors.black),
    this.unselectedItemTextStyle = const TextStyle(color: Colors.black45),
    Color? unselectedItemHoverColor,
    this.highlightedItemBackgroundColor,
    Color? highlightedItemBorderColor,
    Icon? dialogDeleteIcon,
    Icon? dialogEditIcon,
    this.dialogActionWidget,
    this.separatorHeight = 1,
    this.animationDuration = const Duration(milliseconds: 100),
    String? addItemHint,
    this.addItemHintStyle,
    this.itemWidgetBuilder,
    this.reOpenedScrollDuration = const Duration(seconds: 1),
    this.offsetHeight = 3,
    this.offsetWidth = 0,
    this.additionalWidgetSpacing = 5,
    this.openFullScreen = false,
    Color? loadingColor,
    this.loadingSize = 24,
    this.loadingStrokeWidth = 2.5,
  }) : customAddItemHint = addItemHint,
       customSelectedItemBackgroundColor = selectedItemBackgroundColor,
       customSelectedItemHoverColor = selectedItemHoverColor,
       customUnselectedItemHoverColor = unselectedItemHoverColor,
       customHighlightedItemBorderColor = highlightedItemBorderColor,
       customDialogDeleteIcon = dialogDeleteIcon,
       customDialogEditIcon = dialogEditIcon,
       customLoadingColor = loadingColor;

  ///Dropdown Container height (default:`200`).
  final double dialogHeight;

  ///Dropdown Container color
  final Color? dialogBackgroundColor;

  ///The padding for the items of the list.
  ///
  ///default: `EdgeInsets.symmetric(horizontal: 4)`
  final EdgeInsets itemsPadding;

  ///The selected item hover color set explicitly, or `null` to follow the
  ///theme.
  final Color? customSelectedItemHoverColor;

  ///The hover color of the selected item of the list (default: light grey;
  ///under a dark theme `colorScheme.onSecondaryContainer` at 12%).
  Color get selectedItemHoverColor =>
      customSelectedItemHoverColor ?? const Color.fromRGBO(224, 224, 224, 1);

  ///The selected item background color set explicitly, or `null` to follow
  ///the theme.
  final Color? customSelectedItemBackgroundColor;

  ///Selected item background color (default: `Colors.black38`; under a dark
  ///theme `colorScheme.secondaryContainer`).
  Color get selectedItemBackgroundColor =>
      customSelectedItemBackgroundColor ?? Colors.black38;

  ///Selected item TextStyle (default: black text; under a dark theme a style
  ///equal to the default draws in `colorScheme.onSecondaryContainer`).
  final TextStyle? selectedItemTextStyle;

  ///Unselected droplist items TextStyle (default: `Colors.black45` text;
  ///under a dark theme a style equal to the default draws in
  ///`colorScheme.onSurfaceVariant`).
  final TextStyle? unselectedItemTextStyle;

  ///The unselected item hover color set explicitly, or `null` to follow the
  ///theme.
  final Color? customUnselectedItemHoverColor;

  ///The hover color of the unselected items of the list (default: light
  ///grey; under a dark theme `colorScheme.onSurface` at 8%).
  Color get unselectedItemHoverColor =>
      customUnselectedItemHoverColor ?? const Color.fromRGBO(245, 245, 245, 1);

  ///Background of the row highlighted with the keyboard arrows (default:
  ///[unselectedItemHoverColor] with the stock [selectedItemTextStyle] and
  ///[unselectedItemHoverColor]; once you customise either one,
  ///[selectedItemBackgroundColor], so the row keeps your selected pair as in 7.x).
  ///A selected row stays [selectedItemBackgroundColor] and gets the border.
  final Color? highlightedItemBackgroundColor;

  ///The highlight border color set explicitly, or `null` to follow the theme.
  final Color? customHighlightedItemBorderColor;

  ///Border of the row highlighted with the keyboard arrows, the selected row
  ///included (default: `Colors.black26`; under a dark theme
  ///`colorScheme.outline`).
  Color get highlightedItemBorderColor =>
      customHighlightedItemBorderColor ?? Colors.black26;

  ///The delete icon set explicitly, or `null` to follow the theme.
  final Icon? customDialogDeleteIcon;

  ///The delete Icon in dropdown listview (default: red trash, 20; under a
  ///dark theme in `colorScheme.error`).
  Icon get dialogDeleteIcon =>
      customDialogDeleteIcon ??
      const Icon(Icons.delete, color: Color.fromRGBO(183, 28, 28, 1), size: 20);

  ///The edit icon set explicitly, or `null` to follow the theme.
  final Icon? customDialogEditIcon;

  ///The edit Icon in dropdown listview (default: black pencil, 20; under a
  ///dark theme in `colorScheme.onSurfaceVariant`).
  Icon get dialogEditIcon =>
      customDialogEditIcon ??
      const Icon(Icons.edit, color: Colors.black, size: 20);

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

  ///Opens the list full screen (default: `false`).
  final bool openFullScreen;

  ///The spinner color set explicitly, or `null` to follow the theme.
  final Color? customLoadingColor;

  ///Color of the spinner a row shows while its callback runs (default:
  ///[darkGreen]; under a dark theme `colorScheme.primary`).
  Color get loadingColor => customLoadingColor ?? darkGreen;

  ///Size of that spinner, the size of the icons it replaces (default:`24`).
  final double loadingSize;

  ///Stroke width of that spinner (default:`2.5`).
  final double loadingStrokeWidth;
}

///The default settings for the OverlayList.
const defaultOverlaySettings = SimpleOverlaySettings();
