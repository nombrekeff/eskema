/// Validator library
///
/// This library provides a set of classes for validating data. For built in va
library validator;

import 'dart:async';
import 'package:eskema/expectation.dart';
import 'package:eskema/validators.dart';

import 'result.dart';

/// Type representing a validator function (may be sync or async).
typedef ValidatorFunction<T extends Result> = FutureOr<T> Function(dynamic value);

/// Thrown when a synchronous validate() call encounters an async validator.
class AsyncValidatorException implements Exception {
  final String message =
      'Cannot call validate() on a validator chain that contains async operations. Use validateAsync() instead.';
  @override
  String toString() => message;
}

/// Thrown when a validation fails.
class ValidatorFailedException implements Exception {
  String get message => result.toString();
  Result result;
  ValidatorFailedException(this.result);
}

/// Inmutable class from which all validators inherit.
///
/// You can use it to create custom validators,
/// but consider using other ways of creating custom validators (_see [Custom Validators](https://github.com/nombrekeff/eskema/tree/main#custom-validators)_)
///
/// Or consider using one of the [validators] for built in validation.
abstract class IValidator {
  const IValidator({
    bool nullable = false,
    bool optional = false,
  })  : isNullable = nullable,
        isOptional = optional;

  /// Marks the validator as nullable. This means that if the value being checked is null,
  /// the validation is considered valid.
  final bool isNullable;

  /// Marks the validator as optional. This means that if the value being checked is null or missing,
  /// the validation is considered valid.
  final bool isOptional;

  /// Core validation function (may return a Result or Future&lt;Result&gt;).
  /// Don't call directly, use [validate] or [validateAsync].
  FutureOr<Result> validator(dynamic value);

  /// Main validation method. Use this method if you want to validate
  /// that a dynamic value is valid, and get an error message if not.
  ///
  /// You can also call [isValid] if you just want to check if the value is valid.
  ///
  /// If you want to to throw an error use [validateOrThrow]
  ///
  /// [exists] If set to true, the value is consider to "exist",
  /// this is most useful for optional fields in maps.
  ///
  /// Will [throw] an error if used with async validators
  Result validate(dynamic value, {bool exists = true}) {
    if ((value == null && isNullable && exists) || (value == null && isOptional && !exists)) {
      return Result.valid(value);
    }

    final result = validator(value);

    if (result is Future<Result>) {
      throw AsyncValidatorException();
    }

    return result;
  }

  /// Always returns a Future, allowing async + sync validators to compose.
  Future<Result> validateAsync(dynamic value, {bool exists = true}) async {
    if ((value == null && isNullable && exists) || (!exists && isOptional)) {
      return Result.valid(value);
    }

    final result = await validator(value);
    return result;
  }

  /// Works the same as [validate], validates that a given value is valid,
  /// but throws instead if it's not.
  Result validateOrThrow(dynamic value) {
    final result = validate(value);
    if (result.isNotValid) throw ValidatorFailedException(result);
    return result;
  }

  /// Checks if the given value is valid.
  bool isValid(dynamic value) => validate(value).isValid;

  /// Checks if the given value is valid asynchronously.
  FutureOr<bool> isValidAsync(dynamic value) async => (await validateAsync(value)).isValid;

  /// Checks if the given value is not valid.
  bool isNotValid(dynamic value) => !validate(value).isValid;

  /// Checks if the given value is not valid asynchronously.
  FutureOr<bool> isNotValidAsync(dynamic value) async => !(await isValidAsync(value));

  /// Creates a copy of the validator with the given parameters.
  IValidator copyWith({
    bool? nullable,
    bool? optional,
  });

  /// Creates a nullable copy of the validator.
  IValidator nullable<T>() {
    return copyWith(nullable: true);
  }

  /// Creates a optional copy of the validator.
  IValidator optional<T>() {
    return copyWith(optional: true);
  }
}

/// A special type of validator that can operate on a parent map context.
/// Used for conditional validation within an `eskema` map validator.
abstract class IWhenValidator extends IValidator {
  IWhenValidator({super.nullable, super.optional});

  /// Validates the [value] with access to the parent [map]. May be async.
  FutureOr<Result> validateWithParent(dynamic value, Map<String, dynamic> map,
      {bool exists = true});
}

/// An implementation of [IValidator], which accepts a validator function,
/// which is used by the EskValidator to validate some data.
///
/// Take a look at [validators] for examples.
class Validator<T extends Result> extends IValidator {
  static final Validator valid = Validator((v) => Result.valid(v));
  final ValidatorFunction<T> _validator;
  Validator(
    this._validator, {
    super.nullable,
    super.optional,
  });

  @override
  FutureOr<T> validator(dynamic value) => _validator.call(value);

  @override
  IValidator copyWith({
    bool? nullable,
    bool? optional,
  }) {
    return Validator(
      _validator,
      nullable: nullable ?? isNullable,
      optional: optional ?? isOptional,
    );
  }

  @override
  String toString() => 'Validator';
}

