import 'package:collection/collection.dart';
import 'package:eskema/error.dart';
import 'package:eskema/extensions.dart';
import 'package:eskema/result.dart';
import 'package:eskema/util.dart';
import 'package:eskema/validator.dart';

Function _collectionEquals = const DeepCollectionEquality().equals;

EskValidator validator(
  bool Function(dynamic value) comparisonFn,
  EskError Function(dynamic value) errorFn,
) {
  return EskValidator(
    (value) => EskResult(
      isValid: comparisonFn(value),
      errors: [errorFn(value)],
      value: value,
    ),
  );
}

//////////////////////////////////////////////////////////////////////////////////
// Logic/comparison Validators
//////////////////////////////////////////////////////////////////////////////////

/// Checks whether the given value is less than [max]
IEskValidator isLt(num max) =>
    isType<num>() &
    validator(
      (value) => value < max,
      (value) => EskError(message: 'less than $max', value: value),
    );

/// Checks whether the given value is less than or equal [max]
IEskValidator isLte(num max) =>
    isType<num>() & ((isLt(max) | isEq(max)) > "less than or equal to $max");

/// Checks whether the given value is greater than [max]
IEskValidator isGt(num min) =>
    isType<num>() &
    validator((value) => value > min,
        (value) => EskError(message: 'greater than $min', value: value));

/// Checks whether the given value is greater or equal to [max]
IEskValidator isGte(num min) =>
    isType<num>() & ((isGt(min) | isEq(min)) > "greater than or equal to $min");

/// Checks whether the given value is equal to the [otherValue] value of type [T]
///
/// Even though this function accepts any Type, note that it will not work with Collections. For that usecase prefer using [isDeepEq] instead.
IEskValidator isEq<T>(T otherValue) =>
    isType<T>() &
    validator(
      (value) => value == otherValue,
      (value) => EskError(message: 'equal to ${pretifyValue(otherValue)}', value: value),
    );

/// Checks whether the given value is equal to the [otherValue] value of type [T]
IEskValidator isDeepEq<T>(T otherValue) =>
    isType<T>() &
    validator(
      (value) => _collectionEquals(value, otherValue),
      (value) => EskError(message: 'equal to ${pretifyValue(otherValue)}', value: value),
    );

/// Checks whether the given value has a length property and the length matches the validators
IEskValidator length(List<IEskValidator> validators) => EskValidator((value) {
      if (hasLengthProperty(value)) {
        final result = all(validators).validate((value as dynamic).length);
        return result.copyWith(
          errors: [EskError(message: 'length ${result.errors}', value: value)],
        );
      } else {
        return EskResult.invalid(value,
            error: error(
              '${value.runtimeType} does not have a length property',
              value,
            ));
      }
    });

/// Checks whether the given value contains the [item] value of type [T]
///
/// Works for iterables and strings
IEskValidator contains<T>(T item) => EskValidator((value) {
      if (hasContainsProperty(value)) {
        return EskResult(
          isValid: value.contains(item),
          error: error('contains ${pretifyValue(item)}', value),
          value: value,
        );
      } else {
        return EskResult.invalid(
          value,
          error: error(
            '${value.runtimeType} does not have a contains property',
            value,
          ),
        );
      }
    });

/// Checks whether the given value is not empty
IEskValidator isNotEmpty() => stringLength([isGt(0)]);
IEskValidator isEmpty() => stringLength([isLte(0)]);

//////////////////////////////////////////////////////////////////////////////////
// List Validators
//////////////////////////////////////////////////////////////////////////////////

/// Validates that it's a List and the length matches the validators
IEskValidator listLength<T>(List<IEskValidator> validators) => isList<T>() & length(validators);

/// Validates that it's a list of `size` length
IEskValidator listIsOfLength(int size) => listLength([isEq(size)]);

/// Validates that the List contains [item]
///
/// This validator also validates that the value is a List first
/// So there's no need to add the [isList] validator when using this validator
IEskValidator listContains<T>(dynamic item) =>
    isList<T>() & (contains(item) > "List to contain ${pretifyValue(item)}");

/// Validate that the list is empty
IEskValidator listEmpty<T>() => listLength<T>([isLte(0)]) > "List to be empty";
final $listEmpty = listEmpty();

//////////////////////////////////////////////////////////////////////////////////
// String Validators
//////////////////////////////////////////////////////////////////////////////////

/// Validates that the String's length matches the validators
IEskValidator stringLength(List<IEskValidator> validators) => $isString & length(validators);

/// Validates that the String's length is the same as the provided [size]
///
/// This validator also validates that the value is a String first
/// So there's no need to add the [isString] validator when using this validator
IEskValidator stringIsOfLength(int size) => stringLength([isEq(size)]);

/// Validates that the String contains [str]
///
/// This validator also validates that the value is a String first
/// So there's no need to add the [isString] validator when using this validator
IEskValidator stringContains(String str) =>
    $isString & (contains(str) > "String to contain ${pretifyValue(str)}");

/// Validate that the string is empty
IEskValidator stringEmpty<T>() => stringLength([isLte(0)]) > "String to be empty";
final $stringEmpty = stringEmpty();

