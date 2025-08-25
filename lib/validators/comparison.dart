/// Comparison Validators
///
/// This file contains validators for comparing values

library comparison_validators;

import 'package:collection/collection.dart';
import 'package:eskema/util.dart';
import '../eskema.dart';

Function _collectionEquals = const DeepCollectionEquality().equals;

/// Checks whether the given value is equal to the [otherValue] value of type [T]
///
/// Even though this function accepts any Type, note that it will not work with Collections. For that usecase prefer using [isDeepEq] instead.
IValidator isEq<T>(T otherValue) =>
    isType<T>() &
    validator(
      (value) => value == otherValue,
      (value) => Expectation(message: 'equal to ${pretifyValue(otherValue)}', value: value),
    );

/// Checks whether the given value is equal to the [otherValue] value of type [T]
IValidator isDeepEq<T>(T otherValue) =>
    isType<T>() &
    validator(
      (value) => _collectionEquals(value, otherValue),
      (value) => Expectation(message: 'equal to ${pretifyValue(otherValue)}', value: value),
    );

/// Checks whether the given value has a length property and the length matches the validators
IValidator length(List<IValidator> validators) => Validator((value) {
      if (hasLengthProperty(value)) {
        final result = all(validators).validate((value as dynamic).length);

        return result.copyWith(
          expectations: [Expectation(message: 'length ${result.expectations}', value: value)],
        );
      } else {
        return expectation('${value.runtimeType} does not have a length property', value)
            .toInvalidResult();
      }
    });

/// Checks whether the given value contains the [item] value of type [T]
///
/// Works for iterables and strings
IValidator contains<T>(T item) => Validator((value) {
      if (hasContainsProperty(value)) {
        return Result(
          isValid: value.contains(item),
          expectation: expectation('contains ${pretifyValue(item)}', value),
          value: value,
        );
      } else {
        return expectation('${value.runtimeType} does not have a contains property', value)
            .toInvalidResult();
      }
    });

IValidator containsKey(String key) =>
    isMap() &
    Validator((value) {
      return Result(
        isValid: value.containsKey(key),
        expectation: expectation('contains key "$key"', value, key),
        value: value,
      );
    });

/// Checks whether the given value is one of the [options] values of type [T]
IValidator isOneOf<T>(List<T> options) => all([
      isType<T>(),
      Validator(
        (value) => Result(
          isValid: options.contains(value),
          expectations: [
            Expectation(message: 'one of: ${pretifyValue(options)}', value: value)
          ],
          value: value,
        ),
      ),
    ]);
