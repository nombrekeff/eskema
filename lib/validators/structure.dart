/// Structure Validators
///
/// This file contains validators for checking the structure of complex data types.

library validators.structure;

import 'dart:async';
import 'package:eskema/eskema.dart';
import 'package:eskema/expectation_codes.dart';

import 'package:eskema/validator/async_loop.dart';

typedef _State = ({List<Expectation> errors, dynamic transformed});

/// Returns a Validator that checks a value against a Map eskema that declares a validator for each key.
///
/// Example:
/// ```dart
/// final mapField = all([
///   eskema({
///     'name': all([isType<String>()]),
///     'vat': or(
///       isTypeNull(),
///       isGte(0),
///     ),
///     'age': all([
///       isType<int>(),
///       isGte(0),
///     ]),
///   }),
/// ]);
/// ```
IValidator eskema(Map<String, IValidator> mapEskema, {String? message, bool strict = true}) {
  FutureOr<Result> eskemaPredicate(value) {
    final entries = mapEskema.entries.toList();
    // Create a shallow copy to store transformed values
    final typedMap = (value as Map).cast<String, dynamic>();
    final transformed = Map<String, dynamic>.from(typedMap);

    final initialState = (
      errors: <Expectation>[],
      transformed: transformed,
    );

    FutureOr<_State> reducer(_State state, MapEntry<String, IValidator> entry) {
      final key = entry.key;
      final validator = entry.value;
      final fieldValue = value[key];
      final exists = value.containsKey(key);

      FutureOr<Result> res;
      if (validator is IWhenValidator) {
        res = validator.validateWithParent(fieldValue, typedMap, exists: exists);
      } else {
        // Reproduce nullable/optional short-circuit semantics that validate() provided.
        if (!exists) {
          if (validator.isOptional) {
            return state;
          }
          // For required field missing: validate with exists: false so nullable validators fail.
          final missingRes = validator.validate(null, exists: false);
          _collectEskema(missingRes, state.errors, key, message);
          return state;
        }

        if (!exists && validator.isOptional) {
          return state;
        }

        if (exists && fieldValue == null && validator.isNullable) {
          return state;
        }

        res = validator.validator(fieldValue);
      }

      return _processResult(res, state, (r) {
        _collectEskema(r, state.errors, key, message);
        if (r.isValid) {
          state.transformed[key] = r.value;
        }
      });
    }

    return _resolveValidationState(
      asyncFold(entries, initialState, reducer),
      (finalState) => finalState.errors.isEmpty
          ? Result.valid(finalState.transformed, originalValue: value)
          : Result.invalid(finalState.transformed,
              expectations: finalState.errors, originalValue: value),
    );
  }

  return isMap() & Validator(eskemaPredicate);
}

void _collectEskema(Result result, List<Expectation> errors, String key, [String? message]) {
  if (result.isValid) return;

  for (final error in result.expectations) {
    errors.add(Expectation(
      message: message ?? error.message,
      value: error.value,
      path: '.$key${error.path != null ? '${error.path}' : ''}',
      code: error.code ?? ExpectationCodes.structureMapFieldFailed,
      data: error.data,
    ));
  }
}

/// Returns a Validator that checks a value against a Map eskema and fails if
/// any keys exist in the map that are not defined in the [schema].
///
/// Example:
/// ```dart
/// final validator = eskemaStrict({ 'name': isString() });
///
/// validator.validate({ 'name': 'test' }); // valid
/// validator.validate({ 'name': 'test', 'age': 25 }); // invalid
/// ```
IValidator eskemaStrict(Map<String, IValidator> schema, {String? message}) {
  return eskema(schema, message: message) &
      notHasUknownKeys(schema.keys.toList(), message: message);
}

