import 'package:collection/collection.dart';
import 'package:eskema/result.dart';
import 'package:eskema/util.dart';
import 'package:eskema/validator.dart';

Function _collectionEquals = const DeepCollectionEquality().equals;

//////////////////////////////////////////////////////////////////////////////////
// Logic/comparison Validators
//////////////////////////////////////////////////////////////////////////////////

/// Checks whether the given value is less than [max]
IEskValidator isLt(num max) => all([
      isType<num>(),
      EskValidator((value) => EskResult(
            isValid: value < max,
            expected: 'less than $max',
            value: value,
          )),
    ]);

/// Checks whether the given value is less than or equal [max]
IEskValidator isLte(num max) => all([
      isType<num>(),
      EskValidator((value) => EskResult(
            isValid: value <= max,
            expected: 'less than or equal to $max',
            value: value,
          )),
    ]);

/// Checks whether the given value is greater than [max]
IEskValidator isGt(num min) => all([
      isType<num>(),
      EskValidator((value) => EskResult(
            isValid: value > min,
            expected: 'greater than $min',
            value: value,
          )),
    ]);

/// Checks whether the given value is greater or equal to [max]
IEskValidator isGte(num min) => all([
      isType<num>(),
      EskValidator((value) => EskResult(
            isValid: value is num && value >= min,
            expected: 'greater than or equal to $min',
            value: value,
          )),
    ]);

/// Checks whether the given value is equal to the [expected] value of type [T]
///
/// Even though this function accepts any Type, note that it will not work with Collections. For that usecase prefer using [isDeepEq] instead.
IEskValidator isEq<T>(T expected) => all([
      isType<T>(),
      EskValidator((value) => EskResult(
            isValid: value == expected,
            // json.encode is here to format the value correctly, so we know if for example 10 is a number (10) or a string ("10").
            expected: 'equal to ${pretifyValue(expected)}',
            value: value,
          )),
    ]);

/// Checks whether the given value is equal to the [expected] value of type [T]
IEskValidator isDeepEq<T>(T expected) => all([
      isType<T>(),
      EskValidator((value) => EskResult(
            isValid: (_collectionEquals(value, expected)),
            expected: 'equal to ${pretifyValue(expected)}',
            value: value,
          )),
    ]);

/// Checks
IEskValidator length(List<IEskValidator> validators) => EskValidator((value) {
      if (hasLengthProperty(value)) {
        final result = all(validators).validate((value as dynamic).length);
        return result.copyWith(
          expected: 'length ${result.expected}',
        );
      } else {
        return EskResult.invalid(
          '${value.runtimeType} does not have a length property',
          value,
        );
      }
    });

/// Checks whether the given value is not empty
IEskValidator isNotEmpty() => stringLength([isGt(0)]);
IEskValidator isEmpty() => stringLength([isLte(0)]);

//////////////////////////////////////////////////////////////////////////////////
// List Validators
//////////////////////////////////////////////////////////////////////////////////

/// Validates that the List contains [item]
///
/// This validator also validates that the value is a List first
/// So there's no need to add the [isList] validator when using this validator
IEskValidator listContains<T>(T item) => EskValidator((value) {
      final isListResult = isType<List>().validate(value);
      if (isListResult.isNotValid) return isListResult;

      return EskResult(
        isValid: (value as List).contains(item),
        expected: 'List to contain ${pretifyValue(item)}',
        value: value,
      );
    });

/// Validates that it's a List and the length matches the validators
IEskValidator listLength<T>(List<IEskValidator> validators) => all([
      isList<T>(),
      length(validators),
    ]);

/// Validates that it's a list of `size` length
IEskValidator listIsOfLength(int size) => listLength([isEq(size)]);

//////////////////////////////////////////////////////////////////////////////////
// String Validators
//////////////////////////////////////////////////////////////////////////////////

/// Validates that the String's length matches the validators
IEskValidator stringLength(List<IEskValidator> validators) => all([
      $isString,
      length(validators),
    ]);

/// Validates that the String's length is the same as the provided [size]
///
/// This validator also validates that the value is a String first
/// So there's no need to add the [isString] validator when using this validator
IEskValidator stringIsOfLength(int size) => stringLength([isEq(size)]);

