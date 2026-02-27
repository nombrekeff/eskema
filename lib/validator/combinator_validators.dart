/// Validators that combine or branch logic (WhenValidator, Field).
library validator.combinators;

import 'dart:async';
import 'package:eskema/expectation.dart';
import 'package:eskema/result.dart';
import 'package:eskema/src/util.dart' as util;
import 'package:eskema/validator/exception.dart';
import 'package:eskema/validators/combinator.dart';
import 'base_validator.dart';

// Internal micro-helper to reduce duplication.
@pragma('vm:prefer-inline')
Result _failWithMsg(dynamic value, String message) => Result.invalid(value,
    expectation: Expectation(message: message, value: value));

/// The [MultiValidatorBase] class.
abstract class MultiValidatorBase extends IValidator {
  /// Executes the [MultiValidatorBase] operation.
  MultiValidatorBase(
    this.validators, {
    super.nullable,
    super.optional,
    this.message,
    super.name = 'custom',
    super.args = const [],
  });

  /// The [Iterable] property.
  final Iterable<IValidator> validators;

  /// The [message] property.
  final String? message;

  /// Configuration for how this validator should behave
  _ValidatorConfig get _config;

  @override
  FutureOr<Result> validator(dynamic value) {
    var currentValue = value;
    final aggregatedExpectations = <Expectation>[];

    for (var i = 0; i < validators.length; i++) {
      final inputValue = _config.chainsValues ? currentValue : value;
      final result = validators.elementAt(i).validator(inputValue);

      if (result is Future<Result>) {
        return _continueAsync(
            result, i + 1, currentValue, value, aggregatedExpectations);
      }

      final (shouldStop, stopResult) =
          _processResult(result, inputValue, aggregatedExpectations);

      if (shouldStop) return stopResult!;

      if (_config.chainsValues && result.isValid) currentValue = result.value;
    }

    return _buildFinalResult(
        _config.chainsValues ? currentValue : value, aggregatedExpectations);
  }

  Future<Result> _continueAsync(
    Future<Result> pending,
    int nextIndex,
    dynamic currentValue,
    dynamic originalValue,
    List<Expectation> aggregatedExpectations,
  ) async {
    final firstResult = await pending;
    final inputValue = _config.chainsValues ? currentValue : originalValue;

    final (shouldStop, stopResult) =
        _processResult(firstResult, inputValue, aggregatedExpectations);

    if (shouldStop) return stopResult!;

    if (_config.chainsValues && firstResult.isValid) {
      currentValue = firstResult.value;
    }

    for (var i = nextIndex; i < validators.length; i++) {
      final nextInputValue =
          _config.chainsValues ? currentValue : originalValue;
      final result = await validators.elementAt(i).validator(nextInputValue);

      final (shouldStop2, stopResult2) =
          _processResult(result, nextInputValue, aggregatedExpectations);

      if (shouldStop2) return stopResult2!;

      if (_config.chainsValues && result.isValid) currentValue = result.value;
    }

    return _buildFinalResult(
        _config.chainsValues ? currentValue : originalValue,
        aggregatedExpectations);
  }

  /// Processes a validation result and determines if validation should continue.
  /// Returns (shouldStop, result) tuple.
  (bool, Result?) _processResult(Result result, dynamic inputValue,
      List<Expectation> aggregatedExpectations);

  /// Builds the final result when all validators have been processed.
  Result _buildFinalResult(
      dynamic finalValue, List<Expectation> aggregatedExpectations);

  @override
  MultiValidatorBase copyWith({
    bool? nullable,
    bool? optional,
    String? name,
    List<dynamic>? args,
    Iterable<IValidator>? validators,
    String? message,
  });
}

/// Configuration for multi-validator behavior
class _ValidatorConfig {
  const _ValidatorConfig({
    required this.chainsValues,
    required this.shortCircuitOnSuccess,
    required this.shortCircuitOnFailure,
    required this.collectFromValid,
    required this.transformExpectations,
  });

  final bool chainsValues;
  final bool shortCircuitOnSuccess;
  final bool shortCircuitOnFailure;
  final bool collectFromValid;
  final List<Expectation> Function(List<Expectation>)? transformExpectations;

  static const all = _ValidatorConfig(
    chainsValues: true,
    shortCircuitOnSuccess: false,
    shortCircuitOnFailure: true,
    collectFromValid: false,
    transformExpectations: null,
  );

  static const allCollecting = _ValidatorConfig(
    chainsValues: false,
    shortCircuitOnSuccess: false,
    shortCircuitOnFailure: false,
    collectFromValid: false,
    transformExpectations: null,
  );

  static const any = _ValidatorConfig(
    chainsValues: false,
    shortCircuitOnSuccess: true,
    shortCircuitOnFailure: false,
    collectFromValid: false,
    transformExpectations: null,
  );

