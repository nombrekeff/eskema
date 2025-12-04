import 'package:eskema/eskema.dart';

///
/// This example demonstrates Class-based Validation.
///
/// While Eskema is primarily functional, you can also define validators as classes
/// by extending `MapValidator`. This approach is useful for:
/// - Reusability across large projects.
/// - Encapsulating complex validation logic.
/// - Defining schemas that look more like model definitions.
///
void main() {
  print('--- Class-based Validation Example ---');

  // 1. Define Schema (using classes below)
  final testValidator = UserValidator();

  // 2. Define Data
  final validData = {
    'name': 'Test User',
    'settings': {
      'theme': Theme.dark,
      'notificationsEnabled': true,
    },
  };

  final invalidData = {
    'name': 123, // Invalid type
    'settings': {
      'theme': 'blue', // Invalid enum value
    },
  };

  // 3. Validate
  print('\n--- Valid Data ---');
  print('Result: ${testValidator.validate(validData).isValid}');

  print('\n--- Invalid Data ---');
  final result = testValidator.validate(invalidData);
  print('Result: ${result.isValid}');
  print('Errors:');
  for (final e in result.expectations) {
    print('  - ${e.path}: ${e.message}');
  }

  print('-' * 20);
}

// --- Class Definitions ---

class UserValidator extends MapValidator {
  final name = Field(
    id: 'name',
    validators: [
      $isString,
    ],
  );

  final settings = Field(
    id: 'settings',
    nullable: true,
    validators: [
      SettingsValidator(id: 'settings'),
    ],
  );

  @override
  List<Field> get fields => [name, settings];
}

enum Theme { light, dark }

class SettingsValidator extends MapValidator {
  final theme = Field(
    id: 'theme',
    validators: [
      isOneOf(Theme.values),
    ],
  );

  final notificationsEnabled = Field(
    id: 'notificationsEnabled',
    nullable: true,
    validators: [$isBool],
  );

  SettingsValidator({required super.id, super.nullable});

  @override
  List<Field> get fields => [theme, notificationsEnabled];
}
