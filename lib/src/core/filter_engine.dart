import 'package:simple_search_dropdown/src/core/sort_type.dart';
import 'package:simple_search_dropdown/src/helpers/value_item.dart';
import 'package:stringr/stringr.dart';

/// How labels and queries are normalized before matching.
class SearchNormalization {
  /// Creates a normalization policy. Defaults match 7.x behaviour.
  const SearchNormalization({
    this.latinize = true,
    this.caseSensitive = false,
    this.trim = true,
  });

  /// Ignore accents (`maçã` matches `maca`).
  final bool latinize;

  /// Match case exactly when `true`.
  final bool caseSensitive;

  /// Ignore leading and trailing whitespace.
  final bool trim;

  /// Applies this policy to [input].
  String apply(String input) {
    String result = input;
    if (trim) {
      result = result.trim();
    }
    if (latinize) {
      result = result.latinize();
    }
    if (!caseSensitive) {
      result = result.toLowerCase();
    }
    return result;
  }
}

/// Filtering, lookup and sorting shared by the single and multiple dropdowns.
///
/// The engine never mutates the lists it receives. Normalized labels are
/// cached lazily per item, so items added to (or removed from) the source list
/// behind the engine's back are handled without a rebuild.
class FilterEngine<T> {
  /// Creates an engine with the given [normalization].
  FilterEngine({this.normalization = const SearchNormalization()});

  /// The normalization policy used for labels and queries.
  final SearchNormalization normalization;

  final Map<ValueItem<T>, String> _labels = <ValueItem<T>, String>{};

  /// Number of label normalizations performed (cache misses). For tests.
  int normalizeCount = 0;

  /// Normalizes [query] with this engine's policy.
  String normalize(String query) => normalization.apply(query);

  /// The cached normalized label of [item].
  String labelOf(ValueItem<T> item) {
    final String? cached = _labels[item];
    if (cached != null) {
      return cached;
    }
    normalizeCount++;
    return _labels[item] = normalization.apply(item.label);
  }

  /// Drops every cached label (call when the source list is replaced).
  void clearCache() => _labels.clear();

  /// Drops the cached label of [item].
  void forget(ValueItem<T> item) => _labels.remove(item);

  /// Items of [source] whose normalized label contains the normalized [query].
  ///
  /// An empty normalized query returns a copy of [source].
  List<ValueItem<T>> filter(Iterable<ValueItem<T>> source, String query) {
    final String q = normalize(query);
    if (q.isEmpty) {
      return List<ValueItem<T>>.of(source);
    }
    return <ValueItem<T>>[
      for (final ValueItem<T> item in source)
        if (labelOf(item).contains(q)) item,
    ];
  }

  /// First item of [source] whose normalized label equals the normalized [label].
  ValueItem<T>? findByLabel(Iterable<ValueItem<T>> source, String label) {
    final String q = normalize(label);
    for (final ValueItem<T> item in source) {
      if (labelOf(item) == q) {
        return item;
      }
    }
    return null;
  }

  /// A sorted copy of [source] according to [type].
  ///
  /// [SortType.selectedFirst] moves [selected] (if present) to the front.
  static List<ValueItem<T>> sorted<T>(
    Iterable<ValueItem<T>> source,
    SortType type, {
    ValueItem<T>? selected,
  }) {
    final List<ValueItem<T>> copy = List<ValueItem<T>>.of(source);
    sortInPlace(copy, type, selected: selected);
    return copy;
  }

  /// Sorts [list] in place according to [type] (7.x semantics).
  static void sortInPlace<T>(
    List<ValueItem<T>> list,
    SortType type, {
    ValueItem<T>? selected,
  }) {
    switch (type) {
      case SortType.none:
        break;
      case SortType.alphabetical:
        list.sort((a, b) => a.label.compareTo(b.label));
      case SortType.reverseAlphabetical:
        list.sort((a, b) => b.label.compareTo(a.label));
      case SortType.selectedFirst:
        if (selected != null) {
          final int index = list.indexOf(selected);
          if (index > 0) {
            list
              ..removeAt(index)
              ..insert(0, selected);
          }
        }
    }
  }
}
