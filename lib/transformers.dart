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
import 'dart:convert' as convert;
import 'dart:core';

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

/// Adds an expectation message while preserving the child's resulting value
/// (useful for coercions where later constraints rely on the coerced type even on failure).
IValidator _expectPreserveValue(IValidator validator, Expectation expectation) =>
    Validator((value) {
      final r = validator.validate(value);
      if (r.isValid) return Result.valid(r.value);
      return Result.invalid(r.value,
          expectations: [expectation.copyWith(code: r.firstExpectation.code, value: r.value)]);
    });

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

/// Strict integer coercion.
///
/// Accepts only:
///  * Existing `int` values
///  * Strings that are pure base-10 integers (no sign handling beyond leading '-' / '+').
///
/// Rejects:
///  * `double` inputs (even if whole, e.g. `12.0`)
///  * Strings containing decimal points or exponent notation (e.g. `"12.0"`, `"1e3"`).
///
/// See also:
///  * [toInt] – standard (allows doubles and int-like strings)
///  * [toIntSafe] – strict + safe 53-bit range guard
IValidator toIntStrict(IValidator child) => _expectPreserveValue(
    ($isInt | $isIntString) &
        transform((v) {
          final converted = switch (v) {
            final int n => n,
            final String s => int.tryParse(s.trim()),
            _ => null,
          };
          return converted;
        }, child),
    Expectation(message: 'a value strictly convertible to an int'));

/// Safe integer coercion (strict + 53-bit range guard).
///
/// Behavior:
///  * Same accepted forms as [toIntStrict].
///  * Additionally validates that the resulting integer is within the safe
///    IEEE-754 53-bit signed range ([-9007199254740991, 9007199254740991]).
///    This is useful when code may target JavaScript runtimes where larger
///    integers lose precision.
///
/// Rejects any value outside that range.
///
/// See also:
///  * [toInt] – standard coercion (allows doubles)
///  * [toIntStrict] – strict without range guard
const int _kMaxSafeInt = 9007199254740991;
const int _kMinSafeInt = -9007199254740991;
IValidator toIntSafe(IValidator child) => toIntStrict(Validator((value) {
      if (value is int && value <= _kMaxSafeInt && value >= _kMinSafeInt) {
        return child.validate(value);
      }
      return Result.invalid(value,
          expectation: Expectation(
              message: 'a value strictly convertible to an int within safe 53-bit range',
              value: value));
    }));

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

/// Coerces a value to a boolean (standard mode).
///
/// Accepted inputs (case-insensitive):
///  * `bool` values (`true`, `false`)
///  * Integers: `1` => `true`, `0` => `false`
///  * Strings: `"true"`, `"false"`
///
/// This is intentionally stricter than [toBoolLenient] (which also accepts
/// yes/no, y/n, on/off, t/f, 1/0 string variants) while still allowing the
/// common numeric toggles via int type. Use [toBoolStrict] if you need ONLY
/// literal `true`/`false` (and bools) and want to reject 1/0 entirely.
///
/// See also:
///  * [toBoolStrict] – strict literal parsing only
///  * [toBoolLenient] – permissive parsing of many textual toggles
IValidator toBool(IValidator child) {
  return (($isBool | isOneOf([0, 1]) | toLowerCase(isString() & isOneOf(['true', 'false'])))) &
      transform((v) {
        return switch (v) {
          final bool b => b,
          final int i => i == 1,
          final String s => s.toLowerCase().trim() == 'true',
          _ => null,
        };
      }, child);
}

/// Strict bool coercion.
///
/// Only accepts:
///  * Actual `bool` values
///  * Strings `"true"` / `"false"` (case-insensitive)
///
/// Rejects numeric 1/0, yes/no, on/off, t/f, etc. Use [toBool] for a middle
/// ground (adds int 1/0) or [toBoolLenient] for broad textual support.
///
/// See also:
///  * [toBool] – standard (bool + 1/0 + 'true'/'false')
///  * [toBoolLenient] – very permissive variants
IValidator toBoolStrict(IValidator child) {
  return (($isBool | toLowerCase(isString() & isOneOf(['true', 'false'])))) &
          transform((v) {
            return switch (v) {
              final bool b => b,
              final String s => s.toLowerCase().trim() == 'true',
              _ => null,
            };
          }, child) >
      Expectation(message: 'a value strictly convertible to a bool');
}

