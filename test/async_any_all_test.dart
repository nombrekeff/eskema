import 'dart:async';
import 'package:eskema/eskema.dart';
import 'package:test/test.dart';

IValidator asyncBool(bool ok, String msg) => Validator((v) async {
  await Future.delayed(const Duration(milliseconds: 5));
  return Result(
    isValid: ok,
    expectations: [Expectation(message: msg, value: v)],
    value: v,
  );
});

void main() {
  group('any / all async edge cases', () {
    test('any returns first async success and short-circuits later futures', () async {
      var ranLate = false;
      final late = Validator((v) async { ranLate = true; return Result.valid(v); });
      final v = any([
        asyncBool(false,'A'),
        asyncBool(true,'B'),
        late,
      ]);
      final r = await v.validateAsync('x');
      expect(r.isValid, true);
      expect(ranLate, false);
    });

    test('all stops on first async failure', () async {
      var ran = false;
      final late = Validator((v) async { ran = true; return Result.valid(v); });
      final v = all([
        asyncBool(true,'A'),
        asyncBool(false,'B'),
        late,
      ]);
      final r = await v.validateAsync('x');
      expect(r.isValid, false);
      expect(r.description?.contains('B'), true);
      expect(ran, false);
    });
  });
}
