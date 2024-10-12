import 'package:flutter/material.dart';
import 'package:simple_search_dropdown/simple_search_dropdown.dart';

///Class to hold all the customizations of the simple search bar.
class SimpleSearchbarSettings {
  const SimpleSearchbarSettings({
    this.dropdownWidth = 300,
    this.dropdownHeight = 50,
    this.elevation = 2,
    this.backgroundColor = Colors.white,
    this.border = const RoundedRectangleBorder(
      borderRadius: BorderRadius.all(
        Radius.circular(10),
      ),
    ),
    this.clearIconColor,
    this.searchBarTextStyle,
    this.actions,
    this.hint = 'Pesquisar',
    this.hintStyle = const TextStyle(fontSize: 14),
    this.hoverColor = const Color.fromRGBO(245, 245, 245, 1),
    this.showArrow = true,
    this.showClearIcon = true,
    this.dropdownClosedArrowIcon = Icons.arrow_drop_down,
    this.dropdownOpenedArrowIcon = Icons.arrow_drop_up,
    this.outsideIconColor,
    this.outsideIconSize = 20,
    this.clearOnClose = false,
    this.boxMultiSelectedClearIconSize = 20,
    this.boxMultiSelectedClearIconColor,
    this.boxMultiItemWidgetBuilder,
    this.boxMultiSelectedBackgroundColor =
        const Color.fromRGBO(224, 224, 224, 1),
    this.boxMultiSelectedTextStyle,
  });

  ///Main/outside Container height(default:50)
  final double dropdownHeight;

  ///Main/outside Container width(default:300)
  final double dropdownWidth;

  ///The background color of the searchbar and overlay.
  final Color backgroundColor;

  ///The elevation of the searchbar and overlay (default:2).
  final double elevation;

  ///The border of the searchbar.
  final OutlinedBorder? border;

  ///If true, the "x" icon will appear on the end of the searchbar (default:true).
  final bool showClearIcon;

  ///The color of "x" clear icon on the end of the searchbar.
  final Color? clearIconColor;

  ///List of widgets that will go on the end of the search bar.
  final List<Widget>? actions;

  ///The style of searchbar text when something is typed (default:hintStyle)
  final TextStyle? searchBarTextStyle;

  ///The text to be presented on the hint of the searchbar.
  final String hint;

  ///The style of the hint of the searchbar.
  final TextStyle? hintStyle;

  ///The hover color of the searchbar.
  final Color hoverColor;

  ///If true, the arrow icon will appear on the end of the searchbar (default:true).
  final bool showArrow;

  ///Action Icon showed when dropdown is closed
  final IconData dropdownClosedArrowIcon;

  ///Action Icon showed when dropdown is opened
  final IconData dropdownOpenedArrowIcon;

  ///Action dropdown Icon color
  final Color? outsideIconColor;

  ///Action dropdown Icon size (default:20)
  final double outsideIconSize;

  ///If true, the value on the Searchbar will be cleared if nothing was selected (default:false).
  final bool clearOnClose;

  ///Outside/horizontal list of selected items clear icon size (default:20)
  final double boxMultiSelectedClearIconSize;

  ///Outside/horizontal list of selected items clear icon color
  final Color? boxMultiSelectedClearIconColor;

  ///Outside/horizontal list of selected items Background color
  final Color boxMultiSelectedBackgroundColor;

  ///Outside/horizontal list of selected items Background color
  final TextStyle? boxMultiSelectedTextStyle;

  ///Outside/horizontal list of selected items custom widget
  final Widget Function(ValueItem)? boxMultiItemWidgetBuilder;
}

///The default settings for the SimpleSearchbar.
const defaultSearchBarSettings = SimpleSearchbarSettings();
