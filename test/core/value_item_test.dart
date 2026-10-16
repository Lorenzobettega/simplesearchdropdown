import 'package:flutter_test/flutter_test.dart';
import 'package:simple_search_dropdown/simple_search_dropdown.dart';

class _Person {
  const _Person(this.name, this.age);

  final String name;
  final int age;

  Map<String, dynamic> toMap() => {'name': name, 'age': age};
}

void main() {
  group('ValueItem: equality and hashCode', () {
    test('equal when label and value match', () {
      const a = ValueItem<int>(label: 'A', value: 1);
      const b = ValueItem<int>(label: 'A', value: 1);
      expect(a, b);
      expect(a.hashCode, b.hashCode);
    });

    test('different label, value or type parameter are not equal', () {
      const a = ValueItem<int>(label: 'A', value: 1);
      expect(a == const ValueItem<int>(label: 'B', value: 1), isFalse);
      expect(a == const ValueItem<int>(label: 'A', value: 2), isFalse);
      expect(a == const ValueItem<num>(label: 'A', value: 1), isFalse);
    });

    test('label == value items do not all share one hash (N25)', () {
      final Set<int> hashes = <int>{
        for (int i = 0; i < 100; i++)
          ValueItem<String>.fromValue('Item $i').hashCode,
      };
      expect(hashes.length, greaterThan(90));
      expect(
        const ValueItem<String>(label: 'a', value: 'a').hashCode,
        isNot(const ValueItem<String>(label: 'b', value: 'b').hashCode),
      );
    });
  });

  group('ValueItem: fromValue', () {
    test('label defaults to toString of the value', () {
      final item = ValueItem<int>.fromValue(42);
      expect(item.label, '42');
      expect(item.value, 42);
    });

    test('labelBuilder customises the label', () {
      final item = ValueItem<_Person>.fromValue(
        const _Person('Ana', 30),
        labelBuilder: (p) => p.name,
      );
      expect(item.label, 'Ana');
      expect(item.value?.age, 30);
    });
  });

  group('ValueItem: JSON', () {
    test('round-trips primitive values', () {
      const item = ValueItem<String>(label: 'One', value: '1');
      final String json = item.toJson(null);
      expect(json, '{"label":"One","value":"1"}');
      expect(ValueItem<String>.fromJson(json, null), item);
    });

    test('custom value mappers are used both ways', () {
      const item = ValueItem<_Person>(label: 'Ana', value: _Person('Ana', 30));
      final String json = item.toJson((p) => p!.toMap());
      final decoded = ValueItem<_Person>.fromJson(
        json,
        (map) => _Person(map['name'] as String, map['age'] as int),
      );
      expect(decoded.label, 'Ana');
      expect(decoded.value?.age, 30);
    });

    test('missing label decodes as empty string', () {
      expect(ValueItem<String>.fromJson('{"value":"x"}', null).label, '');
    });
  });

  group('ValueItem: copyWith and toString', () {
    test('copyWith replaces only the given fields', () {
      const item = ValueItem<int>(label: 'A', value: 1);
      expect(
        item.copyWith(label: 'B'),
        const ValueItem<int>(label: 'B', value: 1),
      );
      expect(
        item.copyWith(value: 2),
        const ValueItem<int>(label: 'A', value: 2),
      );
    });

    test('toString shows type, label and value', () {
      expect(
        const ValueItem<int>(label: 'A', value: 1).toString(),
        'ValueItem<int>(label: A, value: 1)',
      );
    });
  });
}
