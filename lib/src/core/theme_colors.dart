import 'package:flutter/material.dart';
import 'package:simple_search_dropdown/simple_search_dropdown.dart';

/// The stock settings, to tell a customised style from the default.
const SimpleOverlaySettings _stockList = SimpleOverlaySettings();
const SimpleSearchbarSettings _stockBar = SimpleSearchbarSettings();

/// Whether unset colours come from the colour scheme: under a light theme
/// they keep their fixed 8.0.0 values, so light apps look exactly as before.
bool _followsScheme(ThemeData theme) => theme.brightness == Brightness.dark;

/// `color` at [opacity], as Material state layers do.
Color _layer(Color color, double opacity) =>
    color.withAlpha((opacity * 255).round());

/// The colours a search bar (or multiple box) is drawn with: each one set in
/// [SimpleSearchbarSettings] wins; an unset one is the settings default under
/// a light theme and a [ColorScheme] role under a dark one.
@immutable
class BarColors {
  /// Resolves [bar]'s colours for [theme].
  factory BarColors.of(SimpleSearchbarSettings bar, ThemeData theme) {
    if (!_followsScheme(theme)) {
      return BarColors._(
        background: bar.backgroundColor,
        hover: bar.hoverColor,
        chipBackground: bar.boxMultiSelectedBackgroundColor,
        chipTextStyle: bar.boxMultiSelectedTextStyle,
        chipIconColor: bar.boxMultiSelectedClearIconColor,
        hintStyle: bar.hintStyle,
        shadow: Colors.grey,
      );
    }
    final ColorScheme scheme = theme.colorScheme;
    final TextStyle? chipText = bar.boxMultiSelectedTextStyle;
    final TextStyle? hint = bar.hintStyle;
    return BarColors._(
      background: bar.customBackgroundColor ?? scheme.surfaceContainerHigh,
      hover: bar.customHoverColor ?? _layer(scheme.onSurface, 0.08),
      chipBackground:
          bar.customBoxMultiSelectedBackgroundColor ??
          scheme.secondaryContainer,
      chipTextStyle: chipText?.color != null
          ? chipText
          : (chipText ?? const TextStyle()).copyWith(
              color: scheme.onSecondaryContainer,
            ),
      chipIconColor:
          bar.boxMultiSelectedClearIconColor ?? scheme.onSecondaryContainer,
      hintStyle: hint?.color != null
          ? hint
          : (hint ?? _stockBar.hintStyle ?? const TextStyle()).copyWith(
              color: scheme.onSurfaceVariant,
            ),
      shadow: Colors.black,
    );
  }

  const BarColors._({
    required this.background,
    required this.hover,
    required this.chipBackground,
    required this.chipTextStyle,
    required this.chipIconColor,
    required this.hintStyle,
    required this.shadow,
  });

  /// Fill of the bar, the multiple box and (without
  /// `dialogBackgroundColor`) the list.
  final Color background;

  /// Ink overlay of the bar.
  final Color hover;

  /// Fill of a selected-item chip in the multiple box.
  final Color chipBackground;

  /// Label style of that chip.
  final TextStyle? chipTextStyle;

  /// Color of that chip's remove icon.
  final Color? chipIconColor;

  /// Style of the hint.
  final TextStyle? hintStyle;

  /// Shadow color of the multiple box.
  final Color shadow;
}

/// The colours of the list rows, resolved like [BarColors].
@immutable
class ListColors {
  /// Resolves [list]'s colours for [theme].
  factory ListColors.of(SimpleOverlaySettings list, ThemeData theme) {
    // The stock text style pairs with the hover fill; a customised one keeps
    // the selected background on the highlighted row (7.x).
    final bool stockPair =
        list.selectedItemTextStyle == _stockList.selectedItemTextStyle &&
        list.unselectedItemHoverColor == _stockList.unselectedItemHoverColor;
    if (!_followsScheme(theme)) {
      return ListColors._(
        selectedBackground: list.selectedItemBackgroundColor,
        selectedHover: list.selectedItemHoverColor,
        unselectedHover: list.unselectedItemHoverColor,
        highlightedBackground:
            list.highlightedItemBackgroundColor ??
            (stockPair
                ? list.unselectedItemHoverColor
                : list.selectedItemBackgroundColor),
        highlightedBorder: list.highlightedItemBorderColor,
        selectedTextStyle: list.selectedItemTextStyle,
        unselectedTextStyle: list.unselectedItemTextStyle,
        editIcon: list.dialogEditIcon,
        deleteIcon: list.dialogDeleteIcon,
        loading: list.loadingColor,
      );
    }
    final ColorScheme scheme = theme.colorScheme;
    final Color selectedBackground =
        list.customSelectedItemBackgroundColor ?? scheme.secondaryContainer;
    final Color unselectedHover =
        list.customUnselectedItemHoverColor ?? _layer(scheme.onSurface, 0.08);
    return ListColors._(
      selectedBackground: selectedBackground,
      selectedHover:
          list.customSelectedItemHoverColor ??
          _layer(scheme.onSecondaryContainer, 0.12),
      unselectedHover: unselectedHover,
      highlightedBackground:
          list.highlightedItemBackgroundColor ??
          (stockPair ? unselectedHover : selectedBackground),
      highlightedBorder:
          list.customHighlightedItemBorderColor ?? scheme.outline,
      selectedTextStyle:
          list.selectedItemTextStyle == _stockList.selectedItemTextStyle
          ? TextStyle(color: scheme.onSecondaryContainer)
          : list.selectedItemTextStyle,
      unselectedTextStyle:
          list.unselectedItemTextStyle == _stockList.unselectedItemTextStyle
          ? TextStyle(color: scheme.onSurfaceVariant)
          : list.unselectedItemTextStyle,
      editIcon:
          list.customDialogEditIcon ??
          Icon(Icons.edit, color: scheme.onSurfaceVariant, size: 20),
      deleteIcon:
          list.customDialogDeleteIcon ??
          Icon(Icons.delete, color: scheme.error, size: 20),
      loading: list.customLoadingColor ?? scheme.primary,
    );
  }

  const ListColors._({
    required this.selectedBackground,
    required this.selectedHover,
    required this.unselectedHover,
    required this.highlightedBackground,
    required this.highlightedBorder,
    required this.selectedTextStyle,
    required this.unselectedTextStyle,
    required this.editIcon,
    required this.deleteIcon,
    required this.loading,
  });

  /// Fill of the selected row.
  final Color selectedBackground;

  /// Ink overlay of the selected row.
  final Color selectedHover;

  /// Ink overlay of the other rows.
  final Color unselectedHover;

  /// Fill of the row highlighted with the keyboard (not selected).
  final Color highlightedBackground;

  /// Border of the highlighted row.
  final Color highlightedBorder;

  /// Label style of the selected or highlighted row.
  final TextStyle? selectedTextStyle;

  /// Label style of the other rows.
  final TextStyle? unselectedTextStyle;

  /// The row's edit icon.
  final Icon editIcon;

  /// The row's delete icon.
  final Icon deleteIcon;

  /// Color of the row's spinner.
  final Color loading;
}
