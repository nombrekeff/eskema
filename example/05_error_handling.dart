import 'package:eskema/eskema.dart';

///
/// This example covers different ways to handle validation failures.
///
/// By default, `.validate()` returns a `Result` object, but you can also
/// get a simple boolean or have the validator throw an exception on failure.
///
void main() {
  final validator = isString() & not($isStringEmpty);

  // --- 1. Using the `Result` Object (Default) ---
  // This is the most flexible approach. The `Result` object gives you access
  // to the validity status, the original value, and a list of expectations (errors).
  print('--- Handling Failures with `Result` Object ---');
  final result = validator.validate('');
  if (!result.isValid) {
    print('Validation failed!');
    print('Errors: ${result.expectations}');
  }
  print('-' * 20);

  // --- 2. Using `isValid` for a Boolean Check ---
  // If you only need to know whether the validation passed or failed,
  // `.isValid()` is a convenient shortcut.
  print('--- Handling Failures with `isValid` ---');
  if (!validator.isValid('')) {
    print('The value is invalid (checked with isValid).');
  }
  print('-' * 20);

  // --- 3. Using `validateOrThrow` for Exceptions ---
  // In some application architectures, you might prefer to handle errors
  // with a try-catch block. `validateOrThrow` will throw a
  // `ValidatorFailedException` if validation fails.
  print('--- Handling Failures with `validateOrThrow` ---');
  try {
    validator.validateOrThrow('');
  } on ValidatorFailedException catch (e) {
    print('Caught a ValidatorFailedException!');
    print('Exception details: $e');
  }
  print('-' * 20);
}
