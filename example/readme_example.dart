import 'package:eskema/eskema.dart';

void main() {
  final userValidator = eskema({
    // use built-in validator funtions
    'username': isString(),

    // Some zero-arg validators also have aliases: e.g. `$isBool`, `$isString` - prefer for zero-arg validators
    'lastname': $isString,

    // Combine validators using `all`, `any` and `none`
    'age': all([isInt(), isGte(0)]),

    // or use operators for simplicity, same as using `all`, `any` and `none`, but shorter!!
    'theme': (isString() & (isEq('light') | isEq('dark'))),

    // Make validators nullable, if the field is missing it's considered invalid, use `optional` instead
    // This will be valid if 'premium' exists in the map and is null or returns the result of the child validator
    'premium': nullable($isBool),

    // If you want to allow the field to not exist in the map, and accept null or empty strings
    // You can use the `optional` validator
    'birthday': optional(isDate()),
  });

  final ok = userValidator.validate({
    'username': 'bob',
    'lastname': 'builder',
    'theme': 'light',
    'age': 42,
  });
  print("User is valid: $ok");

  final res = userValidator.validate({
    'username': 'alice',
    'age': -1,
  });
  print(res); // false - "Expected age -> greater than or equal to 0, got -1"
}
