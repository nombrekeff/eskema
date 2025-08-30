/// Structure Validators
///
/// This file contains validators for checking the structure of complex data types.

library validators.structure;

import 'dart:async';
import 'package:eskema/eskema.dart';
import 'package:eskema/expectation_codes.dart';

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
IValidator eskema(Map<String, IValidator> mapEskema, {String? message}) {
  return isMap() &
      Validator(
        (value) {
          final errors = <Expectation>[];
          final entries = mapEskema.entries.toList();
          // We intentionally implement `loop` returning `FutureOr<Result>`:
          // - Each validator may return a Result synchronously or a Future<Result>.
          // - If all validators are synchronous we want to return a plain Result
          //   so callers keep getting synchronous behavior (short-circuits and
          //   cheaper execution).
          // - If any validator is asynchronous we return a Future that chains the
          //   remaining validation steps. Using async/await would always return
          //   a Future<Result> and change the observable behavior.
          //
          // The recursive loop lets us process entries one-by-one and only
          // escalate to a Future when a validator actually returns one.
          FutureOr<Result> loop(int index) {
            if (index >= entries.length) {
              return errors.isEmpty
                  ? Result.valid(value)
                  : Result.invalid(value, expectations: errors);
            }

            final entry = entries[index];
            final key = entry.key;
            final validator = entry.value;
            final fieldValue = value[key];
            final exists = value.containsKey(key);

            FutureOr<Result> res;
            if (validator is IWhenValidator) {
              res = validator.validateWithParent(fieldValue, value, exists: exists);
            } else {
              // Reproduce nullable/optional short-circuit semantics that validate() provided.
              if (!exists) {
                if (validator.isOptional) return loop(index + 1);
                // For required field missing: validate with exists: false so nullable validators fail.
                final missingRes = validator.validate(null, exists: false);
                _collectEskema(missingRes, errors, key, message);
                return loop(index + 1);
              }

              if (!exists && validator.isOptional) {
                return loop(index + 1);
              }

              if (exists && fieldValue == null && validator.isNullable) {
                return loop(index + 1);
              }

              res = validator.validator(fieldValue);
            }

            if (res is Future<Result>) {
              return res.then((r) {
                _collectEskema(r, errors, key, message);
                return loop(index + 1);
              });
            }

            _collectEskema(res, errors, key, message);

            return loop(index + 1);
          }

          return loop(0);
        },
      );
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
  return eskema(schema) &
      Validator((value) {
        final map = value as Map<String, dynamic>;
        final unknownKeys = map.keys.where((key) => !schema.containsKey(key)).toList();

        if (unknownKeys.isEmpty) {
          return Result.valid(value);
        }

        return Result.invalid(
          value,
          expectations: [
            Expectation(
              message: message ?? 'has unknown keys: ${unknownKeys.join(', ')}',
              value: value,
              code: ExpectationCodes.structureUnknownKey,
              data: {'keys': unknownKeys},
            ),
          ],
        );
      });
}

/// Returns a Validator that checks a value against the eskema provided,
/// the eskema defines a validator for each item in the list
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
  return isType<List>() &
      listIsOfLength(eskema.length) &
      Validator((value) {
        final errors = <Expectation>[];

        FutureOr<Result> loop(int index) {
          if (index >= value.length) {
            return errors.isEmpty
                ? Result.valid(value)
                : Result.invalid(value, expectations: errors);
          }

          final item = value[index];
          final effectiveValidator = eskema[index];

          // Nullable short-circuit
          if (item == null && effectiveValidator.isNullable) {
            return loop(index + 1);
          }

          final res = effectiveValidator.validator(item);

          if (res is Future<Result>) {
            return res.then((r) {
              _collectListIndex(r, errors, index, null);
              return loop(index + 1);
            });
          }

          _collectListIndex(res, errors, index, null);

          return loop(index + 1);
        }

        return loop(0);
      });
}

/// Returns a Validator that runs [itemValidator] for each item in the list
///
/// This validator also checks that the value is a list
IValidator listEach(IValidator itemValidator, {String? message}) {
  return $isList &
      Validator((value) {
        final errors = <Expectation>[];
        FutureOr<Result> loop(int index) {
          if (index >= value.length) {
            return errors.isEmpty
                ? Result.valid(value)
                : Result.invalid(value, expectations: errors);
          }

          final item = value[index];

          if (item == null && itemValidator.isNullable) {
            return loop(index + 1);
          }

          final res = itemValidator.validator(item);

          if (res is Future<Result>) {
            return res.then((r) {
              _collectListIndex(r, errors, index, message);
              return loop(index + 1);
            });
          }

          _collectListIndex(res, errors, index, message);

          return loop(index + 1);
        }

        return loop(0);
      });
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
