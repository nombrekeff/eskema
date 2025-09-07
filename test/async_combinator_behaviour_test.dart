import 'dart:async';
import 'package:eskema/eskema.dart';
import 'package:test/test.dart';

// Helpers -------------------------------------------------------------

IValidator asyncPass([String msg = 'ok']) => Validator((v) async {
      await Future.delayed(const Duration(milliseconds: 5));
      // Provide an expectation even on success so none/not tests can transform messages.
      return Result(isValid: true, value: v, expectation: Expectation(message: msg, value: v));
    });

IValidator asyncFail(String msg, {String? code}) => Validator((v) async {
      await Future.delayed(const Duration(milliseconds: 5));
      return Result.invalid(
        v,
        expectations: [Expectation(message: msg, value: v, code: code)],
      );
    });

IValidator asyncTransform(dynamic Function(dynamic) fn) => Validator((v) async {
      await Future.delayed(const Duration(milliseconds: 5));
      return Result.valid(fn(v));
    });

void main() {
  group('async combinators behaviour', () {
    test('all (standard) chains async transformed value into later validators', () async {
      final v = all([
        asyncTransform((n) => (n as num) * 2), // 3 -> 6
        isEq(6),
      ]);
      final r = await v.validateAsync(3);
      expect(r.isValid, true, reason: r.description);
      expect(r.value, 6, reason: 'value should be transformed then chained');
    });

    test('all collecting does NOT chain async transformed value', () async {
      final v = all([
        asyncTransform((n) => (n as num) * 2), // would make 3 -> 6
        isEq(6), // runs against ORIGINAL (3) in collecting mode -> fail
      ], collecting: true);
      final r = await v.validateAsync(3);
      expect(r.isValid, false);
      expect(r.value, 3, reason: 'collecting mode keeps original value');
      expect(r.description.contains('6'), true, reason: 'failure from isEq(6) present');
    });

    test('any short-circuits on first async success (later async not executed)', () async {
      var ranLate = false;
      final late = Validator((v) async {
        ranLate = true;
        return Result.valid(v);
      });
      final v = any([
        asyncFail('A'),
        asyncPass('B'),
        late,
      ]);
      final r = await v.validateAsync('x');
      expect(r.isValid, true, reason: 'second validator should succeed');
      expect(r.description == 'Valid' || r.description.contains('B'), true,
          reason: 'description may be plain Valid or include success expectation');
      expect(ranLate, false, reason: 'later validator should not run');
    });

    test('none fails collecting expectations from async PASS validators', () async {
      final v = none([
        asyncPass('alpha'), // pass => contributes a transformed (not alpha) expectation
        asyncFail('beta'), // fail => ignored by none
      ]);
      final r = await v.validateAsync('x');
      expect(r.isValid, false);
      expect(r.description.contains('not alpha'), true);
      expect(r.description.contains('beta'), false, reason: 'failing child not collected');
    });

    test('not with async child: async pass => failure with not message', () async {
      final v = not(asyncPass('inner ok'));
      final r = await v.validateAsync('x');
      expect(r.isValid, false);
      expect(r.description.contains('not inner ok'), true);
    });

    test('not with async failing child => success', () async {
      final v = not(asyncFail('bad'));
      final r = await v.validateAsync('x');
      expect(r.isValid, true);
    });

    test('& operator merges async validators (AllValidator) and stops on first async failure',
        () async {
      var ranLate = false;
      final late = Validator((v) async {
        ranLate = true;
        return Result.valid(v);
      });
      final v = asyncPass('one') & asyncFail('two') & late;
      final r = await v.validateAsync('x');
      expect(r.isValid, false);
      expect(r.description.contains('two'), true);
      expect(ranLate, false, reason: 'short-circuited before late ran');
    });

    test('withExpectation preserves failing child code from async validator', () async {
      final child = asyncFail('child fail', code: 'child.code');
      final wrapped = withExpectation(
          child, const Expectation(message: 'outer message', code: 'outer.code'));
      final r = await wrapped.validateAsync('x');
      expect(r.isValid, false);
      expect(r.expectations.first.message, 'outer message');
      expect(r.expectations.first.code, 'child.code', reason: 'child code preserved');
    });

    test('throwInstead propagates async failure as exception', () async {
      final v = throwInstead(asyncFail('boom'));
      await expectLater(() => v.validateAsync('x'), throwsA(isA<ValidatorFailedException>()));
    });

    test('validate() throws on async combinator chain', () {
      final v = all([asyncPass(), asyncFail('x')]);
      expect(() => v.validate('x'), throwsA(isA<AsyncValidatorException>()));
    });
  });
}
