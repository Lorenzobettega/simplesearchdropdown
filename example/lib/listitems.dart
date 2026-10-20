import 'package:simple_search_dropdown/simple_search_dropdown.dart';
import 'package:simple_search_dropdown_example/custom.dart';

/// Initial items of the custom-type dropdown.
final List<ValueItem<Custom>> initialCustomItems = List.unmodifiable([
  ValueItem(label: 'Lorenzo', value: Custom('Lorenzo', 134)),
  ValueItem(label: 'Peter', value: Custom('Peter', 1)),
  ValueItem(label: 'Lucas', value: Custom('Lucas', 3)),
  ValueItem(label: 'Gian', value: Custom('Gian', 70)),
  ValueItem(label: 'Lança', value: Custom('Lança', 70)),
  ValueItem(label: 'Não', value: Custom('Não', 70)),
]);

/// Initial items of the shared list. Unmodifiable on purpose: the
/// controllers keep their own copies and never write to it.
final List<ValueItem> initialItems = List.unmodifiable([
  const ValueItem(label: 'Lorenzo'),
  const ValueItem(label: 'Teste', value: 'Teste'),
  const ValueItem(label: '3', value: '3'),
  const ValueItem(label: 'one more', value: 'one more2'),
  for (int i = 4; i <= 130; i++) ValueItem(label: '$i', value: '$i'),
]);
