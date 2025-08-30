/// Number type transformers.
///
/// This file contains transformers for converting values to various numeric types
/// including integers, doubles, numbers, and BigInts.
library transformers.number;

import 'package:eskema/eskema.dart';
import 'core.dart' as core;

/// Coerces a value to an integer.
///
/// Handles existing integers, doubles (by truncating), and strings that can be
/// parsed as an integer.
/// Passes the resulting integer to the [child] validator.
IValidator toInt(IValidator child, {String? message}) {
  final base = ($isInt | $isNumber | $isIntString) &
      core.transform((v) {
        return switch (v) {
          final int n => n,
          final double n => n.toInt(),
          final String s => int.tryParse(s.trim()),
          _ => null,
        };
      }, child);
  return message != null ? core.expectPreserveValue(base, Expectation(message: message)) : base;
}

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
IValidator toIntStrict(IValidator child, {String? message}) {
  final base = ($isInt | $isIntString) &
      core.transform((v) {
        final converted = switch (v) {
          final int n => n,
          final String s => int.tryParse(s.trim()),
          _ => null,
        };
        return converted;
      }, child);
  return message != null ? core.expectPreserveValue(base, Expectation(message: message)) : base;
}

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
IValidator toIntSafe(IValidator child, {String? message}) {
  final strict = toIntStrict(Validator((value) {
    if (value is int && value <= _kMaxSafeInt && value >= _kMinSafeInt) {
      return child.validate(value);
    }

    return Result.invalid(
      value,
      expectation: Expectation(
        message: 'a value strictly convertible to an int within safe 53-bit range',
        value: value,
      ),
    );
  }));

  if (message != null) {
    return core.expectPreserveValue(strict, Expectation(message: message));
  }

  return strict;
}

/// Coerces a value to a double.
///
/// Handles existing doubles, integers (by converting), and strings that can be
/// parsed as a double.
/// Passes the resulting double to the [child] validator.
IValidator toDouble(IValidator child, {String? message}) {
  final base = ($isDouble | $isNumber | $isDoubleString) &
      core.transform((v) {
        return switch (v) {
          final double i => i,
          final int i => i.toDouble(),
          final String s => double.tryParse(s.trim()),
          _ => null,
        };
      }, child);
  return message != null ? core.expectPreserveValue(base, Expectation(message: message)) : base;
}

/// Coerces a value to a number (`num`).
///
/// Handles existing numbers (`num`) and strings that can be parsed as a number.
/// Passes the resulting number to the [child] validator.
IValidator toNum(IValidator child, {String? message}) {
  final base = ($isNumber | $isNumString) &
      core.transform((value) {
        return switch (value) {
          final num n => n,
          final String s => num.tryParse(s.trim()),
          _ => null,
        };
      }, child);
  return message != null ? core.expectPreserveValue(base, Expectation(message: message)) : base;
}

/// Coerces value to a BigInt.
IValidator toBigInt(IValidator child, {String? message}) {
  final base = (isType<BigInt>() | $isInt | $isIntString) &
      core.transform((v) {
        return switch (v) {
          final BigInt b => b,
          final int i => BigInt.from(i),
          final String s => BigInt.tryParse(s.trim()),
          _ => null,
        };
      }, child);
  return message != null ? core.expectPreserveValue(base, Expectation(message: message)) : base;
}