/// Lenient / permissive bool coercion.
///
/// Accepts booleans, ints 1/0, and these case-insensitive string forms:
///  * true / false
///  * t / f
///  * yes / no
///  * y / n
///  * on / off
///  * 1 / 0
///
/// Use this when you need to ingest loosely formatted user input. Prefer
/// [toBool] or [toBoolStrict] for stricter validation where accidental typos
/// should fail fast.
///
/// See also:
///  * [toBool] – standard set
///  * [toBoolStrict] – only literal true/false (and bools)
IValidator toBoolLenient(IValidator child) {
  const trueSet = {'true', 't', 'yes', 'y', 'on', '1'};
  const falseSet = {'false', 'f', 'no', 'n', 'off', '0'};
  return (($isBool |
              isOneOf([0, 1]) |
              toLowerCase(
                isString() &
                    isOneOf([
                      'true',
                      'false',
                      't',
                      'f',
                      'yes',
                      'no',
                      'y',
                      'n',
                      'on',
                      'off',
                      '1',
                      '0'
                    ]),
              ))) &
          transform((v) {
            return switch (v) {
              final bool b => b,
              final int i => i == 1,
              final String s => () {
                  final lower = s.toLowerCase().trim();
                  if (trueSet.contains(lower)) return true;
                  if (falseSet.contains(lower)) return false;
                  return null;
                }(),
              _ => null,
            };
          }, child) >
      Expectation(message: 'a value leniently convertible to a bool');
}

IValidator toString(IValidator child) =>
    ($isString | $isNumber | $isBool | isType<DateTime>()) &
        transform((v) => v.toString(), child) >
    Expectation(message: 'a value convertible to a String');

/// String normalizer (no type pivot): trim leading/trailing whitespace.
IValidator trimString(IValidator child) => transform((v) => v is String ? v.trim() : v, child);

/// Collapse internal whitespace runs to a single space and trim ends.
IValidator collapseWhitespace(IValidator child) =>
    transform((v) => v is String ? v.replaceAll(RegExp(r'\s+'), ' ').trim() : v, child);

/// Lowercase string (ASCII-focused; leaves non-letters unchanged).
IValidator toLowerCaseString(IValidator child) =>
    transform((v) => v is String ? v.toLowerCase() : v, child);

/// Uppercase string.
IValidator toUpperCaseString(IValidator child) =>
    transform((v) => v is String ? v.toUpperCase() : v, child);

/// Basic Unicode punctuation normalization (subset) + trim.
IValidator normalizeUnicodeString(IValidator child) => transform((v) {
      if (v is! String) return v;
      const replacements = {
        '’': "'",
        '‘': "'",
        '“': '"',
        '”': '"',
        '–': '-',
        '—': '-',
        '‐': '-',
        '−': '-',
        '…': '...',
        '´': "'",
      };
      final buffer = StringBuffer();
      for (final ch in v.split('')) {
        buffer.write(replacements[ch] ?? ch);
      }
      return buffer.toString().trim();
    }, child);

