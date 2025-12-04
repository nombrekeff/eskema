/// String Validators
///
/// This file contains validators for checking the format and content of strings.

library validators.string;

import 'package:eskema/config/eskema_config.dart';
import 'package:eskema/enum/case.dart';
import 'package:eskema/extensions/operator_extensions.dart';
import 'package:eskema/src/util.dart';
import 'package:eskema/validator/base_validator.dart';
import 'package:eskema/validators.dart';

/// Validates that the String's length matches the validators
///
/// **Usage Examples:**
/// ```dart
/// // Validate password length (8-20 characters)
/// final passwordLength = stringLength([isInRange(8, 20)]);
/// passwordLength.validate("mypassword");     // Valid
/// passwordLength.validate("short");          // Invalid
///
/// // Validate username length (exactly 10 characters)
/// final usernameLength = stringLength([isEq(10)]);
/// usernameLength.validate("user123456");     // Valid
/// usernameLength.validate("user");           // Invalid
/// ```
IValidator stringLength(List<IValidator> validators, {String? message}) {
  return ($isString & length(validators, message: message));
}

/// Validates that the String's length is the same as the provided [size]
///
/// This validator also validates that the value is a String first
/// So there's no need to add the [isString] validator when using this validator
IValidator stringIsOfLength(int size, {String? message}) {
  return stringLength([isEq(size)], message: message ?? 'String length [to be $size]');
}

/// Validates that the String contains [str]
///
/// This validator also validates that the value is a String first
/// So there's no need to add the [isString] validator when using this validator
///
/// **Usage Examples:**
/// ```dart
/// // Check for required domain in email
/// final hasDomain = stringContains("@example.com");
/// hasDomain.validate("user@example.com");    // Valid
/// hasDomain.validate("user@gmail.com");      // Invalid
///
/// // Validate file extension
/// final isImage = stringContains(".jpg") | stringContains(".png");
/// isImage.validate("photo.jpg");             // Valid
/// isImage.validate("document.pdf");          // Invalid
/// ```
IValidator stringContains(String str, {String? message}) {
  return $isString & contains(str);
}

/// Validates that the String matches the provided pattern
///
/// This validator also validates that the value is a String first
/// So there's no need to add the [isString] validator when using this validator
///
/// **Usage Examples:**
/// ```dart
/// // Validate phone number format
/// final phonePattern = stringMatchesPattern(r'^\+?[\d\s\-\(\)]+$');
/// phonePattern.validate("+1-555-0123");     // Valid
/// phonePattern.validate("invalid-phone");    // Invalid
///
/// // Validate hexadecimal color
/// final hexColor = stringMatchesPattern(r'^#[0-9A-Fa-f]{6}$');
/// hexColor.validate("#FF5733");              // Valid
/// hexColor.validate("#GGG");                 // Invalid
///
/// // Custom error message
/// final customPattern = stringMatchesPattern(r'^\d{4}-\d{2}-\d{2}$',
///   message: 'Date must be in YYYY-MM-DD format');
/// ```
IValidator stringMatchesPattern(Pattern pattern, {String? message}) {
  return isType<String>() &
      validator(
        (value) => pattern.allMatches(value).isNotEmpty,
        (value) => EskemaConfig.expectations.patternMismatch(
          value,
          pattern,
          message: message,
        ),
      );
}

/// Validates that it's a String and it's lowecase
IValidator isLowerCase({String? message}) =>
    isString() &
    validator(
      (value) => value.toLowerCase() == value,
      (value) => EskemaConfig.expectations.caseMismatch(
        value,
        Case.lower,
        message: message,
      ),
    );

/// Validates that it's a String and it's uppercase
IValidator isUpperCase({String? message}) =>
    isString() &
    validator(
      (value) => value.toUpperCase() == value,
      (value) => EskemaConfig.expectations.caseMismatch(
        value,
        Case.upper,
        message: message,
      ),
    );

