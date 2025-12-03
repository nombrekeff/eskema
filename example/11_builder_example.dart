import 'package:eskema/eskema.dart';

///
/// This example demonstrates the Builder API.
///
/// The Builder API provides a fluent interface for constructing schemas.
/// It mirrors the functional API but allows for method chaining, which some
/// developers find more readable, especially for complex nested structures.
///
void main() {
  print('--- Builder API Example ---');

  // 1. Define Schema using Builder
  // Start with `v()` (alias for `builder()`) and chain methods.
  final userSchema = $map().schema({
    // .string() -> ensures it's a string
    // .trim() -> transformer: trims whitespace
    // .not.empty() -> validator: string must not be empty
    'name': $string().trim().not.empty().build(),

    // .email() -> validator: must be a valid email format
    'email': $string().email().build(),

    // .int_() -> ensures it's an int
    // .gte(18) -> validator: must be >= 18
    // .optional() -> field is not required
    'age': $int().gte(18).optional().build(),
  }).build();

  // 2. Define Data
  final validUser = {
    'name': '  John Doe  ', // Will be trimmed
    'email': 'john@example.com',
    'age': 25,
  };

  final invalidUser = {
    'name': '', // Empty
    'email': 'not-an-email',
    'age': 16, // Too young
  };

  // 3. Validate
  print('\n--- Valid User ---');
  final validResult = userSchema.validate(validUser);
  print('Is Valid: ${validResult.isValid}');
  print('Cleaned Data: ${validResult.value}'); // Name is trimmed

  print('\n--- Invalid User ---');
  final invalidResult = userSchema.validate(invalidUser);
  print('Is Valid: ${invalidResult.isValid}');
  print('Errors:');
  for (final e in invalidResult.expectations) {
    print('  - ${e.path}: ${e.message}');
  }

  print('-' * 20);
}
