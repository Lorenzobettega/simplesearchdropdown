/// How the dropdown orders its items.
enum SortType {
  /// Keep the order of the list as given.
  none,

  /// Alphabetical by label (A-Z).
  alphabetical,

  /// Reverse alphabetical by label (Z-A).
  reverseAlphabetical,

  /// Move the selected item to the first position.
  selectedFirst;

  /// Maps the legacy `int sortType` (0-3) to a [SortType].
  static SortType fromLegacy(int value) => switch (value) {
        1 => SortType.alphabetical,
        2 => SortType.reverseAlphabetical,
        3 => SortType.selectedFirst,
        _ => SortType.none,
      };

  /// The legacy `int` value (0-3) of this sort type.
  int get legacyValue => index;
}
