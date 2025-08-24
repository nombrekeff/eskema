// ignore_for_file: unused_local_variable, avoid_print

import 'package:eskema/eskema.dart';

final emailRegexp =
    RegExp(r"^[a-zA-Z0-9.a-zA-Z0-9.!#$%&'*+-/=?^_`{|}~]+@[a-zA-Z0-9]+\.[a-zA-Z]+");

void main() {
  final isEmail = stringMatchesPattern(
    emailRegexp,
    error: 'a valid email address',
  );

  final accountEskema = eskema({
    // You can access some validators directly using the $ prefix (prefer for zero-arg validators)
    'id': $isInt,

    // or you can build the validator using the function
    'name': isString(),
  });

  final purchaseEskema = eskema({
    'product_name': $isString,
    'price': $isDouble,
  });

  final userEskema = eskema({
    'username': $isString,
    'age': $isInt,

    // Value can be null (if key is not present it's considered invalid — use `optional()` if you want to allow missing keys)
    'email': isEmail.nullable(),

    // you can keep it functional by using the `nullable` validator function
    'purchases': nullable(listEach(purchaseEskema)),

    // You can also use optional to allow missing keys, null, and empty strings
    'accounts': optional(listEach(accountEskema)),
  });

  // Validate user data and get a result
  final isUserValid2 = userEskema.validate({
    'username': 'bob',
    'email': null,
    'age': 43,
    'purchases': null,
    'accounts': [
      {'id': 123, 'name': 'account1'}
    ],
  });
  print(isUserValid2.isValid); // true

  // Check if the validator is valid or not
  final userResult = userEskema.validate({});
  print(userResult.isValid);     // should be false
  print(userResult.errors);      // [.username: String (value: null), .age: int (value: null), .email: String (value: null), .purchases: List<dynamic> (value: null)]
  print(userResult.description); // .username: String, .age: int, .email: String, .purchases: List<dynamic> (value: {})

  // You can also use the 'validate' extension method
  final mapData = {
    'username': 'bob',
    'email': null,
    'age': 43,
    'accounts': [
      {'id': 123, 'name': 'account1'}
    ],
  };

  mapData.validate(userEskema); // 
}
