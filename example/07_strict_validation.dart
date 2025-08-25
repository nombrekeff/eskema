import 'package:eskema/eskema.dart';

///
/// This example demonstrates the difference between `eskema` and `eskemaStrict`.
///
/// While `eskema` validates that a map contains the required keys with the correct
/// types, `eskemaStrict` does all of that AND ensures that no unknown keys are
/// present in the map.
///
void main() {
  print('--- Strict Validation ---');

  // --- 1. Standard `eskema` Validator ---
  // This validator only cares that 'username' and 'age' are present and valid.
  // It ignores any extra keys.
  final standardValidator = eskema({
    'username': isString(),
    'age': isInt(),
  });

  final mapWithExtraKeys = {
    'username': 'jane_doe',
    'age': 28,
    'email': 'jane@example.com', // This key is ignored by `eskema`.
  };

  print('\n--- Standard `eskema` ---');
  print(
      'Validating map with extra keys: ${standardValidator.validate(mapWithExtraKeys)}'); // Valid

  // --- 2. `eskemaStrict` Validator ---
  // This validator will fail if it finds any keys that are not defined in the schema.
  // This is useful for APIs where you want to reject requests with unknown fields.
  final strictValidator = eskemaStrict({
    'username': isString(),
    'age': isInt(),
  });

  final validMap = {
    'username': 'jane_doe',
    'age': 28,
  };

  print('\n--- `eskemaStrict` ---');
  print('Validating map with exact keys: ${strictValidator.validate(validMap)}'); // Valid
  print(
      'Validating map with extra keys: ${strictValidator.validate(mapWithExtraKeys)}'); // Invalid

  print('-' * 20);
}
