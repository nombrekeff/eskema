/// String type transformers.
///
/// This file contains transformers for string manipulation and conversion.
library transformers.string;

import 'package:eskema/eskema.dart';
import 'core.dart' as core;

// --- Precompiled RegExp instances (performance: avoid per-call allocations) ---
final RegExp _reWhitespaceRuns = RegExp(r'\s+');

/// Coerces a value to a `String`.
IValidator toString(IValidator child) =>
    ($isString | $isNumber | $isBool | isType<DateTime>()) &
        core.transform((v) => v.toString(), child) >
    Expectation(message: 'a value convertible to a String');

/// String normalizer (no type pivot): trim leading/trailing whitespace.
IValidator trimString(IValidator child) => core.transform((v) => v is String ? v.trim() : v, child);

/// Collapse internal whitespace runs to a single space and trim ends.
IValidator collapseWhitespace(IValidator child) =>
    core.transform((v) => v is String ? v.replaceAll(_reWhitespaceRuns, ' ').trim() : v, child);

/// Lowercase string (ASCII-focused; leaves non-letters unchanged).
IValidator toLowerCaseString(IValidator child) =>
    core.transform((v) => v is String ? v.toLowerCase() : v, child);

/// Uppercase string.
IValidator toUpperCaseString(IValidator child) =>
    core.transform((v) => v is String ? v.toUpperCase() : v, child);

/// Trims leading and trailing whitespace from a string.
///
/// Fails if the input value is not a string.
/// Passes the trimmed string to the [child] validator.
IValidator trim(IValidator child) {
  return isString() & core.transform((v) => v.trim(), child);
}

/// Transforms a string to lowercase.
///
/// Fails if the input value is not a string.
/// Passes the lowercase string to the [child] validator.
IValidator toLowerCase(IValidator child) {
  return isString() & core.transform((v) => v.toLowerCase(), child);
}

/// Transforms a string to uppercase.
///
/// Fails if the input value is not a string.
/// Passes the uppercase string to the [child] validator.
IValidator toUpperCase(IValidator child) {
  return isString() & core.transform((v) => v.toUpperCase(), child);
}

/// Splits a string into a list of substrings.
///
/// Splits the input string at each occurrence of the [separator]. Fails if the
/// input value is not a string.
/// Passes the resulting list of strings to the [child] validator.
///
/// Example: `split(',', listEach(toInt(isGte(0))))`
IValidator split(String separator, IValidator child) {
  return isString() & core.transform((v) => v.split(separator), child);
}
