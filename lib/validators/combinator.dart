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
IValidator any(List<IValidator> validators, {String? message}) => Validator<Result>(
      (value) {
        final collected = <Result>[];

        for (var i = 0; i < validators.length; i++) {
          final resOr = validators[i].validator(value);
          if (resOr is Future<Result>) {
            return _anyAsync(value, validators, collected, i, resOr);
          }
          final res = resOr;
          collected.add(res);
          if (res.isValid) return res;
        }

        final expectations = collected.expand((r) => r.expectations).toList();
        if (message != null) {
          return Result.invalid(value,
              expectation: Expectation(message: message, value: value));
        }
        return Result.invalid(value, expectations: expectations);
      },
    );

Future<Result> _anyAsync(
  dynamic value,
  List<IValidator> validators,
  List<Result> collected,
  int index,
  Future<Result> pending,
) async {
  // resolve current pending
  final first = await pending;
  collected.add(first);
  if (first.isValid) return first;

  // continue with remaining
  for (var i = index + 1; i < validators.length; i++) {
    final r = await validators[i].validator(value);
    collected.add(r);
    if (r.isValid) return r;
  }

  return Result.invalid(
    value,
    expectations: collected.expand((r) => r.expectations).toList(),
  );
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
  FutureOr<Result> pipeline(dynamic value) {
    // Thread potentially transformed values through the chain.
    for (var i = 0; i < validators.length; i++) {
      final resOr = validators[i].validator(value);

      if (resOr is Future<Result>) {
        return _allAsync(value, validators, i, resOr);
      }

      if (resOr.isNotValid) return resOr; // early failure preserves transformed value so far

      value = resOr.value; // adopt transformed value (if unchanged it's a no-op)
    }

    return message != null
        ? Result.invalid(value, expectation: Expectation(message: message, value: value))
        : Result.valid(value);
  }

  return Validator<Result>(pipeline);
}

Future<Result> _allAsync(
  dynamic value,
  List<IValidator> validators,
  int index,
  Future<Result> pending,
) async {
  // Resolve the first async validator (all prior were sync and have already
  // threaded their transformations into `value`).
  var currentValue = value;
  final first = await pending;
  if (first.isNotValid) return first;
  currentValue = first.value;

  for (var i = index + 1; i < validators.length; i++) {
    final r = await validators[i].validator(currentValue);
    if (r is Future<Result>) {
      final awaited = await r; // support cascading async validators
      if (awaited.isNotValid) return awaited;
      currentValue = awaited.value;
      continue;
    }
    if (r.isNotValid) return r;
    currentValue = r.value;
  }
  return Result.valid(currentValue);
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
IValidator none(List<IValidator> validators, {String? message}) => Validator<Result>(
      (value) {
        final expectations = <Expectation>[];

        for (var i = 0; i < validators.length; i++) {
          final resOr = not(validators[i]).validator(value);

          if (resOr is Future<Result>) {
            return _noneAsync(value, validators, expectations, i, resOr);
          }

          if (resOr.isNotValid) expectations.addAll(resOr.expectations);
        }

        if (expectations.isNotEmpty) {
          if (message != null) {
            return Result.invalid(value,
                expectation: Expectation(message: message, value: value));
          }
          return Result.invalid(value, expectations: expectations);
        }
        return message != null
            ? Result.invalid(value, expectation: Expectation(message: message, value: value))
            : Result.valid(value);
      },
    );

Future<Result> _noneAsync(
  dynamic value,
  List<IValidator> validators,
  List<Expectation> expectations,
  int index,
  Future<Result> pending,
) async {
  final first = await pending;

  if (first.isNotValid) expectations.addAll(first.expectations);

  for (var i = index + 1; i < validators.length; i++) {
    final res = await not(validators[i]).validator(value);
    if (res.isNotValid) expectations.addAll(res.expectations);
  }

  return expectations.isNotEmpty
      ? Result.invalid(value, expectations: expectations)
      : Result.valid(value);
}

/// Passes the test if the passed in validator is not valid
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
IValidator not(IValidator validator, {String? message}) => Validator<Result>(
      (value) {
        final resOr = validator.validator(value);
        if (resOr is Future<Result>) return _notAsync(value, resOr, message: message);

        if (message != null) {
          return Result.invalid(
            value,
            expectation: Expectation(message: message, value: value),
          );
        }

        final expectations = resOr.expectations
            .map(
              (error) => error.copyWith(
                message: 'not ${error.message}',
                code: error.code ?? 'logic.not_expected',
              ),
            )
            .toList();

        return Result(isValid: resOr.isNotValid, expectations: expectations, value: value);
      },
    );

Future<Result> _notAsync(dynamic value, Future<Result> pending, {String? message}) async {
  final result = await pending;
  final expectations = result.expectations
      .map((error) => error.copyWith(
          message: 'not ${error.message}', code: error.code ?? 'logic.not_expected'))
      .toList();
  if (message != null) {
    return Result.invalid(value, expectation: Expectation(message: message, value: value));
  }
  return Result(isValid: result.isNotValid, expectations: expectations, value: value);
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
IValidator throwInstead(IValidator validator) => Validator<Result>((value) {
      final resOr = validator.validator(value);
      if (resOr is Future<Result>) return _throwInsteadAsync(resOr);
      if (resOr.isNotValid) throw ValidatorFailedException(resOr);
      return Result.valid(value);
    });

Future<Result> _throwInsteadAsync(Future<Result> pending) async {
  final result = await pending;
  if (result.isNotValid) throw ValidatorFailedException(result);
  return Result.valid(result.value);
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
      final resOr = child.validator(value);

      if (resOr is Future<Result>) {
        return resOr.then((r) => Result(
              isValid: r.isValid,
              expectations: [
                (message != null ? error.copyWith(message: message) : error)
                    .copyWith(value: value, code: r.isValid ? null : r.firstExpectation.code)
              ],
              value: value,
            ));
      }

      return Result(
        isValid: resOr.isValid,
        expectations: [
          (message != null ? error.copyWith(message: message) : error)
              .copyWith(value: value, code: resOr.isValid ? null : resOr.firstExpectation.code)
        ],
        value: value,
      );
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
  final base = WhenValidator(condition, then, otherwise);
  if (message == null) return base;
  // Wrap with a proxy that intercepts misuse (validate()) and parent usage (validateWithParent)
  return _WhenWithMessage(base, message);
}

class _WhenWithMessage extends IWhenValidator {
  final WhenValidator inner;
  final String message;
  _WhenWithMessage(this.inner, this.message);

  @override
  FutureOr<Result> validateWithParent(dynamic value, Map<String, dynamic> map,
      {bool exists = true}) async {
    final res = await inner.validateWithParent(value, map, exists: exists);
    if (res.isValid) return res;
    return Result.invalid(value, expectation: Expectation(message: message, value: value));
  }

  @override
  Result validate(dynamic value, {bool exists = true}) {
    // misuse outside eskema
    return Result.invalid(value, expectation: Expectation(message: message, value: value));
  }

  @override
  IValidator copyWith({bool? nullable, bool? optional}) {
    return _WhenWithMessage(
      inner.copyWith(nullable: nullable, optional: optional) as WhenValidator,
      message,
    );
  }

  @override
  FutureOr<Result> validator(value) => validate(value);
}
