import 'package:collection/collection.dart';
import 'package:eskema/util.dart';

import 'result.dart';

Function _collectionEquals = const DeepCollectionEquality().equals;

typedef EskValidatorFn = IResult Function(dynamic value);

abstract class IEskValidator {
  IResult validate(dynamic value);
  bool isValid(dynamic value) => validate(value).isValid;
  bool isNotValid(dynamic value) => !validate(value).isValid;

  bool _nullable;

  IEskValidator({bool nullable = false}) : _nullable = nullable;

  bool get isNullable => _nullable;

  IEskValidator copyWith({bool? nullable});

  IEskValidator orNullable<T>() {
    return copyWith(nullable: true);
  }
}

abstract class EskIdValidator extends IEskValidator {
  final String id;

  EskIdValidator({required this.id, super.nullable});
}

class EskValidator extends IEskValidator {
  final EskValidatorFn _validator;
  EskValidator(this._validator, {super.nullable});

  @override
  IResult validate(dynamic value) {
    final result = _validator.call(value);
    if (value == null && isNullable) return Result.valid;
    return result;
  }

  @override
  IEskValidator copyWith({bool? nullable}) {
    return EskValidator(_validator, nullable: nullable ?? isNullable);
  }

  @override
  String toString() => 'Validator';
}

class EskField extends EskIdValidator {
  final List<EskValidator> validators;

  EskField({required this.validators, required super.id, super.nullable});

  @override
  IResult validate(dynamic value) {
    if ((value == null && isNullable)) {
      return Result.valid;
    }

    if ((value == null && !isNullable)) {
      return Result.invalid('not null', value);
    }

    for (var validator in validators) {
      final result = validator.validate(value);
      if (result.isNotValid) {
        return result;
      }
    }
    return Result.valid;
  }

  @override
  IEskValidator copyWith({bool? nullable}) {
    return EskField(
      validators: List<EskValidator>.from(
          validators.map((v) => v.copyWith(nullable: nullable))),
      id: id,
      nullable: nullable ?? isNullable,
    );
  }
}

abstract class EskMap<T extends Map> extends EskIdValidator {
  List<IEskValidator> get fields;
  EskMap({super.id = 'class_validator', super.nullable});

  @override
  IResult validate(dynamic map) {
    if (map == null && isNullable) {
      return Result.valid..value = map;
    }

    if ((map == null && !isNullable) || map is! Map) {
      return Result.invalid('Expected a ${T.runtimeType}', map);
    }

    if (map.isEmpty && !isNullable) {
      return Result.invalid('No data provided for validation', map);
    }

    for (final field in fields) {
      if (field is EskIdValidator) {
        final mapValue = map[field.id];
        // If the field is nullable, we can skip validation if the value is null
        if (mapValue == null && field.isNullable) continue;

        print(
          "Validating field: ${field.id}, value: $mapValue, with field: ${field}",
        );

        final result = field.validate(mapValue);
        if (result.isValid) continue;

        String expected = '';

        if (field is EskMap) {
          expected += '${field.id}.${result.expected}';
        } else {
          expected += '${field.id} to be ${result.expected}';
        }

        return Result(
          isValid: result.isValid,
          expected: expected,
          value: mapValue,
        );
      }
    }

    return Result.valid..value = map;
  }

  @override
  IEskValidator copyWith({bool? nullable}) {
    throw Exception(
        'copyWith not implemented for ${runtimeType}, as it defines properties that cannot be copied automaticaly.\n' +
            'Please create a new instance manually. Or override the "copyWith" method.');
  }
}

/// Returns a [EskValidator] that checks if the given value null
EskValidator isTypeNull() {
  return EskValidator((value) => Result(
        isValid: value == null,
        expected: 'null',
        value: value,
      ));
}

/// Returns a [EskValidator] that checks if the given value is the correct type
EskValidator isType<T>() {
  return EskValidator((value) => Result(
        isValid: value is T,
        expected: T.toString(),
        value: value,
      ));
}

/// Returns a [EskValidator] that checks if the given value is the correct type
EskValidator isTypeOrNull<T>() {
  return EskValidator((value) => Result(
        isValid: value is T || value == null,
        expected: '${T.toString()} or null',
        value: value,
      ));
}

/// Checks whether the given value is less than [max]
EskValidator isLt(num max) {
  return all([
    isType<num>(),
    EskValidator((value) => Result(
          isValid: value < max,
          expected: 'less than $max',
          value: value,
        )),
  ]);
}

