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
  FutureOr<Result> eskemaPredicate(value) {
    final entries = mapEskema.entries.toList();
    return _loop(entries: entries, errors: [], value: value, index: 0, message: message);
  }

  return isMap() & Validator(eskemaPredicate);
}

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
FutureOr<Result> _loop({
  required List<MapEntry<String, IValidator>> entries,
  required List<Expectation> errors,
  required dynamic value,
  required int index,
  required String? message,
}) {
  if (index >= entries.length) {
    return errors.isEmpty ? Result.valid(value) : Result.invalid(value, expectations: errors);
  }

  final entry = entries[index];
  final key = entry.key;
  final validator = entry.value;
  final fieldValue = value[key];
  final exists = value.containsKey(key);

  FutureOr<Result> next() =>
      _loop(entries: entries, errors: errors, value: value, index: index + 1, message: message);

  FutureOr<Result> res;
  if (validator is IWhenValidator) {
    res = validator.validateWithParent(fieldValue, value, exists: exists);
  } else {
    // Reproduce nullable/optional short-circuit semantics that validate() provided.
    if (!exists) {
      if (validator.isOptional) {
        return next();
      }
      // For required field missing: validate with exists: false so nullable validators fail.
      final missingRes = validator.validate(null, exists: false);
      _collectEskema(missingRes, errors, key, message);
      return next();
    }

    if (!exists && validator.isOptional) {
      return next();
    }

    if (exists && fieldValue == null && validator.isNullable) {
      return next();
    }

    res = validator.validator(fieldValue);
  }

  if (res is Future<Result>) {
    return res.then((r) {
      _collectEskema(r, errors, key, message);
      return next();
    });
  }

  _collectEskema(res, errors, key, message);

  return next();
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
  FutureOr<Result> strictEskemaPredicate(value) {
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
  }

  return eskema(schema) & Validator(strictEskemaPredicate);
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
IValidator eskemaList(List<IValidator> eskema) {
  FutureOr<Result> listPredicate(value) {
    return _listLoop(
      value: value,
      getValidator: (index) => eskema[index],
      errors: [],
      index: 0,
    );
  }

  return isType<List>() & listIsOfLength(eskema.length) & Validator(listPredicate);
}

/// Returns a Validator that runs [itemValidator] for each item in the list
///
/// This validator also checks that the value is a list
IValidator listEach(IValidator itemValidator, {String? message}) {
  FutureOr<Result> listEachPredicate(value) {
    return _listLoop(
      value: value,
      getValidator: (_) => itemValidator,
      errors: [],
      index: 0,
      message: message,
    );
  }

  return $isList & Validator(listEachPredicate);
}

FutureOr<Result> _listLoop({
  required dynamic value,
  required IValidator Function(int) getValidator,
  required List<Expectation> errors,
  required int index,
  String? message,
}) {
  if (index >= value.length) {
    return errors.isEmpty ? Result.valid(value) : Result.invalid(value, expectations: errors);
  }

  final item = value[index];
  final validator = getValidator(index);

  if (item == null && validator.isNullable) {
    return _listLoop(
        value: value,
        getValidator: getValidator,
        errors: errors,
        index: index + 1,
        message: message);
  }

  final res = validator.validator(item);

  if (res is Future<Result>) {
    return res.then((r) {
      _collectListIndex(r, errors, index, message);
      return _listLoop(
          value: value,
          getValidator: getValidator,
          errors: errors,
          index: index + 1,
          message: message);
    });
  }

  _collectListIndex(res, errors, index, message);

  return _listLoop(
      value: value,
      getValidator: getValidator,
      errors: errors,
      index: index + 1,
      message: message);
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
