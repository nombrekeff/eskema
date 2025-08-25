/// Number Validators
/// 
/// This file contains validators for numeric values.
library number_validators;
import 'package:eskema/expectation.dart';
import 'package:eskema/extensions.dart';
import 'package:eskema/validator.dart';
import 'package:eskema/validators.dart';

/// Checks whether the given value is less than [max]
IValidator isLt(num max) =>
    isType<num>() &
    validator(
      (value) => value < max,
      (value) => Expectation(message: 'less than $max', value: value),
    );

/// Checks whether the given value is less than or equal [max]
IValidator isLte(num max) =>
    isType<num>() & ((isLt(max) | isEq(max)) > "less than or equal to $max");

/// Checks whether the given value is greater than [min]
IValidator isGt(num min) =>
    isType<num>() &
    validator((value) => value > min,
        (value) => Expectation(message: 'greater than $min', value: value));

/// Checks whether the given value is greater or equal to [min]
IValidator isGte(num min) =>
    isType<num>() & ((isGt(min) | isEq(min)) > "greater than or equal to $min");

/// Checks whether the given numeric value is within the range `min`, `max` (inclusive).
IValidator isInRange(num min, num max) =>
    isNumber() & isGte(min) & isLte(max) > 'between $min and $max inclusive';
