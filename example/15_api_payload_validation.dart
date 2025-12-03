import 'package:eskema/eskema.dart';

///
/// Real-world Example: API Payload Validation (User Registration)
///
/// This example simulates validating a JSON payload for a user registration endpoint.
/// It demonstrates:
/// - Validating required fields.
/// - Email format validation.
/// - Password strength checks (using custom logic).
/// - Handling optional fields with defaults or constraints.
///
void main() {
  print('--- API Payload Validation Example ---');

  // 1. Define Schema
  final registrationSchema = eskema({
    // Username: Required, string, min length 3, max length 20
    'username': required(
      isString() & stringLength([isGte(3), isLte(20)]),
      message: 'Username is required and must be between 3 and 20 characters',
    ),

    // Email: Required, valid email format
    'email': required(
      isString() & isEmail(),
      message: 'A valid email address is required',
    ),

    // Password: Required, string, min length 8
    // We also add a custom check for "strength" (simulated here)
    'password': required(
      isString() & stringLength([isGte(8)]) & _isStrongPassword(),
      message: 'Password must be at least 8 characters and contain "!"',
    ),

    // Age: Optional, but if present must be int >= 18
    'age': optional(isInt() & isGte(18)),

    // Terms Accepted: Required, must be true
    'termsAccepted': required(
      isEq(true),
      message: 'You must accept the terms and conditions',
    ),
  });

  // 2. Define Data
  final validPayload = {
    'username': 'new_user',
    'email': 'user@example.com',
    'password': 'password123!', // Contains '!'
    'age': 25,
    'termsAccepted': true,
  };

  final invalidPayload = {
    'username': 'ab', // Too short
    'email': 'not-an-email',
    'password': 'weak', // Too short, no '!'
    // 'termsAccepted' is missing
  };

  // 3. Validate
  print('\n--- Valid Payload ---');
  final validRes = registrationSchema.validate(validPayload);
  if (validRes.isValid) {
    print('Registration allowed for: ${validRes.value['username']}');
  } else {
    print('Registration failed: ${validRes.detailed()}');
  }

  print('\n--- Invalid Payload ---');
  final invalidRes = registrationSchema.validate(invalidPayload);
  if (!invalidRes.isValid) {
    print('Registration failed with ${invalidRes.expectations.length} errors:');
    for (final e in invalidRes.expectations) {
      print('  - [${e.path}] ${e.message}');
    }
  }

  print('-' * 20);
}

// Custom validator helper for password strength
IValidator _isStrongPassword() {
  return validator(
    (val) => val is String && val.contains('!'),
    (val) => const Expectation(message: 'Password must contain "!"'),
  );
}
