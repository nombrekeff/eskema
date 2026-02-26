import 'package:eskema/eskema.dart';

class TestClassValidator extends MapValidator {
  final Field nameField = Field(
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
  List<IdValidator> get fields => [nameField, settings];
}

enum Theme { light, dark }

class SettingsValidator extends MapValidator {
  final Field theme = Field(
    id: 'theme',
    validators: [
      isOneOf(Theme.values),
    ],
  );

  final Field notificationsEnabled = Field(
    id: 'notificationsEnabled',
    nullable: true,
    validators: [$isBool],
  );

  SettingsValidator({required super.id, super.nullable});

  @override
  List<IdValidator> get fields => [theme, notificationsEnabled];
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