  static const none = _ValidatorConfig(
    chainsValues: false,
    shortCircuitOnSuccess: false,
    shortCircuitOnFailure: false,
    collectFromValid: true,
    transformExpectations: _transformToNot,
  );

  static List<Expectation> _transformToNot(List<Expectation> expectations) =>
      expectations
          .map((exp) => exp.copyWith(message: 'not ${exp.message}'))
          .toList();
}

/// Succeeds if all child validators succeed. Fails on the first failure or collects all failures.
class AllValidator extends MultiValidatorBase {
  /// The [collecting] property.
  final bool collecting;

  /// Executes the [AllValidator] operation.
  AllValidator(
    super.validators, {
    super.nullable,
    super.optional,
    super.message,
    super.name = 'all',
    List<dynamic>? args,
    this.collecting = false,
  }) : super(args: args ?? List.from(validators));

  @override
  _ValidatorConfig get _config =>
      collecting ? _ValidatorConfig.allCollecting : _ValidatorConfig.all;

  @override
  (bool, Result?) _processResult(Result result, dynamic inputValue,
      List<Expectation> aggregatedExpectations) {
    if (collecting) {
      // Collecting mode: collect all failures, never short-circuit
      if (result.isNotValid) {
        aggregatedExpectations.addAll(result.expectations);
      }
      return (false, null);
    } else {
      // Standard mode: short-circuit on first failure
      if (result.isNotValid) {
        final failResult =
            message != null ? _failWithMsg(result.value, message!) : result;

        return (true, failResult);
      }
      return (false, null);
    }
  }

  @override
  Result _buildFinalResult(
      dynamic finalValue, List<Expectation> aggregatedExpectations) {
    if (collecting) {
      // Collecting mode: return failures if any, success otherwise
      if (aggregatedExpectations.isNotEmpty) {
        return message != null
            ? _failWithMsg(finalValue, message!)
            : Result.invalid(finalValue, expectations: aggregatedExpectations);
      }
      return Result.valid(finalValue);
    } else {
      // Standard mode: message forces failure even if all children pass
      return message != null
          ? _failWithMsg(finalValue, message!)
          : Result.valid(finalValue);
    }
  }

  @override
  AllValidator copyWith({
    bool? nullable,
    bool? optional,
    String? name,
    List<dynamic>? args,
    Iterable<IValidator>? validators,
    String? message,
  }) =>
      AllValidator(
        validators ?? this.validators,
        nullable: nullable ?? isNullable,
        optional: optional ?? isOptional,
        message: message ?? this.message,
        name: name ?? this.name,
        args: args ?? this.args,
        collecting: collecting,
      );
}

/// Succeeds if at least one child validator succeeds. Fails if all fail.
class AnyValidator extends MultiValidatorBase {
  /// Executes the [AnyValidator] operation.
  AnyValidator(super.validators,
      {super.nullable,
      super.optional,
      super.message,
      super.name = 'any',
      List<dynamic>? args})
      : super(args: args ?? List.from(validators));

  @override
  _ValidatorConfig get _config => _ValidatorConfig.any;

  @override
  (bool, Result?) _processResult(Result result, dynamic inputValue,
      List<Expectation> aggregatedExpectations) {
    if (result.isValid) {
      // Short-circuit on first success
      return (true, result);
    }
    // Collect failures and continue
    aggregatedExpectations.addAll(result.expectations);

    return (false, null);
  }

  @override
  Result _buildFinalResult(
      dynamic finalValue, List<Expectation> aggregatedExpectations) {
    // If we get here, all validators failed
    return message != null
        ? _failWithMsg(finalValue, message!)
        : Result.invalid(finalValue, expectations: aggregatedExpectations);
  }

  @override
  AnyValidator copyWith({
    bool? nullable,
    bool? optional,
    String? name,
    List<dynamic>? args,
    Iterable<IValidator>? validators,
    String? message,
  }) =>
      AnyValidator(
        validators ?? this.validators,
        nullable: nullable ?? isNullable,
        optional: optional ?? isOptional,
        message: message ?? this.message,
        name: name ?? this.name,
        args: args ?? this.args,
      );
}

/// Succeeds if all child validators fail. Fails if any succeed.
class NoneValidator extends MultiValidatorBase {
  /// Executes the [NoneValidator] operation.
  NoneValidator(super.validators,
      {super.nullable,
      super.optional,
      super.message,
      super.name = 'none',
      List<dynamic>? args})
      : super(args: args ?? List.from(validators));

  @override
  _ValidatorConfig get _config => _ValidatorConfig.none;

