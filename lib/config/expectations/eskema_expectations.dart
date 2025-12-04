import 'package:eskema/enum/case.dart';
import 'package:eskema/expectation.dart';
import 'package:eskema/expectation_codes.dart';

/// The contract for generating expectations.
/// Users can extend this to customize messages or behavior globally.
class EskemaExpectations {
  const EskemaExpectations();

  /// Helper to reduce boilerplate in the methods below.
  Expectation _create({
    required String code,
    required dynamic value,
    required String defaultMessage,
    Map<String, Object?>? data,
    String? overrideMessage,
  }) {
    return Expectation.fromCode(
      code: code,
      value: value,
      data: data,
      message: overrideMessage,
      defaultMessage: defaultMessage,
    );
  }

  // --- Value Domain ---

  Expectation lengthOutOfRange(
    dynamic value,
    dynamic expected, {
    String? message,
    Map<String, Object?> data = const {},
  }) {
    return _create(
      code: ExpectationCodes.valueLengthOutOfRange,
      value: value,
      defaultMessage: 'Length must be $expected',
      data: {'expected': expected, ...data},
      overrideMessage: message,
    );
  }

  Expectation containsMissing(
    dynamic value,
    dynamic expected, {
    String? message,
    Map<String, Object?> data = const {},
  }) {
    return _create(
      code: ExpectationCodes.valueContainsMissing,
      value: value,
      defaultMessage: 'Must contain $expected',
      data: {'expected': expected, ...data},
      overrideMessage: message,
    );
  }

  Expectation patternMismatch(
    dynamic value,
    Pattern pattern, {
    String? message,
    Map<String, Object?> data = const {},
  }) {
    return _create(
      code: ExpectationCodes.valuePatternMismatch,
      value: value,
      defaultMessage: 'Must match pattern "$pattern"',
      data: {'pattern': pattern, ...data},
      overrideMessage: message,
    );
  }

  Expectation caseMismatch(
    dynamic value,
    Case expectedCase, {
    String? message,
    Map<String, Object?> data = const {},
  }) {
    return _create(
      code: ExpectationCodes.valueCaseMismatch,
      value: value,
      defaultMessage: 'Must be $expectedCase case',
      data: {'expected_case': expectedCase, ...data},
      overrideMessage: message,
    );
  }

  Expectation equalMismatch(
    dynamic value,
    dynamic expected, {
    String? message,
    Map<String, Object?> data = const {},
  }) {
    return _create(
      code: ExpectationCodes.valueEqualMismatch,
      value: value,
      defaultMessage: 'Must be equal to $expected',
      data: {'expected': expected, ...data},
      overrideMessage: message,
    );
  }

  Expectation deepEqualMismatch(
    dynamic value,
    dynamic expected, {
    String? message,
    Map<String, Object?> data = const {},
  }) {
    return _create(
      code: ExpectationCodes.valueDeepEqualMismatch,
      value: value,
      defaultMessage: 'Must be deeply equal to $expected',
      data: {'expected': expected, ...data},
      overrideMessage: message,
    );
  }

  Expectation membershipMismatch(
    dynamic value,
    dynamic validSet, {
    String? message,
    Map<String, Object?> data = const {},
  }) {
    return _create(
      code: ExpectationCodes.valueMembershipMismatch,
      value: value,
      defaultMessage: 'Must be one of $validSet',
      data: {'valid_set': validSet, ...data},
      overrideMessage: message,
    );
  }

  // --- Date Domain ---

  Expectation dateOutOfRange(
    dynamic value,
    dynamic min,
    dynamic max, {
    String? message,
    Map<String, Object?> data = const {},
  }) {
    return _create(
      code: ExpectationCodes.valueDateOutOfRange,
      value: value,
      defaultMessage: 'Date must be between $min and $max',
      data: {'min': min, 'max': max, ...data},
      overrideMessage: message,
    );
  }

  Expectation dateMismatch(
    dynamic value,
    dynamic comparison,
    String type, {
    String? message,
    Map<String, Object?> data = const {},
  }) {
    return _create(
      code: ExpectationCodes.valueDateMismatch,
      value: value,
      defaultMessage: 'Date must be $type $comparison',
      data: {'comparison': comparison, 'type': type, ...data},
      overrideMessage: message,
    );
  }

  Expectation dateNotPast(
    dynamic value, {
    String? message,
    Map<String, Object?> data = const {},
  }) {
    return _create(
      code: ExpectationCodes.valueDateNotPast,
      value: value,
      defaultMessage: 'Date must be in the past',
      data: {'value': value, ...data},
      overrideMessage: message,
    );
  }

