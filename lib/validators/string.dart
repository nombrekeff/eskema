/// String Validators
///
/// This file contains validators for checking the format and content of strings.

library string_validators;

import 'package:eskema/eskema.dart';
import 'package:eskema/util.dart';

/// Validates that the String's length matches the validators
IValidator stringLength(List<IValidator> validators) => $isString & length(validators);

/// Validates that the String's length is the same as the provided [size]
///
/// This validator also validates that the value is a String first
/// So there's no need to add the [isString] validator when using this validator
IValidator stringIsOfLength(int size) => stringLength([isEq(size)]);

/// Validates that the String contains [str]
///
/// This validator also validates that the value is a String first
/// So there's no need to add the [isString] validator when using this validator
IValidator stringContains(String str) =>
    $isString & (contains(str) > "String to contain ${pretifyValue(str)}");

/// Validate that it's a String and the string is empty
IValidator stringEmpty<T>() => stringLength([isLte(0)]) > "String to be empty";

/// Validates that the String matches the provided pattern
///
/// This validator also validates that the value is a String first
/// So there's no need to add the [isString] validator when using this validator
IValidator stringMatchesPattern(Pattern pattern, {String? error}) {
  return isType<String>() &
      validator(
        (value) => pattern.allMatches(value).isNotEmpty,
        (value) => Expectation(message: error ?? 'String to match "$pattern"', value: value),
      );
}

/// Validates that it's a String and it's lowecase
IValidator isLowerCase() =>
    isString() & (stringMatchesPattern(RegExp(r'^[a-z]+$')) > 'lowercase string');

/// Validates that it's a String and it's uppercase
IValidator isUpperCase() =>
    isString() & (stringMatchesPattern(RegExp(r'^[A-Z]+$')) > 'uppercase string');

/// Validates that the String is a valid email address.
IValidator isEmail() {
  // A simple regex for email validation. For a more robust one, consider a dedicated package.
  final emailRegex = RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');
  return isString() & stringMatchesPattern(emailRegex, error: 'a valid email address');
}

/// Checks whether the given value is not empty
IValidator isNotEmpty() => stringLength([isGt(0)]);
IValidator isEmpty() => stringLength([isLte(0)]);

/// Validates that the String is a valid URL. By it uses non-strict validation (like "example.com").
///
/// If you want to enforce strict validation (must include scheme), set [strict] to true or use [isStrictUrl].
IValidator isUrl({bool strict = false}) {
  return isString() &
      validator(
        (value) =>
            strict ? Uri.tryParse(value)?.isAbsolute ?? false : Uri.tryParse(value) != null,
        (value) => Expectation(message: 'a valid URL', value: value),
      );
}

IValidator isStrictUrl() => isUrl(strict: true);

/// Validates that the String is a valid UUID (v4).
IValidator isUuidV4() {
  final uuidRegex = RegExp(
      r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-4[0-9a-fA-F]{3}-[89abAB][0-9a-fA-F]{3}-[0-9a-fA-F]{12}$');
  return isString() & stringMatchesPattern(uuidRegex, error: 'a valid UUID v4');
}

/// Validates that the String can be parsed as an `int` (e.g. '123', '-42')
IValidator isIntString() =>
    isType<String>() &
    validator(
      (value) => int.tryParse(value.trim()) != null,
      (value) => Expectation(message: 'a valid formatted int String', value: value),
    );

/// Validates that the String can be parsed as a `double` (e.g. '123.45', '-1e3')
IValidator isDoubleString() =>
    isType<String>() &
    validator(
      (value) => double.tryParse(value.trim()) != null,
      (value) => Expectation(message: 'a valid formatted double String', value: value),
    );

/// Validates that the String can be parsed as a `num` (int or double)
IValidator isNumString() =>
    isType<String>() &
    validator(
      (value) => num.tryParse(value.trim()) != null,
      (value) => Expectation(message: 'a valid formatted number String', value: value),
    );

/// Checks whether the given value is a valid DateTime formatted String
IValidator isDate() => validator(
      (value) => DateTime.tryParse(value) != null,
      (value) => Expectation(message: 'a valid DateTime formatted String', value: value),
    );
