import 'dart:convert';

/// [label] is the item that is displayed in the list. [value] is the value that is returned when the item is selected.
/// If the [value] is not provided, the [label] is used as the value.
/// An example of a [ValueItem] is:
/// ```dart
/// const ValueItem(label: 'Option 1', value: '1')
/// ```

class ValueItem<T> {
  /// Default constructor for [ValueItem]
  const ValueItem({
    required this.label,
    this.value,
  });

  /// fromJson method for [ValueItem]
  ///
  /// [customValueFromMap] is an optional fromMap function to use if value is a custom class.
  factory ValueItem.fromJson(String source,
          dynamic Function(Map<String, dynamic>)? customValueFromMap) =>
      ValueItem<T>._fromMap(json.decode(source), customValueFromMap);

  /// fromMap method for [ValueItem]
  factory ValueItem._fromMap(Map<String, dynamic> map,
      dynamic Function(Map<String, dynamic>)? customValueFromMap) {
    return ValueItem<T>(
      label: map['label'] ?? '',
      value: customValueFromMap != null
          ? customValueFromMap(map['value'])
          : map['value'],
    );
  }

  /// The label of the value item
  final String label;

  /// The value of the value item
  final T? value;

  /// toString method for [ValueItem]
  @override
  String toString() {
    return 'ValueItem(label: $label, value: ${value.toString()})';
  }

  /// toMap method for [ValueItem]
  Map<String, dynamic> _toMap(
      Map<String, dynamic> Function(T? value)? customValueToMap) {
    return {
      'label': label,
      'value': customValueToMap != null ? customValueToMap(value) : value,
    };
  }

  /// toJson method for [ValueItem]
  ///
  /// [customValueToMap] is an optional toMap function to use if value is a custom class.
  String toJson(Map<String, dynamic> Function(T? value)? customValueToMap) =>
      json.encode(_toMap(customValueToMap));

  /// Equality operator for [ValueItem]
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }

    return other is ValueItem<T> &&
        other.label == label &&
        other.value == value;
  }

  /// Hashcode for [ValueItem]
  @override
  int get hashCode => label.hashCode ^ value.hashCode;

  /// CopyWith method for [ValueItem]
  ValueItem<T> copyWith({
    String? label,
    T? value,
  }) {
    return ValueItem(
      label: label ?? this.label,
      value: value ?? this.value,
    );
  }
}
