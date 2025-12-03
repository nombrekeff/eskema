import 'package:eskema/eskema.dart';

///
/// This example demonstrates Polymorphic Validation using `switchBy`.
///
/// Polymorphic validation is used when the schema of an object depends on a
/// "discriminator" field. This is common in handling discriminated unions,
/// such as different types of events, user roles, or payment methods.
///
void main() {
  print('--- Polymorphic Validation Example ---');

  // 1. Define Schema
  // We switch on the 'type' field.
  final schema = switchBy('type', {
    // If type == 'business', use this schema:
    'business': eskema({
      'taxId': required(isString()) & stringLength([isGte(5)]),
    }),
    // If type == 'person', use this schema:
    'person': eskema({
      'name': required(isString() & stringLength([isGte(5)])),
    }),
  });

  // 2. Define Data
  final businessData = {'type': 'business', 'taxId': '123456789'};
  final personData = {'type': 'person', 'name': 'Alice Smith'};
  
  final invalidBusiness = {'type': 'business', 'taxId': '123'}; // Too short
  final unknownType = {'type': 'alien', 'planet': 'mars'};

  // 3. Validate
  print('\n--- Valid Business ---');
  print('Result: ${schema.validate(businessData).isValid}');

  print('\n--- Valid Person ---');
  print('Result: ${schema.validate(personData).isValid}');

  print('\n--- Invalid Business ---');
  final invalidRes = schema.validate(invalidBusiness);
  print('Result: ${invalidRes.isValid}');
  print('Error: ${invalidRes.expectations.first.message}');

  print('\n--- Unknown Type ---');
  final unknownRes = schema.validate(unknownType);
  print('Result: ${unknownRes.isValid}');
  print('Error: ${unknownRes.expectations.first.message}');

  print('-' * 20);
}
