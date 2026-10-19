/// How the dropdown orders its items.
enum SortType {
  /// Keep the order of the list as given.
  none,

  /// Alphabetical by label (A-Z).
  alphabetical,

  /// Reverse alphabetical by label (Z-A).
  reverseAlphabetical,

  /// Move the selected item to the first position.
  selectedFirst,
}
