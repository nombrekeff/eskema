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
IValidator toDateTime(IValidator child, {String? message}) {
  final base = core.transform((value) {
    return switch (value) {
      final DateTime d => d,
      final String s => DateTime.tryParse(s.trim()),
      _ => null,
    };
  }, child);

  return handleReturnPreserveValue(base, message);
}
