/// Comparison Validators
///
/// This file contains validators for comparing values

library validators.comparison;

import 'dart:async';

import 'package:collection/collection.dart';
import 'package:eskema/src/util.dart';
import '../eskema.dart';
import 'package:eskema/expectation_codes.dart';

Function _collectionEquals = const DeepCollectionEquality().equals;

/// Checks whether the given value is equal to the [otherValue] value of type [T]
///
/// Even though this function accepts any Type, note that it will not work with Collections. For that usecase prefer using [isDeepEq] instead.
IValidator isEq<T>(T otherValue, {String? message}) =>
    isType<T>() &
    validator(
      (value) => value == otherValue,
      (value) => Expectation(
        message: message ?? 'equal to ${prettifyValue(otherValue)}',
        value: value,
        code: ExpectationCodes.valueEqualMismatch,
        data: {
          'expected': prettifyValue(otherValue),
          'found': prettifyValue(value),
          'mode': 'shallow'
        },
      ),
    );

/// Checks whether the given value is equal to the [otherValue] value of type [T]
IValidator isDeepEq<T>(T otherValue, {String? message}) =>
    isType<T>() &
    validator(
      (value) => _collectionEquals(value, otherValue),
      (value) => Expectation(
        message: message ?? 'equal to ${prettifyValue(otherValue)}',
        value: value,
        code: ExpectationCodes.valueDeepEqualMismatch,
        data: {
          'expected': prettifyValue(otherValue),
          'found': prettifyValue(value),
          'mode': 'deep'
        },
      ),
    );

/// Checks whether the given value has a length property and the length matches the validators
IValidator length(List<IValidator> validators, {String? message}) {
  FutureOr<Result> pipeline(value) {
    if (hasLengthProperty(value)) {
      final len = (value as dynamic).length;
      final result = all(validators).validate(len);
      if (result.isValid) return Result.valid(value);
      // Re-wrap child expectations into a single consolidated expectation for clarity.
      // Child messages (e.g. 'equal to 2') are wrapped in square brackets like prior behavior.
      final joined = result.expectations.map((e) => e.message).join(' & ');
      return Result.invalid(value, expectations: [
        Expectation(
          message: message ?? 'length [$joined]',
          value: value,
          code: ExpectationCodes.valueLengthOutOfRange,
          data: {'length': len},
        )
      ]);
    } else {
      return expectation(message ?? '${value.runtimeType} does not have a length property',
              value, null, 'logic.predicate_failed')
          .toInvalidResult();
    }
  }

  return Validator(pipeline);
}

/// Checks whether the given value contains the [item] value of type [T]
///
/// Works for iterables and strings
IValidator contains<T>(T item, {String? message}) => Validator((value) {
      if (hasContainsProperty(value)) {
        return Result(
          isValid: value.contains(item),
          expectation: Expectation(
            message: message ?? 'contains ${prettifyValue(item)}',
            value: value,
            code: ExpectationCodes.valueContainsMissing,
            data: {'needle': prettifyValue(item)},
          ),
          value: value,
        );
      } else {
        return Expectation(
          message: '${value.runtimeType} does not have a contains property',
          value: value,
          code: ExpectationCodes.valueContainsMissing,
        ).toInvalidResult();
      }
    });

/// Checks whether the given value is one of the [options] values of type [T]
IValidator isOneOf<T>(Iterable<T> options, {String? message}) => all([
      isType<T>(),
      Validator(
        (value) => Result(
          isValid: options.contains(value),
          expectations: [
            Expectation(
                message: message ?? 'one of: ${prettifyValue(options)}',
                value: value,
                code: ExpectationCodes.valueMembershipMismatch,
                data: {'options': options.map((e) => e.toString()).toList()})
          ],
          value: value,
        ),
      ),
    ]);
