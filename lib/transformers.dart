/// ### Transformers
///
/// Value–coercion helpers that run BEFORE the provided `child` [validator].
/// They:
///  * Accept a broader set of input types (e.g. int / num / String for toInt)
///  * Produce a (possibly) transformed value
///  * Pass that value to the `child` [validator]
///
/// Failure model:
///  * The “pre‑check” part (e.g. `$isInt | $isNumber | $isIntString`) ensures
///    only plausible values reach the mapper. If that OR [validator] fails,
///    the chain stops there (no transform executed).
///  * The `transform(...)` function itself NEVER throws; it may return `null`.
///    If it returns `null`, the `child` [validator] receives `null` (and will
///    typically fail unless it is `nullable()`).
///
/// Composition patterns:
///  * Coerce then constrain:
///      final age = toInt(isGte(0) & isLte(130));
///  * Add null support after coercion:
///      final maybeDate = toDateTime(isType&lt;DateTime>()).nullable();
///  * Field extraction + transform:
///      final userAge = getField('age', toInt(isGte(18)));
///
/// Expectations:
///  * Each helper appends (via `> 'a valid DateTime formatted String'` etc.)
///    a human readable expectation for clearer error messages.
///
/// NOTE: These are “inline transformers” — they do not mutate external data,
/// only the value flowing through the validator pipeline.
library transformers;

import 'package:eskema/eskema.dart';

/// Transforms a value using a provided function.
///
/// The [fn] function is applied to the input value, and the result is then
/// passed to the [child] validator. This is a low-level building block for
/// creating custom transformers.
IValidator transform<T>(T Function(dynamic) fn, IValidator child) {
  return Validator((value) {
    return child.validate(fn(value));
  });
}

/// Coerces a value to an integer.
///
/// Handles existing integers, doubles (by truncating), and strings that can be
/// parsed as an integer.
/// Passes the resulting integer to the [child] validator.
IValidator toInt(IValidator child) =>
    ($isInt | $isNumber | $isIntString) &
    transform((v) {
      return switch (v) {
        final int n => n,
        final double n => n.toInt(),
        final String s => int.tryParse(s.trim()),
        _ => null,
      };
    }, child);

/// Coerces a value to a double.
///
/// Handles existing doubles, integers (by converting), and strings that can be
/// parsed as a double.
/// Passes the resulting double to the [child] validator.
IValidator toDouble(IValidator child) =>
    ($isDouble | $isNumber | $isDoubleString) &
    transform((v) {
      return switch (v) {
        final double i => i,
        final int i => i.toDouble(),
        final String s => double.tryParse(s.trim()),
        _ => null,
      };
    }, child);

/// Coerces a value to a number (`num`).
///
/// Handles existing numbers (`num`) and strings that can be parsed as a number.
/// Passes the resulting number to the [child] validator.
IValidator toNum(IValidator child) =>
    ($isNumber | $isNumString) &
    transform((value) {
      return switch (value) {
        final num n => n,
        final String s => num.tryParse(s.trim()),
        _ => null,
      };
    }, child);

/// Coerces a value to a boolean.
///
/// Handles existing booleans, the integers `1` and `0`, and the strings
/// `"true"` and `"false"`. The check is case-insensitive.
/// Passes the resulting boolean to the [child] validator.
IValidator toBool(IValidator child) {
  return ($isBool | isOneOf([0, 1]) | (toLowerCase(isString() & isOneOf(['true', 'false'])))) &
      transform((v) {
        return switch (v) {
          final bool b => b,
          final int i => i == 1,
          final String s => s.toLowerCase().trim() == 'true',
          _ => null,
        };
      }, child);
}

/// Trims leading and trailing whitespace from a string.
///
/// Fails if the input value is not a string.
/// Passes the trimmed string to the [child] validator.
IValidator trim(IValidator child) {
  return isString() & transform((v) => v.trim(), child);
}

/// Provides a default value if the input is `null`.
///
/// If the input value is `null`, it is replaced with [defaultValue]. Otherwise,
/// the original value is passed through.
/// Passes the resulting value to the [child] validator.
IValidator defaultTo(dynamic defaultValue, IValidator child) {
  return transform((v) => v ?? defaultValue, child);
}

/// Splits a string into a list of substrings.
///
/// Splits the input string at each occurrence of the [separator]. Fails if the
/// input value is not a string.
/// Passes the resulting list of strings to the [child] validator.
///
/// Example: `split(',', listEach(toInt(isGte(0))))`
IValidator split(String separator, IValidator child) {
  return isString() & transform((v) => v.split(separator), child);
}

/// Coerces a value to a `DateTime`.
///
/// Handles existing `DateTime` objects and strings that can be parsed as a
/// `DateTime`.
/// Passes the resulting `DateTime` to the [child] validator.
IValidator toDateTime(IValidator child) =>
    transform((value) {
      return switch (value) {
        final DateTime d => d,
        final String s => DateTime.tryParse(s.trim()),
        _ => null,
      };
    }, child) >
    Expectation(message: 'a valid DateTime formatted String');

/// Extracts and validates a field from a map.
///
/// Retrieves the value associated with the [key] from a map and passes it to
/// the [inner] validator. Fails if the input is not a map or if the key is
/// not present.
///
/// If you need to validate more than one field, consider using [eskema].
IValidator getField(String key, IValidator inner) =>
    isMap() &
    containsKey(key) &
    Validator((value) {
      final r = inner.validate(value[key]);
      if (r.isValid) return r;

      return Result.invalid(
        value,
        expectations: r.expectations
            .map((e) => Expectation(
                  message: e.message,
                  value: e.value,
                  path: '$key${e.path != null ? '.${e.path}' : ''}',
                ))
            .toList(),
      );
    });

/// Transforms a string to lowercase.
///
/// Fails if the input value is not a string.
/// Passes the lowercase string to the [child] validator.
IValidator toLowerCase(IValidator child) {
  return isString() & transform((v) => v.toLowerCase(), child);
}

/// Transforms a string to uppercase.
///
/// Fails if the input value is not a string.
/// Passes the uppercase string to the [child] validator.
IValidator toUpperCase(IValidator child) {
  return isString() & transform((v) => v.toUpperCase(), child);
}