/// Returns a Validator that checks a value against the eskema provided,
/// the eskema defines a validator for each item in the list.
/// Must match, structure and Validators
///
/// Example:
/// ```dart
/// final isValidList = eskemaList([isType<String>(), isType<int>()]);
/// isValidList(["1", 2]).isValid;   // true
/// isValidList(["1", "2"]).isValid; // false
/// isValidList([1, "2"]).isValid;   // false
/// ```
///
/// `isValidList` will only be valid:
/// * if the array is of length 2
/// * the first item is a string
/// * and the second item is an int
///
/// This validator also checks that the value is a list
IValidator eskemaList<T>(List<IValidator> eskema) {
  FutureOr<Result> listPredicate(value) {
    final initialState = (
      index: 0,
      errors: <Expectation>[],
    );

    FutureOr<({int index, List<Expectation> errors})> reducer(
      ({int index, List<Expectation> errors}) state,
      IValidator effectiveValidator,
    ) {
      final index = state.index;
      final item = value[index];

      // Nullable short-circuit
      if (item == null && effectiveValidator.isNullable) {
        return (index: index + 1, errors: state.errors);
      }

      final res = effectiveValidator.validator(item);

      return _processResult(
        res,
        (index: index + 1, errors: state.errors),
        (r) => _collectListIndex(r, state.errors, index, null),
      );
    }

    return _resolveValidationState(
      asyncFold(eskema, initialState, reducer),
      (finalState) => finalState.errors.isEmpty
          ? Result.valid(value)
          : Result.invalid(value, expectations: finalState.errors),
    );
  }

  return isType<List>() & listIsOfLength(eskema.length) & Validator(listPredicate);
}

/// Returns a Validator that runs [itemValidator] for each item in the list
///
/// This validator also checks that the value is a list
IValidator every(IValidator itemValidator, {String? message}) {
  FutureOr<Result> listEachPredicate(value) {
    final initialState = (
      index: 0,
      errors: <Expectation>[],
    );

    FutureOr<({int index, List<Expectation> errors})> reducer(
      ({int index, List<Expectation> errors}) state,
      dynamic item,
    ) {
      final index = state.index;

      if (item == null && itemValidator.isNullable) {
        return (index: index + 1, errors: state.errors);
      }

      final res = itemValidator.validator(item);

      return _processResult(
        res,
        (index: index + 1, errors: state.errors),
        (r) => _collectListIndex(r, state.errors, index, message),
      );
    }

    return _resolveValidationState(
      asyncFold(value, initialState, reducer),
      (finalState) {
        // Cast is needed because asyncFold returns FutureOr<S> which might lose specific record type info if not careful,
        // but here S is explicit in reducer.
        // Actually asyncFold<T, S> returns FutureOr<S>.
        // The cast in original code: final finalState = result as ({int index, List<Expectation> errors});
        // was probably due to type inference.
        // Let's rely on type inference or cast if needed.
        final s = finalState as ({int index, List<Expectation> errors});
        return s.errors.isEmpty
            ? Result.valid(value)
            : Result.invalid(value, expectations: s.errors);
      },
    );
  }

  return $isList & Validator(listEachPredicate);
}

void _collectListIndex(Result result, List<Expectation> errors, int index, [String? message]) {
  if (result.isValid) return;

  for (var error in result.expectations) {
    errors.add(Expectation(
      message: message ?? error.message,
      value: error.value,
      path: '[$index]${error.path != null ? '${error.path}' : ''}',
      code: error.code ?? ExpectationCodes.structureListItemFailed,
      data: error.data,
    ));
  }
}

/// Returns a Validator that runs [itemValidator] for each item in the list
///
/// This validator also checks that the value is a list
@Deprecated('deprecated "listEach" in favor of "every"')
IValidator Function(IValidator itemValidator, {String? message}) listEach = every;

FutureOr<S> _processResult<S>(
  FutureOr<Result> res,
  S nextState,
  void Function(Result r) collector,
) {
  if (res is Future<Result>) {
    return res.then((r) {
      collector(r);
      return nextState;
    });
  }
  collector(res);
  return nextState;
}

FutureOr<Result> _resolveValidationState<S>(
  FutureOr<S> foldResult,
  Result Function(S state) resultBuilder,
) {
  if (foldResult is Future<S>) {
    return foldResult.then(resultBuilder);
  }
  return resultBuilder(foldResult);
}