/// Validates that the String contains [substring]
///
/// This validator also validates that the value is a String first
/// So there's no need to add the [isString] validator when using this validator
IEskValidator stringContains(String substring) => EskValidator((value) {
      final isString = isType<String>().validate(value);
      if (isString.isNotValid) return isString;

      return EskResult(
        isValid: (value as String).contains(substring),
        expected: 'String to contain "$substring"',
        value: value,
      );
    });

/// Validates that the String does not contain [substring]
///
/// This validator also validates that the value is a String first
/// So there's no need to add the [isString] validator when using this validator
IEskValidator stringNotContains(String substring) => EskValidator((value) {
      final isListResult = isType<String>().validate(value);
      if (isListResult.isNotValid) return isListResult;

      return EskResult(
        isValid: !(value as String).contains(substring),
        expected: 'String to not contain "$substring"',
        value: value,
      );
    });

/// Validates that the String matches the provided pattern
///
/// This validator also validates that the value is a String first
/// So there's no need to add the [isString] validator when using this validator
IEskValidator stringMatchesPattern(Pattern pattern, {String? expectedMessage}) {
  return EskValidator((value) {
    final isListResult = isType<String>().validate(value);
    if (isListResult.isNotValid) return isListResult;

    return EskResult(
      isValid: pattern.allMatches(value).isNotEmpty,
      expected: expectedMessage ?? 'String to match "$pattern"',
      value: value,
    );
  });
}

//////////////////////////////////////////////////////////////////////////////////
// Combinators
//////////////////////////////////////////////////////////////////////////////////

/// Passes the test if any of the [EskValidator]s are valid, and fails if any are invalid
IEskValidator any(List<IEskValidator> validators) => EskValidator((value) {
      final results = [];
      for (final validator in validators) {
        final result = validator.validate(value);
        results.add(result);
        if (result.isValid) return result;
      }

      return EskResult(
        isValid: false,
        expected: results.map((r) => r.expected).join(' or '),
        value: value,
      );
    });

/// Passes the test if all of the [EskValidator]s are valid, and fails if any of them are invalid
///
/// In the case that a [EskValidator] fails, it's [EskResult] will be returned
IEskValidator all(List<IEskValidator> validators) => EskValidator((value) {
      for (final validator in validators) {
        final result = validator.validate(value);
        if (result.isNotValid) return result;
      }

      return EskResult.valid(value);
    });

/// Passes the test if the contition is !valid
IEskValidator not(IEskValidator validator) => EskValidator((value) {
      final result = validator.validate(value);
      return EskResult(
        isValid: !result.isValid,
        expected: 'not ${result.expected}',
        value: value,
      );
    });

/// Allows the passed in validator to be nullable
IEskValidator nullable(IEskValidator validator) => validator.nullable();

/// Checks whether the given value is one of the [options] values of type [T]
IEskValidator isOneOf<T>(List<T> options) => all([
      isType<T>(),
      EskValidator((value) => EskResult(
            isValid: options.contains(value),
            expected: 'one of: ${pretifyValue(options)}',
            value: value,
          )),
    ]);

/// Returns a [EskValidator] that throws a [ValidatorFailedException] instead of returning a result
IEskValidator throwInstead(IEskValidator validator) => EskValidator((value) {
      final result = validator.validate(value);
      if (result.isNotValid) throw ValidatorFailedException(result);
      return EskResult.valid(value);
    });

