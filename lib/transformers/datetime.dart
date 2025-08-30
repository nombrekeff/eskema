/// Date and time transformers.
///
/// This file contains transformers for converting values to DateTime objects
/// and date-only representations.
library transformers.datetime;

import 'package:eskema/eskema.dart';
import 'core.dart' as core;

/// Coerces a value to a `DateTime`.
///
/// Handles existing `DateTime` objects and strings that can be parsed as a
/// `DateTime`.
/// Passes the resulting `DateTime` to the [child] validator.
IValidator toDateTime(IValidator child) =>
    core.transform((value) {
      return switch (value) {
        final DateTime d => d,
        final String s => DateTime.tryParse(s.trim()),
        _ => null,
      };
    }, child) >
    Expectation(message: 'a valid DateTime formatted String');

/// Coerces value to a DateTime at midnight (date-only).
IValidator toDateOnly(IValidator child) =>
    (isType<DateTime>() | $isString) &
    core.transform((v) {
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
