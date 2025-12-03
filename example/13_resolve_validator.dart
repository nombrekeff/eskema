import 'package:eskema/eskema.dart';

///
/// This example demonstrates the `resolve` validator.
///
/// The `resolve` validator allows you to dynamically choose a validator based on
/// the value of other fields in the parent object. This is essential for
/// conditional validation logic where the schema depends on the data itself.
///
void main() {
  print('--- Resolve Validator Example ---');

  // 1. Define Schema
  final $role = isOneOf(['admin', 'user']);
  final $username = all([isString(), not($isStringEmpty)]);
  final $status = isString() & isOneOf(['active', 'inactive', 'pending']);

  final $commonConfig = {
    'theme': isString(),
    'notifications': isBool(),
  };

  // Schema for Admin users
  final $adminConfig = eskema({
    ...$commonConfig,
    'required_admin_setting': required(isString()),
  });

  // Schema for Standard users
  final $userConfig = eskema({
    ...$commonConfig,
    'required_user_setting': required(isString()),
  });

  // Dynamic validator for 'config' field
  // ignore: body_might_complete_normally_nullable
  final $config = resolve((parent) {
    // Check the 'role' field of the parent object
    switch (parent['role']) {
      case 'admin':
        return $adminConfig;
      case 'user':
        return $userConfig;
    }
    // If role is unknown or missing, we could return null (no validation)
    // or a validator that always fails.
  });

  final userValidator = eskema({
    'role': $role,
    'username': $username,
    'status': $status,
    'config': $config,
  });

  // 2. Define Data
  final validAdmin = {
    'role': 'admin',
    'username': 'john_doe',
    'status': 'active',
    'config': {'theme': 'dark', 'notifications': true, 'required_admin_setting': 'value'}
  };

  final validUser = {
    'role': 'user',
    'username': 'test',
    'status': 'active',
    'config': {'theme': 'dark', 'notifications': true, 'required_user_setting': 'value'}
  };

  final invalidUser = {
    'role': 'user',
    'username': 'test',
    'status': 'active',
    'config': {'theme': 'dark', 'notifications': true} // Missing required_user_setting
  };

  // 3. Validate
  print('\n--- Valid Admin ---');
  print('Result: ${userValidator.validate(validAdmin).isValid}'); // true

  print('\n--- Valid User ---');
  print('Result: ${userValidator.validate(validUser).isValid}'); // true

  print('\n--- Invalid User (Missing Config) ---');
  final result = userValidator.validate(invalidUser);
  print('Result: ${result.isValid}'); // false
  print('Errors: ${result.expectations.map((e) => e.message).join(', ')}');

  print('-' * 20);
}
