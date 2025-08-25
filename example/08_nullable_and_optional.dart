import 'package:eskema/eskema.dart';

///
/// This example clarifies the important distinction between `nullable` and `optional`.
///
/// This is most relevant when validating fields within a map using `eskema`.
///
void main() {
  final validator = eskema({
    // --- 1. `nullable()` ---
    // The key 'required_but_nullable' MUST be present in the map.
    // However, its value is allowed to be `null`.
    'required_but_nullable': isString().nullable(),

    // --- 2. `optional()` ---
    // The key 'optional_and_not_nullable' MAY be missing from the map.
    // If it IS present, its value must be a non-null string.
    'optional_and_not_nullable': isString().optional(),

    // --- 3. Chaining `nullable()` and `optional()` ---
    // The key 'optional_and_nullable' MAY be missing.
    // If it IS present, its value can be either a string OR `null`.
    'optional_and_nullable': isString().nullable().optional(),
  });

  print('--- Nullable vs. Optional ---');

  // --- `nullable()` Behavior ---
  print('\n--- Testing `required_but_nullable` ---');
  // Valid: Key is present, value is null.
  print("Validating {'required_but_nullable': null}: ${validator.validate({
        'required_but_nullable': null
      })}");
  // Invalid: Key is missing.
  print("Validating {}: ${validator.validate({})}");

  // --- `optional()` Behavior ---
  print('\n--- Testing `optional_and_not_nullable` ---');
  // Valid: Key is present with a valid value.
  print(
      "Validating {'optional_and_not_nullable': 'hello'}: ${validator.validate({
        'optional_and_not_nullable': 'hello'
      })}");
  // Valid: Key is missing.
  print("Validating {}: ${validator.validate({})}");
  // Invalid: Key is present, but value is null.
  print(
      "Validating {'optional_and_not_nullable': null}: ${validator.validate({
        'optional_and_not_nullable': null
      })}");

  // --- Chained Behavior ---
  print('\n--- Testing `optional_and_nullable` ---');
  // Valid: Key is present with a valid value.
  print("Validating {'optional_and_nullable': 'hello'}: ${validator.validate({
        'optional_and_nullable': 'hello'
      })}");
  // Valid: Key is present, value is null.
  print("Validating {'optional_and_nullable': null}: ${validator.validate({
        'optional_and_nullable': null
      })}");
  // Valid: Key is missing.
  print("Validating {}: ${validator.validate({})}");

  print('-' * 20);
}
