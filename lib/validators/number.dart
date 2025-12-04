/// Number Validators
///
/// This file contains validators for numeric values.
library validators.number;

import 'package:eskema/config/eskema_config.dart';
import 'package:eskema/extensions/operator_extensions.dart';
import 'package:eskema/validator.dart';
import 'package:eskema/validators.dart';

/// Checks whether the given value is less than [max]
IValidator isLt<T extends num>(T max, {String? message}) {
  assert(!(max.isNaN), 'max must be a valid number');
  return isType<T>() &
      validator(
        (value) => value < max,
        (value) => EskemaConfig.expectations.rangeOutOfBounds(
          value,
          double.negativeInfinity,
          max,
          message: message ?? 'Number less than $max',
          data: {'operator': '<', 'limit': max},
        ),
      );
}

/// Checks whether the given value is less than or equal [max]
IValidator isLte<T extends num>(T max, {String? message}) {
  assert(!(max.isNaN), 'max must be a valid number');
  return (isType<T>() & (isLt(max) | isEq(max))) >
      EskemaConfig.expectations.rangeOutOfBounds(
        null,
        double.negativeInfinity,
        max,
        message: message ?? 'Number less than or equal to $max',
        data: {'operator': '<=', 'limit': max},
      );
}

/// Checks whether the given value is greater than [min]
IValidator isGt<T extends num>(T min, {String? message}) {
  assert(!(min.isNaN), 'min must be a valid number');
  return isType<T>() &
      validator(
        (value) => value > min,
        (value) => EskemaConfig.expectations.rangeOutOfBounds(
          value,
          min,
          double.infinity,
          message: message ?? 'Number greater than $min',
          data: {'operator': '>', 'limit': min},
        ),
      );
}

/// Checks whether the given value is greater or equal to [min]
IValidator isGte<T extends num>(T min, {String? message}) {
  assert(!(min.isNaN), 'min must be a valid number');
  return (isType<T>() & (isGt(min) | isEq(min))) >
      EskemaConfig.expectations.rangeOutOfBounds(
        null,
        min,
        double.infinity,
        message: message ?? 'Number greater than or equal to $min',
        data: {'operator': '>=', 'limit': min},
      );
}

/// Checks whether the given numeric value is within the range `min`, `max` (inclusive).
IValidator isInRange<T extends num>(T min, T max, {String? message}) {
  assert(!(min.isNaN) && !(max.isNaN), 'min/max must be valid numbers');
  assert(min <= max, 'min must be <= max');
  return (isNumber() & isGte(min) & isLte(max)) >
      EskemaConfig.expectations.rangeOutOfBounds(
        null,
        min,
        max,
        message: message ?? 'Number between $min and $max inclusive',
        data: {'operator': 'between_inclusive', 'min': min, 'max': max},
      );
}
