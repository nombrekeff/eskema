import 'dart:convert';

String pretifyValue(value) {
  if (value is Map) return json.encode(value);
  if (value is List) return json.encode(value);
  if (value is String) return '"$value"';

  return value.toString();
}
