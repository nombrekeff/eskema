/// Core validator abstractions and base implementations.
library validator.base;

import 'dart:async';
import 'package:eskema/result.dart';
import 'package:eskema/validator/exception.dart';

/// Type representing a validator function (may be sync or async).
typedef ValidatorFunction<T extends Result> = FutureOr<T> Function(dynamic value);

/// Immutable base class from which all validators inherit.
abstract class IValidator {
  const IValidator({bool nullable = false, bool optional = false})
      : isNullable = nullable,
        isOptional = optional;

  final bool isNullable;
  final bool isOptional;

  FutureOr<Result> validator(dynamic value);

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

  Future<Result> validateAsync(dynamic value, {bool exists = true}) async {
    if ((value == null && isNullable && exists) || (!exists && isOptional)) {
      return Result.valid(value);
    }
    final result = await validator(value);
    return result;
  }

  Result validateOrThrow(dynamic value) {
    final result = validate(value);
    if (result.isNotValid) throw ValidatorFailedException(result);
    return result;
  }

  bool isValid(dynamic value) => validate(value).isValid;
  FutureOr<bool> isValidAsync(dynamic value) async => (await validateAsync(value)).isValid;
  bool isNotValid(dynamic value) => !validate(value).isValid;
  FutureOr<bool> isNotValidAsync(dynamic value) async => !(await isValidAsync(value));

  IValidator copyWith({bool? nullable, bool? optional});

  IValidator nullable<T>() => copyWith(nullable: true);
  IValidator optional<T>() => copyWith(optional: true);
}

/// A special type of validator that can operate on a parent map context.
abstract class IWhenValidator extends IValidator {
  IWhenValidator({super.nullable, super.optional});
  FutureOr<Result> validateWithParent(dynamic value, Map<String, dynamic> map, {bool exists = true});
}

/// Generic implementation wrapper for a validator.
class Validator<T extends Result> extends IValidator {
  static final Validator valid = Validator((v) => Result.valid(v));
  final ValidatorFunction<T> _validator;
  Validator(this._validator, {super.nullable, super.optional});

  @override
  FutureOr<T> validator(dynamic value) => _validator.call(value);

  @override
  IValidator copyWith({bool? nullable, bool? optional}) => Validator(
        _validator,
        nullable: nullable ?? isNullable,
        optional: optional ?? isOptional,
      );

  @override
  String toString() => 'Validator';
}

/// Base class that adds an identifier to a validator (used by map/field validators).
class IdValidator<T extends Result> extends Validator<T> {
  final String? id;
  IdValidator({required ValidatorFunction<T> validator, this.id = '', super.nullable, super.optional})
      : super(validator);
}
