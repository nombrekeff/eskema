import 'package:eskema/eskema.dart';

///
/// This example demonstrates how to validate lists in different ways.
///
void main() {
  print('--- List Validation ---');

  // --- 1. `listEach`: Validating Each Item Uniformly ---
  // Use `listEach` when every item in the list must conform to the same validator.
  print('\n--- `listEach` Example ---');
  final positiveIntListValidator = isList() & every(isInt() & isGte(0));

  final validInts = [1, 2, 3, 10];
  final invalidInts = [1, -2, 3];

  print('Validating $validInts: ${positiveIntListValidator.validate(validInts)}'); // Valid
  print(
      'Validating $invalidInts: ${positiveIntListValidator.validate(invalidInts)}'); // Invalid

  // --- 2. `eskemaList`: Validating a Heterogeneous List ---
  // Use `eskemaList` when the list has a fixed structure with different types
  // at different positions (like a tuple).
  print('\n--- `eskemaList` Example ---');
  final tupleValidator = eskemaList([
    isString(), // The first item must be a String.
    isInt(), // The second item must be an int.
    isBool(), // The third item must be a bool.
  ]);

  final validTuple = ['user_profile', 123, true];
    final invalidTuple = ['user_profile', '123', true]; // '123' is not an int (second position fails)

  print('Validating $validTuple: ${tupleValidator.validate(validTuple)}'); // Valid
  print(
      'Validating $invalidTuple: ${tupleValidator.validate(invalidTuple)}'); // Invalid

  // --- 3. `listIsOfLength` and `contains`: Other List Checks ---
  // You can also validate the properties of the list itself.
  print('\n--- Other List Checks ---');
  final listPropertiesValidator = isList() &
      listIsOfLength(3) &
      listContains('admin');

  final validList = ['guest', 'user', 'admin'];
  final invalidList = ['guest', 'user']; // Fails length and contains checks.

  print(
      'Validating $validList: ${listPropertiesValidator.validate(validList)}'); // Valid
    print(
            'Validating $invalidList: ${listPropertiesValidator.validate(invalidList)}'); // Invalid (fails length & contains)

  print('-' * 20);
}
