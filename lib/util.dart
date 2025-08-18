import 'dart:convert';

import 'result.dart';

String pretifyValue(value) {
  try {
    if (value is Map) return json.encode(value);
    if (value is List) return json.encode(value);
    if (value is String) return '"$value"';
  } catch (_) {}

  return value.toString();
}

class ValidatorFailedException implements Exception {
  String get message => result.toString();
  EskResult result;
  ValidatorFailedException(this.result);
}
