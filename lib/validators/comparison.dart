/// Comparison Validators
///
/// This file contains validators for comparing values

library validators.comparison;

import 'package:collection/collection.dart';
import 'package:eskema/config/eskema_config.dart';
import 'package:eskema/src/util.dart';
import '../eskema.dart';

Function _collectionEquals = const DeepCollectionEquality().equals;

/// A validator that always returns valid
IValidator noop() => Validator((value) => Result.valid(value));

/// Checks whether the given value is equal to the [otherValue] value of type [T]
///
/// Even though this function accepts any Type, note that it will not work with Collections. 
/// For that usecase prefer using [isDeepEq] instead.
IValidator isEq<T>(T otherValue, {String? message}) =>
    validator(
      (value) => value == otherValue,
      (value) => EskemaConfig.expectations.equalMismatch(
        value,
        otherValue,
        message: message,
        data: {
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
      (value) => EskemaConfig.expectations.deepEqualMismatch(
        value,
        otherValue,
        message: message,
        data: {
          'found': prettifyValue(value),
          'mode': 'deep'
        },
      ),
    );

/// Checks whether the given value has a length property and the length matches the validators
IValidator length(List<IValidator> validators, {String? message}) {
  return Validator((value) {
    if (hasLengthProperty(value)) {
      final len = (value as dynamic).length;
      final result = all(validators).validate(len);

      if (result.isValid) return Result.valid(value);

      // Re-wrap child expectations into a single consolidated expectation for clarity.
      // Child messages (e.g. 'equal to 2') are wrapped in square brackets like prior behavior.
      final joined = result.expectations.map((e) => e.message).join(' & ');

      return EskemaConfig.expectations.lengthOutOfRange(
        value,
        len, // passing len as expected? No, lengthOutOfRange expects 'expected'.
             // But here we don't know the expected length, we just know it failed.
             // The message 'length [$joined]' implies we are aggregating errors.
             // Maybe we should use a generic expectation or update lengthOutOfRange?
             // lengthOutOfRange(value, expected).
             // Here we are wrapping child expectations.
             // The original code used valueLengthOutOfRange code.
             // Let's use lengthOutOfRange with len as expected (which is weird but matches data 'length': len?)
             // Wait, original data was {'length': len}.
             // lengthOutOfRange puts {'expected': expected}.
             // So if I pass len as expected, data will be {'expected': len}.
             // But we want {'length': len}.
             // I can override data.
        message: message ?? 'length [$joined]',
        data: {'length': len},
      ).toInvalidResult();
    }

    return EskemaConfig.expectations.predicateFailed(
      value,
      message: message ?? '${value.runtimeType} does not have a length property',
    ).toInvalidResult();
  });
}

/// Checks whether the given value contains the [item] value of type [T]
///
/// Works for iterables and strings
IValidator contains<T>(T item, {String? message}) {
  return Validator((value) {
    if (hasContainsProperty(value)) {
      return Result(
        isValid: value.contains(item),
        expectation: EskemaConfig.expectations.containsMissing(
          value,
          item,
          message: message,
          data: {'needle': prettifyValue(item)},
        ),
        value: value,
      );
    }

    return EskemaConfig.expectations.containsMissing(
      value,
      'contains property',
      message: '${value.runtimeType} does not have a contains property',
    ).toInvalidResult();
  });
}

/// Checks whether the given value is one of the [options] values of type [T]
IValidator isOneOf<T>(Iterable<T> options, {String? message}) {
  return Validator(
    (value) => Result(
      isValid: options.contains(value),
      expectation: EskemaConfig.expectations.membershipMismatch(
        value,
        options,
        message: message,
        data: {'options': options.map((e) => e.toString()).toList()},
      ),
      value: value,
    ),
  );
}
