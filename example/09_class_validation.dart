import 'package:eskema/eskema.dart';

class TestClassValidator extends MapValidator {
  final name = Field(
    id: 'name',
    validators: [
      $isString,
    ],
  );

  final settings = SettingsValidator(
    id: 'settings',
    nullable: true,
  );

  @override
  get fields => [name, settings];
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
  get fields => [theme, notificationsEnabled];
}

void main() {
  final testValidator = TestClassValidator();
  final mapValid = testValidator.validate({
    'name': 'Test',
    'settings': {
      'theme': Theme.dark,
      // 'notificationsEnabled': true,
    },
  });

  print(mapValid);
}
