/// Core validator abstractions and base implementations.
library validator.base;

import 'dart:async';
import 'package:eskema/result.dart';
import 'package:eskema/validator/exception.dart';

/// Type representing a validator function (may be sync or async).
typedef ValidatorFunction<T extends Result> = FutureOr<T> Function(
    dynamic value);

/// Immutable base class from which all validators inherit.
abstract class IValidator {
  /// Executes the [IValidator] operation.
  const IValidator({
    bool nullable = false,
    bool optional = false,
    this.name = 'custom',
    this.args = const [],
  })  : isNullable = nullable,
        isOptional = optional;

  /// The [isNullable] property.
  final bool isNullable;

  /// The [isOptional] property.
  final bool isOptional;

  /// The [name] property.
  final String name;

  /// The [List] property.
  final List<dynamic> args;

  /// Executes the [FutureOr] operation.
  FutureOr<Result> validator(dynamic value);

  /// Executes the [validate] operation.
  Result validate(dynamic value, {bool exists = true}) {
    if ((value == null && isNullable && exists) ||
        (value == null && isOptional && !exists)) {
      return Result.valid(value);
    }

    final result = validator(value);

    if (result is Future<Result>) {
      throw AsyncValidatorException();
    }

    return result;
  }

  /// Executes the [Future] operation.
  Future<Result> validateAsync(dynamic value, {bool exists = true}) async {
    if ((value == null && isNullable && exists) || (!exists && isOptional)) {
      return Result.valid(value);
    }

    final result = await validator(value);

    return result;
  }

  /// Executes the [validateOrThrow] operation.
  Result validateOrThrow(dynamic value) {
    final result = validate(value);

    if (result.isNotValid) throw ValidatorFailedException(result);

    return result;
  }

  /// Executes the [isValid] operation.
  bool isValid(dynamic value) => validate(value).isValid;

  /// Executes the [FutureOr] operation.
  FutureOr<bool> isValidAsync(dynamic value) async =>
      (await validateAsync(value)).isValid;

  /// Executes the [isNotValid] operation.
  bool isNotValid(dynamic value) => !validate(value).isValid;

  /// Executes the [FutureOr] operation.
  FutureOr<bool> isNotValidAsync(dynamic value) async =>
      !(await isValidAsync(value));

  /// Executes the [copyWith] operation.
  IValidator copyWith(
      {bool? nullable, bool? optional, String? name, List? args});

  /// Executes the [nullable] operation.
  IValidator nullable<T>() => copyWith(nullable: true);

  /// Executes the [optional] operation.
  IValidator optional<T>() => copyWith(optional: true);
}

/// A special type of validator that can operate on a parent map context.
abstract class IWhenValidator extends IValidator {
  /// Executes the [IWhenValidator] operation.
  IWhenValidator({
    super.nullable,
    super.optional,
    super.name,
    super.args,
  });

  /// Executes the [FutureOr] operation.
  FutureOr<Result> validateWithParent(
    dynamic value,
    Map<String, dynamic> map, {
    bool exists = true,
  });
}

/// Generic implementation wrapper for a validator.
class Validator<T extends Result> extends IValidator {
  /// Executes the [valid] operation.
  static final Validator valid = Validator((v) => Result.valid(v));
  final ValidatorFunction<T> _validator;

  /// Executes the [Validator] operation.
  Validator(
    this._validator, {
    super.nullable,
    super.optional,
    super.name,
    super.args,
  });

  @override
  FutureOr<T> validator(dynamic value) => _validator.call(value);

  @override
  IValidator copyWith({
    bool? nullable,
    bool? optional,
    String? name,
    List<dynamic>? args,
  }) =>
      Validator(
        _validator,
        nullable: nullable ?? isNullable,
        optional: optional ?? isOptional,
        name: name ?? this.name,
        args: args ?? this.args,
      );

  @override
  String toString() => 'Validator(name: $name, args: $args)';
}

/// Base class that adds an identifier to a validator (used by map/field validators).
class IdValidator<T extends Result> extends Validator<T> {
  /// The [id] property.
  final String? id;

  /// Executes the [IdValidator] operation.
  IdValidator({
    required ValidatorFunction<T> validator,
    this.id = '',
    bool? nullable,
    bool? optional,
    String? name,
    List<dynamic>? args,
  }) : super(
          validator,
          nullable: nullable ?? false,
          optional: optional ?? false,
          name: name ?? 'custom',
          args: args ?? const [],
        );
}