/// A conditional validator that applies either the [then] or [otherwise]
/// branch based on the result of the [condition] validator.
/// 
/// **Example**
/// ```dart
/// final user = {
///   'id': '123',
///   'email': 'test@example.com',
///   'age': 25,
/// };
///
/// final validator = WhenValidator(
///   condition: Field('age').isAdult(),
///   then: Field('email').isEmail(),
///   otherwise: Field('email').isNotEmpty(),
/// );
///
/// final result = validator.validate(user);
/// ```
class WhenValidator extends IWhenValidator {
  final IValidator condition;
  final IValidator then;
  final IValidator otherwise;

  WhenValidator(this.condition, this.then, this.otherwise, {super.nullable, super.optional});

  @override
  Result validate(dynamic value, {bool exists = true}) {
    // This validator must be used within an `eskema` map validator
    // to have access to the parent map.
    return Result.invalid(
      value,
      expectations: [
        Expectation(
          message: '`when` validator can only be used inside an `eskema` map validator',
          value: value,
        )
      ],
    );
  }

  @override
  FutureOr<Result> validateWithParent(dynamic value, Map<String, dynamic> map,
      {bool exists = true}) {
    final cond = condition.validator(map);
    if (cond is Future<Result>) {
      return cond.then((cr) => _evalBranch(cr, value));
    }
    return _evalBranch(cond, value);
  }

  FutureOr<Result> _evalBranch(Result conditionResult, dynamic value) {
    if (conditionResult.isValid) {
      return then.validator(value);
    } else {
      return otherwise.validator(value);
    }
  }

  @override
  IValidator copyWith({
    bool? nullable,
    bool? optional,
    IValidator? condition,
    IValidator? then,
    IValidator? otherwise,
  }) {
    return WhenValidator(
      condition ?? this.condition,
      then ?? this.then,
      otherwise ?? this.otherwise,
      nullable: nullable ?? isNullable,
      optional: optional ?? isOptional,
    );
  }

  @override
  FutureOr<Result> validator(value) {
    // Not needed
    throw UnimplementedError();
  }
}

/// A [Validator] sub-class, which adds an identifier,
/// which can be used to identify the validator,
/// for example [MapValidator] uses it to validate its fields.
class IdValidator<T extends Result> extends Validator<T> {
  /// Identifier for this particular validator.
  final String id;

  IdValidator({
    required ValidatorFunction<T> validator,
    this.id = '',
    super.nullable,
    super.optional,
  }) : super(validator);
}

/// An implementation of [IdValidator], which acepts a list of validators.
///
/// See [example](https://github.com/nombrekeff/eskema/tree/main/example/class_validation.dart)
class Field extends IdValidator {
  Field({
    required this.validators,
    super.id,
    super.nullable,
    super.optional,
  }) : super(validator: Result.valid);

  /// List of validators to apply to the field.
  ///
  /// Each validator will be applied in order, and the first one to fail will
  /// determine the error result, otherwise it will be considered valid.
  final List<IValidator> validators;

  @override
  FutureOr<Result> validator(dynamic value) {
    final base = super.validator(value);
    if (base is Future<Result>) {
      return base.then((r) => _continueChain(r, value));
    }
    return _continueChain(base, value);
  }

  Result _continueChain(Result base, dynamic value) {
    if (base.isNotValid) return base;
    for (final v in validators) {
      // Use sync path if possible; users can call validateAsync on the outer validator if needed.
      final r = v.validate(value);
      if (r.isNotValid) return r;
    }
    return Result.valid(value);
  }

  @override
  IValidator copyWith({bool? nullable, bool? optional}) {
    return Field(
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
abstract class MapValidator<T extends Map> extends IdValidator {
  MapValidator({super.id = '', super.nullable}) : super(validator: isMap().validate);

  /// List of [IdValidator]s used to validate a dynamic `Map`.
  /// Each field represents a value in the map, `id` is used to identify the key from the map.
  List<IdValidator> get fields;

  @override
  FutureOr<Result> validator(dynamic value) {
    final base = super.validator(value);
    if (base is Future<Result>) {
      return base.then((r) => _mapContinue(r, value));
    }
    return _mapContinue(base, value);
  }

  Result _mapContinue(Result base, dynamic value) {
    if (base.isNotValid) return base;
    for (final field in fields) {
      final mapValue = value[field.id];
      if (mapValue == null && field.isNullable) continue;
      final result = field.validate(mapValue);
      if (result.isValid) continue;
      final error = field is MapValidator
          ? '${field.id}.${result.description}'
          : '${field.id} to be ${result.description}';
      return Result(
        isValid: result.isValid,
        expectations: [Expectation(message: error, value: mapValue)],
        value: mapValue,
      );
    }
    return Result.valid(value);
  }

  @override
  IValidator copyWith({bool? nullable, bool? optional}) {
    throw Exception(
        'copyWith not implemented for $runtimeType, as it defines properties that cannot be copied automaticaly.\n'
        'Please create a new instance manually. Or override the "copyWith" method.');
  }
}