//////////////////////////////////////////////////////////////////////////////////
// Structure types
//////////////////////////////////////////////////////////////////////////////////

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
IEskValidator eskema(Map<String, IEskValidator> eskema) {
  return EskValidator((value) {
    if (value is! Map) return EskResult.invalid('Map', value);

    for (final key in eskema.keys) {
      final field = eskema[key];
      final result = field!.validate(value[key]);

      if (result.isNotValid) {
        return EskResult.invalid('$key -> ${result.expected}', result.value);
      }
    }

    return EskResult.valid(value);
  });
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
IEskValidator eskemaList(List<IEskValidator> eskema) {
  return EskValidator((value) {
    // Before checking the eskema, we validate that it's a list and matches the eskema length
    final result = all([
      isType<List>(),
      listIsOfLength(eskema.length),
    ]).validate(value);

    if (result.isNotValid) return result;

    for (int index = 0; index < value.length; index++) {
      final item = value[index];
      final effectiveValidator = eskema[index];
      final result = effectiveValidator.validate(item);

      if (result.isNotValid) {
        return EskResult.invalid('[$index] -> ${result.expected}', value);
      }
    }

    return EskResult.valid(value);
  });
}

/// Returns a Validator that runs [itemValidator] for each item in the list
///
/// This validator also checks that the value is a list
IEskValidator listEach(IEskValidator itemValidator) {
  return EskValidator((value) {
    if (value is! List) return EskResult.invalid('List', value);

    for (int index = 0; index < value.length; index++) {
      final item = value[index];
      final result = itemValidator.validate(item);

      if (result.isNotValid) {
        return EskResult.invalid('[$index] -> ${result.expected}', item);
      }
    }

    return EskResult.valid(value);
  });
}

//////////////////////////////////////////////////////////////////////////////////
// Built in types
//////////////////////////////////////////////////////////////////////////////////

/// Returns a [EskValidator] that checks if the given value is the correct type
IEskValidator isType<T>() => EskValidator((value) => EskResult(
      isValid: value is T,
      expected: T.toString(),
      value: value,
    ));

/// Returns a [EskValidator] that checks if the given value is the correct type
IEskValidator isTypeOrNull<T>() => isType<T>().nullable();

/// Returns a [IEskValidator] that checks if the given value is `null`
/// For better performance and readability, use the [$isNull] variable directly.
IEskValidator isNull() => isType<Null>();
final $isNull = isNull();

/// Returns a [IEskValidator] that checks if the given value is a `String`
/// For better performance and readability, use the [$isString] variable directly.
IEskValidator isString() => isType<String>();
final $isString = isString();

/// Returns a [IEskValidator] that checks if the given value is a `num`
/// For better performance and readability, use the [$isNumber] variable directly.
IEskValidator isNumber() => isType<num>();
final $isNumber = isNumber();

/// Returns a [IEskValidator] that checks if the given value is a `int`
/// For better performance and readability, use the [$isInteger] variable directly.
IEskValidator isInteger() => isType<int>();
final $isInteger = isInteger();

/// Returns a [IEskValidator] that checks if the given value is a `double`
/// For better performance and readability, use the [$isDouble] variable directly.
IEskValidator isDouble() => isType<double>();
final $isDouble = isDouble();

/// Returns a [IEskValidator] that checks if the given value is a `bool`
/// For better performance and readability, use the [$isBoolean] variable directly.
IEskValidator isBoolean() => isType<bool>();
final $isBoolean = isBoolean();

/// Returns a [IEskValidator] that checks if the given value is a `Function`
/// For better performance and readability, use the [$isFunction] variable directly.
IEskValidator isFunction() => isType<Function>();
final $isFunction = isFunction();

/// Returns a [IEskValidator] that checks if the given value is a `List`
/// For better performance and readability, use the [$isList] variable directly.
IEskValidator isList<T>() => isType<List<T>>();
final $isList = isList();

/// Returns a [IEskValidator] that checks if the given value is a `Map`
/// For better performance and readability, use the [$isMap] variable directly.
IEskValidator isMap<K, V>() => isType<Map<K, V>>();
final $isMap = isMap();

/// Returns a [IEskValidator] that checks if the given value is a `Set`
/// For better performance and readability, use the [$isSet] variable directly.
IEskValidator isSet<T>() => isType<Set<T>>();
final $isSet = isSet();

/// Returns a [IEskValidator] that checks if the given value is a `Record`
IEskValidator isRecord() => isType<Record>();
final $isRecord = isRecord();

/// Returns a [IEskValidator] that checks if the given value is a `Symbol`
/// For better performance and readability, use the [$isSymbol] variable directly.
IEskValidator isSymbol() => isType<Symbol>();
final $isSymbol = isSymbol();

/// Returns a [IEskValidator] that checks if the given value is a `Enum`
/// For better performance and readability, use the [$isEnum] variable directly.
IEskValidator isEnum() => isType<Enum>();
final $isEnum = isEnum();

/// Returns a [IEskValidator] that checks if the given value is a `Future`
/// For better performance and readability, use the [$isFuture] variable directly.
IEskValidator isFuture<T>() => isType<Future<T>>();
final $isFuture = isFuture();

/// Returns a [IEskValidator] that checks if the given value is a `Iterable`
/// For better performance and readability, use the [$isIterable] variable directly.
IEskValidator isIterable<T>() => isType<Iterable<T>>();
final $isIterable = isIterable();

/// Checks whether the given value is a valid DateTime formattedString
IEskValidator isDate() => EskValidator((value) => EskResult(
      isValid: DateTime.tryParse(value) != null,
      expected: 'a valid date',
      value: value,
    ));
