import 'package:eskema/eskema.dart';

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
IValidator eskema(Map<String, IValidator> eskema) {
  return isMap() &
      Validator((value) {
        final errors = <Expectation>[];

        for (final entry in eskema.entries) {
          final key = entry.key;
          final validator = entry.value;
          final fieldValue = value[key];

          final Result result;
          if (validator is IWhenValidator) {
            result = validator.validateWithParent(
              fieldValue,
              value,
              exists: value.containsKey(key),
            );
          } else {
            result = validator.validate(fieldValue, exists: value.containsKey(key));
          }

          if (!result.isValid) {
            for (var error in result.expectations) {
              errors.add(
                Expectation(
                  message: error.message,
                  value: error.value,
                  path: '.$key${error.path != null ? '${error.path}' : ''}',
                ),
              );
            }
          }
        }

        return errors.isEmpty
            ? Result.valid(value)
            : Result.invalid(value, expectations: errors);
      });
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
IValidator eskemaStrict(Map<String, IValidator> schema) {
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
            Expectation(message: 'has unknown keys: ${unknownKeys.join(', ')}', value: value)
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

        for (int index = 0; index < value.length; index++) {
          final item = value[index];
          final effectiveValidator = eskema[index];
          final result = effectiveValidator.validate(item);

          if (result.isNotValid) {
            for (var error in result.expectations) {
              errors.add(
                Expectation(
                  message: error.message,
                  value: error.value,
                  path: '[$index]${error.path != null ? '${error.path}' : ''}',
                ),
              );
            }
          }
        }

        return errors.isNotEmpty
            ? Result.invalid(value, expectations: errors)
            : Result.valid(value);
      });
}

/// Returns a Validator that runs [itemValidator] for each item in the list
///
/// This validator also checks that the value is a list
IValidator listEach(IValidator itemValidator) {
  return $isList &
      Validator((value) {
        final errors = <Expectation>[];
        for (int index = 0; index < value.length; index++) {
          final item = value[index];
          final result = itemValidator.validate(item);

          if (result.isNotValid) {
            for (var error in result.expectations) {
              errors.add(
                Expectation(
                  message: error.message,
                  value: error.value,
                  path: '[$index]${error.path != null ? '${error.path}' : ''}',
                ),
              );
            }
          }
        }

        return errors.isNotEmpty
            ? Result.invalid(value, expectations: errors)
            : Result.valid(value);
      });
}