/// Remove a common set of latin diacritics (quick map, not full Unicode NFD).
IValidator removeDiacriticsString(IValidator child) => transform((v) {
      if (v is! String) return v;
      const map = {
        'á': 'a',
        'à': 'a',
        'ä': 'a',
        'â': 'a',
        'ã': 'a',
        'å': 'a',
        'ā': 'a',
        'ą': 'a',
        'Á': 'A',
        'À': 'A',
        'Ä': 'A',
        'Â': 'A',
        'Ã': 'A',
        'Å': 'A',
        'Ā': 'A',
        'Ą': 'A',
        'é': 'e',
        'è': 'e',
        'ë': 'e',
        'ê': 'e',
        'ė': 'e',
        'ę': 'e',
        'ē': 'e',
        'É': 'E',
        'È': 'E',
        'Ë': 'E',
        'Ê': 'E',
        'Ė': 'E',
        'Ę': 'E',
        'Ē': 'E',
        'í': 'i',
        'ì': 'i',
        'ï': 'i',
        'î': 'i',
        'į': 'i',
        'ī': 'i',
        'Í': 'I',
        'Ì': 'I',
        'Ï': 'I',
        'Î': 'I',
        'Į': 'I',
        'Ī': 'I',
        'ó': 'o',
        'ò': 'o',
        'ö': 'o',
        'ô': 'o',
        'õ': 'o',
        'ø': 'o',
        'ō': 'o',
        'œ': 'oe',
        'Ó': 'O',
        'Ò': 'O',
        'Ö': 'O',
        'Ô': 'O',
        'Õ': 'O',
        'Ø': 'O',
        'Ō': 'O',
        'Œ': 'OE',
        'ú': 'u',
        'ù': 'u',
        'ü': 'u',
        'û': 'u',
        'ū': 'u',
        'Ú': 'U',
        'Ù': 'U',
        'Ü': 'U',
        'Û': 'U',
        'Ū': 'U',
        'ç': 'c',
        'ć': 'c',
        'Ç': 'C',
        'Ć': 'C',
        'ñ': 'n',
        'ń': 'n',
        'Ñ': 'N',
        'Ń': 'N',
        'ý': 'y',
        'ÿ': 'y',
        'Ý': 'Y',
        'Ÿ': 'Y',
        'ž': 'z',
        'ź': 'z',
        'Ž': 'Z',
        'Ź': 'Z',
        'ß': 'ss',
        'Æ': 'AE',
        'æ': 'ae'
      };
      final sb = StringBuffer();
      for (final ch in v.split('')) {
        sb.write(map[ch] ?? ch);
      }
      return sb.toString();
    }, child);

/// Slugify (lowercase, remove diacritics, replace non-alnum with '-', collapse dashes, trim edges)
IValidator slugifyString(IValidator child) => transform((v) {
      if (v is! String) return v;
      // remove diacritics using map above (duplicate minimal subset)
      const map = {
        'á': 'a',
        'à': 'a',
        'ä': 'a',
        'â': 'a',
        'ã': 'a',
        'å': 'a',
        'ā': 'a',
        'ą': 'a',
        'é': 'e',
        'è': 'e',
        'ë': 'e',
        'ê': 'e',
        'ė': 'e',
        'ę': 'e',
        'ē': 'e',
        'í': 'i',
        'ì': 'i',
        'ï': 'i',
        'î': 'i',
        'į': 'i',
        'ī': 'i',
        'ó': 'o',
        'ò': 'o',
        'ö': 'o',
        'ô': 'o',
        'õ': 'o',
        'ø': 'o',
        'ō': 'o',
        'œ': 'oe',
        'ú': 'u',
        'ù': 'u',
        'ü': 'u',
        'û': 'u',
        'ū': 'u',
        'ç': 'c',
        'ć': 'c',
        'ñ': 'n',
        'ń': 'n',
        'ý': 'y',
        'ÿ': 'y',
        'ž': 'z',
        'ź': 'z',
        'ß': 'ss',
        'Æ': 'ae',
        'æ': 'ae'
      };
      final sb = StringBuffer();
      for (final ch in v.toLowerCase().split('')) {
        sb.write(map[ch] ?? ch);
      }
      var slug = sb.toString();
      slug = slug.replaceAll(RegExp(r'[^a-z0-9]+'), '-');
      slug = slug.replaceAll(RegExp(r'-{2,}'), '-');
      slug = slug.replaceAll(RegExp(r'^-|-$'), '');
      return slug;
    }, child);

/// Strip HTML tags (simple, non-nested-aware sanitizer substitute)
IValidator stripHtmlString(IValidator child) =>
    transform((v) => v is String ? v.replaceAll(RegExp(r'<[^>]*>'), '') : v, child);

