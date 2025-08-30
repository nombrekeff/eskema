/// Combinator Validators
///
/// This file contains validators for combining multiple validation rules.
library validators.combinator;

import 'dart:async';
import 'package:eskema/eskema.dart';

/// Passes the test if any of the [Validator]s are valid, and fails if any are invalid
IValidator any(List<IValidator> validators) => Validator<Result>(
      (value) {
        final collected = <Result>[];

        for (var i = 0; i < validators.length; i++) {
          final resOr = validators[i].validator(value);
          if (resOr is Future<Result>) {
            return _anyAsync(value, validators, collected, i, resOr);
          }
          final res = resOr;
          collected.add(res);
          if (res.isValid) return res;
        }

        return Result.invalid(
          value,
          expectations: collected.expand((r) => r.expectations).toList(),
        );
      },
    );

Future<Result> _anyAsync(
  dynamic value,
  List<IValidator> validators,
  List<Result> collected,
  int index,
  Future<Result> pending,
) async {
  // resolve current pending
  final first = await pending;
  collected.add(first);
  if (first.isValid) return first;

  // continue with remaining
  for (var i = index + 1; i < validators.length; i++) {
    final r = await validators[i].validator(value);
    collected.add(r);
    if (r.isValid) return r;
  }

  return Result.invalid(
    value,
    expectations: collected.expand((r) => r.expectations).toList(),
  );
}

/// Passes the test if all of the [Validator]s are valid, and fails if any of them are invalid
///
/// In the case that a [Validator] fails, it's [Result] will be returned
IValidator all(List<IValidator> validators) {
  FutureOr<Result> pipeline(dynamic value) {
    // Thread potentially transformed values through the chain.
    for (var i = 0; i < validators.length; i++) {
      final resOr = validators[i].validator(value);
      if (resOr is Future<Result>) {
        return _allAsync(value, validators, i, resOr);
      }
      if (resOr.isNotValid) return resOr; // early failure preserves transformed value so far
      value = resOr.value; // adopt transformed value (if unchanged it's a no-op)
    }
    return Result.valid(value);
  }

  return Validator<Result>(pipeline);
}

Future<Result> _allAsync(
  dynamic value,
  List<IValidator> validators,
  int index,
  Future<Result> pending,
) async {
  // Resolve the first async validator (all prior were sync and have already
  // threaded their transformations into `value`).
  var currentValue = value;
  final first = await pending;
  if (first.isNotValid) return first;
  currentValue = first.value;

  for (var i = index + 1; i < validators.length; i++) {
    final r = await validators[i].validator(currentValue);
    if (r is Future<Result>) {
      final awaited = await r; // support cascading async validators
      if (awaited.isNotValid) return awaited;
      currentValue = awaited.value;
      continue;
    }
    if (r.isNotValid) return r;
    currentValue = r.value;
  }
  return Result.valid(currentValue);
}

/// Passes the test if none of the validators pass
IValidator none(List<IValidator> validators) => Validator<Result>(
      (value) {
        final expectations = <Expectation>[];

        for (var i = 0; i < validators.length; i++) {
          final resOr = not(validators[i]).validator(value);

          if (resOr is Future<Result>) {
            return _noneAsync(value, validators, expectations, i, resOr);
          }

          if (resOr.isNotValid) expectations.addAll(resOr.expectations);
        }

        return expectations.isNotEmpty
            ? Result.invalid(value, expectations: expectations)
            : Result.valid(value);
      },
    );

Future<Result> _noneAsync(
  dynamic value,
  List<IValidator> validators,
  List<Expectation> expectations,
  int index,
  Future<Result> pending,
) async {
  final first = await pending;

  if (first.isNotValid) expectations.addAll(first.expectations);

  for (var i = index + 1; i < validators.length; i++) {
    final res = await not(validators[i]).validator(value);
    if (res.isNotValid) expectations.addAll(res.expectations);
  }

  return expectations.isNotEmpty
      ? Result.invalid(value, expectations: expectations)
      : Result.valid(value);
}

/// Passes the test if the passed in validator is not valid
///
/// When the inner validator succeeds, the failure will reuse its `code` if present,
/// otherwise falls back to `logic.not_expected`. See docs/expectation_codes.md.
IValidator not(IValidator validator) => Validator<Result>(
      (value) {
        final resOr = validator.validator(value);
        if (resOr is Future<Result>) return _notAsync(value, resOr);

        return Result(
          isValid: resOr.isNotValid,
          expectations: resOr.expectations
              .map((error) => error.copyWith(
                  message: 'not ${error.message}', code: error.code ?? 'logic.not_expected'))
              .toList(),
          value: value,
        );
      },
    );

Future<Result> _notAsync(dynamic value, Future<Result> pending) async {
  final result = await pending;

  return Result(
    isValid: result.isNotValid,
    expectations: result.expectations
        .map((error) => error.copyWith(
            message: 'not ${error.message}', code: error.code ?? 'logic.not_expected'))
        .toList(),
    value: value,
  );
}

/// Returns a [Validator] that throws a [ValidatorFailedException] instead of returning a result
IValidator throwInstead(IValidator validator) => Validator<Result>((value) {
      final resOr = validator.validator(value);
      if (resOr is Future<Result>) return _throwInsteadAsync(resOr);
      if (resOr.isNotValid) throw ValidatorFailedException(resOr);
      return Result.valid(value);
    });

Future<Result> _throwInsteadAsync(Future<Result> pending) async {
  final result = await pending;
  if (result.isNotValid) throw ValidatorFailedException(result);
  return Result.valid(result.value);
}

/// Returns a [IValidator] that wraps the given [child] validator and adds the
/// provided [error] message to the result if the validation fails.
/// Preserves the underlying child's `code` and `data` (if the child failed).
/// See docs/expectation_codes.md.
IValidator withExpectation(IValidator child, Expectation error) => Validator<Result>((value) {
      final resOr = child.validator(value);

      if (resOr is Future<Result>) {
        return resOr.then((r) => Result(
              isValid: r.isValid,
              expectations: [
                error.copyWith(value: value, code: r.isValid ? null : r.firstExpectation.code)
              ],
              value: value,
            ));
      }

      return Result(
        isValid: resOr.isValid,
        expectations: [
          error.copyWith(value: value, code: resOr.isValid ? null : resOr.firstExpectation.code)
        ],
        value: value,
      );
    });

/// Creates a conditional validator. It's conditional based on some other field in the eskema.
///
/// The [condition] validator is run against the parent map.
/// - If the condition is met, [then] is used to validate the current field's value.
/// - If the condition is not met, [otherwise] is used.
IValidator when(
  IValidator condition, {
  required IValidator then,
  required IValidator otherwise,
}) {
  return WhenValidator(condition, then, otherwise);
}