/// Checks whether the given string is empty
IValidator isStringEmpty() => validator(
      (value) => value.isEmpty,
      (value) => EskemaConfig.expectations.empty(value),
    );

/// Validates that the String can be parsed as an `int` (e.g. '123', '-42')
///
/// **Usage Examples:**
/// ```dart
/// final intStringValidator = isIntString();
/// intStringValidator.validate("123");        // Valid
/// intStringValidator.validate("-42");        // Valid
/// intStringValidator.validate("12.5");       // Invalid
/// intStringValidator.validate("not-a-number"); // Invalid
///
/// // Combined with length validation
/// final idValidator = all([$isString, isIntString(), stringLength([isEq(9)])]);
/// ```
IValidator isIntString({String? message}) =>
    isType<String>() &
    validator(
      (value) => int.tryParse(value.trim()) != null,
      (value) => EskemaConfig.expectations.formatInvalid(
        value,
        'int string',
        message: message,
      ),
    );

/// Validates that the String can be parsed as a `double` (e.g. '123.45', '-1e3')
///
/// **Usage Examples:**
/// ```dart
/// final doubleStringValidator = isDoubleString();
/// doubleStringValidator.validate("123.45");     // Valid
/// doubleStringValidator.validate("-1e3");        // Valid
/// doubleStringValidator.validate("12");          // Valid (int is also double)
/// doubleStringValidator.validate("not-a-number"); // Invalid
///
/// // For strict double-only validation
/// final strictDouble = all([$isString, isDoubleString(), not(isIntString())]);
/// ```
IValidator isDoubleString({String? message}) =>
    isType<String>() &
    validator(
      (value) => double.tryParse(value.trim()) != null,
      (value) => EskemaConfig.expectations.formatInvalid(
        value,
        'double string',
        message: message,
      ),
    );

/// Validates that the String can be parsed as a `num` (int or double)
IValidator isNumString({String? message}) =>
    isType<String>() &
    validator(
      (value) => num.tryParse(value.trim()) != null,
      (value) => EskemaConfig.expectations.formatInvalid(
        value,
        'num string',
        message: message,
      ),
    );

/// Validates that the String can be parsed as a `bool` ('true' or 'false', case insensitive)
///
/// **Usage Examples:**
/// ```dart
/// final boolStringValidator = isBoolString();
/// boolStringValidator.validate("true");       // Valid
/// boolStringValidator.validate("false");      // Valid
/// boolStringValidator.validate("TRUE");       // Valid (case insensitive)
/// boolStringValidator.validate("yes");        // Invalid
/// boolStringValidator.validate("1");          // Invalid
///
/// // Combined with trimming
/// final configValidator = eskema({
///   'enabled': all([$isString, isBoolString()]),
///   'debug': all([$isString, isBoolString()]),
/// });
/// ```
IValidator isBoolString({String? message}) =>
    isType<String>() &
    validator(
      (value) {
        final lower = value.toLowerCase().trim();
        return lower == 'true' || lower == 'false';
      },
      (value) => EskemaConfig.expectations.formatInvalid(
        value,
        'bool string',
        message: message,
      ),
    );

/// Checks whether the given value is a valid DateTime formatted String
///
/// **Usage Examples:**
/// ```dart
/// final dateValidator = isDate();
/// dateValidator.validate("2023-12-25");           // Valid
/// dateValidator.validate("2023-12-25T10:30:00Z"); // Valid
/// dateValidator.validate("not-a-date");           // Invalid
/// dateValidator.validate("25-12-2023");           // Invalid
///
/// // Combined with other validations
/// final eventValidator = eskema({
///   'title': $isString,
///   'date': all([$isString, isDate()]),
///   'description': $isString.optional(),
/// });
/// ```
IValidator isDate({String? message}) => validator(
      (value) => DateTime.tryParse(value) != null,
      (value) => EskemaConfig.expectations.dateInvalid(
        value,
        message: message
      ),
    );
