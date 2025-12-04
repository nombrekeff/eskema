import 'package:eskema/eskema.dart';

///
/// This example demonstrates how to use operators for concise validation composition.
///
/// Eskema provides operator overloads for common combinators:
/// - `&` (AND): Combines two validators where BOTH must pass. Equivalent to `all([...])`.
/// - `|` (OR): Combines two validators where AT LEAST ONE must pass. Equivalent to `any([...])`.
/// - `>` (Expectation): Attaches a custom error message to a validator.
///
void main() {
  print('--- Operator Examples ---');

  // 1. Define Validators using Operators
  print('\n--- 1. AND Operator (&) ---');
  // The `&` operator combines validators. Both must succeed.
  final usernameValidator = isString() & stringLength([isGt(3)]);

  print("Validating 'bob' (length > 3? NO): ${usernameValidator.validate('bob')}"); // Invalid
  print("Validating 'alice' (length > 3? YES): ${usernameValidator.validate('alice')}"); // Valid

  print('\n--- 2. OR Operator (|) ---');
  // The `|` operator allows for multiple valid possibilities.
  final roleValidator = isEq('admin') | isEq('editor');

  print("Validating 'admin': ${roleValidator.validate('admin')}"); // Valid
  print("Validating 'guest': ${roleValidator.validate('guest')}"); // Invalid

  print('\n--- 3. Custom Error Message (>) ---');
  // The `>` operator attaches a custom expectation (error message) to the validator.
  // This message is used if the validator fails.
  final ageValidator = (isInt() & isGte(18)) >
      const Expectation(message: 'Must be an adult (18+)');

  final result = ageValidator.validate(16);
  print('Validating 16: ${result.isValid}'); // false
  print('Error: ${result.expectations.first.message}'); // Must be an adult (18+)

  print('-' * 20);
}
