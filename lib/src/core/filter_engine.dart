import 'package:simple_search_dropdown/src/core/sort_type.dart';
import 'package:simple_search_dropdown/src/helpers/value_item.dart';
import 'package:stringr/stringr.dart';

/// How labels and queries are normalized before matching.
class SearchNormalization {
  /// Creates a normalization policy. Defaults match the 7.x single dropdown;
  /// a legacy `MultipleSearchDropDown(listItems:)` uses `trim: false`, as the
  /// 7.x multiple did.
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

  /// A-Z/Z-A always ignore case, accents and surrounding spaces (D2),
  /// whatever the filter options.
  static const SearchNormalization _sortPolicy = SearchNormalization();

  /// Sort keys, only used when [normalization] differs from [_sortPolicy].
  final Map<ValueItem<T>, String> _sortKeys = <ValueItem<T>, String>{};

  /// Number of label normalizations performed (cache misses). For tests.
  int normalizeCount = 0;

  /// Number of A-Z/Z-A sorts actually performed. For tests.
  int sortCount = 0;

  /// Number of cached labels and sort keys. For tests.
  int get cachedLabelCount => _labels.length + _sortKeys.length;

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
  void clearCache() {
    _labels.clear();
    _sortKeys.clear();
  }

  /// Drops the cached label of [item].
  void forget(ValueItem<T> item) {
    _labels.remove(item);
    _sortKeys.remove(item);
  }

  /// Drops the cached labels of items that are no longer in [live].
  void retainOnly(Iterable<ValueItem<T>> live) {
    if (_labels.isEmpty && _sortKeys.isEmpty) {
      return;
    }
    final Set<ValueItem<T>> keep = live.toSet();
    bool gone(ValueItem<T> item, String _) => !keep.contains(item);
    _labels.removeWhere(gone);
    _sortKeys.removeWhere(gone);
  }

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

  /// The entry of [list] that a callback stored for [item], or `null`.
  ///
  /// That is [item] itself, else an entry equal to it, else an entry added
  /// since [before] (an identity snapshot) whose normalized label is
  /// [item]'s: the callback's own copy, e.g. with a server id.
  ValueItem<T>? storedFor(
    List<ValueItem<T>> list,
    Set<ValueItem<T>> before,
    ValueItem<T> item,
  ) {
    ValueItem<T>? equal;
    ValueItem<T>? copy;
    String? label;
    for (final ValueItem<T> e in list) {
      if (identical(e, item)) {
        return e;
      }
      if (equal != null) {
        continue;
      }
      if (e == item) {
        equal = e;
      } else if (copy == null &&
          !before.contains(e) &&
          labelOf(e) == (label ??= labelOf(item))) {
        copy = e;
      }
    }
    return equal ?? copy;
  }

  bool get _sortMatchesFilter =>
      normalization.latinize &&
      !normalization.caseSensitive &&
      normalization.trim;

  String _sortKeyOf(ValueItem<T> item) => _sortMatchesFilter
      ? labelOf(item)
      : _sortKeys[item] ??= _sortPolicy.apply(item.label);

  /// Orders two items by label ignoring case, accents and surrounding spaces,
  /// whatever the filter options; falls back to the raw label so the order is
  /// total.
  int compare(ValueItem<T> a, ValueItem<T> b) {
    final int byKey = _sortKeyOf(a).compareTo(_sortKeyOf(b));
    return byKey != 0 ? byKey : a.label.compareTo(b.label);
  }

  void _sort(
    List<ValueItem<T>> list,
    int Function(ValueItem<T>, ValueItem<T>) cmp,
  ) {
    for (int i = 1; i < list.length; i++) {
      if (cmp(list[i - 1], list[i]) > 0) {
        sortCount++;
        list.sort(cmp);
        return;
      }
    }
  }

  /// A sorted copy of [source] according to [type].
  ///
  /// [SortType.selectedFirst] moves [selected] (if present) to the front.
  List<ValueItem<T>> sorted(
    Iterable<ValueItem<T>> source,
    SortType type, {
    ValueItem<T>? selected,
  }) {
    final List<ValueItem<T>> copy = List<ValueItem<T>>.of(source);
    sortInPlace(copy, type, selected: selected);
    return copy;
  }

  /// Sorts [list] in place according to [type].
  ///
  /// A list that is already in A-Z/Z-A order is left untouched.
  void sortInPlace(
    List<ValueItem<T>> list,
    SortType type, {
    ValueItem<T>? selected,
  }) {
    switch (type) {
      case SortType.none:
        break;
      case SortType.alphabetical:
        _sort(list, compare);
      case SortType.reverseAlphabetical:
        _sort(list, (a, b) => compare(b, a));
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
