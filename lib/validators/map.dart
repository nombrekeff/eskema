/// Map Validators
///
/// This file contains validators that are specific to Maps

library validators.map;

import 'package:eskema/eskema.dart';
import 'package:eskema/src/util.dart';

/// Validator that checks if a map contains a specific key.
IValidator containsKey(String key, {String? message}) =>
    isMap() &
    Validator((value) {
      return Result(
        isValid: value.containsKey(key),
        value: value,
        expectation: Expectation(
          message: message ?? 'contains key "$key"',
          value: value,
          code: 'value.contains_missing',
        ),
      );
    });

/// Validator that checks if a map contains a specific set of keys.
IValidator containsKeys(Iterable<String> keys, {String? message}) =>
    isMap() &
    Validator((value) {
      final missingKeys = keys.any((key) => !value.containsKey(key));

      return Result(
        isValid: !missingKeys,
        expectation: Expectation(
          message: message ?? 'contains keys: ${prettifyValue(keys)}',
          value: value,
          code: 'value.contains_missing',
        ),
        value: value,
      );
    });

/// Validator that checks if a map contains a specific set of values.
IValidator containsValues(Iterable<dynamic> values, {String? message}) =>
    isMap() &
    Validator((value) {
      final missingValues = values.any((val) => !value.containsValue(val));

      return Result(
        isValid: !missingValues,
        expectation: Expectation(
          message: message ?? 'contains values: ${prettifyValue(values)}',
          value: value,
          code: 'value.contains_missing',
        ),
        value: value,
      );
    });
