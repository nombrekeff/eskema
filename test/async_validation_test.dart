import 'dart:async';
import 'package:eskema/eskema.dart';
import 'package:test/test.dart' hide isNotEmpty;

/// Helper to build an async validator that waits then returns the provided result.
IValidator asyncPass([Duration delay = const Duration(milliseconds: 5)]) {
  return Validator((value) async {
    await Future.delayed(delay);
    return Result.valid(value);
  });
}

IValidator asyncFail(String message, {Duration delay = const Duration(milliseconds: 5)}) {
  return Validator((value) async {
    await Future.delayed(delay);
    return Result.invalid(value, expectations: [Expectation(message: message, value: value)]);
  });
}

void main() {
  group('async validation', () {
    test('validateAsync succeeds with mixed sync+async', () async {
      final v = all([
        isString(),
        asyncPass(),
        validator((v) => v == 'ok', (v) => Expectation(message: '== ok', value: v)),
      ]);

      // validate() should throw because chain contains async
      expect(() => v.validate('ok'), throwsA(isA<AsyncValidatorException>()));

      final result = await v.validateAsync('ok');
      expect(result.isValid, true);
    });

    test('validateAsync fails when async child fails', () async {
      final v = all([
        isString(),
        asyncFail('nope'),
      ]);

      expect(() => v.validate('x'), throwsA(isA<AsyncValidatorException>()));
      final result = await v.validateAsync('x');
      expect(result.isValid, false);
      expect(result.description.contains('nope'), true);
    });

    test('pure sync chain still works with validate()', () {
      final v = all([isString(), isNotEmpty()]);
      final ok = v.validate('hi');
      expect(ok.isValid, true);
      final bad = v.validate('');
      expect(bad.isValid, false);
    });

    test('pure sync chain also usable via validateAsync()', () async {
      final v = all([isInt(), isGte(0)]);
      final r = await v.validateAsync(10);
      expect(r.isValid, true);
    });
  });
}
