import 'package:eskema/eskema.dart' hide contains; // avoid matcher clash
import 'package:test/test.dart';

void main() {
  group('Combinator custom messages', () {
    test('any custom message overrides collected failures', () {
      final v = any([isInt(), isBool()], message: 'int or bool required');
      final r = v.validate('x');
      expect(r.isValid, false);
      expect(r.firstExpectation.message, 'int or bool required');
    });

    test('all custom message forces failure even if all pass (documented behavior change)', () {
      final v = all([isInt(), isGte(0)], message: 'must satisfy all (forced)');
      final r = v.validate(5);
      expect(r.isValid, false);
      expect(r.firstExpectation.message, 'must satisfy all (forced)');
    });

    test('none custom message on collected failure', () {
      final v = none([isInt(), isBool()], message: 'must be neither int nor bool');
      final r = v.validate(1);
      expect(r.isValid, false);
      expect(r.firstExpectation.message, 'must be neither int nor bool');
    });

    test('not custom message override', () {
      final v = not(isInt(), message: 'must NOT be int');
      final r = v.validate(5);
      expect(r.isValid, false);
      expect(r.firstExpectation.message, 'must NOT be int');
    });

    test('withExpectation extra message param override', () {
      final base = isInt();
      final wrapped = withExpectation(base, const Expectation(message: 'orig'), message: 'override');
      final r = wrapped.validate('x');
      expect(r.isValid, false);
      expect(r.firstExpectation.message, 'override');
    });

    test('when with custom message outside eskema (usage error still overridden)', () {
      final w = when(isInt(), then: isString(), otherwise: isBool(), message: 'conditional fail');
      final r = w.validate(1); // misuse, but message should be overridden
      expect(r.isValid, false);
      expect(r.firstExpectation.message, 'conditional fail');
    });
  });
}
