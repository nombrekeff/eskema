// ignore_for_file: unused_local_variable, avoid_print

import 'package:eskema/eskema.dart';

final emailRegexp = RegExp(r"^[a-zA-Z0-9.a-zA-Z0-9.!#$%&'*+-/=?^_`{|}~]+@[a-zA-Z0-9]+\.[a-zA-Z]+");

void main() {
  final stringField = Field([isTypeString()]);
  final emailField = Field.nullable([
    stringMatchesPattern(emailRegexp, expectedMessage: 'a valid email address'),
  ]);
  final intField = Field([isTypeInt()]);
  final doubleField = Field([isTypeDouble()]);
  final numField = Field([isTypeNum()]);
  final boolField = Field([isTypeBool()]);

  final accountField = MapField({
    'id': intField,
    'name': stringField,
  });

  final purchaseField = MapField({
    'product_name': stringField,
    'price': doubleField,
  });

  final userField = MapField({
    'username': stringField,
    'email': emailField,
    'age': intField,
    'accounts': ListField(
      fieldValidator: accountField,
    ),
    'purchases': ListField.nullable(
      fieldValidator: purchaseField,
    ),
  });

  final invalidRes1 = userField.validate({});
  print(invalidRes1.isValid);
  print(invalidRes1.expected);

  final res1 = userField.validate({
    'username': 'bob',
    'email': null,
    'age': 43,
    'accounts': [
      {'id': 123, 'name': 'account1'}
    ],
  });
  print(res1.isValid);
  print(res1.expected);

  final res2 = userField.validate({
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
  print(res2.isValid);
  print(res2.expected);
}
