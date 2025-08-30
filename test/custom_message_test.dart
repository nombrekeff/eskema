import 'package:eskema/eskema.dart' hide contains; // hide validator contains to avoid clash
import 'package:test/test.dart' as t;

void main() {
  t.group('Validator custom message propagation', () {
    t.test('number range validator custom message', () {
      final v = isInRange(5, 10, message: 'between five and ten');
      final r = v.validate(3);
      t.expect(r.isValid, t.isFalse);
      t.expect(r.firstExpectation.message, 'between five and ten');
    });

    t.test('stringContains custom message', () {
      final v = stringContains('abc', message: 'must have abc');
      final r = v.validate('zzz');
      t.expect(r.isValid, t.isFalse);
      t.expect(r.firstExpectation.message, 'must have abc');
    });

    t.test('map containsKey custom message', () {
      final v = containsKey('id', message: 'needs id');
      final r = v.validate({'name': 'x'});
      t.expect(r.isValid, t.isFalse);
      t.expect(r.firstExpectation.message, 'needs id');
    });

    t.test('structure eskemaStrict custom message for unknown keys', () {
      final v = eskemaStrict({'id': isInt()}, message: 'unexpected keys present');
      final r = v.validate({'id': 1, 'extra': true});
      t.expect(r.isValid, t.isFalse);
      t.expect(r.firstExpectation.message, 'unexpected keys present');
    });

    t.test('listEach custom message', () {
      final v = listEach(isInt(), message: 'all items must be int');
      final r = v.validate([1, 'a', 3]);
      t.expect(r.isValid, t.isFalse);
      // Wrapped expectations should adopt the custom listEach message.
      t.expect(r.firstExpectation.message, 'all items must be int');
    });

    t.test('eskema field custom message propagates', () {
      final v = eskema({
        'age': isGte(18, message: 'adult age required'),
      });
      final r = v.validate({'age': 10});
      t.expect(r.isValid, t.isFalse);
      t.expect(r.firstExpectation.message, 'adult age required');
    });

    t.test('isEmail with custom message', () {
      final v = isEmail(message: 'invalid email');
      final r = v.validate('not-email');
      t.expect(r.isValid, t.isFalse);
      t.expect(r.firstExpectation.message, 'invalid email');
    });

    t.test('isDateInFuture custom message', () {
      final v = isDateInFuture(message: 'must be future');
      final r = v.validate(DateTime(2000));
      t.expect(r.isValid, t.isFalse);
      t.expect(r.firstExpectation.message, 'must be future');
    });
  });

  t.group('Transformer expectation messages', () {
    t.test('toIntStrict no implicit expectation without custom message', () {
      final v = toIntStrict(isGte(10));
      final r = v.validate('abc');
      t.expect(r.isValid, t.isFalse);
      // Exposes underlying isIntString expectation
      t.expect(r.firstExpectation.message, t.contains('int'));
    });

    t.test('toDateTime no implicit expectation without custom message', () {
      final v = toDateTime(isDateInFuture());
      final r = v.validate('not-a-date');
      t.expect(r.isValid, t.isFalse);
      // Underlying isDate expectation surfaces (format invalid)
      t.expect(r.firstExpectation.message, t.contains('DateTime'));
    });
  });
}
