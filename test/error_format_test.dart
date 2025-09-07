import 'package:eskema/eskema.dart';
import 'package:test/test.dart' as t;

void main() {
  t.group('error_format', () {
    t.test('buildValidationMessage valid', () {
      final r = Result.valid('hello');
      final msg = buildValidationMessage(r);
      t.expect(msg.startsWith('Valid (String):'), t.isTrue);
    });

    t.test('buildValidationMessage invalid single', () {
  final r = Result.invalid('x', expectation: const Expectation(message: 'must be number', value: 'x'));
      final msg = buildValidationMessage(r);
      t.expect(msg.contains('Validation failed'), t.isTrue);
      t.expect(msg.contains('must be number'), t.isTrue);
    });

    t.test('extension detailed()', () {
  final r = Result.invalid(5, expectation: const Expectation(message: 'boom', value: 5));
      t.expect(r.detailed(), 'Validation failed (errors: 1) for value (int): 5\n  1) boom');
    });
  });
}
