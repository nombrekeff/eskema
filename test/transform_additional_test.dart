import 'package:test/test.dart';
import 'package:eskema/eskema.dart';

void main() {
  group('toInt', () {
    final v = toInt(isInt());

    test('double not coerces to int', () {
      final res = v.validate(3.1);
      expect(res.isValid, true);
    });
    test('numeric string coerces to int', () {
      final res = v.validate('2');
      expect(res.isValid, true);
    });
    test('invalid string fails', () {
      final res = v.validate('pi');
      expect(res.isValid, false);
      expect(res.description, 'int, num, a valid formatted int String');
    });
  });

  group('toDouble', () {
    final v = toDouble(isDouble());
    test('int coerces to double', () {
      final res = v.validate(3);
      expect(res.isValid, true);
    });
    test('numeric string coerces to double', () {
      final res = v.validate('3.14');
      expect(res.isValid, true);
    });
    test('invalid string fails', () {
      final res = v.validate('pi');
      expect(res.isValid, false);
      expect(res.description, 'double, num, a valid formatted double String');
    });
  });

  group('toNum', () {
    final v = toNum(isNumber());
    test('int passes', () => expect(v.validate(5).isValid, true));
    test('double passes', () => expect(v.validate(5.2).isValid, true));
    test('numeric string passes', () => expect(v.validate('42').isValid, true));
    test('invalid string fails', () => expect(v.validate('NaN!').isValid, false));
    test(
        'invalid string fails',
        () => expect(
            v.validate('NaN!').description, 'num, a valid formatted number String'));
  });

  group('trim transformer', () {
    final v = trim(stringIsOfLength(3));
    test('trims spaces', () {
      expect(v.validate('  abc  ').isValid, true);
    });
    test('too short after trim fails', () {
      expect(v.validate('  ab  ').isValid, false);
    });
    test('non string fails', () {
      expect(v.validate(123).isValid, false);
      expect(v.validate(123).description, 'String');
    });
  });

  group('toDateTime', () {
    final v = toDateTime($isDateTime, message: 'a valid DateTime formatted String'); // explicit message to preserve previous expectation

    test('parses ISO string', () {
      expect(v.validate('2024-01-02T03:04:05Z').isValid, true);
    });

    test('rejects invalid string', () {
      expect(v.validate('not-a-date').isValid, false);
      expect(v.validate('not-a-date').description, 'a valid DateTime formatted String');
    });

    test('accepts DateTime object', () {
      expect(v.validate(DateTime.now()).isValid, true);
    });
  });
}