/// Coerces value to a BigInt.
IValidator toBigInt(IValidator child) =>
    (isType<BigInt>() | $isInt | $isIntString) &
        transform((v) {
          return switch (v) {
            final BigInt b => b,
            final int i => BigInt.from(i),
            final String s => BigInt.tryParse(s.trim()),
            _ => null,
          };
        }, child) >
    Expectation(message: 'a value convertible to a BigInt');

/// Coerces value to a Uri.
IValidator toUri(IValidator child) =>
    (isType<Uri>() | $isString) &
    transform((v) {
      return switch (v) {
        final Uri u => u,
        final String s => Uri.tryParse(s.trim()),
        _ => null,
      };
    }, Validator((val) {
      if (val is Uri && val.hasScheme) return Result.valid(val);
      return Result.invalid(val,
          expectation: Expectation(message: 'a value convertible to a Uri', value: val));
    })) &
    child;

/// Coerces value to a DateTime at midnight (date-only).
IValidator toDateOnly(IValidator child) =>
    (isType<DateTime>() | $isString) &
    transform((v) {
      final DateTime? dt = switch (v) {
        final DateTime d => d,
        final String s => DateTime.tryParse(s.trim()),
        _ => null,
      };
      if (dt == null) return null;
      // If original was a string with potential rollover (e.g. 2024-02-30 becomes 2024-03-01)
      // detect mismatch and treat as invalid.
      if (v is String) {
        final trimmed = v.trim();
        final expected =
            '${dt.year.toString().padLeft(4, '0')}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
        if (trimmed.length == 10 && trimmed.contains('-') && trimmed != expected) {
          return null; // trigger failure path
        }
      }
      return DateTime(dt.year, dt.month, dt.day);
    }, Validator((val) {
      if (val is DateTime) return Result.valid(val);
      return Result.invalid(val,
          expectation:
              Expectation(message: 'a value convertible to a Date (midnight)', value: val));
    })) &
    child;

/// Coerces a JSON string into its decoded form (Map/List). Leaves existing Map/List untouched.
IValidator toJsonDecoded(IValidator child) => Validator((value) {
      final mapped = switch (value) {
        final Map m => m,
        final List l => l,
        final String s => _tryJsonDecode(s),
        _ => null,
      };

      if (mapped is! Map && mapped is! List) {
        return Result.invalid(
          value,
          expectation: Expectation(
            message: 'a JSON decodable value (Map/List)',
            value: value,
          ),
        );
      }

      return child.validate(mapped);
    });

dynamic _tryJsonDecode(String s) {
  try {
    final decoded = convert.jsonDecode(s);
    return (decoded is Map || decoded is List) ? decoded : null;
  } catch (_) {
    return null;
  }
}

/// Picks a subset of keys from a Map, producing a new Map with only those keys present
/// (if they existed). Fails if input is not a Map.
IValidator pickKeys(Iterable<String> keys, IValidator child) => Validator((value) {
      if (value is! Map) {
        return Result.invalid(value,
            expectation: Expectation(
                message: 'a Map containing keys: ${keys.join(', ')}', value: value));
      }
      final out = <dynamic, dynamic>{};
      for (final k in keys) {
        if (value.containsKey(k)) out[k] = value[k];
      }
      final r = child.validate(out);
      if (r.isValid) return Result.valid(out);
      return r;
    });

/// Plucks a single key's value from a Map (similar to getField but transform style).
IValidator pluckKey(String key, IValidator child) => Validator((value) {
      if (value is! Map || !value.containsKey(key)) {
        return Result.invalid(
          value,
          expectation: Expectation(message: 'a Map containing key: $key', value: value),
        );
      }
      final extracted = value[key];
      return child.validate(extracted);
    });

/// Flattens a nested Map structure into a single-level Map using the provided [delimiter].
/// Only flattens nested Maps (non-Map values become leaves). Arrays/lists are left as-is.
IValidator flattenMapKeys(String delimiter, IValidator child) => Validator((value) {
      if (value is! Map) {
        return Result.invalid(value,
            expectation: Expectation(message: 'a Map flattable by keys', value: value));
      }
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
      final r = child.validate(flat);
      if (r.isValid) return Result.valid(flat);
      return r;
    });

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
