import 'package:eskema/eskema.dart';

void main() {
  final $role = isOneOf(['admin', 'user']);
  final $username = all([isString(), not($isStringEmpty)]);
  final $status = isString() & isOneOf(['active', 'inactive', 'pending']);

  final $commonConfig = {
    'theme': isString(),
    'notifications': isBool(),
  };
  final $adminConfig = eskema({
    ...$commonConfig,
    'required_admin_setting': required(isString()),
  });
  final $userConfig = eskema({
    ...$commonConfig,
    'required_user_setting': required(isString()),
  });

  // ignore: body_might_complete_normally_nullable
  final $config = resolve((parent) {
    switch (parent['role']) {
      case 'admin':
        return $adminConfig;
      case 'user':
        return $userConfig;
    }
  });

  final userValidator = eskema({
    'role': $role,
    'username': $username,
    'status': $status,
    'config': $config,
  });

  // 1. Define some data to validate.
  final validData1 = {
    'role': 'admin',
    'username': 'john_doe',
    'status': 'active',
    'config': {'theme': 'dark', 'notifications': true, 'required_admin_setting': 'value'}
  };

  final validData2 = {
    'role': 'user',
    'username': 'test',
    'status': 'active',
    'config': {'theme': 'dark', 'notifications': true, 'required_user_setting': 'value'}
  };

  final invalidData1 = {
    'role': 'user',
    'username': 'test',
    'status': 'active',
    'config': {'theme': 'dark', 'notifications': true}
  };

  final invalidData2 = {
    'role': 'admin',
    'username': 'test',
    'status': 'active',
    'config': {'theme': 'dark', 'notifications': true}
  };

  final result1 = userValidator.validate(validData1);
  final result2 = userValidator.validate(validData2);
  final result3 = userValidator.validate(invalidData1);
  final result4 = userValidator.validate(invalidData2);

  print('1 >>> $result1');
  print('2 >>> $result2');
  print('3 >>> $result3');
  print('4 >>> $result4');
}
