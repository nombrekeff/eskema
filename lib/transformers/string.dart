/// String type transformers.
///
/// This file contains transformers for string manipulation and conversion.
library transformers.string;

import 'package:eskema/eskema.dart';
import 'core.dart' as core;

// --- Precompiled RegExp instances (performance: avoid per-call allocations) ---
final RegExp _reWhitespaceRuns = RegExp(r'\s+');

/// Coerces a value to a `String`.
IValidator toString(IValidator child, {String? message}) {
  final base = ($isString | $isNumber | $isBool | isType<DateTime>()) &
      core.transform((v) => v.toString(), child);
  if (message != null) {
    return core.expectPreserveValue(base, Expectation(message: message));
  }

  return base; // preserve original expectations / chaining semantics
}

/// String normalizer (no type pivot): trim leading/trailing whitespace.
IValidator trimString(IValidator child, {String? message}) {
  final base = core.transform((v) => v is String ? v.trim() : v, child);

  return message != null ? core.expectPreserveValue(base, Expectation(message: message)) : base;
}

/// Collapse internal whitespace runs to a single space and trim ends.
IValidator collapseWhitespace(IValidator child, {String? message}) {
  final base = core.transform(
    (v) => v is String ? v.replaceAll(_reWhitespaceRuns, ' ').trim() : v,
    child,
  );

  return message != null ? core.expectPreserveValue(base, Expectation(message: message)) : base;
}

/// Lowercase string (ASCII-focused; leaves non-letters unchanged).
IValidator toLowerCaseString(IValidator child, {String? message}) {
  final base = core.transform((v) => v is String ? v.toLowerCase() : v, child);

  return message != null ? core.expectPreserveValue(base, Expectation(message: message)) : base;
}

/// Uppercase string.
IValidator toUpperCaseString(IValidator child, {String? message}) {
  final base = core.transform((v) => v is String ? v.toUpperCase() : v, child);

  return message != null ? core.expectPreserveValue(base, Expectation(message: message)) : base;
}

/// Trims leading and trailing whitespace from a string.
///
/// Fails if the input value is not a string.
/// Passes the trimmed string to the [child] validator.
IValidator trim(IValidator child, {String? message}) {
  final base = isString() & core.transform((v) => v.trim(), child);

  return message != null ? core.expectPreserveValue(base, Expectation(message: message)) : base;
}

/// Transforms a string to lowercase.
///
/// Fails if the input value is not a string.
/// Passes the lowercase string to the [child] validator.
IValidator toLowerCase(IValidator child, {String? message}) {
  final base = isString() & core.transform((v) => v.toLowerCase(), child);

  return message != null ? core.expectPreserveValue(base, Expectation(message: message)) : base;
}

/// Transforms a string to uppercase.
///
/// Fails if the input value is not a string.
/// Passes the uppercase string to the [child] validator.
IValidator toUpperCase(IValidator child, {String? message}) {
  final base = isString() & core.transform((v) => v.toUpperCase(), child);

  return message != null ? core.expectPreserveValue(base, Expectation(message: message)) : base;
}

/// Splits a string into a list of substrings.
///
/// Splits the input string at each occurrence of the [separator]. Fails if the
/// input value is not a string.
/// Passes the resulting list of strings to the [child] validator.
///
/// Example: `split(',', listEach(toInt(isGte(0))))`
IValidator split(String separator, IValidator child, {String? message}) {
  final base = isString() & core.transform((v) => v.split(separator), child);

  return message != null ? core.expectPreserveValue(base, Expectation(message: message)) : base;
}
