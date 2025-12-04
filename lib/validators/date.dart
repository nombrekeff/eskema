/// Date Validators
///
/// This file contains validators for working with DateTime values.
library validators.date;

import 'package:eskema/config/eskema_config.dart';
import '../validator.dart';
import '../expectation.dart';
import '../result.dart';

// Internal helper to reduce duplication for DateTime-based predicates.
IValidator _datePredicate({
  required bool Function(DateTime value) test,
  required Expectation Function(dynamic value) expectationBuilder,
}) {
  return Validator((value) {
    final isDt = value is DateTime;
    final valid = isDt && test(value);

    if (valid) return Result.valid(value);

    return Result(
      isValid: false,
      value: value,
      expectation: expectationBuilder(value),
    );
  });
}

/// DateTime must be before (or equal if inclusive) given bound.
IValidator isDateBefore(DateTime dt, {bool inclusive = false, String? message}) {
  return _datePredicate(
    test: (v) => inclusive ? !v.isAfter(dt) : v.isBefore(dt),
    expectationBuilder: (v) => EskemaConfig.expectations.dateOutOfRange(
      v,
      double.negativeInfinity, // No min
      dt.toIso8601String(),
      message: message ??
          'a DateTime before${inclusive ? ' or equal to' : ''} ${dt.toIso8601String()}',
      data: {
        'bound': dt.toIso8601String(),
        'op': 'before',
        'inclusive': inclusive,
      },
    ),
  );
}

/// DateTime must be after (or equal if inclusive) given bound.
IValidator isDateAfter(DateTime dt, {bool inclusive = false, String? message}) {
  return _datePredicate(
    test: (v) => inclusive ? !v.isBefore(dt) : v.isAfter(dt),
    expectationBuilder: (v) => EskemaConfig.expectations.dateOutOfRange(
      v,
      dt.toIso8601String(),
      double.infinity, // No max
      message: message ??
          'a DateTime after${inclusive ? ' or equal to' : ''} ${dt.toIso8601String()}',
      data: {
        'bound': dt.toIso8601String(),
        'op': 'after',
        'inclusive': inclusive,
      },
    ),
  );
}

/// DateTime must fall within the interval.
IValidator isDateBetween(
  DateTime start,
  DateTime end, {
  bool inclusiveStart = true,
  bool inclusiveEnd = true,
  String? message,
}) {
  return _datePredicate(
    test: (v) =>
        (inclusiveStart ? !v.isBefore(start) : v.isAfter(start)) &&
        (inclusiveEnd ? !v.isAfter(end) : v.isBefore(end)),
    expectationBuilder: (v) => EskemaConfig.expectations.dateOutOfRange(
      v,
      start.toIso8601String(),
      end.toIso8601String(),
      message: message ??
          'a DateTime between ${start.toIso8601String()} and ${end.toIso8601String()} (${inclusiveStart ? '[' : '('}${inclusiveEnd ? ']' : ')'})',
      data: {
        'start': start.toIso8601String(),
        'end': end.toIso8601String(),
        'inclusiveStart': inclusiveStart,
        'inclusiveEnd': inclusiveEnd,
      },
    ),
  );
}

/// DateTime must be same calendar day.
IValidator isDateSameDay(DateTime dt, {String? message}) {
  return _datePredicate(
    test: (v) => v.year == dt.year && v.month == dt.month && v.day == dt.day,
    expectationBuilder: (v) => EskemaConfig.expectations.dateMismatch(
      v,
      dt.toIso8601String().substring(0, 10),
      'on the same day as',
      message: message,
      data: {'targetDay': dt.toIso8601String().substring(0, 10)},
    ),
  );
}

/// DateTime must be in the past.
IValidator isDateInPast({bool allowNow = true, String? message}) {
  final now = DateTime.now();

  return _datePredicate(
    test: (v) => allowNow ? !v.isAfter(now) : v.isBefore(now),
    expectationBuilder: (v) => EskemaConfig.expectations.dateNotPast(
      v,
      message: message ?? 'a DateTime in the past${allowNow ? ' or now' : ''}',
      data: {'now': now.toIso8601String(), 'allowNow': allowNow},
    ),
  );
}

/// DateTime must be in the future.
IValidator isDateInFuture({bool allowNow = true, String? message}) {
  final now = DateTime.now();

  return _datePredicate(
    test: (v) => allowNow ? !v.isBefore(now) : v.isAfter(now),
    expectationBuilder: (v) => EskemaConfig.expectations.dateNotFuture(
      v,
      message: message ?? 'a DateTime in the future${allowNow ? ' or now' : ''}',
      data: {'now': now.toIso8601String(), 'allowNow': allowNow},
    ),
  );
}
