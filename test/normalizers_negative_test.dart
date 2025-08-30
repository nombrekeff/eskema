import 'package:test/test.dart';
import 'package:eskema/eskema.dart';

void main() {
  group('string normalizers negative (idempotent) cases', () {
    test('trimString no-op when already trimmed', () {
      final v = vBuilder().string().trim().build();
      final r = v.validate('abc');
      expect(r.value, 'abc');
    });

    test('collapseWhitespace no-op for single spaces', () {
      final v = vBuilder().string().collapseWhitespace().build();
      final r = v.validate('a b c');
      expect(r.value, 'a b c');
    });

    test('toLowerCaseString no-op for lowercase', () {
      final v = vBuilder().string().toLowerCase().build();
      final r = v.validate('abc123');
      expect(r.value, 'abc123');
    });

    test('toUpperCaseString no-op for uppercase', () {
      final v = vBuilder().string().toUpperCase().build();
      final r = v.validate('ABC');
      expect(r.value, 'ABC');
    });
  });
}

RootBuilder vBuilder() => v();
