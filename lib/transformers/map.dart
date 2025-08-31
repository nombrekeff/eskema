/// Map and structure transformers.
///
/// This file contains transformers for working with Map structures,
/// including picking keys, plucking values, and flattening nested maps.
library transformers.map;

import 'dart:async';

import 'package:eskema/eskema.dart';
import 'core.dart' as core;

/// Picks a subset of keys from a Map, producing a new Map with only those keys present
/// (if they existed). Fails if input is not a Map.
IValidator pickKeys(Iterable<String> keys, IValidator child, {String? message}) {
  return core.pivotValue(
    (value) {
      if (value is! Map) return null;

      final out = <dynamic, dynamic>{};

      for (final k in keys) {
        if (value.containsKey(k)) out[k] = value[k];
      }

      return out;
    },
    child: child,
    errorMessage: message ?? 'a Map containing keys: ${keys.join(', ')}',
  );
}

/// Plucks a single key's value from a Map (similar to getField but transform style).
IValidator pluckKey(String key, IValidator child, {String? message}) {
  return core.pivotValue(
    (value) {
      if (value is! Map || !value.containsKey(key)) return null;
      return value[key];
    },
    child: child,
    errorMessage: message ?? 'a Map containing key: $key',
  );
}

/// Flattens a nested Map structure into a single-level Map using the provided [delimiter].
/// Only flattens nested Maps (non-Map values become leaves). Arrays/lists are left as-is.
IValidator flattenMapKeys(String delimiter, IValidator child, {String? message}) {
  return core.pivotValue(
    (value) {
      if (value is! Map) return null;

      final Map<String, dynamic> flat = {};

      void walk(dynamic node, String prefix) {
        if (node is Map) {
          node.forEach((k, val) {
            final newPrefix = prefix.isEmpty ? '$k' : '$prefix$delimiter$k';
            if (val is Map) {
              walk(val, newPrefix);
            } else {
              flat[newPrefix] = val;
            }
          });
        } else {
          if (prefix.isNotEmpty) flat[prefix] = node;
        }
      }

      walk(value, '');

      return flat;
    },
    child: child,
    errorMessage: message ?? 'a Map flattable by keys',
  );
}

/// Extracts and validates a field from a map.
///
/// Retrieves the value associated with the [key] from a map and passes it to
/// the [inner] validator. Fails if the input is not a map or if the key is
/// not present.
///
/// If you need to validate more than one field, consider using [eskema].
IValidator getField(String key, IValidator inner) {
  FutureOr<Result> fieldPredicate(value) {
    final result = inner.validate(value[key]);
    if (result.isValid) return result;

    return Result.invalid(
      value,
      expectations: result.expectations
          .map(
            (e) => Expectation(
              message: e.message,
              value: e.value,
              path: '$key${e.path != null ? '.${e.path}' : ''}',
            ),
          ),
    );
  }

  return isMap() & containsKey(key) & Validator(fieldPredicate);
}
