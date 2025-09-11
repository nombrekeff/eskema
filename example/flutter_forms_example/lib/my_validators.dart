import 'package:eskema/validators/string.dart';

final $containsLowercase = stringMatches(
  RegExp(r'[a-z]'),
  message: "Must contain lowercase letters",
);
final $containsUppercase = stringMatches(
  RegExp(r'[A-Z]'),
  message: "Must  contain uppercase letters",
);
final $containsNumber = stringMatches(
  RegExp(r'[0-9]'),
  message: "Must contain numbers",
);
final $containsSpecialChar = stringMatches(
  RegExp(r'[^A-Za-z0-9]'),
  message: "Must contain special characters",
);
