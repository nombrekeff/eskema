/// Date Validators
///
/// This file contains validators for working with DateTime values.
library validators.date;

import '../validator.dart';
import '../expectation.dart';
import '../expectation_codes.dart';
import '../result.dart';

// Internal helper to reduce duplication for DateTime-based predicates.
IValidator _datePredicate({
  required String defaultMessage,
  required bool Function(DateTime value) test,
  required String code,
  required Map<String, dynamic> Function() dataBuilder,
  String? message,
}) {
  return Validator((value) {
    final isDt = value is DateTime;
    final valid = isDt && test(value);
    
    return Result(
      isValid: valid,
      value: value,
      expectation: Expectation(
        message: message ?? defaultMessage,
        value: value,
        code: code,
        data: dataBuilder(),
      ),
    );
  });
}

/// DateTime must be before (or equal if inclusive) given bound.
IValidator isDateBefore(DateTime dt, {bool inclusive = false, String? message}) {
  return _datePredicate(
    defaultMessage:
        'a DateTime before${inclusive ? ' or equal to' : ''} ${dt.toIso8601String()}',
    test: (v) => inclusive ? !v.isAfter(dt) : v.isBefore(dt),
    code: ExpectationCodes.valueDateOutOfRange,
    dataBuilder: () => {
      'bound': dt.toIso8601String(),
      'op': 'before',
      'inclusive': inclusive,
    },
    message: message,
  );
}

/// DateTime must be after (or equal if inclusive) given bound.
IValidator isDateAfter(DateTime dt, {bool inclusive = false, String? message}) {
  return _datePredicate(
    defaultMessage:
        'a DateTime after${inclusive ? ' or equal to' : ''} ${dt.toIso8601String()}',
    test: (v) => inclusive ? !v.isBefore(dt) : v.isAfter(dt),
    code: ExpectationCodes.valueDateOutOfRange,
    dataBuilder: () => {
      'bound': dt.toIso8601String(),
      'op': 'after',
      'inclusive': inclusive,
    },
    message: message,
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
    defaultMessage:
        'a DateTime between ${start.toIso8601String()} and ${end.toIso8601String()} (${inclusiveStart ? '[' : '('}${inclusiveEnd ? ']' : ')'})',
    test: (v) =>
        (inclusiveStart ? !v.isBefore(start) : v.isAfter(start)) &&
        (inclusiveEnd ? !v.isAfter(end) : v.isBefore(end)),
    code: ExpectationCodes.valueDateOutOfRange,
    dataBuilder: () => {
      'start': start.toIso8601String(),
      'end': end.toIso8601String(),
      'inclusiveStart': inclusiveStart,
      'inclusiveEnd': inclusiveEnd,
    },
    message: message,
  );
}

/// DateTime must be same calendar day.
IValidator isDateSameDay(DateTime dt, {String? message}) {
  return _datePredicate(
    defaultMessage: 'a DateTime on the same day as ${dt.toIso8601String().substring(0, 10)}',
    test: (v) => v.year == dt.year && v.month == dt.month && v.day == dt.day,
    code: ExpectationCodes.valueDateMismatch,
    dataBuilder: () => {'targetDay': dt.toIso8601String().substring(0, 10)},
    message: message,
  );
}

/// DateTime must be in the past.
IValidator isDateInPast({bool allowNow = true, String? message}) {
  final now = DateTime.now();

  return _datePredicate(
    defaultMessage: 'a DateTime in the past${allowNow ? ' or now' : ''}',
    test: (v) => allowNow ? !v.isAfter(now) : v.isBefore(now),
    code: ExpectationCodes.valueDateNotPast,
    dataBuilder: () => {'now': now.toIso8601String(), 'allowNow': allowNow},
    message: message,
  );
}

/// DateTime must be in the future.
IValidator isDateInFuture({bool allowNow = true, String? message}) {
  final now = DateTime.now();

  return _datePredicate(
    defaultMessage: 'a DateTime in the future${allowNow ? ' or now' : ''}',
    test: (v) => allowNow ? !v.isBefore(now) : v.isAfter(now),
    code: ExpectationCodes.valueDateNotFuture,
    dataBuilder: () => {'now': now.toIso8601String(), 'allowNow': allowNow},
    message: message,
  );
}