/// Validates that the String matches the provided pattern
///
/// This validator also validates that the value is a String first
/// So there's no need to add the [isString] validator when using this validator
IEskValidator stringMatchesPattern(Pattern pattern, {String? error}) {
  return isType<String>() &
      validator(
        (value) => pattern.allMatches(value).isNotEmpty,
        (value) => EskError(message: error ?? 'String to match "$pattern"', value: value),
      );
}

//////////////////////////////////////////////////////////////////////////////////
// Combinators
//////////////////////////////////////////////////////////////////////////////////

/// Passes the test if any of the [EskValidator]s are valid, and fails if any are invalid
IEskValidator any(List<IEskValidator> validators) => EskValidator((value) {
      final results = <EskResult>[];

      for (final validator in validators) {
        final result = validator.validate(value);
        results.add(result);
        if (result.isValid) return result;
      }

      return EskResult(
        isValid: false,
        errors: results.expand((r) => r.errors).toList(),
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

/// Passes the test if none of the validators pass
IEskValidator none(List<IEskValidator> validators) {
  return EskValidator((value) {
    final errors = <EskError>[];

    for (final validator in validators) {
      final result = not(validator).validate(value);

      if (result.isNotValid) {
        errors.addAll(result.errors);
      }
    }

    return errors.isNotEmpty
        ? EskResult.invalid(value, errors: errors)
        : EskResult.valid(value);
  });
}

/// Passes the test if the passed in validator is not valid
IEskValidator not(IEskValidator validator) => EskValidator(
      (value) {
        final result = validator.validate(value);

        return EskResult(
          isValid: !result.isValid,
          errors: result.errors
              .map((error) => error.copyWith(message: 'not ${error.message}'))
              .toList(),
          value: value,
        );
      },
    );

/// Allows the passed in validator to be nullable
IEskValidator nullable(IEskValidator validator) => validator.nullable();

/// Checks whether the given value is one of the [options] values of type [T]
IEskValidator isOneOf<T>(List<T> options) => all([
      isType<T>(),
      EskValidator(
        (value) => EskResult(
          isValid: options.contains(value),
          errors: [EskError(message: 'one of: ${pretifyValue(options)}', value: value)],
          value: value,
        ),
      ),
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
  return $isMap &
      EskValidator((value) {
        final errors = <EskError>[];

        for (final key in eskema.keys) {
          final field = eskema[key];
          final result = field!.validate(value[key]);

          if (result.isNotValid) {
            for (var error in result.errors) {
              errors.add(
                EskError(
                  message: error.message,
                  value: error.value,
                  path: '.$key${error.path != null ? '${error.path}' : ''}',
                ),
              );
            }
          }
        }

        return errors.isNotEmpty
            ? EskResult.invalid(value, errors: errors)
            : EskResult.valid(value);
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
IEskValidator eskemaList<T>(List<IEskValidator> eskema) {
  return isType<List>() &
      listIsOfLength(eskema.length) &
      EskValidator((value) {
        final errors = <EskError>[];

        for (int index = 0; index < value.length; index++) {
          final item = value[index];
          final effectiveValidator = eskema[index];
          final result = effectiveValidator.validate(item);

          if (result.isNotValid) {
            for (var error in result.errors) {
              errors.add(
                EskError(
                  message: error.message,
                  value: error.value,
                  path: '[$index]${error.path != null ? '${error.path}' : ''}',
                ),
              );
            }
          }
        }

        return errors.isNotEmpty
            ? EskResult.invalid(value, errors: errors)
            : EskResult.valid(value);
      });
}

/// Returns a Validator that runs [itemValidator] for each item in the list
///
/// This validator also checks that the value is a list
IEskValidator listEach(IEskValidator itemValidator) {
  return $isList &
      EskValidator((value) {
        final errors = <EskError>[];
        for (int index = 0; index < value.length; index++) {
          final item = value[index];
          final result = itemValidator.validate(item);

          if (result.isNotValid) {
            for (var error in result.errors) {
              errors.add(
                EskError(
                  message: error.message,
                  value: error.value,
                  path: '[$index]${error.path != null ? '${error.path}' : ''}',
                ),
              );
            }
          }
        }

        return errors.isNotEmpty
            ? EskResult.invalid(value, errors: errors)
            : EskResult.valid(value);
      });
}

//////////////////////////////////////////////////////////////////////////////////
// Built in types
//////////////////////////////////////////////////////////////////////////////////

/// Returns a [EskValidator] that checks if the given value is the correct type
IEskValidator isType<T>() => validator(
      (value) => value is T,
      (value) => EskError(message: T.toString(), value: value),
    );

/// Returns a [EskValidator] that checks if the given value is the correct type
IEskValidator isTypeOrNull<T>() => isType<T>() | isNull();

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
/// For better performance and readability, use the [$isInt] variable directly.
IEskValidator isInt() => isType<int>();
final $isInt = isInt();

/// Returns a [IEskValidator] that checks if the given value is a `double`
/// For better performance and readability, use the [$isDouble] variable directly.
IEskValidator isDouble() => isType<double>();
final $isDouble = isDouble();

/// Returns a [IEskValidator] that checks if the given value is a `bool`
/// For better performance and readability, use the [$isBool] variable directly.
IEskValidator isBool() => isType<bool>();
final $isBool = isBool();

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

/// Checks whether the given value is a valid DateTime formatted String
IEskValidator isDate() => validator(
      (value) => DateTime.tryParse(value) != null,
      (value) => EskError(message: 'a valid DateTime formatted String', value: value),
    );
