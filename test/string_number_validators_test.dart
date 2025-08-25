import 'package:test/test.dart';
import 'package:eskema/eskema.dart';

void main() {
  group('isIntString', () {
    final v = isIntString();

    test('valid integers', () {
      expect(v.validate('0').isValid, true);
      expect(v.validate('-42').isValid, true);
      expect(v.validate(' 123 ').isValid, true); // trims
    });

    test('invalid integers', () {
      expect(v.validate('3.14').isValid, false); // decimal
      expect(v.validate('1e3').isValid, false); // scientific notation not pure int
      expect(v.validate('abc').isValid, false);
      expect(v.validate(123).isValid, false); // non-string
    });
  });

  group('isDoubleString', () {
    final v = isDoubleString();

    test('valid doubles (including ints as doubles)', () {
      expect(v.validate('3.14').isValid, true);
      expect(v.validate('-0.5').isValid, true);
      expect(v.validate('1e3').isValid, true); // scientific
      expect(v.validate('  2  ').isValid, true); // integer parses as double
    });

    test('invalid doubles', () {
      expect(v.validate('abc').isValid, false);
      expect(v.validate('1 2').isValid, false); // space inside number
      expect(v.validate(1.23).isValid, false); // non-string
    });
  });

  group('isNumString', () {
    final v = isNumString();

    test('valid numbers (int, double, scientific)', () {
      expect(v.validate('42').isValid, true);
      expect(v.validate('3.14').isValid, true);
      expect(v.validate('-1e3').isValid, true);
      expect(v.validate(' 5 ').isValid, true);
    });

    test('invalid numbers', () {
      expect(v.validate('abc').isValid, false);
      expect(v.validate('1 2').isValid, false);
      expect(v.validate(42).isValid, false); // non-string
    });
  });
}
