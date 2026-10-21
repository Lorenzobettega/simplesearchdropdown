import 'package:flutter/material.dart';
import 'package:simple_search_dropdown/simple_search_dropdown.dart';

///Class to hold all the customizations of the simple search bar.
class SimpleSearchbarSettings {
  /// Creates search bar settings; every field has a default.
  const SimpleSearchbarSettings({
    this.dropdownWidth = 300,
    this.dropdownHeight = 50,
    this.elevation = 2,
    Color? backgroundColor,
    this.border = const RoundedRectangleBorder(
      borderRadius: BorderRadius.all(Radius.circular(10)),
    ),
    this.clearIconColor,
    this.searchBarTextStyle,
    this.actions,
    String? hint,
    this.hintStyle = const TextStyle(fontSize: 14),
    Color? hoverColor,
    this.showArrow = true,
    this.showClearIcon = true,
    this.dropdownClosedArrowIcon = Icons.arrow_drop_down,
    this.dropdownOpenedArrowIcon = Icons.arrow_drop_up,
    this.outsideIconColor,
    this.outsideIconSize = 20,
    this.dropdownClosedIconFunction,
    this.dropdownOpenedIconFunction,
    this.clearOnClose = false,
    this.boxMultiSelectedClearIconSize = 20,
    this.boxMultiSelectedClearIconColor,
    this.boxMultiItemWidgetBuilder,
    Color? boxMultiSelectedBackgroundColor,
    this.boxMultiSelectedTextStyle,
    this.searchBarPadding,
    this.showKeyboardOnTap = true,
    this.keyboardType,
    this.textInputAction,
    this.showDivider = false,
  }) : customHint = hint,
       customBackgroundColor = backgroundColor,
       customHoverColor = hoverColor,
       customBoxMultiSelectedBackgroundColor = boxMultiSelectedBackgroundColor;

  ///Main/outside Container height(default:50)
  final double dropdownHeight;

  ///Main/outside Container width(default:300)
  final double dropdownWidth;

  ///The background color set explicitly, or `null` to follow the theme.
  final Color? customBackgroundColor;

  ///The background color of the searchbar and overlay (default: white; under
  ///a dark theme the dropdowns use `colorScheme.surfaceContainerHigh`).
  Color get backgroundColor => customBackgroundColor ?? Colors.white;

  ///The elevation of the searchbar and overlay (default:2).
  final double elevation;

  ///The border of the searchbar.
  final OutlinedBorder border;

  ///If true, the "x" icon will appear on the end of the searchbar (default:true).
  final bool showClearIcon;

  ///The color of "x" clear icon on the end of the searchbar.
  final Color? clearIconColor;

  ///List of widgets that will go on the end of the search bar.
  final List<Widget>? actions;

  ///The style of searchbar text when something is typed (default:hintStyle)
  final TextStyle? searchBarTextStyle;

  ///The hint set explicitly, or `null` to use [SearchDropDownStrings.searchHint].
  final String? customHint;

  ///The hint of the searchbar (default: `'Pesquisar'`).
  String get hint => customHint ?? const SearchDropDownStrings().searchHint;

  ///The style of the hint of the searchbar. Without a color, a dark theme
  ///draws the hint in `colorScheme.onSurfaceVariant`.
  final TextStyle? hintStyle;

  ///The hover color set explicitly, or `null` to follow the theme.
  final Color? customHoverColor;

  ///The hover color of the searchbar (default: light grey; under a dark theme
  ///the dropdowns use `colorScheme.onSurface` at 8%).
  Color get hoverColor =>
      customHoverColor ?? const Color.fromRGBO(245, 245, 245, 1);

  ///If true, the arrow icon will appear on the end of the searchbar (default:true).
  final bool showArrow;

  ///Action Icon showed when dropdown is closed
  final IconData dropdownClosedArrowIcon;

  ///Function of the Icon showed when dropdown is closed
  final Function()? dropdownClosedIconFunction;

  ///Action Icon showed when dropdown is opened
  final IconData dropdownOpenedArrowIcon;

  ///Function of the Icon showed when dropdown is opened
  final Function()? dropdownOpenedIconFunction;

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

  ///The chip background color set explicitly, or `null` to follow the theme.
  final Color? customBoxMultiSelectedBackgroundColor;

  ///Outside/horizontal list of selected items Background color (default:
  ///light grey; under a dark theme the dropdowns use
  ///`colorScheme.secondaryContainer`).
  Color get boxMultiSelectedBackgroundColor =>
      customBoxMultiSelectedBackgroundColor ??
      const Color.fromRGBO(224, 224, 224, 1);

  ///Outside/horizontal list of selected items TextStyle
  final TextStyle? boxMultiSelectedTextStyle;

  ///Outside/horizontal list of selected items custom widget
  final Widget Function(ValueItem)? boxMultiItemWidgetBuilder;

  ///The internal padding of the searchBar
  final EdgeInsetsGeometry? searchBarPadding;

  ///If true, the keyboard will appear when you tap the searchbar (default:true).
  final bool showKeyboardOnTap;

  ///The keyboard type of the search bar.
  final TextInputType? keyboardType;

  ///The keyboard action button of the search bar.
  final TextInputAction? textInputAction;

  ///If true, a divider between the searchbar and the list of items will appear (default:false).
  final bool showDivider;
}

///The default settings for the SimpleSearchbar.
const defaultSearchBarSettings = SimpleSearchbarSettings();