  @override
  (bool, Result?) _processResult(Result result, dynamic inputValue,
      List<Expectation> aggregatedExpectations) {
    // For `none`, collect expectations from VALID results (passing validators)
    // and transform them to "not X" messages
    if (result.isValid) {
      // If the passing child produced no expectations (common for simple validators),
      // synthesize a placeholder so `none` can still fail meaningfully.
      final source = result.expectations.isEmpty
          ? [Expectation(message: 'passed', value: inputValue)]
          : result.expectations;

      final notExpectations = source.map((exp) =>
          exp.copyWith(message: 'not ${exp.message}', value: inputValue));
      aggregatedExpectations.addAll(notExpectations);
    }

    // Never short-circuit, always continue
    return (false, null);
  }

  @override
  Result _buildFinalResult(
      dynamic finalValue, List<Expectation> aggregatedExpectations) {
    // If we have any passing validators (which add their expectations to the aggregated list)
    // then `none` should fail and return those expectations
    if (aggregatedExpectations.isNotEmpty) {
      return message != null
          ? _failWithMsg(finalValue, message!)
          : Result.invalid(finalValue, expectations: aggregatedExpectations);
    }
    // If we get here, all validators failed, so `none` succeeds
    return Result.valid(finalValue);
  }

  @override
  NoneValidator copyWith({
    bool? nullable,
    bool? optional,
    String? name,
    List<dynamic>? args,
    Iterable<IValidator>? validators,
    String? message,
  }) =>
      NoneValidator(
        validators ?? this.validators,
        nullable: nullable ?? isNullable,
        optional: optional ?? isOptional,
        message: message ?? this.message,
        name: name ?? this.name,
        args: args ?? this.args,
      );
}

// --- Single-Child and Other Combinators ---

/// Base class for validators that operate on a single child validator.
abstract class _SingleChildValidator extends IValidator {
  _SingleChildValidator(this.child,
      {super.nullable, super.optional, super.name, super.args, this.message});

  final IValidator child;
  final String? message;

  @override
  FutureOr<Result> validator(dynamic value) {
    final result = child.validator(value);

    if (result is Future<Result>) {
      return result.then((r) => _processResult(r, value));
    }
    return _processResult(result, value);
  }

  /// Processes the child validator's result and returns the final result.
  Result _processResult(Result result, dynamic value);
}

/// The [NotValidator] class.
class NotValidator extends _SingleChildValidator {
  /// Executes the [NotValidator] operation.
  NotValidator(super.child,
      {super.nullable,
      super.optional,
      super.message,
      super.name = 'not',
      super.args = const []});

  @override
  Result _processResult(Result result, dynamic value) {
    if (result.isValid) {
      // When the child validator passes, we need to create a "not X" message
      if (message != null) {
        return _failWithMsg(value, message!);
      } else {
        // Create "not X" expectations from the child's expectations. If the child
        // produced none (common for primitive validators), synthesize a placeholder
        // so that consumers (and fuzz tests) always see at least one expectation.
        final source = result.expectations.isEmpty
            ? [Expectation(message: 'passed', value: value)]
            : result.expectations;

        final notExpectations = source.map((exp) => exp.copyWith(
            message: util.capitalize('not ${exp.message}'), value: value));

        return Result.invalid(value, expectations: notExpectations);
      }
    }
    // If the child failed, `not` succeeds.
    return Result.valid(value);
  }

  @override
  IValidator copyWith({
    bool? nullable,
    bool? optional,
    String? name,
    List<dynamic>? args,
    String? message,
  }) =>
      NotValidator(
        child,
        nullable: nullable ?? isNullable,
        optional: optional ?? isOptional,
        message: message ?? this.message,
        name: name ?? this.name,
        args: args ?? this.args,
      );
}

/// The [ThrowInsteadValidator] class.
class ThrowInsteadValidator extends _SingleChildValidator {
  /// Executes the [ThrowInsteadValidator] operation.
  ThrowInsteadValidator(super.child,
      {super.name = 'throwInstead', super.args = const []})
      : super(nullable: child.isNullable, optional: child.isOptional);

  @override
  Result _processResult(Result result, dynamic value) {
    if (result.isNotValid) throw ValidatorFailedException(result);

    return Result.valid(result.value);
  }

  @override
  IValidator copyWith(
          {bool? nullable,
          bool? optional,
          String? name,
          List<dynamic>? args}) =>
      ThrowInsteadValidator(
          child.copyWith(nullable: nullable, optional: optional),
          name: name ?? this.name,
          args: args ?? this.args);
}

/// The [Field] class.
class Field extends IdValidator {
  /// Executes the [Field] operation.
  Field({
    required this.validators,
    super.id,
    super.nullable,
    super.optional,
    super.name,
    super.args,
  }) : super(validator: (value) => all(validators).validator(value));

  /// The [List] property.
  final List<IValidator> validators;

  @override
  IValidator copyWith({
    bool? nullable,
    bool? optional,
    String? name,
    List<dynamic>? args,
  }) =>
      Field(
        validators: validators,
        id: id,
        nullable: nullable ?? isNullable,
        optional: optional ?? isOptional,
        name: name ?? this.name,
        args: args ?? this.args,
      );
}
