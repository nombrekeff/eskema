import 'package:eskema/eskema.dart';

void main() {
  final userValidator = eskema({
    'username': isString(),

    // Combine validators using `all` and `any`
    'age': all([isInteger(), isGte(0)]),

    // or use operators for simplicity:
    'theme': (isString() & (isEq('light') | isEq('dark'))).nullable(),

    // Some zero-arg validators also have canonical aliases: e.g. `$isBoolean`, `$isString`
    'premium': nullable($isBoolean),

    // Make a validator nullable
    'email': stringMatchesPattern(
      RegExp(r"^[^@\s]+@[^@\s]+\.[^@\s]+$"),
      expectedMessage: 'a valid email address',
    ).nullable(),
  });

  final ok = userValidator.validate({
    'username': 'bob',
    'age': 42,
  });
  print("User is valid: $ok");

  final res = userValidator.validate({
    'username': 'alice',
    'age': -1,
  });
  print(res); // false - "Expected age -> greater than or equal to 0, got -1"
}
