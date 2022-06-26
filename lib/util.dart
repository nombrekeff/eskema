import 'dart:convert';

import 'result.dart';

String pretifyValue(value) {
  if (value is Map) return json.encode(value);
  if (value is List) return json.encode(value);
  if (value is String) return '"$value"';

  return value.toString();
}

class ValidatorFailedException implements Exception {
  String get message => result.toString();
  IResult result;
  ValidatorFailedException(this.result);
}
