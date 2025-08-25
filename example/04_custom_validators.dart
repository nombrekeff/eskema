import 'package:eskema/eskema.dart';

///
/// This example shows how to create your own custom validators.
///
/// While Eskema provides a rich set of built-in validators, you will often
/// need to create domain-specific validators. There are three main ways to do this.
///
void main() {
  print('--- Custom Validators ---');

  // --- 1. By Composition ---
  // This is the easiest way. Combine existing validators to create a new one.
  print('\nMethod 1: By Composition');
  IValidator isPositiveInt() => isInt() & isGte(0);

  final composedValidator = isPositiveInt();
  print('Validating 10 with composed validator: ${composedValidator.validate(10)}'); // Valid
  print(
      'Validating -5 with composed validator: ${composedValidator.validate(-5)}'); // Invalid

  // --- 2. With the `validator` Helper ---
  // For more complex logic, use the `validator` helper function. It takes a
  // comparison function and an error-generating function.
  print('\nMethod 2: Using the `validator` helper');
  IValidator isDivisibleBy(int n) {
    return validator(
      // The first function returns `true` if the value is valid.
      (value) => value is int && value % n == 0,
      // The second function returns an `Expectation` for the error message.
      (value) => Expectation(message: 'must be divisible by $n', value: value),
    );
  }

  final divisibleBy3 = isDivisibleBy(3);
  print('Validating 9 with helper: ${divisibleBy3.validate(9)}'); // Valid
  print('Validating 10 with helper: ${divisibleBy3.validate(10)}'); // Invalid

  // --- 3. With a Custom Class ---
  // For the most complex scenarios, you can extend the `Validator` class.
  // This is useful when your validator has its own configuration or state.
  print('\nMethod 3: With a custom class');

  final startsWithId = HasPrefixValidator('id_');
  print(
      "Validating 'id_123' with custom class: ${startsWithId.validate('id_123')}"); // Valid
  print(
      "Validating 'user_123' with custom class: ${startsWithId.validate('user_123')}"); // Invalid

  print('-' * 20);
}

class HasPrefixValidator extends Validator {
  final String prefix;

  HasPrefixValidator(this.prefix)
      : super(
          (value) {
            if (value is String && value.startsWith(prefix)) {
              return Result.valid(value);
            }
            return Result.invalid(
              value,
              expectations: [
                Expectation(message: 'must start with "$prefix"', value: value)
              ],
            );
          },
        );
}
