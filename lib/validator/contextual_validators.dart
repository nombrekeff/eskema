import 'dart:async';

import 'package:eskema/expectation.dart';
import 'package:eskema/result.dart';
import 'package:eskema/validator/base_validator.dart';

// Internal micro-helper to reduce duplication.
@pragma('vm:prefer-inline')
Result _failWithMsg(dynamic value, String message) =>
    Result.invalid(value, expectation: Expectation(message: message, value: value));

/// Resolves a validator based on the parent object.
class ResolveValidator extends IWhenValidator {
  final IValidator? Function(Map parentObject) resolver;

  ResolveValidator({
    required this.resolver,
    super.nullable,
    super.optional,
  });

  @override
  Result validate(dynamic value, {bool exists = true}) => Result.invalid(
        value,
        expectation: Expectation(
          message: '`resolve` validator can only be used inside an `eskema` map validator',
          value: value,
        ),
      );

  @override
  FutureOr<Result> validateWithParent(
    dynamic value,
    Map<String, dynamic> map, {
    bool exists = true,
  }) {
    final resolverValidator = resolver(map);
    final resolverResult = resolverValidator?.validator(value);

    if (resolverResult == null) return Result.valid(value);

    if (resolverResult is Future<Result>) {
      return resolverResult.then((cr) => _evalBranch(cr, value));
    }

    return _evalBranch(resolverResult, value);
  }

  FutureOr<Result> _evalBranch(Result resolverResult, dynamic value) {
    return resolverResult.isValid ? Result.valid(value) : resolverResult;
  }

  @override
  IValidator copyWith({
    bool? nullable,
    bool? optional,
    IValidator Function(Map parentObject)? resolver,
  }) =>
      ResolveValidator(
        resolver: resolver ?? this.resolver,
        nullable: nullable ?? isNullable,
        optional: optional ?? isOptional,
      );

  @override
  FutureOr<Result> validator(value) => throw UnimplementedError();
}

/// Conditional validator. It's conditional based on some other field in the eskema.
class WhenValidator extends IWhenValidator {
  final IValidator condition;
  final IValidator then;
  final IValidator otherwise;

  WhenValidator({
    required this.condition,
    required this.then,
    required this.otherwise,
    super.nullable,
    super.optional,
  });

  @override
  Result validate(dynamic value, {bool exists = true}) => Result.invalid(
        value,
        expectation: Expectation(
          message: '`when` validator can only be used inside an `eskema` map validator',
          value: value,
        ),
      );

  @override
  FutureOr<Result> validateWithParent(
    dynamic value,
    Map<String, dynamic> map, {
    bool exists = true,
  }) {
    final cond = condition.validator(map);
    if (cond is Future<Result>) return cond.then((cr) => _evalBranch(cr, value));
    return _evalBranch(cond, value);
  }

  FutureOr<Result> _evalBranch(Result conditionResult, dynamic value) =>
      conditionResult.isValid ? then.validator(value) : otherwise.validator(value);

  @override
  IValidator copyWith({
    bool? nullable,
    bool? optional,
    IValidator? condition,
    IValidator? then,
    IValidator? otherwise,
  }) =>
      WhenValidator(
        condition: condition ?? this.condition,
        then: then ?? this.then,
        otherwise: otherwise ?? this.otherwise,
        nullable: nullable ?? isNullable,
        optional: optional ?? isOptional,
      );

  @override
  FutureOr<Result> validator(value) => throw UnimplementedError();
}

/// Adds a custom error message to a `when` validator.
class WhenWithMessage extends IWhenValidator {
  final WhenValidator inner;
  final String message;
  WhenWithMessage(this.inner, this.message);

  @override
  FutureOr<Result> validateWithParent(
    dynamic value,
    Map<String, dynamic> map, {
    bool exists = true,
  }) {
    final res = inner.validateWithParent(value, map, exists: exists);

    if (res is Future<Result>) {
      return res.then((r) => _processResult(r, value));
    }

    return _processResult(res, value);
  }

  Result _processResult(Result res, dynamic value) {
    if (res.isValid) return res;
    return _failWithMsg(value, message);
  }

  @override
  Result validate(dynamic value, {bool exists = true}) => _failWithMsg(value, message);

  @override
  IValidator copyWith({bool? nullable, bool? optional}) => WhenWithMessage(
        inner.copyWith(nullable: nullable, optional: optional) as WhenValidator,
        message,
      );

  @override
  FutureOr<Result> validator(value) => validate(value);
}
