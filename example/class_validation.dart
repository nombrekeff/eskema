import 'package:eskema/eskema.dart';

class TestClassValidator extends EskMap {
  final name = EskField(
    id: 'name',
    validators: [
      isType<String>(),
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

class SettingsValidator extends EskMap {
  final theme = EskField(
    id: 'theme',
    validators: [
      isOneOf(Theme.values),
    ],
  );

  final notificationsEnabled = EskField(
    id: 'notificationsEnabled',
    nullable: true,
    validators: [
      isType<bool>(),
    ],
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
