import 'dart:async';
import 'package:eskema/eskema.dart';
import 'package:test/test.dart';

IValidator asyncPass() => Validator((v) async {
  await Future.delayed(const Duration(milliseconds: 5));
  return Result.valid(v);
});

IValidator asyncFail(String msg) => Validator((v) async {
  await Future.delayed(const Duration(milliseconds: 5));
  return Result.invalid(v, expectations: [Expectation(message: msg, value: v)]);
});

void main() {
  group('eskemaStrict async + sync', () {
    test('sync valid no unknown keys', () {
      final v = eskemaStrict({'id': isInt(), 'name': isString().optional()});
      final r = v.validate({'id': 1});
      expect(r.isValid, true);
    });

    test('sync valid no unknown keys with invalid type', () {
      final v = eskemaStrict({'id': isInt(), 'name': isString().optional()});
      final r = v.validate({'id': 1, 'name': 2});
      expect(r.isValid, false);
      expect(r.description, '.name: String');
    });


    test('sync unknown key invalid', () {
      final v = eskemaStrict({'id': isInt()});
      final r = v.validate({'id': 1, 'extra': true});
      expect(r.isValid, false);
      expect(r.description.contains('has unknown keys'), true);
    });

    test('async field pass but unknown key still detected', () async {
      final v = eskemaStrict({'id': asyncPass(), 'name': isString()});
      final r = await v.validateAsync({'id': 1, 'name': 'x', 'extra': 5});
      expect(r.isValid, false);
      expect(r.description.contains('has unknown keys'), true);
    });

    test('async field failure short-circuits before unknown keys', () async {
      final v = eskemaStrict({'id': asyncFail('bad id'), 'name': isString()});
      final r = await v.validateAsync({'id': 'oops', 'name': 'x', 'extra': 5});
      expect(r.isValid, false);
      expect(r.description.contains('bad id'), true);
      // Should NOT include unknown key message because second phase skipped
      expect(r.description.contains('has unknown keys'), false);
    });

    test('validate() throws on async schema', () {
      final v = eskemaStrict({'id': asyncPass()});
      expect(() => v.validate({'id': 1}), throwsA(isA<AsyncValidatorException>()));
    });
  });
}
