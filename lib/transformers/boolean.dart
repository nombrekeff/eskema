/// Boolean type transformers.
///
/// This file contains transformers for converting values to boolean types
/// with different levels of permissiveness.
library transformers.boolean;

import 'package:eskema/eskema.dart';
import 'core.dart' as core;

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
IValidator toBool(IValidator child, {String? message}) {
  final validator =
      (($isBool | isOneOf([0, 1]) | toLowerCase(isString() & isOneOf(['true', 'false'])))) &
          core.transform((v) {
            return switch (v) {
              final bool b => b,
              final int i => i == 1,
              final String s => s.toLowerCase().trim() == 'true',
              _ => null,
            };
          }, child);

  return handleReturnPreserveValue(validator, message);
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
IValidator toBoolStrict(IValidator child, {String? message}) {
  final validator = (($isBool | toLowerCase(isString() & isOneOf(['true', 'false'])))) &
      core.transform((v) {
        return switch (v) {
          final bool b => b,
          final String s => s.toLowerCase().trim() == 'true',
          _ => null,
        };
      }, child);

  return handleReturnPreserveValue(validator, message);
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
IValidator toBoolLenient(IValidator child, {String? message}) {
  const trueSet = {'true', 't', 'yes', 'y', 'on', '1'};
  const falseSet = {'false', 'f', 'no', 'n', 'off', '0'};
  final $stringBoolMatcher = ($isBool |
      isOneOf([0, 1]) |
      toLowerCase(
        isString() &
            isOneOf(['true', 'false', 't', 'f', 'yes', 'no', 'y', 'n', 'on', 'off', '1', '0']),
      ));
  final transformToBool = core.transform(
    (v) {
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
    },
    child,
  );

  final validator = $stringBoolMatcher & transformToBool;

  return handleReturnPreserveValue(validator, message);
}
