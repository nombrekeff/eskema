import 'dart:async';
import 'package:eskema/eskema.dart';
import 'package:test/test.dart';

IValidator delayedInt = Validator((v) async {
  await Future.delayed(const Duration(milliseconds: 5));
  return Result(
    isValid: v is int,
    expectations: [Expectation(message: 'int', value: v)],
    value: v,
  );
});

void main() {
  group('async listEach / eskemaList', () {
    test('listEach passes with all valid async', () async {
      final v = listEach(delayedInt);
      final r = await v.validateAsync([1,2,3]);
      expect(r.isValid, true, reason: r.description);
    });

    test('listEach fails early when first invalid async', () async {
      final v = listEach(delayedInt);
      final r = await v.validateAsync([1,'x',3]);
      expect(r.isValid, false);
      expect(r.description?.contains('[1]'), true);
    });

    test('eskemaList with mixed async+sync', () async {
      final v = eskemaList([delayedInt, isString()]);
      final r = await v.validateAsync([10,'ok']);
      expect(r.isValid, true);
    });

    test('eskemaList reports async error with path', () async {
      final v = eskemaList([delayedInt, isString()]);
      final r = await v.validateAsync(['bad','ok']);
      expect(r.isValid, false);
      expect(r.description?.contains('[0]'), true);
    });
  });
}
