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
/// By default, validation stops at the first failure and chains transformed values.
/// If [collecting] is true, all validators are run against the original input value
/// and all failures are collected without value chaining.
///
/// **Usage Examples:**
/// ```dart
/// // Standard behavior: stop at first failure, chain values
/// final passwordValidator = all([
///   toString(),                         // Convert to string first
///   stringLength([isGte(8)]),          // Then validate length (chained value)
///   stringMatchesPattern(r'[A-Z]'),     // Must contain uppercase
/// ]);
///
/// // Collecting behavior: show all errors at once
/// final formValidator = all([
///   isType<String>(),                   // Must be a string
///   stringLength([isGte(3)]),          // Must be at least 3 chars
///   stringMatchesPattern(r'[A-Z]'),     // Must contain uppercase
///   stringMatchesPattern(r'[0-9]'),     // Must contain number
/// ], collecting: true);
/// 
/// // Will show ALL validation errors, not just the first one
/// final result = formValidator.validate(123);
/// // result.expectations will contain errors for type, length, uppercase, and number
/// ```
AllValidator all(List<IValidator> validators, {String? message, bool collecting = false}) {
  return AllValidator(validators, message: message, collecting: collecting);
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

@pragma('vm:prefer-inline')
Expectation _applyOverride(Expectation base, String? message, dynamic value, {String? code}) {
  if (message == null) return base.copyWith(value: value, code: code ?? base.code);
  return base.copyWith(message: message, value: value, code: code ?? base.code);
}
