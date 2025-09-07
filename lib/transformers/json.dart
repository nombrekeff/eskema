/// JSON transformers.
///
/// This file contains transformers for working with JSON data.
library transformers.json;

import 'dart:convert' as convert;
import 'package:eskema/eskema.dart';

/// Coerces a JSON string into its decoded form (Map/List). Leaves existing Map/List untouched.
IValidator toJsonDecoded(IValidator child, {String? message}) {
  return Validator((value) {
    final mapped = switch (value) {
      final Map m => m,
      final List l => l,
      final String s => _tryJsonDecode(s),
      _ => null,
    };

    if (mapped is! Map && mapped is! List) {
      return Expectation(
        message: message ?? 'a JSON decodable value (Map/List)',
        value: value,
      ).toInvalidResult();
    }

    return child.validate(mapped);
  });
}

dynamic _tryJsonDecode(String s) {
  try {
    final decoded = convert.jsonDecode(s);
    return (decoded is Map || decoded is List) ? decoded : null;
  } catch (_) {
    return null;
  }
}
