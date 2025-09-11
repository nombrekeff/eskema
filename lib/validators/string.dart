/// String Validators
///
/// This file contains validators for checking the format and content of strings.

library validators.string;

import 'package:eskema/eskema.dart';
import 'package:eskema/expectation_codes.dart';
import 'package:eskema/src/util.dart';

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
  return stringLength([isEq(size)], message: message ?? 'String length to be $size');
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
  return $isString &
      contains(
        str,
        message: message ?? 'String to contain ${prettifyValue(str)}',
      );
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
        (value) => Expectation(
          message: message ?? 'String to match "$pattern"',
          value: value,
          code: ExpectationCodes.valuePatternMismatch,
          data: {'pattern': pattern.toString()},
        ),
      );
}

/// Validates that it's a String and it's lowecase
IValidator isLowerCase({String? message}) =>
    isString() &
    validator(
      (value) => value.toLowerCase() == value,
      (value) => Expectation(
        message: message ?? 'lowercase string',
        code: ExpectationCodes.valueCaseMismatch,
        data: {'expected_case': 'lower'},
      ),
    );

/// Validates that it's a String and it's uppercase
IValidator isUpperCase({String? message}) =>
    isString() &
    validator(
      (value) => value.toUpperCase() == value,
      (value) => Expectation(
        message: message ?? 'uppercase string',
        code: ExpectationCodes.valueCaseMismatch,
        data: {'expected_case': 'upper'},
      ),
    );

final emailRegex = RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');

/// Validates that the String is a valid email address.
///
/// **Usage Examples:**
/// ```dart
/// final emailValidator = isEmail();
/// emailValidator.validate("user@example.com");    // Valid
/// emailValidator.validate("invalid-email");       // Invalid
/// emailValidator.validate("user@.com");           // Invalid
///
/// // Combined with other validators
/// final strictEmail = all([$isString, isEmail()]);
/// ```
IValidator isEmail({String? message}) {
  return isString() &
      stringMatchesPattern(emailRegex, message: message ?? 'a valid email address');
}

/// Checks whether the given string is empty
IValidator isStringEmpty({String? message}) {
  return stringLength([isLte(0)]) >
      Expectation(
        message: message ?? 'String to be empty',
        code: ExpectationCodes.valueLengthOutOfRange,
        data: {'expected': 0},
      );
}

/// Validates that the String is a valid URL. By it uses non-strict validation (like "example.com").
///
/// If you want to enforce strict validation (must include scheme), set [strict] to true or use [isStrictUrl].
///
/// **Usage Examples:**
/// ```dart
/// final urlValidator = isUrl();
/// urlValidator.validate("https://example.com");     // Valid
/// urlValidator.validate("example.com");             // Valid (non-strict)
/// urlValidator.validate("not-a-url");               // Invalid
///
/// // Strict validation (requires scheme)
/// final strictUrl = isUrl(strict: true);
/// strictUrl.validate("https://example.com");        // Valid
/// strictUrl.validate("example.com");                // Invalid
///
/// // Or use the convenience method
/// final strictUrl2 = isStrictUrl();
/// ```
IValidator isUrl({bool strict = false, String? message}) {
  return isString() &
      validator(
        (value) {
          return strict
              ? Uri.tryParse(value)?.isAbsolute ?? false
              : Uri.tryParse(value) != null;
        },
        (value) => Expectation(
          message: message ?? 'a valid URL',
          value: value,
          code: ExpectationCodes.valueFormatInvalid,
          data: {'format': 'url'},
        ),
      );
}

IValidator isStrictUrl({String? message}) => isUrl(strict: true, message: message);

final uuidRegex = RegExp(
    r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-4[0-9a-fA-F]{3}-[89abAB][0-9a-fA-F]{3}-[0-9a-fA-F]{12}$');

/// Validates that the String is a valid UUID (v4).
///
/// **Usage Examples:**
/// ```dart
/// final uuidValidator = isUuidV4();
/// uuidValidator.validate("550e8400-e29b-41d4-a716-446655440000"); // Valid
/// uuidValidator.validate("not-a-uuid");                        // Invalid
/// uuidValidator.validate("550e8400-e29b-41d4-a716");            // Invalid
///
/// // Combined with other validations
/// final entityValidator = eskema({
///   'id': all([$isString, isUuidV4()]),
///   'name': $isString,
/// });
/// ```
IValidator isUuidV4({String? message}) {
  return isString() & stringMatchesPattern(uuidRegex, message: message ?? 'a valid UUID v4');
}

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
      (value) => Expectation(
        message: message ?? 'a valid formatted int String',
        value: value,
        code: ExpectationCodes.valueFormatInvalid,
        data: {'format': 'int'},
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
      (value) => Expectation(
        message: message ?? 'a valid formatted double String',
        value: value,
        code: ExpectationCodes.valueFormatInvalid,
        data: {'format': 'double'},
      ),
    );

/// Validates that the String can be parsed as a `num` (int or double)
IValidator isNumString({String? message}) =>
    isType<String>() &
    validator(
      (value) => num.tryParse(value.trim()) != null,
      (value) => Expectation(
        message: message ?? 'a valid formatted number String',
        value: value,
        code: ExpectationCodes.valueFormatInvalid,
        data: {'format': 'num'},
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
      (value) => Expectation(
        message: message ?? 'a valid formatted boolean String',
        value: value,
        code: ExpectationCodes.valueFormatInvalid,
        data: {'format': 'bool'},
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
      (value) => Expectation(
        message: message ?? 'a valid DateTime formatted String',
        value: value,
        code: ExpectationCodes.valueFormatInvalid,
        data: {'format': 'date_time'},
      ),
    );