  Expectation dateNotFuture(
    dynamic value, {
    String? message,
    Map<String, Object?> data = const {},
  }) {
    return _create(
      code: ExpectationCodes.valueDateNotFuture,
      value: value,
      defaultMessage: 'Date must be in the future',
      data: {'value': value, ...data},
      overrideMessage: message,
    );
  }

  // --- Format Domain ---

  Expectation formatInvalid(
    dynamic value,
    String format, {
    String? message,
    Map<String, Object?> data = const {},
  }) {
    return _create(
      code: ExpectationCodes.valueFormatInvalid,
      value: value,
      defaultMessage: 'Invalid format: expected $format',
      data: {'format': format, ...data},
      overrideMessage: message,
    );
  }

  Expectation dateInvalid(
    dynamic value, {
    String? message,
    Map<String, Object?> data = const {},
  }) {
    return _create(
      code: ExpectationCodes.valueDateInvalid,
      value: value,
      defaultMessage: 'Invalid date',
      data: {'value': value, ...data},
      overrideMessage: message,
    );
  }

  Expectation isEmail(
    dynamic value, {
    String? message,
    Map<String, Object?> data = const {},
  }) {
    return formatInvalid(value, 'email',
        message: message ?? 'Must be a valid email address', data: data);
  }

  Expectation isUrl(
    dynamic value, {
    String? message,
    Map<String, Object?> data = const {},
  }) {
    return formatInvalid(value, 'url', message: message ?? 'Must be a valid URL', data: data);
  }

  Expectation isUuid(
    dynamic value, {
    String? message,
    Map<String, Object?> data = const {},
  }) {
    return formatInvalid(value, 'uuid', message: message ?? 'Must be a valid UUID', data: data);
  }

  // --- Structure Domain ---

  Expectation structureMapFieldFailed(
    dynamic value,
    String key, {
    String? message,
    Map<String, Object?> data = const {},
  }) {
    return _create(
      code: ExpectationCodes.structureMapFieldFailed,
      value: value,
      defaultMessage: 'Validation failed for field "$key"',
      data: {'key': key, ...data},
      overrideMessage: message,
    );
  }

  Expectation structureUnknownKey(
    dynamic value,
    String key, {
    String? message,
    Map<String, Object?> data = const {},
  }) {
    return _create(
      code: ExpectationCodes.structureUnknownKey,
      value: value,
      defaultMessage: 'Unknown key "$key" found',
      data: {'key': key, ...data},
      overrideMessage: message,
    );
  }

  Expectation structureListItemFailed(
    dynamic value,
    int index, {
    String? message,
    Map<String, Object?> data = const {},
  }) {
    return _create(
      code: ExpectationCodes.structureListItemFailed,
      value: value,
      defaultMessage: 'Validation failed at index $index',
      data: {'index': index, ...data},
      overrideMessage: message,
    );
  }

  // --- Logic / General Domain ---

  Expectation notExpected(
    dynamic value, {
    String? message,
    Map<String, Object?> data = const {},
  }) {
    return _create(
      code: ExpectationCodes.logicNotExpected,
      value: value,
      defaultMessage: 'Value matches strict condition (expected not to match)',
      data: {'value': value, ...data},
      overrideMessage: message,
    );
  }

  Expectation typeMismatch(
    dynamic value,
    String expectedType, {
    String? message,
    Map<String, Object?> data = const {},
  }) {
    return _create(
      code: ExpectationCodes.typeMismatch,
      value: value,
      defaultMessage: 'Expected type $expectedType but found ${value.runtimeType}',
      data: {'expectedType': expectedType, 'foundType': '${value.runtimeType}', ...data},
      overrideMessage: message,
    );
  }

  Expectation rangeOutOfBounds(
    dynamic value,
    num min,
    num max, {
    String? message,
    Map<String, Object?> data = const {},
  }) {
    return _create(
      code: ExpectationCodes.valueRangeOutOfBounds,
      value: value,
      defaultMessage: 'Value must be between $min and $max',
      data: {'min': min, 'max': max, ...data},
      overrideMessage: message,
    );
  }

  Expectation predicateFailed(
    dynamic value, {
    String? message,
    Map<String, Object?> data = const {},
  }) {
    return _create(
      code: ExpectationCodes.logicPredicateFailed,
      value: value,
      defaultMessage: 'Condition failed',
      data: {'value': value, ...data},
      overrideMessage: message,
    );
  }
}
