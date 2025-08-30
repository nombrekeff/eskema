/// Number Validators
///
/// This file contains validators for numeric values.
library validators.number;

import 'package:eskema/expectation.dart';
import 'package:eskema/extensions.dart';
import 'package:eskema/validator.dart';
import 'package:eskema/validators.dart';

/// Checks whether the given value is less than [max]
IValidator isLt(num max, {String? message}) {
  assert(!(max.isNaN), 'max must be a valid number');
  return isType<num>() &
      validator(
        (value) => value < max,
        (value) => Expectation(
          message: message ?? 'less than $max',
          value: value,
          code: 'value.range_out_of_bounds',
          data: {'operator': '<', 'limit': max},
        ),
      );
}

/// Checks whether the given value is less than or equal [max]
IValidator isLte(num max, {String? message}) {
  assert(!(max.isNaN), 'max must be a valid number');
  return (isType<num>() & (isLt(max) | isEq(max))) >
      Expectation(
          message: message ?? 'less than or equal to $max',
          code: 'value.range_out_of_bounds',
          data: {'operator': '<=', 'limit': max});
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
          code: 'value.range_out_of_bounds',
          data: {'operator': '>', 'limit': min},
        ),
      );
}

/// Checks whether the given value is greater or equal to [min]
IValidator isGte(num min, {String? message}) {
  assert(!(min.isNaN), 'min must be a valid number');
  return (isType<num>() & (isGt(min) | isEq(min))) >
      Expectation(
        message: message ?? 'greater than or equal to $min',
        code: 'value.range_out_of_bounds',
        data: {'operator': '>=', 'limit': min},
      );
}

/// Checks whether the given numeric value is within the range `min`, `max` (inclusive).
IValidator isInRange(num min, num max, {String? message}) {
  assert(!(min.isNaN) && !(max.isNaN), 'min/max must be valid numbers');
  assert(min <= max, 'min must be <= max');
  return (isNumber() & isGte(min) & isLte(max)) >
      Expectation(
          message: message ?? 'between $min and $max inclusive',
          code: 'value.range_out_of_bounds',
          data: {'operator': 'between_inclusive', 'min': min, 'max': max});
}
