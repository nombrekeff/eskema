/// Date Validators
///
/// This file contains validators for working with DateTime values.
library validators.date;

import '../validator.dart';
import '../expectation.dart';
import '../expectation_codes.dart';
import '../result.dart';

/// DateTime must be before (or equal if inclusive) given bound.
IValidator isDateBefore(DateTime dt, {bool inclusive = false, String? message}) => Validator((value) {
      final ok = value is DateTime && (inclusive ? !value.isAfter(dt) : value.isBefore(dt));
      return Result(
        isValid: ok,
        expectation: Expectation(
          message: message ??
              'a DateTime before${inclusive ? ' or equal to' : ''} ${dt.toIso8601String()}',
          value: value,
          code: ExpectationCodes.valueDateOutOfRange,
          data: {
            'bound': dt.toIso8601String(),
            'op': 'before',
            'inclusive': inclusive,
          },
        ),
        value: value,
      );
    });

/// DateTime must be after (or equal if inclusive) given bound.
IValidator isDateAfter(DateTime dt, {bool inclusive = false, String? message}) => Validator((value) {
      final ok = value is DateTime && (inclusive ? !value.isBefore(dt) : value.isAfter(dt));
      return Result(
        isValid: ok,
        expectation: Expectation(
          message: message ??
              'a DateTime after${inclusive ? ' or equal to' : ''} ${dt.toIso8601String()}',
          value: value,
          code: ExpectationCodes.valueDateOutOfRange,
          data: {
            'bound': dt.toIso8601String(),
            'op': 'after',
            'inclusive': inclusive,
          },
        ),
        value: value,
      );
    });

/// DateTime must fall within the interval.
IValidator isDateBetween(DateTime start, DateTime end,
        {bool inclusiveStart = true, bool inclusiveEnd = true, String? message}) =>
    Validator((value) {
      final ok = value is DateTime &&
          (inclusiveStart ? !value.isBefore(start) : value.isAfter(start)) &&
          (inclusiveEnd ? !value.isAfter(end) : value.isBefore(end));
      return Result(
        isValid: ok,
        expectation: Expectation(
          message: message ??
              'a DateTime between ${start.toIso8601String()} and ${end.toIso8601String()} (${inclusiveStart ? '[' : '('}${inclusiveEnd ? ']' : ')'})',
          value: value,
          code: ExpectationCodes.valueDateOutOfRange,
          data: {
            'start': start.toIso8601String(),
            'end': end.toIso8601String(),
            'inclusiveStart': inclusiveStart,
            'inclusiveEnd': inclusiveEnd,
          },
        ),
        value: value,
      );
    });

/// DateTime must be same calendar day.
IValidator isDateSameDay(DateTime dt, {String? message}) => Validator((value) {
      final ok = value is DateTime &&
          value.year == dt.year &&
          value.month == dt.month &&
          value.day == dt.day;
      return Result(
        isValid: ok,
        expectation: Expectation(
          message: message ??
              'a DateTime on the same day as ${dt.toIso8601String().substring(0, 10)}',
          value: value,
          code: ExpectationCodes.valueDateMismatch,
          data: {'targetDay': dt.toIso8601String().substring(0, 10)},
        ),
        value: value,
      );
    });

/// DateTime must be in the past.
IValidator isDateInPast({bool allowNow = true, String? message}) {
  final now = DateTime.now();
  return Validator((value) {
    final ok = value is DateTime && (allowNow ? !value.isAfter(now) : value.isBefore(now));
    return Result(
      isValid: ok,
      expectation: Expectation(
        message: message ?? 'a DateTime in the past${allowNow ? ' or now' : ''}',
        value: value,
        code: ExpectationCodes.valueDateNotPast,
        data: {'now': now.toIso8601String(), 'allowNow': allowNow},
      ),
      value: value,
    );
  });
}

/// DateTime must be in the future.
IValidator isDateInFuture({bool allowNow = true, String? message}) {
  final now = DateTime.now();
  return Validator((value) {
    final ok = value is DateTime && (allowNow ? !value.isBefore(now) : value.isAfter(now));
    return Result(
      isValid: ok,
      expectation: Expectation(
        message: message ?? 'a DateTime in the future${allowNow ? ' or now' : ''}',
        value: value,
        code: ExpectationCodes.valueDateNotFuture,
        data: {'now': now.toIso8601String(), 'allowNow': allowNow},
      ),
      value: value,
    );
  });
}