/// Checks whether the given value is less than or equal [max]
EskValidator isLte(num max) {
  return all([
    isType<num>(),
    EskValidator((value) => Result(
          isValid: value <= max,
          expected: 'less than or equal to $max',
          value: value,
        )),
  ]);
}

/// Checks whether the given value is greater than [max]
EskValidator isGt(num min) {
  return all([
    isType<num>(),
    EskValidator((value) => Result(
          isValid: value > min,
          expected: 'greater than $min',
          value: value,
        )),
  ]);
}

/// Checks whether the given value is greater or equal to [max]
EskValidator isGte(num min) {
  return all([
    isType<num>(),
    EskValidator((value) => Result(
          isValid: value is num && value >= min,
          expected: 'greater than or equal to $min',
          value: value,
        )),
  ]);
}

/// Checks whether the given value is equal to the [expected] value of type [T]
///
/// Even though this function accepts any Type, note that it will not work with Collections. For that usecase prefer using [isDeepEqual] instead.
EskValidator isEq<T>(T expected) {
  return all([
    isType<T>(),
    EskValidator((value) => Result(
          isValid: value == expected,
          // json.encode is here to format the value correctly, so we know if for example 10 is a number (10) or a string ("10").
          expected: 'equal to ${pretifyValue(expected)}',
          value: value,
        )),
  ]);
}

/// Checks whether the given value is equal to the [expected] value of type [T]
EskValidator isDeepEq<T>(T expected) {
  return all([
    isType<T>(),
    EskValidator((value) => Result(
          isValid: (_collectionEquals(value, expected)),
          expected: 'equal to ${pretifyValue(expected)}',
          value: value,
        )),
  ]);
}

/// Checks whether the given value is a valid DateTime formattedString
EskValidator isDate() {
  return EskValidator((value) => Result(
        isValid: DateTime.tryParse(value) != null,
        expected: 'a valid date',
        value: value,
      ));
}

/// Validates that the list's length is the same as the provided [size]
///
/// This validator also validates that the value is a list first
/// So there's no need to add the [isTypeList] validator when using this validator
EskValidator listIsOfLength(int size) {
  return EskValidator((value) {
    final isListResult = isType<List>().validate(value);
    if (isListResult.isNotValid) return isListResult;

    return Result(
      isValid: (value as List).length == size,
      expected: 'List of size $size',
      value: value,
    );
  });
}

/// Validates that the String's length is the same as the provided [size]
///
/// This validator also validates that the value is a String first
/// So there's no need to add the [isTypeString] validator when using this validator
EskValidator stringIsOfLength(int size) {
  return EskValidator((value) {
    final isStringResult = isType<String>().validate(value);
    if (isStringResult.isNotValid) return isStringResult;

    return Result(
      isValid: (value as String).length == size,
      expected: 'String of length $size',
      value: value,
    );
  });
}

/// Validates that the String contains [substring]
///
/// This validator also validates that the value is a String first
/// So there's no need to add the [isTypeString] validator when using this validator
EskValidator stringContains(String substring) {
  return EskValidator((value) {
    final isString = isType<String>().validate(value);
    if (isString.isNotValid) return isString;

    return Result(
      isValid: (value as String).contains(substring),
      expected: 'String to contain "$substring"',
      value: value,
    );
  });
}

/// Validates that the List contains [item]
///
/// This validator also validates that the value is a List first
/// So there's no need to add the [isType<List>] validator when using this validator
EskValidator listContains<T>(T item) {
  return EskValidator((value) {
    final isListResult = isType<List>().validate(value);
    if (isListResult.isNotValid) return isListResult;

    return Result(
      isValid: (value as List).contains(item),
      expected: 'List to contain ${pretifyValue(item)}',
      value: value,
    );
  });
}

/// Validates that the String does not contain [substring]
///
/// This validator also validates that the value is a String first
/// So there's no need to add the [isTypeString] validator when using this validator
EskValidator stringNotContains(String substring) {
  return EskValidator((value) {
    final isListResult = isType<String>().validate(value);
    if (isListResult.isNotValid) return isListResult;

    return Result(
      isValid: !(value as String).contains(substring),
      expected: 'String to not contain "$substring"',
      value: value,
    );
  });
}

/// Validates that the String matches the provided pattern
///
/// This validator also validates that the value is a String first
/// So there's no need to add the [isTypeString] validator when using this validator
EskValidator stringMatchesPattern(Pattern pattern, {String? expectedMessage}) {
  return EskValidator((value) {
    final isListResult = isType<String>().validate(value);
    if (isListResult.isNotValid) return isListResult;

    return Result(
      isValid: pattern.allMatches(value).isNotEmpty,
      expected: expectedMessage ?? 'String to match "$pattern"',
      value: value,
    );
  });
}

