/// Number Validators
///
/// This file contains validators for numeric values.
library validators.number;

import 'package:eskema/expectation.dart';
import 'package:eskema/expectation_codes.dart';
import 'package:eskema/extensions/operator_extensions.dart';
import 'package:eskema/validator.dart';
import 'package:eskema/validators.dart';

/// Checks whether the given value is less than [max]
IValidator isLt<T extends num>(T max, {String? message}) {
  assert(!(max.isNaN), 'max must be a valid number');
  return isType<T>() &
      validator(
        (value) => value < max,
        (value) => Expectation(
          message: message ?? 'less than $max',
          value: value,
          code: ExpectationCodes.valueRangeOutOfBounds,
          data: {'operator': '<', 'limit': max},
        ),
      );
}

/// Checks whether the given value is less than or equal [max]
IValidator isLte<T extends num>(T max, {String? message}) {
  assert(!(max.isNaN), 'max must be a valid number');
  return (isType<T>() & (isLt(max) | isEq(max))) >
      Expectation(
        message: message ?? 'less than or equal to $max',
        code: ExpectationCodes.valueRangeOutOfBounds,
        data: {'operator': '<=', 'limit': max},
      );
}

/// Checks whether the given value is greater than [min]
IValidator isGt<T extends num>(T min, {String? message}) {
  assert(!(min.isNaN), 'min must be a valid number');
  return isType<T>() &
      validator(
        (value) => value > min,
        (value) => Expectation(
          message: message ?? 'greater than $min',
          value: value,
          code: ExpectationCodes.valueRangeOutOfBounds,
          data: {'operator': '>', 'limit': min},
        ),
      );
}

/// Checks whether the given value is greater or equal to [min]
IValidator isGte<T extends num>(T min, {String? message}) {
  assert(!(min.isNaN), 'min must be a valid number');
  return (isType<T>() & (isGt(min) | isEq(min))) >
      Expectation(
        message: message ?? 'greater than or equal to $min',
        code: ExpectationCodes.valueRangeOutOfBounds,
        data: {'operator': '>=', 'limit': min},
      );
}

/// Checks whether the given numeric value is within the range `min`, `max` (inclusive).
IValidator isInRange<T extends num>(T min, T max, {String? message}) {
  assert(!(min.isNaN) && !(max.isNaN), 'min/max must be valid numbers');
  assert(min <= max, 'min must be <= max');
  return (isNumber() & isGte(min) & isLte(max)) >
      Expectation(
        message: message ?? 'between $min and $max inclusive',
        code: ExpectationCodes.valueRangeOutOfBounds,
        data: {'operator': 'between_inclusive', 'min': min, 'max': max},
      );
}
