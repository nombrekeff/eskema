/// Combinator Validators
/// 
/// This file contains validators for combining multiple validation rules.
library combinator_validators;

import 'package:eskema/eskema.dart';

/// Passes the test if any of the [Validator]s are valid, and fails if any are invalid
IValidator any(List<IValidator> validators) => Validator((value) {
      final results = <Result>[];

      for (final validator in validators) {
        final result = validator.validate(value);
        results.add(result);
        if (result.isValid) return result;
      }

      return Result.invalid(
        value,
        expectations: results.expand((r) => r.expectations).toList(),
      );
    });

/// Passes the test if all of the [Validator]s are valid, and fails if any of them are invalid
///
/// In the case that a [Validator] fails, it's [Result] will be returned
IValidator all(List<IValidator> validators) => Validator((value) {
      for (final validator in validators) {
        final result = validator.validate(value);
        if (result.isNotValid) return result;
      }

      return Result.valid(value);
    });

/// Passes the test if none of the validators pass
IValidator none(List<IValidator> validators) {
  return Validator((value) {
    final expectations = <Expectation>[];

    for (final validator in validators) {
      final result = not(validator).validate(value);

      if (result.isNotValid) {
        expectations.addAll(result.expectations);
      }
    }

    return expectations.isNotEmpty
        ? Result.invalid(value, expectations: expectations)
        : Result.valid(value);
  });
}

/// Passes the test if the passed in validator is not valid
IValidator not(IValidator validator) => Validator(
      (value) {
        final result = validator.validate(value);

        return Result(
          isValid: !result.isValid,
          expectations: result.expectations
              .map((error) => error.copyWith(message: 'not ${error.message}'))
              .toList(),
          value: value,
        );
      },
    );

/// Returns a [Validator] that throws a [ValidatorFailedException] instead of returning a result
IValidator throwInstead(IValidator validator) => Validator(
      (value) {
        final result = validator.validate(value);
        if (result.isNotValid) throw ValidatorFailedException(result);
        return Result.valid(value);
      },
    );

/// Returns a [IValidator] that wraps the given [child] validator and adds the
/// provided [error] message to the result if the validation fails.
IValidator withError(IValidator child, String error) {
  return Validator(
    (value) => Result(
      isValid: child.validate(value).isValid,
      expectations: [Expectation(message: error, value: value)],
      value: value,
    ),
  );
}

/// Creates a conditional validator. It's conditional based on some other field in the eskema.
///
/// The [condition] validator is run against the parent map.
/// - If the condition is met, [then] is used to validate the current field's value.
/// - If the condition is not met, [otherwise] is used.
IValidator when(
  IValidator condition, {
  required IValidator then,
  required IValidator otherwise,
}) {
  return WhenValidator(condition, then, otherwise);
}
