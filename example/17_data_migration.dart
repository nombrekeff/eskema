import 'package:eskema/eskema.dart';

///
/// Real-world Example: Data Migration / Cleanup
///
/// This example demonstrates how to use transformers to clean up "dirty" data
/// during a migration or import process.
///
/// It demonstrates:
/// - Coercing strings to numbers (`toInt`).
/// - Trimming whitespace (`trim`).
/// - Providing default values (`defaultTo`).
/// - Validating a list of records.
///
void main() {
  print('--- Data Migration Example ---');

  // 1. Define Schema for a single record
  // We want to transform the input into a clean format.
  final recordSchema = eskema({
    // ID: Must be an integer. If it's a string " 123 ", convert it.
    'id': required(toInt(isGte(1))),

    // Name: Trim whitespace.
    'name': required(trim(isString() & not($isStringEmpty))),

    // Active: Convert "true"/"false" strings to boolean. Default to false if missing.
    'is_active': defaultTo(false, toBool(isBool())),

    // Tags: Ensure it's a list. If null, default to empty list.
    'tags': defaultTo([], isList()),
  });

  // 2. Define Dirty Data
  final rawRecords = [
    // Record 1: Clean
    {'id': 1, 'name': 'Alice', 'is_active': true, 'tags': ['admin']},
    
    // Record 2: Dirty (String ID, whitespace name, string boolean, null tags)
    {'id': ' 2 ', 'name': '  Bob  ', 'is_active': 'false', 'tags': null},
    
    // Record 3: Invalid (ID not a number)
    {'id': 'three', 'name': 'Charlie'},
  ];

  // 3. Validate and Transform
  print('\n--- Processing Records ---');
  
  for (var i = 0; i < rawRecords.length; i++) {
    final record = rawRecords[i];
    final result = recordSchema.validate(record);

    if (result.isValid) {
      print('Record ${i + 1}: Success');
      print('  Original: $record');
      print('  Cleaned:  ${result.value}');
    } else {
      print('Record ${i + 1}: Failed');
      print('  Original: $record');
      print('  Error:    ${result.expectations.first.message}');
    }
  }

  print('-' * 20);
}
