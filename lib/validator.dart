import 'package:eskema/error.dart';
import 'package:eskema/util.dart';
import 'package:eskema/validators.dart';

import 'result.dart';

/// Type representing a validator function.
typedef EskValidatorFn<T extends EskResult> = T Function(dynamic value);

/// Inmutable class from which all validators inherit.
///
/// You can use it to create custom validators,
/// but consider using other ways of creating custom validators (_see [Custom Validators](https://github.com/nombrekeff/eskema/tree/main#custom-validators)_)
///
/// Or consider using one of the [validators] for built in validation.
abstract class IEskValidator {
  const IEskValidator({bool nullable = false, bool optional = false})
      : isNullable = nullable,
        isOptional = optional;

  /// Marks the validator as nullable. This means that if the value being checked is null,
  /// the validation is considered valid.
  final bool isNullable;

  /// Marks the validator as optional. This means that if the value being checked is null or missing,
  /// the validation is considered valid.
  final bool isOptional;

  /// Validates the given [value] and returns the result.
  ///
  /// Don't call directly, call [validate] instead.
  EskResult validator(dynamic value);

  /// Main validation method. Use this method if you want to validate
  /// that a dynamic value is valid, and get an error message if not.
  ///
  /// You can also call [isValid] if you just want to check if the value is valid.
  ///
  /// If you want to to throw an error use [validateOrThrow]
  ///
  /// [exists] If set to true, the value is consider to "exist",
  /// this is most useful for optional fields in maps.
  EskResult validate(dynamic value, {bool exists = true}) {
    if ((value == null && isNullable && exists) || (!exists && isOptional)) {
      return EskResult.valid(value);
    }

    return validator(value);
  }

  /// Works the same as [validate], validates that a given value is valid,
  /// but throws instead if it's not.
  EskResult validateOrThrow(dynamic value) {
    final result = validate(value);
    if (result.isNotValid) throw ValidatorFailedException(result);
    return result;
  }

  /// Checks if the given value is valid.
  bool isValid(dynamic value) => validate(value).isValid;

  /// Checks if the given value is not valid.
  bool isNotValid(dynamic value) => !validate(value).isValid;

  /// Creates a copy of the validator with the given parameters.
  IEskValidator copyWith({bool? nullable, bool? optional});

  /// Creates a nullable copy of the validator.
  IEskValidator nullable<T>() {
    return copyWith(nullable: true);
  }

  /// Creates a optional copy of the validator.
  IEskValidator optional<T>() {
    return copyWith(optional: true);
  }
}

/// An implementation of [IEskValidator], which accepts a validator function,
/// which is used by the EskValidator to validate some data.
///
/// Take a look at [validators] for examples.
class EskValidator<T extends EskResult> extends IEskValidator {
  final EskValidatorFn<T> _validator;
  EskValidator(this._validator, {super.nullable, super.optional});

  @override
  T validator(dynamic value) {
    return _validator.call(value);
  }

  @override
  IEskValidator copyWith({bool? nullable, bool? optional}) {
    return EskValidator(
      _validator,
      nullable: nullable ?? isNullable,
      optional: optional ?? isOptional,
    );
  }

  @override
  String toString() => 'Validator';
}

/// A [EskValidator] sub-class, which adds an identifier,
/// which can be used to identify the validator,
/// for example [EskMap] uses it to validate its fields.
class IEskIdValidator extends EskValidator {
  /// Identifier for this particular validator.
  final String id;

  IEskIdValidator({
    required EskValidatorFn validator,
    this.id = '',
    super.nullable,
    super.optional,
  }) : super(validator);
}

/// An implementation of [IEskIdValidator], which acepts a list of validators.
///
/// See [example](https://github.com/nombrekeff/eskema/tree/main/example/class_validation.dart)
class EskField extends IEskIdValidator {
  EskField({
    required this.validators,
    super.id,
    super.nullable,
    super.optional,
  }) : super(validator: EskResult.valid);

  /// List of validators to apply to the field.
  ///
  /// Each validator will be applied in order, and the first one to fail will
  /// determine the error result, otherwise it will be considered valid.
  final List<IEskValidator> validators;

  @override
  EskResult validator(dynamic value) {
    final superRes = super.validator(value);
    if (superRes.isNotValid) return superRes;

    for (var validator in validators) {
      final result = validator.validate(value);
      if (result.isNotValid) {
        return result;
      }
    }

    return EskResult.valid(value);
  }

  @override
  IEskValidator copyWith({bool? nullable, bool? optional}) {
    return EskField(
      validators: validators,
      id: id,
      nullable: nullable ?? isNullable,
      optional: optional ?? isOptional,
    );
  }
}

/// Abstract class from which to create class based validator schemes.
/// EskMap is a utility class designed to facilitate the validation and transformation
/// of map-like data structures in Dart. It provides a flexible way to define validation
/// rules and apply them to input data, ensuring that the data conforms to expected
/// formats or constraints.
///
/// This is particularly useful when working with dynamic data sources such as JSON,
/// form inputs, or external APIs, where the structure and types of the data may not
/// be guaranteed.
///
/// Example:
/// ```dart
/// class UserValidator extends EskMap {
///   final name = EskField(
///     id: 'name',
///     validators: [ $isString ],
///   );
///   final age = EskField(
///     id: 'age',
///     validators: [ $isInt, $isGt(0) ],
///   );
///   @override
///   get fields => [name, age];
/// }
///
/// final userValidator = UserValidator();
///
/// final result = userValidator.validate({
///   'name': 'Alice',
///   'age': 30
/// });
///
/// if (result.isValid) {
///   print('Validation passed!');
/// } else {
///   print(result.toString());
/// }
/// ```
///
/// In this example, `EskMap` is used to define a schema where `name` is a required
/// string and `age` is an integer with a minimum value of 0. The `validate` method
/// checks the input data against these rules and returns the result.
abstract class EskMap<T extends Map> extends IEskIdValidator {
  EskMap({super.id = '', super.nullable}) : super(validator: isMap().validate);

  /// List of [IEskIdValidator]s used to validate a dynamic `Map`.
  /// Each field represents a value in the map, `id` is used to identify the key from the map.
  List<IEskIdValidator> get fields;

  @override
  EskResult validator(dynamic value) {
    final superRes = super.validator(value);
    if (superRes.isNotValid) return superRes;

    for (final field in fields) {
      final mapValue = value[field.id];
      // If the field is nullable, we can skip validation if the value is null
      if (mapValue == null && field.isNullable) continue;

      final result = field.validate(mapValue);
      if (result.isValid) continue;

      String error = '';

      if (field is EskMap) {
        error += '${field.id}.${result.description}';
      } else {
        error += '${field.id} to be ${result.description}';
      }

      return EskResult(
          isValid: result.isValid,
          errors: [EskError(message: error, value: mapValue)],
          value: mapValue);
    }

    return EskResult.valid(value);
  }

  @override
  IEskValidator copyWith({bool? nullable, bool? optional}) {
    throw Exception(
        'copyWith not implemented for $runtimeType, as it defines properties that cannot be copied automaticaly.\n'
        'Please create a new instance manually. Or override the "copyWith" method.');
  }
}
