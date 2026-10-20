import 'package:simple_search_dropdown/src/helpers/value_item.dart';

/// Puts [to] where [from] is in [list] (a list the controller owns) and
/// returns the entry that now stands for [to].
///
/// An entry already `==` to [to] elsewhere in [list] is kept, and [from]'s
/// slot dropped, instead of a duplicate; without [from], [to] is appended.
ValueItem<T> replaceItem<T>(
  List<ValueItem<T>> list,
  ValueItem<T> from,
  ValueItem<T> to,
) {
  final int index = list.indexOf(from);
  if (to != from) {
    final int existing = list.indexOf(to);
    if (existing != -1) {
      final ValueItem<T> kept = list[existing];
      if (index != -1) {
        list.removeAt(index);
      }
      return kept;
    }
  }
  if (index != -1) {
    list[index] = to;
  } else {
    list.add(to);
  }
  return to;
}

/// Whether [a] and [b] hold the same instances in the same order.
bool sameInstances<E>(List<E> a, List<E> b) {
  if (a.length != b.length) {
    return false;
  }
  for (int i = 0; i < a.length; i++) {
    if (!identical(a[i], b[i])) {
      return false;
    }
  }
  return true;
}
