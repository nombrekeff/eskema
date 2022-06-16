import 'dart:convert';

import 'package:collection/collection.dart';
import 'package:eskema/util.dart';

import 'result.dart';

Function _collectionEquals = const DeepCollectionEquality().equals;

typedef Validator = IResult Function(dynamic value);

/// Returns a [Validator] that checks if the given value null
Validator isTypeNull() {
  return (value) => Result(
        isValid: value == null,
        expected: 'null',
      );
}

/// Returns a [Validator] that checks if the given value is the correct type
Validator isType<T>() {
  return (value) => Result(
        isValid: value is T,
        expected: T.toString(),
      );
}

/// Returns a [Validator] that checks if the given value is the correct type
Validator isTypeOrNull<T>() {
  return (value) => Result(
        isValid: value is T || value == null,
        expected: '${T.toString()} or null',
      );
}

/// Checks whether the given value is less than [max]
Validator isLt(num max) {
  return and(
    isType<num>(),
    (value) => Result(
      isValid: value < max,
      expected: 'less than $max',
    ),
  );
}

/// Checks whether the given value is less than or equal [max]
Validator isLte(num max) {
  return and(
    isType<num>(),
    (value) => Result(
      isValid: value <= max,
      expected: 'less than or equal to $max',
    ),
  );
}

/// Checks whether the given value is greater than [max]
Validator isGt(num min) {
  return and(
    isType<num>(),
    (value) => Result(
      isValid: value > min,
      expected: 'greater than $min',
    ),
  );
}

/// Checks whether the given value is greater or equal to [max]
Validator isGte(num min) {
  return and(
    isType<num>(),
    (value) => Result(
      isValid: value is num && value >= min,
      expected: 'greater than or equal to $min',
    ),
  );
}

/// Checks whether the given value is equal to the [expected] value of type [T]
///
/// Even though this function accepts any Type, note that it will not work with Collections. For that usecase prefer using [isDeepEqual] instead.
Validator isEq<T>(T expected) {
  return and(
    isType<T>(),
    (value) => Result(
      isValid: value == expected,
      // json.encode is here to format the value correctly, so we know if for example 10 is a number (10) or a string ("10").
      expected: 'equal to ${pretifyValue(expected)}',
    ),
  );
}

/// Checks whether the given value is equal to the [expected] value of type [T]
Validator isDeepEq<T>(T expected) {
  return and(
    isType<T>(),
    (value) => Result(
      isValid: (_collectionEquals(value, expected)),
      expected: 'equal to ${pretifyValue(expected)}',
    ),
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
    final isListResult = isType<List>().call(value);
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
    final isStringResult = isType<String>().call(value);
    if (isStringResult.isNotValid) return isStringResult;

    return Result(
      isValid: (value as String).length == size,
      expected: 'String of length $size',
    );
  };
}

/// Validates that the String contains [substring]
///
/// This validator also validates that the value is a String first
/// So there's no need to add the [isTypeString] validator when using this validator
Validator stringContains(String substring) {
  return (value) {
    final isString = isType<String>().call(value);
    if (isString.isNotValid) return isString;

    return Result(
      isValid: (value as String).contains(substring),
      expected: 'String to contain "$substring"',
    );
  };
}

/// Validates that the List contains [item]
///
/// This validator also validates that the value is a List first
/// So there's no need to add the [isType<List>] validator when using this validator
Validator listContains<T>(T item) {
  return (value) {
    final isListResult = isType<List>().call(value);
    if (isListResult.isNotValid) return isListResult;

    return Result(
      isValid: (value as List).contains(item),
      expected: 'List to contain ${pretifyValue(item)}',
    );
  };
}

/// Validates that the String does not contain [substring]
///
/// This validator also validates that the value is a String first
/// So there's no need to add the [isTypeString] validator when using this validator
Validator stringNotContains(String substring) {
  return (value) {
    final isListResult = isType<String>().call(value);
    if (isListResult.isNotValid) return isListResult;

    return Result(
      isValid: !(value as String).contains(substring),
      expected: 'String to not contain "$substring"',
    );
  };
}

