import 'package:eskema/eskema.dart';
import 'package:test/test.dart';

void main() {
  group('String normalizer transformers', () {
    test('trim normalizes leading/trailing whitespace', () {
      final validator = builder().string().trim().build();
      expect(validator.validate('  hi  ').value, equals('hi'));
      expect(validator.validate('\thi\n').value, equals('hi'));
    });

    test('collapseWhitespace collapses internal runs', () {
      final validator = builder().string().collapseWhitespace().build();
      expect(validator.validate('a   b \n c').value, equals('a b c'));
    });

    test('toLowerCase lowercases', () {
      final validator = builder().string().toLowerCase().build();
      expect(validator.validate('HeLLo').value, equals('hello'));
    });

    test('toUpperCase uppercases', () {
      final validator = builder().string().toUpperCase().build();
      expect(validator.validate('HeLLo').value, equals('HELLO'));
    });
  });
}
