/// Combinator Validators
///
/// This file contains validators for combining multiple validation rules.
library validators.combinator;

import 'dart:async';
import 'package:eskema/eskema.dart';

/// Passes the test if any of the [Validator]s are valid, and fails if any are invalid
///
/// **Usage Examples:**
/// ```dart
/// // Accept either a string or a number
/// final stringOrNumber = any([$isString, $isNumber]);
/// stringOrNumber.validate("hello"); // Valid
/// stringOrNumber.validate(42);      // Valid
/// stringOrNumber.validate(true);    // Invalid
///
/// // Multiple validation strategies for email
/// final emailValidator = any([
///   $isEmail,  // Standard email format
///   stringMatchesPattern(r'^.+@localhost$'), // Local development
/// ]);
/// ```
IValidator any(List<IValidator> validators, {String? message}) {
  return AnyValidator(validators, message: message);
}

/// Passes the test if all of the [Validator]s are valid, and fails if any of them are invalid
///
/// In the case that a [Validator] fails, it's [Result] will be returned
///
/// **Usage Examples:**
/// ```dart
/// // Validate a password with multiple requirements
/// final passwordValidator = all([
///   stringLength([isGte(8)]),           // At least 8 characters
///   stringMatchesPattern(r'[A-Z]'),     // Contains uppercase
///   stringMatchesPattern(r'[a-z]'),     // Contains lowercase
///   stringMatchesPattern(r'[0-9]'),     // Contains number
/// ]);
///
/// // Chain transformations and validations
/// final processedData = all([
///   toString(),                         // Convert to string first
///   stringLength([isGte(1)]),          // Then validate length
///   stringMatchesPattern(r'^[A-Z]'),    // Must start with uppercase
/// ]);
/// ```
IValidator all(List<IValidator> validators, {String? message}) {
  return AllValidator(validators, message: message);
}

/// Passes the test if none of the validators pass
///
/// **Usage Examples:**
/// ```dart
/// // Ensure a string is NOT a reserved keyword
/// final notReserved = none([
///   isEq("class"),
///   isEq("function"),
///   isEq("var"),
///   isEq("const"),
/// ]);
/// notReserved.validate("myVariable"); // Valid
/// notReserved.validate("class");      // Invalid
///
/// // Validate that a number is not in a forbidden range
/// final notForbidden = none([
///   isInRange(0, 10),    // Not 0-10
///   isInRange(50, 60),   // Not 50-60
/// ]);
/// ```
IValidator none(List<IValidator> validators, {String? message}) {
  return NoneValidator(validators, message: message);
}

/// Passes the test if the child validator is not valid
///
/// When the inner validator succeeds, the failure will reuse its `code` if present,
/// otherwise falls back to `logic.not_expected`. See docs/expectation_codes.md.
///
/// **Usage Examples:**
/// ```dart
/// // Validate that a string is NOT empty
/// final notEmpty = not(stringEmpty());
/// notEmpty.validate("hello"); // Valid
/// notEmpty.validate("");       // Invalid
///
/// // Ensure a number is not zero
/// final notZero = not(isEq(0));
/// notZero.validate(5);  // Valid
/// notZero.validate(0);  // Invalid
///
/// // Validate that a field is NOT present (for optional fields)
/// final fieldNotPresent = not(exists());
/// ```
IValidator not(IValidator child, {String? message}) {
  return NotValidator(child, message: message);
}

/// Returns a [Validator] that throws a [ValidatorFailedException] instead of returning a result
///
/// **Usage Examples:**
/// ```dart
/// // API endpoint validation that throws on invalid input
/// final strictEmail = throwInstead($isEmail);
/// try {
///   strictEmail.validate("invalid-email"); // Throws ValidatorFailedException
/// } catch (e) {
///   print("Validation failed: ${e.message}");
/// }
///
/// // Form submission with immediate failure
/// final formValidator = throwInstead(all([
///   $isString,
///   stringLength([isGte(5)]),
/// ]));
/// ```
IValidator throwInstead(IValidator validator) {
  return ThrowInsteadValidator(validator);
}

/// Returns a [IValidator] that wraps the given [child] validator and adds the
/// provided [error] message to the result if the validation fails.
/// Preserves the underlying child's `code` and `data` (if the child failed).
/// See docs/expectation_codes.md.
///
/// **Usage Examples:**
/// ```dart
/// // Custom error message for age validation
/// final ageValidator = withExpectation(
///   isInRange(0, 150),
///   Expectation(message: "Age must be between 0 and 150 years")
/// );
///
/// // Localized error messages
/// final nameValidator = withExpectation(
///   stringLength([isGte(2)]),
///   Expectation(message: "El nombre debe tener al menos 2 caracteres")
/// );
///
/// // Preserve error codes while customizing message
/// final emailValidator = withExpectation(
///   $isEmail,
///   Expectation(message: "Please enter a valid email address", code: "email.invalid")
/// );
/// ```
IValidator withExpectation(IValidator child, Expectation error, {String? message}) =>
    Validator<Result>((value) {
      final result = child.validator(value);

      Expectation build(Result r) => _applyOverride(
            error,
            message,
            value,
            code: r.isValid ? null : r.firstExpectation.code,
          );

      if (result is Future<Result>) {
        return result.then(
          (r) => Result(isValid: r.isValid, expectation: build(r), value: value),
        );
      }

      return Result(isValid: result.isValid, expectation: build(result), value: value);
    });

/// Creates a conditional validator. It's conditional based on some other field in the eskema.
///
/// The [condition] validator is run against the parent map.
/// - If the condition is met, [then] is used to validate the current field's value.
/// - If the condition is not met, [otherwise] is used.
///
/// **Usage Examples:**
/// ```dart
/// // Conditional validation based on user type
/// final userValidator = eskema({
///   'userType': $isString,
///   'permissions': when(
///     isEq('admin'),           // Condition: if userType is 'admin'
///     isList(),                // Then: permissions must be a list
///     isEq(null),              // Otherwise: permissions must be null
///   ),
/// });
///
/// // Age-based validation
/// final personValidator = eskema({
///   'age': $isInt,
///   'licenseNumber': when(
///     isGte(18),               // Condition: if age >= 18
///     stringLength([isEq(8)]), // Then: license must be 8 characters
///     isEq(null),              // Otherwise: license must be null
///   ),
/// });
///
/// // Complex conditional logic
/// final paymentValidator = eskema({
///   'method': $isString,
///   'cardNumber': when(
///     isEq('credit_card'),     // If payment method is credit card
///     stringMatchesPattern(r'^\d{16}$'), // Then: validate 16-digit card number
///     isEq(null),              // Otherwise: card number should be null
///   ),
/// });
/// ```
IValidator when(
  IValidator condition, {
  required IValidator then,
  required IValidator otherwise,
  String? message,
}) {
  final base = WhenValidator(condition: condition, then: then, otherwise: otherwise);

  // Wrap with a proxy that intercepts misuse (validate()) and parent usage (validateWithParent)
  return message == null ? base : WhenWithMessage(base, message);
}

@pragma('vm:prefer-inline')
Expectation _applyOverride(Expectation base, String? message, dynamic value, {String? code}) {
  if (message == null) return base.copyWith(value: value, code: code ?? base.code);
  return base.copyWith(message: message, value: value, code: code ?? base.code);
}
