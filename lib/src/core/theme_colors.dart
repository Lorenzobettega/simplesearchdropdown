import 'package:flutter/material.dart';
import 'package:simple_search_dropdown/simple_search_dropdown.dart';

/// The corner radius shared by the search bar, the multiple box and the open
/// list (the dialogs use the same 12).
const BorderRadius dropdownRadius = BorderRadius.all(Radius.circular(12));

/// The stock settings, to tell a customised style from the default.
const SimpleOverlaySettings _stockList = SimpleOverlaySettings();
const SimpleSearchbarSettings _stockBar = SimpleSearchbarSettings();

/// `color` at [opacity], as Material state layers do.
Color _layer(Color color, double opacity) =>
    color.withAlpha((opacity * 255).round());

/// The fill of a raised container: in light, elevation is drawn by the
/// shadow, so the container is the low tone (as an M3 elevated card); in
/// dark, shadows barely show, so elevation is a lighter tone.
Color _raisedSurface(ColorScheme scheme) =>
    scheme.brightness == Brightness.light
    ? scheme.surfaceContainerLow
    : scheme.surfaceContainerHigh;

/// The colours a search bar (or multiple box) is drawn with: each one set in
/// [SimpleSearchbarSettings] wins; an unset one is a [ColorScheme] role, under
/// a light theme and a dark one alike.
@immutable
class BarColors {
  /// Resolves [bar]'s colours for [theme].
  factory BarColors.of(SimpleSearchbarSettings bar, ThemeData theme) {
    final ColorScheme scheme = theme.colorScheme;
    final TextStyle? chipText = bar.boxMultiSelectedTextStyle;
    final TextStyle? hint = bar.hintStyle;
    return BarColors._(
      background: bar.customBackgroundColor ?? _raisedSurface(scheme),
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
      // The 8.0.0 shadows, which already matched the M3 bar's elevation.
      shadow: scheme.brightness == Brightness.light
          ? Colors.grey
          : Colors.black,
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
          ? TextStyle(color: scheme.onSurface)
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
