import 'package:eskema/eskema.dart';

///
/// This example demonstrates the basic features of Eskema, including:
/// - Creating a schema validator with `eskema`.
/// - Using built-in type and comparison validators.
/// - Combining validators with the `&` (AND) and `|` (OR) operators.
/// - Handling validation results.
///
void main() {
  // 1. Define a schema for a user map.
  // The `eskema` validator takes a map where each key corresponds to a field
  // in the data you want to validate, and the value is another validator.
  final userValidator = eskema({
    // For the 'username' field, we require it to be a string AND not empty.
    // The `&` operator chains validators together in a logical AND.
    'username': all([isString(), not($isStringEmpty)]),

    // For 'age', it must be an integer AND greater than or equal to 0.
    'age': isInt() & isGte(0, message: 'All validators can specify a custom message!'),

    // For 'status', the value must be one of the strings in the provided list.
    'status': isString() & isOneOf(['active', 'inactive', 'pending']),

    // For 'role', the value can be either 'admin' OR 'user'.
    // The `|` operator chains validators in a logical OR.
    'role': isEq('admin') | isEq('user'),
  });

  // 2. Define some data to validate.
  final validUser = {
    'username': 'john_doe',
    'age': 30,
    'status': 'active',
    'role': 'admin',
  };

  final invalidUser = {
    'username': '', // Fails `isNotEmpty`
    'age': -5, // Fails `isGte(0)`
    'status': 'archived', // Fails `isIn`
    'role': 'guest', // Fails both `isEq` checks
  };

  // --- Validation Success Case ---

  // 3. Validate the correct data.
  final validResult = userValidator.validate(validUser);

  print('--- Basic Validation: Success Case ---');
  print('Is valid: ${validResult.isValid}'); // true
  print('Value: ${validResult.value}');
  print('Expectations: ${validResult.expectations}'); // Empty list
  print('-' * 20);

  // --- Validation Failure Case ---

  // 4. Validate the incorrect data to see the errors.
  final invalidResult = userValidator.validate(invalidUser);

  print('--- Basic Validation: Failure Case ---');
  print('Is valid: ${invalidResult.isValid}'); // false
  print('Value: ${invalidResult.value}');

  // The `expectations` list now contains detailed error messages for each
  // field that failed validation.
  print('Expectations:');
  for (final expectation in invalidResult.expectations) {
    print('  - ${expectation.path}: ${expectation.message}');
  }
  //  - username: String to be not empty
  //  - age: greater than or equal to 0
  //  - status: one of: ["active", "inactive", "pending"]
  //  - role: equal to "admin"
  //  - role: equal to "user"
  // NOTE: Using the `|` operator internally leverages `any()`. When a value fails
  // all OR branches, you get an expectation per branch (both shown above).
  print('-' * 20);
}
