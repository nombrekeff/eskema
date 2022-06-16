// ignore_for_file: unused_local_variable, avoid_print

import 'package:eskema/eskema.dart';

final emailRegexp = RegExp(r"^[a-zA-Z0-9.a-zA-Z0-9.!#$%&'*+-/=?^_`{|}~]+@[a-zA-Z0-9]+\.[a-zA-Z]+");

void main() {
  final isEmail = stringMatchesPattern(emailRegexp, expectedMessage: 'a valid email address');

  final isAccount = eskema({
    'id': isType<int>(),
    'name': isType<String>(),
  });

  final isPurchase = eskema({
    'product_name': isType<String>(),
    'price': isType<double>(),
  });

  final userField = eskema({
    'username': isType<String>(),
    'email': nullable(isEmail),
    'age': isType<int>(),
    'accounts': listEach(isAccount),
    'purchases': nullable(
      listEach(isPurchase),
    ),
  });

  final invalidRes1 = userField({});
  print(invalidRes1.isValid); // should be false
  print(invalidRes1.expected); // should be "username -> String"

  final res1 = userField({
    'username': 'bob',
    'email': null,
    'age': 43,
    'accounts': [
      {'id': 123, 'name': 'account1'}
    ],
  });
  print(res1.isValid); // true
  print(res1.expected); // null

  final res2 = userField({
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
}
