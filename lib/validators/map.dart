/// Map Validators
///
/// This file contains validators that are specific to Maps

library validators.map;

import 'package:eskema/config/eskema_config.dart';
import 'package:eskema/eskema.dart';
import 'package:eskema/src/util.dart';

/// Validator that checks if a map contains a specific key.
IValidator containsKey(String key, {String? message}) =>
    isMap() &
    validator(
      (m) => m.containsKey(key),
      (m) => EskemaConfig.expectations.containsMissing(
        m,
        key,
        message: message ?? 'contains key "$key"',
        data: {'key': key},
      ),
    );

/// Validator that checks if a map contains a specific set of keys.
IValidator containsKeys(Iterable<String> keys, {String? message}) =>
    isMap() &
    validator(
      (m) => !keys.any((key) => !m.containsKey(key)),
      (m) => EskemaConfig.expectations.containsMissing(
        m,
        keys,
        message: message ?? 'contains keys: ${prettifyValue(keys)}',
        data: {'keys': keys},
      ),
    );

/// Validator that checks if a map contains a specific set of values.
IValidator containsValues(Iterable<dynamic> values, {String? message}) =>
    isMap() &
    validator(
      (m) => !values.any((val) => !m.containsValue(val)),
      (m) => EskemaConfig.expectations.containsMissing(
        m,
        values,
        message: message ?? 'contains values: ${prettifyValue(values)}',
        data: {'values': values},
      ),
    );

/// Validator that checks if a map contains a specific set of keys.
IValidator hasUnknownKeys(List<String> allowedKeys, {String? message}) =>
    isMap() &
    validator(
      (m) => m.keys.any((key) => !allowedKeys.contains(key)),
      (m) => EskemaConfig.expectations.structureUnknownKey(
        m,
        'unknown',
        message: message ?? 'contains unknown keys: ${prettifyValue(allowedKeys)}',
        data: {'allowedKeys': allowedKeys},
      ),
    );

/// Validator that checks if a map does not contain any unknown keys.
IValidator notHasUknownKeys(List<String> allowedKeys, {String? message}) =>
    not(hasUnknownKeys(allowedKeys), message: message ?? 'contains unknown keys');
