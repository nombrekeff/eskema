/// Validators that combine or branch logic (WhenValidator, Field).
library validator.combinators;

import 'dart:async';
import 'package:eskema/expectation.dart';
import 'package:eskema/result.dart';
import 'package:eskema/validator/exception.dart';
import 'package:eskema/validators/combinator.dart';
import 'base_validator.dart';

// Internal micro-helper to reduce duplication.
@pragma('vm:prefer-inline')
Result _failWithMsg(dynamic value, String message) =>
    Result.invalid(value, expectation: Expectation(message: message, value: value));

/// An abstract base for validators that operate on a list of child validators.
///
/// This class handles the core iteration logic, including the sync/async split,
/// allowing subclasses to focus solely on their specific validation rules.
abstract class _MultiValidatorBase extends IValidator {
  _MultiValidatorBase(this.validators, {super.nullable, super.optional, this.message});

  final List<IValidator> validators;
  final String? message;

  /// Determines if the output value of one validator should be passed as the
  /// input to the next. `AllValidator` chains values, while `AnyValidator` and
  /// `NoneValidator` do not.
  bool get _chainsTransformedValue;

  /// Processes the result of a single child validator.
  ///
  /// Subclasses override this to implement their specific logic (e.g., short-circuiting
  /// on the first failure for `AllValidator`, or on the first success for `AnyValidator`).
  ///
  /// Returns a `Result` to indicate completion or `null` to continue iteration.
  Result? _processResult(Result result, dynamic currentValue);

  /// Builds the final `Result` after all validators have been processed.
  Result _buildFinalResult(dynamic finalValue, List<Expectation> aggregatedExpectations);

  @override
  FutureOr<Result> validator(dynamic value) {
    var currentValue = value;
    final aggregatedExpectations = <Expectation>[];

    for (var i = 0; i < validators.length; i++) {
      final result = validators[i].validator(currentValue);

      if (result is Future<Result>) {
        // Switch to the async path.
        return _continueAsync(result, i + 1, currentValue, aggregatedExpectations);
      }

      final outcome = _processResult(result, currentValue);
      if (outcome != null) return outcome; // Short-circuit.

      if (result.isNotValid) aggregatedExpectations.addAll(result.expectations);
      if (_chainsTransformedValue) currentValue = result.value;
    }

    return _buildFinalResult(currentValue, aggregatedExpectations);
  }

  Future<Result> _continueAsync(
    Future<Result> pending,
    int nextIndex,
    dynamic currentValue,
    List<Expectation> aggregatedExpectations,
  ) async {
    final firstResult = await pending;
    final firstOutcome = _processResult(firstResult, currentValue);
    if (firstOutcome != null) return firstOutcome; // Short-circuit.

    if (firstResult.isNotValid) aggregatedExpectations.addAll(firstResult.expectations);
    if (_chainsTransformedValue) currentValue = firstResult.value;

    for (var i = nextIndex; i < validators.length; i++) {
      final result = await validators[i].validator(currentValue);
      final outcome = _processResult(result, currentValue);
      if (outcome != null) return outcome; // Short-circuit.

      if (result.isNotValid) aggregatedExpectations.addAll(result.expectations);
      if (_chainsTransformedValue) currentValue = result.value;
    }

    return _buildFinalResult(currentValue, aggregatedExpectations);
  }
}

/// Succeeds if all child validators succeed. Fails on the first failure.
class AllValidator extends _MultiValidatorBase {
  AllValidator(super.validators, {super.nullable, super.optional, super.message});

  @override
  bool get _chainsTransformedValue => true;

  @override
  Result? _processResult(Result result, dynamic currentValue) {
    if (result.isNotValid) {
      // Short-circuit on first failure.
      return message != null ? _failWithMsg(result.value, message!) : result;
    }
    return null; // Continue.
  }

  @override
  Result _buildFinalResult(dynamic finalValue, List<Expectation> _) {
    // If a message is provided, it forces failure even if all children pass.
    return message != null ? _failWithMsg(finalValue, message!) : Result.valid(finalValue);
  }

  @override
  IValidator copyWith({bool? nullable, bool? optional}) => AllValidator(
        validators,
        nullable: nullable ?? isNullable,
        optional: optional ?? isOptional,
        message: message,
      );
}

/// Succeeds if at least one child validator succeeds. Fails if all fail.
class AnyValidator extends _MultiValidatorBase {
  AnyValidator(super.validators, {super.nullable, super.optional, super.message});

  @override
  bool get _chainsTransformedValue => false;

  @override
  Result? _processResult(Result result, dynamic currentValue) {
    if (result.isValid) {
      // Short-circuit on first success.
      return result;
    }
    return null; // Continue.
  }

  @override
  Result _buildFinalResult(dynamic finalValue, List<Expectation> aggregatedExpectations) {
    // If we get here, all validators failed.
    return message != null
        ? _failWithMsg(finalValue, message!)
        : Result.invalid(finalValue, expectations: aggregatedExpectations);
  }

  @override
  IValidator copyWith({bool? nullable, bool? optional}) => AnyValidator(
        validators,
        nullable: nullable ?? isNullable,
        optional: optional ?? isOptional,
        message: message,
      );
}

/// Succeeds if all child validators fail. Fails if any succeed.
class NoneValidator extends _MultiValidatorBase {
  NoneValidator(super.validators, {super.nullable, super.optional, super.message});

  @override
  bool get _chainsTransformedValue => false;

