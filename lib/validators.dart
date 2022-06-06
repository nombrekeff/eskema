import 'common.dart';

/// Returns a [Validator] that checks if the given value is the correct type
Validator isType<T>() {
  return (value) => Result(
        isValid: value is T,
        expected: T.toString(),
      );
}

/// Returns a [Validator] that checks if the given value is a String
Validator isTypeString() => isType<String>();

/// Returns a [Validator] that checks if the given value is a double
Validator isTypeDouble() => isType<double>();

/// Returns a [Validator] that checks if the given value is an int
Validator isTypeInt() => isType<int>();

/// Returns a [Validator] that checks if the given value is a num
Validator isTypeNum() => isType<num>();

/// Returns a [Validator] that checks if the given value is a bool
Validator isTypeBool() => isType<bool>();

/// Returns a [Validator] that checks if the given value is a Map<K, V>
Validator isTypeMap<K, V>() => isType<Map<K, V>>();

/// Returns a [Validator] that checks if the given value is a List<T>
Validator isTypeList<T>() => isType<List<T>>();

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

/// Checks whether the given value is less than [max]
Validator isLt(num max) {
  return (value) => Result(
        isValid: value is num && value < max,
        expected: 'lower than $max',
      );
}

/// Checks whether the given value is greater than [max]
Validator isGt(num min) {
  return (value) => Result(
        isValid: value is num && value > min,
        expected: 'greater than $min',
      );
}

/// Checks whether the given value is equal to the [expected] number
Validator isEq(num expected) {
  return (value) => Result(
        isValid: value is num && value == expected,
        expected: 'equal to $expected',
      );
}

/// Checks whether the given value is equal to the [expected] String
Validator isStringEq(String expected) {
  return (value) => Result(
        isValid: value is String && value == expected,
        expected: 'equal to "$expected"',
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
/// So there's no need to add the [isTypeList] validator when using this validator
Validator listIsOfLength(int size) {
  return (value) {
    final isListResult = isTypeList().call(value);
    if (isListResult.isNotValid) return isListResult;

    return Result(
      isValid: (value as List).length == size,
      expected: 'List of size $size',
    );
  };
}

/// Validates that the String's length is the same as the provided [size]
///
/// This validator also validates that the value is a String first
/// So there's no need to add the [isTypeString] validator when using this validator
Validator stringIsOfLength(int size) {
  return (value) {
    final isStringResult = isTypeString().call(value);
    if (isStringResult.isNotValid) return isStringResult;

    return Result(
      isValid: (value as String).length == size,
      expected: 'String of length $size',
    );
  };
}

/// Validates that the String contains [substring]
Validator stringContains(String substring) {
  return (value) {
    final isListResult = isTypeString().call(value);
    if (isListResult.isNotValid) return isListResult;

    return Result(
      isValid: (value as String).contains(substring),
      expected: 'String to contain "$substring"',
    );
  };
}

/// Validates that the String does not contain [substring]
Validator stringNotContains(String substring) {
  return (value) {
    final isListResult = isTypeString().call(value);
    if (isListResult.isNotValid) return isListResult;

    return Result(
      isValid: !(value as String).contains(substring),
      expected: 'String to not contain "$substring"',
    );
  };
}

/// Validates that the String matches the provided pattern
Validator stringMatchesPattern(Pattern pattern, {String? expectedMessage}) {
  return (value) {
    final isListResult = isTypeString().call(value);
    if (isListResult.isNotValid) return isListResult;

    return Result(
      isValid: pattern.allMatches(value).isNotEmpty,
      expected: expectedMessage ?? 'String to not match "$pattern"',
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
