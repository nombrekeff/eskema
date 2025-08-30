import 'package:eskema/eskema.dart';

///
/// This example demonstrates conditional validation using the `when` validator.
///
/// The `when` validator is powerful for scenarios where the validation rules for
/// one field depend on the value of another field within the same map.
///
void main() {
  // Imagine you have a form where the postal code format depends on the selected country.
  final addressValidator = eskema({
    'country': isOneOf(['USA', 'Canada']),

    // The `when` validator allows for conditional logic.
    'postal_code': when(
      // 1. Condition: This validator is run against the *parent map*.
      // Here, we check if the 'country' field is equal to 'USA'.
      getField('country', isEq('USA')),

      // 2. `then`: If the condition is true, this validator is applied to the
      // `postal_code` field.
      then: isString() & stringIsOfLength(5) >
          const Expectation(message: 'must be a 5-digit US zip code'),

      // 3. `otherwise`: If the condition is false, this validator is applied instead.
      otherwise: isString() & stringIsOfLength(6) >
          const Expectation(message: 'must be a 6-character Canadian postal code'),
    ),
  });

  print('--- Conditional Validation ---');

  // --- Success Cases ---

  final validUsaAddress = {'country': 'USA', 'postal_code': '90210'};
  print('USA Address (Valid): ${addressValidator.validate(validUsaAddress)}');

  final validCanadaAddress = {'country': 'Canada', 'postal_code': 'M5H2N2'};
  print('Canada Address (Valid): ${addressValidator.validate(validCanadaAddress)}');

  // --- Failure Cases ---

  // The postal code does not match the format for 'USA'.
  final invalidUsaAddress = {'country': 'USA', 'postal_code': 'M5H2N2'};
  print('USA Address (Invalid): ${addressValidator.validate(invalidUsaAddress)}');

  // The postal code does not match the format for 'Canada'.
  final invalidCanadaAddress = {'country': 'Canada', 'postal_code': '90210'};
  print('Canada Address (Invalid): ${addressValidator.validate(invalidCanadaAddress)}');

  print('-' * 20);
}
