/// Map Validators
///
/// This file contains validators that are specific to Maps

library validators.map;

import 'package:eskema/eskema.dart';
import 'package:eskema/expectation_codes.dart';
import 'package:eskema/src/util.dart';

// Internal helper to reduce duplication across contains* validators.
// Assumes previous isMap() validator in the chain, so casts are safe.
IValidator _mapPredicateValidator({
  required String message,
  required bool Function(Map<dynamic, dynamic> map) test,
  String? code, // pass through expectation code (string for const reasons)
  Map<String, Object>? data,
}) {
  return isMap() &
      Validator((value) {
        return Result(
          isValid: test(value),
          value: value,
          expectation: Expectation(
            message: message,
            value: value,
            code: code,
            data: data,
          ),
        );
      });
}

/// Validator that checks if a map contains a specific key.
IValidator containsKey(String key, {String? message}) => _mapPredicateValidator(
      test: (m) => m.containsKey(key),
      code: ExpectationCodes.valueContainsMissing,
      message: message ?? 'contains key "$key"',
      data: {'key': key},
    );

/// Validator that checks if a map contains a specific set of keys.
IValidator containsKeys(Iterable<String> keys, {String? message}) => _mapPredicateValidator(
      message: message ?? 'contains keys: ${prettifyValue(keys)}',
      test: (m) => !keys.any((key) => !m.containsKey(key)),
      code: ExpectationCodes.valueContainsMissing,
      data: {'keys': keys},
    );

/// Validator that checks if a map contains a specific set of values.
IValidator containsValues(Iterable<dynamic> values, {String? message}) =>
    _mapPredicateValidator(
      message: message ?? 'contains values: ${prettifyValue(values)}',
      test: (m) => !values.any((val) => !m.containsValue(val)),
      code: ExpectationCodes.valueContainsMissing,
      data: {'values': values},
    );

/// Validator that checks if a map contains a specific set of keys.
IValidator hasUnknownKeys(List<String> allowedKeys, {String? message}) =>
    _mapPredicateValidator(
      message: message ?? 'contains unknown keys: ${prettifyValue(allowedKeys)}',
      test: (m) => m.keys.any((key) => !allowedKeys.contains(key)),
      code: ExpectationCodes.structureUnknownKey,
      data: {'allowedKeys': allowedKeys},
    );

/// Validator that checks if a map does not contain any unknown keys.
IValidator notHasUknownKeys(List<String> allowedKeys, {String? message}) =>
    not(hasUnknownKeys(allowedKeys), message: message ?? 'contains unknown keys');
