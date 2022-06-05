import 'common.dart';

Validator isType<T>() {
  return (value) => Result(
        isValid: value is T,
        expected: T.toString(),
      );
}

Validator isTypeObject() => isType<Object>();
Validator isTypeString() => isType<String>();
Validator isTypeDouble() => isType<double>();
Validator isTypeInt() => isType<int>();
Validator isTypeNum() => isType<num>();
Validator isTypeBool() => isType<bool>();
Validator isTypeMap<K, V>() => isType<Map<K, V>>();
Validator isTypeList<T>() => isType<List<T>>();
Validator isTypeSet() => isType<Set>();
Validator isTypeFuture() => isType<Future>();
Validator isTypeStream() => isType<Stream>();

/// Checks whether the given value is greater or equal than [min]
Validator isMin(num min) {
  return (value) => Result(
        isValid: value is num && value >= min,
        expected: 'higher or equal $min',
      );
}

/// Checks whether the given value is less or equal than [max]
Validator isMax(num max) {
  return (value) => Result(
        isValid: value is num && value <= max,
        expected: 'lower or equal $max',
      );
}


/// Checks whether the given value is a valid DateTime formattedString
Validator isDate() {
  return (value) => Result(
        isValid: DateTime.tryParse(value) != null,
        expected: 'a valid date',
      );
}

/// Validates that the list's length is the same as the provided [size]
///
/// This validator also validates that the value is a list first
Validator listIsOfSize(int size) {
  return (value) {
    final isListResult = isTypeList().call(value);
    if (isListResult.isNotValid) return isListResult;

    return Result(
      isValid: value.length == size,
      expected: 'List of size $size',
    );
  };
}

/// Passes the test if either of the [Validator]s are valid, and fails if both are invalid
Validator either(Validator validator1, Validator validator2) {
  return (value) {
    final res1 = validator1(value);
    final res2 = validator2(value);

    return Result(
      isValid: res1.isValid || res2.isValid,
      expected: '${res1.expected} or ${res2.expected}',
    );
  };
}
