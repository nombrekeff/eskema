// ignore_for_file: unused_local_variable, avoid_print

import 'package:eskema/eskema.dart';
import 'package:eskema/extensions.dart';

final emailRegexp = RegExp(
    r"^[a-zA-Z0-9.a-zA-Z0-9.!#$%&'*+-/=?^_`{|}~]+@[a-zA-Z0-9]+\.[a-zA-Z]+");

void main() {
  final isEmail = stringMatchesPattern(
    emailRegexp,
    expectedMessage: 'a valid email address',
  );

  final accountEskema = eskema({
    // You can access some validators directly using the $ prefix
    'id': $isInteger,

    // or you can build the validator using the function
    'name': isString(),
  });

  final purchaseEskema = eskema({
    'product_name': $isString,
    'price': $isDouble,
  });

  final userEskema = eskema({
    'username': $isString,
    'age': $isInteger,
    // Nullable fields can be defined using the copyWith method
    'accounts': listEach(accountEskema).copyWith(nullable: true),
    // by using the orNullable method
    'email': isEmail.nullable(),
    // or by using the nullable validator
    'purchases': nullable(listEach(purchaseEskema)),
  });

  final isUserValid1 = userEskema.isValid({});
  print(isUserValid1); // should be false

  final isUserValid2 = userEskema.validate({
    'username': 'bob',
    'email': null,
    'age': 43,
    'accounts': [
      {'id': 123, 'name': 'account1'}
    ],
  });
  print(isUserValid2.isValid); // true
  print(isUserValid2.expected); // null

  final res2 = userEskema.validate({
    'username': 'bob',
    'email': null,
    'age': 43,
    'accounts': [
      {'id': 123, 'name': 'account1'}
    ],
    'purchases': [
      {'product_name': 'beer', 'price': 2.50}
    ],
  });
  print(res2.isValid); // true
  print(res2.expected); // null

  final mapData = {
    'username': 'bob',
    'email': null,
    'age': 43,
    'accounts': [
      {'id': 123, 'name': 'account1'}
    ],
  };

  mapData.validate(userEskema);
}
