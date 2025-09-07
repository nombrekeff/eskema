/// Core transformer utilities and helpers.
///
/// This file contains the fundamental building blocks for creating transformers,
/// including the basic transform function and the unified pivotValue helper.
library transformers.core;

import 'package:eskema/eskema.dart';

IValidator handleReturnPreserveValue(IValidator validator, String? message) {
  return message != null
      ? expectPreserveValue(validator, Expectation(message: message))
      : validator;
}


/// Transforms a value using a provided function.
///
/// The [fn] function is applied to the input value, and the result is then
/// passed to the [child] validator. This is a low-level building block for
/// creating custom transformers.
IValidator transform<T>(T Function(dynamic) fn, IValidator child) {
  return Validator((value) => child.validate(fn(value)));
}

/// Unified helper for value pivoting operations.
///
/// This function creates a validator that transforms the input value using the
/// provided [transformFn], then validates the result with the [child] validator.
/// If the transformation fails or returns null, it returns an invalid result
/// with the provided [errorMessage].
///
/// This preserves the behavior of the original functions:
/// - If child validation succeeds, returns Result.valid with the transformed value
/// - If child validation fails, returns the child's result (preserving error details)
///
/// This is used internally by pickKeys, pluckKey, and flattenMapKeys to reduce
/// code duplication.
IValidator pivotValue(
  dynamic Function(dynamic value) transformFn, {
  required IValidator child,
  required String errorMessage,
}) {
  return Validator((value) {
    final transformed = transformFn(value);

    if (transformed == null) {
      return Expectation(message: errorMessage, value: value).toInvalidResult();
    }

    final childResult = child.validate(transformed);
    if (childResult.isValid) return Result.valid(transformed);

    return childResult;
  });
}

/// Adds an expectation message while preserving the child's resulting value
/// (useful for coercions where later constraints rely on the coerced type even on failure).
IValidator expectPreserveValue(IValidator validator, Expectation expectation) {
  return Validator((value) {
    final innerResult = validator.validate(value);
    if (innerResult.isValid) return Result.valid(innerResult.value);

    return Result.invalid(innerResult.value, expectations: [
      expectation.copyWith(
        code: innerResult.firstExpectation.code,
        value: innerResult.value,
      )
    ]);
  });
}
