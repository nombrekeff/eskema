import 'package:eskema/config/eskema_config.dart';
import 'package:eskema/expectation.dart';
import 'package:eskema/expectation_codes.dart';
import 'package:eskema/extensions/operator_extensions.dart';
import 'package:eskema/validator/base_validator.dart';
import 'package:eskema/validators.dart';

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
      stringMatchesPattern(
        EskemaConfig.emailRegex,
        message: message ?? 'a valid email address',
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
  return isString() &
      stringMatchesPattern(
        EskemaConfig.uuidRegex,
        message: message ?? 'a valid UUID v4',
      );
}
