import 'package:flutter/material.dart';

///Class to hold all the customizations of the simple search bar.
class SimpleSearchbarSettings {
  const SimpleSearchbarSettings({
    this.border,
    this.clearIconColor,
    this.actions,
    this.hint,
    this.hintStyle,
    this.hoverColor,
    this.dropdownClosedArrowIcon,
    this.dropdownOpenedArrowIcon,
    this.outsideIconColor,
    this.outsideIconSize,
  });
  ///The border of the searchbar.
  final OutlinedBorder? border;
  ///The color of "x" clear icon on the end of the searchbar.
  final Color? clearIconColor;
  ///List of widgets that will go on the end of the search bar.
  final List<Widget>? actions;
  ///The text to be presented on the hint of the searchbar.
  final String? hint;
  ///The style of the hint of the searchbar.
  final TextStyle? hintStyle;
  ///The hover color of the searchbar.
  final Color? hoverColor;
  ///Action Icon showed when dropdown is closed
  final IconData? dropdownClosedArrowIcon;
  ///Action Icon showed when dropdown is opened
  final IconData? dropdownOpenedArrowIcon;
  ///Action dropdown Icon color
  final Color? outsideIconColor;
  ///Action dropdown Icon size(default:20)
  final double? outsideIconSize;
}