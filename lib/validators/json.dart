/// JSON Validators
///
/// This file contains validators for working with JSON data.
library validators.json;

import '../validator.dart';
import '../expectation.dart';
import '../result.dart';

/// Validates that value is a JSON container (Map or List).
IValidator isJsonContainer({String? message}) => Validator((value) {
      final ok = value is Map || value is List;
      return Result(
        isValid: ok,
        value: value,
        expectation: Expectation(
          message: message ?? 'a JSON Map or List',
          value: value,
          code: 'value.type_mismatch',
          data: {'expected': 'Map|List', 'found': value.runtimeType.toString()},
        ),
      );
    });

/// Validates that value is a JSON object (Map with String keys).
IValidator isJsonObject({String? message}) => Validator((value) {
      final ok = value is Map && value.keys.every((k) => k is String);
      return Result(
        isValid: ok,
        value: value,
        expectation: Expectation(
          message: message ?? 'a JSON object',
          value: value,
          code: 'value.type_mismatch',
          data: {'expected': 'Map<String,dynamic>'},
        ),
      );
    });

/// Validates that value is a JSON array (List).
IValidator isJsonArray({String? message}) => Validator((value) {
      final ok = value is List;
      return Result(
        isValid: ok,
        value: value,
        expectation: Expectation(
          message: message ?? 'a JSON array',
          value: value,
          code: 'value.type_mismatch',
          data: {'expected': 'List'},
        ),
      );
    });

/// Ensures object has all specified keys (string).
IValidator jsonHasKeys(Iterable<String> keys, {String? message}) => Validator((value) {
      final ok = value is Map && keys.every((k) => value.containsKey(k));
      return Result(
        isValid: ok,
        value: value,
        expectation: Expectation(
          message: message ?? 'JSON object has keys: ${keys.join(', ')}',
          value: value,
          code: 'value.contains_missing',
          data: {'keys': keys.toList()},
        ),
      );
    });

/// Ensures array length within bounds.
IValidator jsonArrayLength({int? min, int? max, String? message}) => Validator((value) {
      final ok = value is List &&
          (min == null || value.length >= min) &&
          (max == null || value.length <= max);
      return Result(
        isValid: ok,
        value: value,
        expectation: Expectation(
          message: message ??
              'array length${min != null ? ' >= $min' : ''}${max != null ? ' <= $max' : ''}',
          value: value,
          code: 'value.length_out_of_range',
          data: {'min': min, 'max': max, 'length': value is List ? value.length : null},
        ),
      );
    });

/// Ensures every element of array satisfies inner validator.
IValidator jsonArrayEvery(IValidator elementValidator, {String? message}) => Validator((value) {
      if (value is! List) {
        return Result(
          isValid: false,
          value: value,
          expectation: Expectation(
            message: message ?? 'a JSON array',
            value: value,
            code: 'value.type_mismatch',
          ),
        );
      }
      for (final el in value) {
        final r = elementValidator.validate(el);
        if (!r.isValid) {
          return Result(
            isValid: false,
            value: value,
            expectations: r.expectations,
          );
        }
      }
      return Result.valid(value);
    });