/// Validates that the String matches the provided pattern
///
/// This validator also validates that the value is a String first
/// So there's no need to add the [isTypeString] validator when using this validator
Validator stringMatchesPattern(Pattern pattern, {String? expectedMessage}) {
  return (value) {
    final isListResult = isType<String>().call(value);
    if (isListResult.isNotValid) return isListResult;

    return Result(
      isValid: pattern.allMatches(value).isNotEmpty,
      expected: expectedMessage ?? 'String to match "$pattern"',
    );
  };
}

/// Passes the test if either of the [Validator]s are valid, and fails if both are invalid
Validator or(Validator validator1, Validator validator2) {
  return (value) {
    final res1 = validator1(value);
    final res2 = validator2(value);

    return Result(
      isValid: res1.isValid || res2.isValid,
      expected: '${res1.expected} or ${res2.expected}',
    );
  };
}

/// Passes the test if both of the [Validator]s are valid, and fails if any of them are invalid
///
/// In the case that a [Validator] fails, it's [Result] will be returned
Validator and(Validator validator1, Validator validator2) {
  return (value) {
    final res1 = validator1(value);
    if (res1.isNotValid) return res1;

    final res2 = validator2(value);
    if (res2.isNotValid) return res2;

    return Result.valid;
  };
}

/// Passes the test if the contition is !valid
Validator not(Validator validator) {
  return (value) {
    final result = validator(value);

    return Result(
      isValid: !result.isValid,
      expected: 'not ${result.expected}',
    );
  };
}

/// Allows the passed in validator to be nullable
Validator nullable(Validator validator) {
  return (value) {
    if (value == null) return Result.valid;
    return validator(value);
  };
}

/// Valid if every validator is valid or returns the first invalid result
Validator all(List<Validator> validators) {
  return (value) {
    if (validators.isNotEmpty) {
      for (final validator in validators) {
        final result = validator.call(value);
        if (result.isNotValid) return result;
      }
    }

    return Result.valid;
  };
}

/// Returns a Validator that checks a value against a Map eskema that declares a validator for each key.
///
/// Example:
/// ```dart
/// final mapField = all([
///   eskema({
///     'name': all([isType<String>()]),
///     'vat': or(
///       isTypeNull(),
///       isGte(0),
///     ),
///     'age': all([
///       isType<int>(),
///       isGte(0),
///     ]),
///   }),
/// ]);
/// ```
Validator eskema(Map<String, Validator> eskema) {
  return (value) {
    if (value is! Map) return Result.invalid('Map');

    for (final key in eskema.keys) {
      final field = eskema[key] as Validator;
      final result = field.call(value[key]);

      if (result.isNotValid) {
        return Result.invalid('$key -> ${result.expected}');
      }
    }

    return Result.valid;
  };
}

/// Returns a Validator that checks a value against the eskema provided,
/// the eskema defines a validator for each item in the list
///
/// Example:
/// ```dart
/// final isValidList = eskemaList([isType<String>(), isType<int>()]);
/// isValidList(["1", 2]).isValid;   // true
/// isValidList(["1", "2"]).isValid; // false
/// isValidList([1, "2"]).isValid;   // false
/// ```
///
/// `isValidList` will only be valid:
/// * if the array is of length 2
/// * the first item is a string
/// * and the second item is an int
///
/// This validator also checks that the value is a list
Validator eskemaList(List<Validator> eskema) {
  return (value) {
    // Before checking the eskema, we validate that it's a list and matches the eskema length
    final result = all([isType<List>(), listIsOfLength(eskema.length)]).call(value);
    if (result.isNotValid) return result;

    for (int index = 0; index < value.length; index++) {
      final item = value[index];
      final effectiveValidator = eskema[index];
      final result = effectiveValidator.call(item);

      if (result.isNotValid) {
        return Result.invalid('[$index] -> ${result.expected}');
      }
    }

    return Result.valid;
  };
}

/// Returns a Validator that runs [itemValidator] for each item in the list
///
/// This validator also checks that the value is a list
Validator listEach(Validator itemValidator) {
  return (value) {
    if (value is! List) return Result.invalid('List');

    for (int index = 0; index < value.length; index++) {
      final item = value[index];
      final result = itemValidator.call(item);

      if (result.isNotValid) {
        return Result.invalid('[$index] -> ${result.expected}');
      }
    }

    return Result.valid;
  };
}
