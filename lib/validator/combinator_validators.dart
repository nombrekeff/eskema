/// Validators that combine or branch logic (WhenValidator, Field).
library validator.combinators;

import 'dart:async';
import 'package:eskema/expectation.dart';
import 'package:eskema/result.dart';
import 'base_validator.dart';

/// Conditional validator picking between two branches given a condition.
class WhenValidator extends IWhenValidator {
  final IValidator condition;
  final IValidator then;
  final IValidator otherwise;

  WhenValidator(this.condition, this.then, this.otherwise, {super.nullable, super.optional});

  @override
  Result validate(dynamic value, {bool exists = true}) => Result.invalid(
        value,
        expectations: [
          Expectation(
            message: '`when` validator can only be used inside an `eskema` map validator',
            value: value,
          )
        ],
      );

  @override
  FutureOr<Result> validateWithParent(dynamic value, Map<String, dynamic> map, {bool exists = true}) {
    final cond = condition.validator(map);
    if (cond is Future<Result>) return cond.then((cr) => _evalBranch(cr, value));
    return _evalBranch(cond, value);
  }

  FutureOr<Result> _evalBranch(Result conditionResult, dynamic value) =>
      conditionResult.isValid ? then.validator(value) : otherwise.validator(value);

  @override
  IValidator copyWith({bool? nullable, bool? optional, IValidator? condition, IValidator? then, IValidator? otherwise}) =>
      WhenValidator(
        condition ?? this.condition,
        then ?? this.then,
        otherwise ?? this.otherwise,
        nullable: nullable ?? isNullable,
        optional: optional ?? isOptional,
      );

  @override
  FutureOr<Result> validator(value) => throw UnimplementedError();
}

/// Field validator composed of an ordered list of validators.
class Field extends IdValidator {
  final List<IValidator> validators;
  Field({required this.validators, super.id, super.nullable, super.optional}) : super(validator: Result.valid);

  @override
  FutureOr<Result> validator(dynamic value) {
    final base = super.validator(value);
    if (base is Future<Result>) return base.then((r) => _continueChain(r, value));
    return _continueChain(base, value);
  }

  Result _continueChain(Result base, dynamic value) {
    if (base.isNotValid) return base;
    for (final v in validators) {
      final r = v.validate(value);
      if (r.isNotValid) return r;
    }
    return Result.valid(value);
  }

  @override
  IValidator copyWith({bool? nullable, bool? optional}) => Field(
        validators: validators,
        id: id,
        nullable: nullable ?? isNullable,
        optional: optional ?? isOptional,
      );
}
