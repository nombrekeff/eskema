import 'package:json_scheme/json_scheme.dart';

Validator isType<T>() {
  return (value) {
    // final isValidType = value.runtimeType == type;

    if (value is T) {
      return Result.valid(value: value);
    }

    return Result.invalid(
      value: value,
      expected: T.toString(),
      actual: value.runtimeType.toString(),
    );
  };
}

Validator isTypeObject() => isType<Object>();
Validator isTypeString() => isType<String>();
Validator isTypeDouble() => isType<double>();
Validator isTypeInt() => isType<int>();
Validator isTypeNum() => isType<num>();
Validator isTypeBool() => isType<bool>();
Validator isTypeMap<K, V>() => isType<Map<K, V>>();
Validator isTypeList<T>() => isType<List<T>>();
// Validator isTypeList<T>() {
//   return (value) {
//     if (value is List<T>) return Result.valid(value: value);
//     return Result.invalid(
//       value: value,
//       expected: 'List',
//       actual: value.runtimeType.toString(),
//     );
//   };
// }

// Validator isTypeMap() {
//   return (value) {
//     if (value is Map) return Result.valid(value: value);
//     return Result.invalid(
//       value: value,
//       expected: 'Map',
//       actual: value.runtimeType.toString(),
//     );
//   };
// }

Validator isTypeSet() => isType<Set>();
Validator isTypeFuture() => isType<Future>();
Validator isTypeStream() => isType<Stream>();

Validator isMin(num min) {
  return (value) {
    if (value is num && value < min) {
      return Result.invalid(
        value: value,
        expected: 'higher or equal $min',
        actual: value.runtimeType.toString(),
      );
    }
    return Result.valid(value: value);
  };
}

Validator isMax(num max) {
  return (value) {
    if (value is num && value > max) {
      return Result.invalid(
        value: value,
        expected: 'lower or equal $max',
        actual: value.runtimeType.toString(),
      );
    }

    return Result.valid(value: value);
  };
}

Validator isDate() {
  return (value) {
    try {
      DateTime.parse(value);
      return Result.valid(value: value);
    } catch (e) {
      return Result.invalid(
        value: value,
        expected: 'a valid date',
        actual: value.runtimeType.toString(),
      );
    }
  };
}

// List validators
Validator listIsOfSize(int size) {
  return (value) {
    final isListResult = isTypeList().call(value);
    if (isListResult.isNotValid) return isListResult;

    if (value.length != size) {
      return Result.invalid(
        value: value,
        expected: 'List of size $size',
        actual: value.runtimeType.toString(),
      );
    }

    return Result.valid(value: value);
  };
}

// Utility validators

/// Passes the test if either of the [Validator]s are valid, and fails if both are invalid
Validator either(Validator validator1, Validator validator2) {
  return (value) {
    final res1 = validator1(value);
    final res2 = validator2(value);

    if (!res1.isValid && !res2.isValid) {
      return Result.invalid(
        value: value,
        expected: '${res1.expected} or ${res2.expected}',
        actual: value.runtimeType.toString(),
      );
    }

    return Result.valid(value: value);
  };
}
