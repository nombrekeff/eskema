/// Comparison Validators
///
/// This file contains validators for comparing values

library comparison_validators;

import 'dart:async';

import 'package:collection/collection.dart';
import 'package:eskema/src/util.dart';
import '../eskema.dart';

Function _collectionEquals = const DeepCollectionEquality().equals;

/// Checks whether the given value is equal to the [otherValue] value of type [T]
///
/// Even though this function accepts any Type, note that it will not work with Collections. For that usecase prefer using [isDeepEq] instead.
IValidator isEq<T>(T otherValue) =>
    isType<T>() &
    validator(
      (value) => value == otherValue,
      (value) => Expectation(
        message: 'equal to ${prettifyValue(otherValue)}',
        value: value,
        code: 'value.equal_mismatch',
        data: {
          'expected': prettifyValue(otherValue),
          'found': prettifyValue(value),
          'mode': 'shallow'
        },
      ),
    );

/// Checks whether the given value is equal to the [otherValue] value of type [T]
IValidator isDeepEq<T>(T otherValue) =>
    isType<T>() &
    validator(
      (value) => _collectionEquals(value, otherValue),
      (value) => Expectation(
        message: 'equal to ${prettifyValue(otherValue)}',
        value: value,
        code: 'value.deep_equal_mismatch',
        data: {
          'expected': prettifyValue(otherValue),
          'found': prettifyValue(value),
          'mode': 'deep'
        },
      ),
    );

/// Checks whether the given value has a length property and the length matches the validators
IValidator length(List<IValidator> validators) {
  FutureOr<Result> pipeline(value) {
    if (hasLengthProperty(value)) {
      final result = all(validators).validate((value as dynamic).length);

      return result.copyWith(
        expectations: [
          Expectation(
            message: 'length ${result.expectations}',
            value: value,
            code: 'value.length_out_of_range',
            data: {'length': (value as dynamic).length},
          )
        ],
      );
    } else {
      return expectation('${value.runtimeType} does not have a length property', value, null,
              'logic.predicate_failed')
          .toInvalidResult();
    }
  }

  return Validator(pipeline);
}

/// Checks whether the given value contains the [item] value of type [T]
///
/// Works for iterables and strings
IValidator contains<T>(T item) => Validator((value) {
      if (hasContainsProperty(value)) {
        return Result(
          isValid: value.contains(item),
          expectation: expectation(
              'contains ${prettifyValue(item)}', value, null, 'value.contains_missing'),
          value: value,
        );
      } else {
        return expectation('${value.runtimeType} does not have a contains property', value,
                null, 'logic.predicate_failed')
            .toInvalidResult();
      }
    });

/// Checks whether the given value is one of the [options] values of type [T]
IValidator isOneOf<T>(Iterable<T> options) => all([
      isType<T>(),
      Validator(
        (value) => Result(
          isValid: options.contains(value),
          expectations: [
            Expectation(
                message: 'one of: ${prettifyValue(options)}',
                value: value,
                code: 'value.membership_mismatch',
                data: {'options': options.map((e) => e.toString()).toList()})
          ],
          value: value,
        ),
      ),
    ]);
