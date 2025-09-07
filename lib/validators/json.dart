/// JSON Validators
///
/// This file contains validators for working with JSON data.
library validators.json;

import 'package:eskema/eskema.dart';
import 'package:eskema/expectation_codes.dart';

/// Validates that value is a JSON container (Map or List).
IValidator isJsonContainer({String? message}) =>
    ($isMap | $isList) >
    Expectation(
      message: message ?? 'a JSON Map or List',
      code: ExpectationCodes.typeMismatch,
      data: {'expected': 'Map|List'},
    );

/// Validates that value is a JSON object (Map with String keys).
IValidator isJsonObject({String? message}) =>
    $isMap &
    Validator((value) {
      final ok = value.keys.every((k) => k is String);

      return Result(
        isValid: ok,
        value: value,
        expectation: Expectation(
          message: message ?? 'a JSON object',
          value: value,
          code: ExpectationCodes.typeMismatch,
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
          code: ExpectationCodes.typeMismatch,
          data: {'expected': 'List'},
        ),
      );
    });

/// Ensures object has all specified keys (string).
IValidator jsonHasKeys(Iterable<String> keys, {String? message}) =>
    $isMap &
    Validator((value) {
      final ok = keys.every((k) => value.containsKey(k));
      return Result(
        isValid: ok,
        value: value,
        expectation: Expectation(
          message: message ?? 'JSON object has keys: ${keys.join(', ')}',
          value: value,
          code: ExpectationCodes.typeMismatch,
          data: {'keys': keys.toList()},
        ),
      );
    });

/// Ensures array length within bounds.
IValidator jsonArrayLength({int? min, int? max, String? message}) =>
    $isList &
    Validator((value) {
      final ok = (min == null || value.length >= min) && (max == null || value.length <= max);
      return Result(
        isValid: ok,
        value: value,
        expectation: Expectation(
          message: message ??
              'array length${min != null ? ' >= $min' : ''}${max != null ? ' <= $max' : ''}',
          value: value,
          code: ExpectationCodes.valueLengthOutOfRange,
          data: {'min': min, 'max': max, 'length': value is List ? value.length : null},
        ),
      );
    });

/// Ensures every element of array satisfies inner validator.
IValidator jsonArrayEvery(IValidator elementValidator, {String? message}) =>
    $isList &
    Validator((value) {
      for (final el in value) {
        final elementResult = elementValidator.validate(el);

        if (!elementResult.isValid) {
          return Result(
            isValid: false,
            value: value,
            expectations: elementResult.expectations,
          );
        }
      }

      return Result.valid(value);
    });
