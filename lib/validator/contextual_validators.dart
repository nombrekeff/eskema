import 'dart:async';

import 'package:eskema/expectation.dart';
import 'package:eskema/result.dart';
import 'package:eskema/validator/base_validator.dart';

// Internal micro-helper to reduce duplication.
@pragma('vm:prefer-inline')
Result _failWithMsg(dynamic value, String message) => Result.invalid(value,
    expectation: Expectation(message: message, value: value));

/// The [ResolveValidator] class.
class ResolveValidator extends IWhenValidator {
  /// Executes the [Function] operation.
  final IValidator? Function(Map parentObject) resolver;

  /// Executes the [ResolveValidator] operation.
  ResolveValidator({
    required this.resolver,
    super.nullable,
    super.optional,
    super.name = 'resolve',
    super.args = const [],
  });

  @override
  Result validate(dynamic value, {bool exists = true}) => Result.invalid(
        value,
        expectation: Expectation(
          message:
              '`resolve` validator can only be used inside an `eskema` map validator',
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
    String? name,
    List<dynamic>? args,
    IValidator Function(Map parentObject)? resolver,
  }) =>
      ResolveValidator(
        resolver: resolver ?? this.resolver,
        nullable: nullable ?? isNullable,
        optional: optional ?? isOptional,
        name: name ?? this.name,
        args: args ?? this.args,
      );

  @override
  FutureOr<Result> validator(value) => throw UnimplementedError();
}

/// The [WhenValidator] class.
class WhenValidator extends IWhenValidator {
  /// The [condition] property.
  final IValidator condition;

  /// The [then] property.
  final IValidator then;

  /// The [otherwise] property.
  final IValidator otherwise;

  /// Executes the [WhenValidator] operation.
  WhenValidator({
    required this.condition,
    required this.then,
    required this.otherwise,
    super.nullable,
    super.optional,
    super.name = 'when',
    super.args = const [],
  });

  @override
  Result validate(dynamic value, {bool exists = true}) => Result.invalid(
        value,
        expectation: Expectation(
          message:
              '`when` validator can only be used inside an `eskema` map validator',
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

    if (cond is Future<Result>) {
      return cond.then((cr) => _evalBranch(cr, value));
    }

    return _evalBranch(cond, value);
  }

  FutureOr<Result> _evalBranch(Result conditionResult, dynamic value) =>
      conditionResult.isValid
          ? then.validator(value)
          : otherwise.validator(value);

  @override
  IValidator copyWith({
    bool? nullable,
    bool? optional,
    String? name,
    List<dynamic>? args,
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
        name: name ?? this.name,
        args: args ?? this.args,
      );

  @override
  FutureOr<Result> validator(value) => throw UnimplementedError();
}

/// The [WhenWithMessage] class.
class WhenWithMessage extends IWhenValidator {
  /// The [inner] property.
  final WhenValidator inner;

  /// The [message] property.
  final String message;

  /// Executes the [WhenWithMessage] operation.
  WhenWithMessage(this.inner, this.message)
      : super(
          nullable: inner.isNullable,
          optional: inner.isOptional,
          name: inner.name,
          args: inner.args,
        );

  @override
  FutureOr<Result> validateWithParent(
    dynamic value,
    Map<String, dynamic> map, {
    bool exists = true,
  }) async {
    final res = await inner.validateWithParent(value, map, exists: exists);

    if (res.isValid) return res;

    return _failWithMsg(value, message);
  }

  @override
  Result validate(dynamic value, {bool exists = true}) =>
      _failWithMsg(value, message);

  @override
  IValidator copyWith(
          {bool? nullable,
          bool? optional,
          String? name,
          List<dynamic>? args}) =>
      WhenWithMessage(
        inner.copyWith(
          nullable: nullable,
          optional: optional,
          name: name,
          args: args,
        ) as WhenValidator,
        message,
      );

  @override
  FutureOr<Result> validator(value) => validate(value);
}