/// Passes the test if any of the [EskValidator]s are valid, and fails if any are invalid
EskValidator any(List<IEskValidator> validators) {
  return EskValidator((value) {
    final results = validators.map((v) => v.validate(value)).toList();

    return Result(
      isValid: results.any((r) => r.isValid),
      expected: results.map((r) => r.expected).join(' or '),
      value: value,
    );
  });
}

/// Passes the test if all of the [EskValidator]s are valid, and fails if any of them are invalid
///
/// In the case that a [EskValidator] fails, it's [Result] will be returned
EskValidator all(List<IEskValidator> validators) {
  return EskValidator((value) {
    for (final validator in validators) {
      final result = validator.validate(value);
      if (result.isNotValid) return result;
    }

    return Result.valid..value = value;
  });
}

/// Passes the test if the contition is !valid
EskValidator not(EskValidator validator) {
  return EskValidator((value) {
    final result = validator.validate(value);

    return Result(
      isValid: !result.isValid,
      expected: 'not ${result.expected}',
      value: value,
    );
  });
}

/// Allows the passed in validator to be nullable
EskValidator nullable(EskValidator validator) {
  return EskValidator((value) {
    if (value == null) return Result.valid;
    return validator.validate(value);
  });
}

/// Checks whether the given value is one of the [options] values of type [T]
///
EskValidator isOneOf<T>(List<T> options) {
  return all([
    isType<T>(),
    EskValidator((value) => Result(
          isValid: options.contains(value),
          expected: 'one of: ${pretifyValue(options)}',
          value: value,
        )),
  ]);
}

/// Returns a [EskValidator] that throws a [ValidatorFailedException] instead of returning a result
EskValidator throwInstead(EskValidator validator) {
  return EskValidator((value) {
    final result = validator.validate(value);
    if (result.isNotValid) throw ValidatorFailedException(result);

    return Result.valid;
  });
}

/// Returns a Validator that checks a value against a Map eskema that declares a validator for each key.
///
/// Example:
/// ```dart
/// final mapField = all([
///   eskema({
///     'name': all([isType<String>()]),
///     'vat': or(
///       isTypeNull(),
///       isGte(0),
///     ),
///     'age': all([
///       isType<int>(),
///       isGte(0),
///     ]),
///   }),
/// ]);
/// ```
EskValidator eskema(Map<String, IEskValidator> eskema) {
  return EskValidator((value) {
    if (value is! Map) return Result.invalid('Map', value);

    for (final key in eskema.keys) {
      final field = eskema[key] as IEskValidator;
      final result = field.validate(value[key]);

      if (result.isNotValid) {
        return Result.invalid('$key -> ${result.expected}', result.value);
      }
    }

    return Result.valid;
  });
}

/// Returns a Validator that checks a value against the eskema provided,
/// the eskema defines a validator for each item in the list
///
/// Example:
/// ```dart
/// final isValidList = eskemaList([isType<String>(), isType<int>()]);
/// isValidList(["1", 2]).isValid;   // true
/// isValidList(["1", "2"]).isValid; // false
/// isValidList([1, "2"]).isValid;   // false
/// ```
///
/// `isValidList` will only be valid:
/// * if the array is of length 2
/// * the first item is a string
/// * and the second item is an int
///
/// This validator also checks that the value is a list
EskValidator eskemaList(List<EskValidator> eskema) {
  return EskValidator((value) {
    // Before checking the eskema, we validate that it's a list and matches the eskema length
    final result =
        all([isType<List>(), listIsOfLength(eskema.length)]).validate(value);
    if (result.isNotValid) return result;

    for (int index = 0; index < value.length; index++) {
      final item = value[index];
      final effectiveValidator = eskema[index];
      final result = effectiveValidator.validate(item);

      if (result.isNotValid) {
        return Result.invalid('[$index] -> ${result.expected}', value);
      }
    }

    return Result.valid;
  });
}

/// Returns a Validator that runs [itemValidator] for each item in the list
///
/// This validator also checks that the value is a list
EskValidator listEach(EskValidator itemValidator) {
  return EskValidator((value) {
    if (value is! List) return Result.invalid('List', value);

    for (int index = 0; index < value.length; index++) {
      final item = value[index];
      final result = itemValidator.validate(item);

      if (result.isNotValid) {
        return Result.invalid('[$index] -> ${result.expected}', item);
      }
    }

    return Result.valid;
  });
}
