import 'dart:async';
import 'package:eskema/eskema.dart';
import 'package:test/test.dart' hide isNotEmpty;

IValidator asyncValid([String? tag]) => Validator((v) async {
  await Future.delayed(const Duration(milliseconds: 5));
  return Result.valid(v);
});

IValidator asyncInvalid(String msg) => Validator((v) async {
  await Future.delayed(const Duration(milliseconds: 5));
  return Result.invalid(v, expectations: [Expectation(message: msg, value: v)]);
});

void main() {
  group('async eskema structure', () {
    final schema = eskema({
      'id': isInt(),
      'name': (isString() & isNotEmpty()).nullable(),
      'email': asyncValid(),
      'age': asyncInvalid('too young').optional(),
      'country': isOneOf(['USA','CA']).optional(),
    });

    test('valid object with nullable name null + missing optional age', () async {
      final m = {'id': 1, 'name': null, 'email': 'x', 'country': 'USA'};
      final r = await schema.validateAsync(m);
      expect(r.isValid, true, reason: r.description);
    });

    test('invalid object async failure age present', () async {
      final m = {'id': 1, 'name': 'John', 'email': 'x', 'age': 10};
      final r = await schema.validateAsync(m);
      expect(r.isValid, false);
      expect(r.description.contains('too young'), true);
      expect(r.description.contains('.age'), true);
    });

    test('validate() throws on async path', () {
      final m = {'id': 1, 'name': 'John', 'email': 'x'};
      expect(() => schema.validate(m), throwsA(isA<AsyncValidatorException>()));
    });
  });
}