  @override
  FutureOr<Result> validator(dynamic value) {
    final aggregatedExpectations = <Expectation>[];

    for (var i = 0; i < validators.length; i++) {
      final result = validators[i].validator(value);

      if (result is Future<Result>) {
        // Switch to the async path.
        return _continueNoneAsync(result, i + 1, value, aggregatedExpectations);
      }

      // For `none`, collect expectations from VALID results (passing validators)
      // and transform them to "not X" messages
      if (result.isValid) {
        final notExpectations = result.expectations
            .map((exp) => exp.copyWith(message: 'not ${exp.message}'))
            .toList();
        aggregatedExpectations.addAll(notExpectations);
      }
    }

    return _buildFinalResult(value, aggregatedExpectations);
  }

  Future<Result> _continueNoneAsync(
    Future<Result> pending,
    int nextIndex,
    dynamic value,
    List<Expectation> aggregatedExpectations,
  ) async {
    final firstResult = await pending;

    // For `none`, collect expectations from VALID results (passing validators)
    // and transform them to "not X" messages
    if (firstResult.isValid) {
      final notExpectations = firstResult.expectations
          .map((exp) => exp.copyWith(message: 'not ${exp.message}'))
          .toList();
      aggregatedExpectations.addAll(notExpectations);
    }

    for (var i = nextIndex; i < validators.length; i++) {
      final result = await validators[i].validator(value);

      // For `none`, collect expectations from VALID results (passing validators)
      // and transform them to "not X" messages
      if (result.isValid) {
        final notExpectations = result.expectations
            .map((exp) => exp.copyWith(message: 'not ${exp.message}'))
            .toList();
        aggregatedExpectations.addAll(notExpectations);
      }
    }

    return _buildFinalResult(value, aggregatedExpectations);
  }

  @override
  Result? _processResult(Result result, dynamic currentValue) {
    // This method is not used since we override the main validator method
    return null;
  }

  @override
  Result _buildFinalResult(dynamic finalValue, List<Expectation> aggregatedExpectations) {
    // If we have any passing validators (which add their expectations to the aggregated list)
    // then `none` should fail and return those expectations
    if (aggregatedExpectations.isNotEmpty) {
      return message != null
          ? _failWithMsg(finalValue, message!)
          : Result.invalid(finalValue, expectations: aggregatedExpectations);
    }
    // If we get here, all validators failed, so `none` succeeds.
    return Result.valid(finalValue);
  }

  @override
  IValidator copyWith({bool? nullable, bool? optional}) => NoneValidator(
        validators,
        nullable: nullable ?? isNullable,
        optional: optional ?? isOptional,
        message: message,
      );
}

// --- Single-Child and Other Combinators (largely unchanged) ---

mixin _SingleChildAsync {
  Future<Result> _handleAsync(Future<Result> pending, Result Function(Result) onResult) async {
    final result = await pending;
    return onResult(result);
  }
}

class NotValidator extends IValidator with _SingleChildAsync {
  IValidator child;
  final String? message;

  NotValidator(this.child, {super.nullable, super.optional, this.message});

  @override
  FutureOr<Result> validator(value) {
    final result = child.validator(value);
    if (result is Future<Result>) return _handleAsync(result, (r) => _processResult(r, value));
    return _processResult(result, value);
  }

  Result _processResult(Result result, dynamic value) {
    if (result.isValid) {
      // When the child validator passes, we need to create a "not X" message
      if (message != null) {
        return _failWithMsg(value, message!);
      } else {
        // Create "not X" expectations from the child's expectations
        final notExpectations = result.expectations
            .map((exp) => exp.copyWith(message: 'not ${exp.message}', value: value))
            .toList();
        return Result.invalid(value, expectations: notExpectations);
      }
    }
    // If the child failed, `not` succeeds.
    return Result.valid(value);
  }

  @override
  IValidator copyWith({bool? nullable, bool? optional}) => NotValidator(
        child,
        nullable: nullable ?? isNullable,
        optional: optional ?? isOptional,
        message: message,
      );
}

class ThrowInsteadValidator extends IValidator with _SingleChildAsync {
  final IValidator child;
  ThrowInsteadValidator(this.child);

  @override
  FutureOr<Result> validator(value) {
    final resOr = child.validator(value);
    if (resOr is Future<Result>) return _handleAsync(resOr, _throwOrResult);
    return _throwOrResult(resOr);
  }

  Result _throwOrResult(Result result) {
    if (result.isNotValid) throw ValidatorFailedException(result);
    return Result.valid(result.value);
  }

  @override
  IValidator copyWith({bool? nullable, bool? optional}) =>
      ThrowInsteadValidator(child.copyWith(nullable: nullable, optional: optional));
}

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

class WhenWithMessage extends IWhenValidator {
  final WhenValidator inner;
  final String message;
  WhenWithMessage(this.inner, this.message);

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
  Result validate(dynamic value, {bool exists = true}) => _failWithMsg(value, message);

  @override
  IValidator copyWith({bool? nullable, bool? optional}) => WhenWithMessage(
        inner.copyWith(nullable: nullable, optional: optional) as WhenValidator,
        message,
      );

  @override
  FutureOr<Result> validator(value) => validate(value);
}

class Field extends IdValidator {
  Field({required this.validators, super.id, super.nullable, super.optional})
      : super(validator: (value) => all(validators).validator(value));

  final List<IValidator> validators;

  @override
  IValidator copyWith({bool? nullable, bool? optional}) => Field(
        validators: validators,
        id: id,
        nullable: nullable ?? isNullable,
        optional: optional ?? isOptional,
      );
}
