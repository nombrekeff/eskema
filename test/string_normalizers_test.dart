import 'package:eskema/eskema.dart';
import 'package:test/test.dart';

void main() {
  group('String normalizer transformers', () {
    test('trim normalizes leading/trailing whitespace', () {
      final validator = v().string().trim().build();
      expect(validator.validate('  hi  ').value, equals('hi'));
      expect(validator.validate('\thi\n').value, equals('hi'));
    });

    test('collapseWhitespace collapses internal runs', () {
      final validator = v().string().collapseWhitespace().build();
      expect(validator.validate('a   b \n c').value, equals('a b c'));
    });

    test('toLowerCase lowercases', () {
      final validator = v().string().toLowerCase().build();
      expect(validator.validate('HeLLo').value, equals('hello'));
    });

    test('toUpperCase uppercases', () {
      final validator = v().string().toUpperCase().build();
      expect(validator.validate('HeLLo').value, equals('HELLO'));
    });

    test('normalizeUnicode replaces punctuation variants', () {
      final validator = v().string().normalizeUnicode().build();
      expect(validator.validate('“Hello—World…”').value, equals('"Hello-World..."'));
    });

    test('removeDiacritics strips accents (single and multi-char)', () {
      final validator = v().string().removeDiacritics().build();
      expect(
          validator.validate('Crème Brûlée Æther cœ').value, equals('Creme Brulee AEther coe'));
    });

    test('slugify produces URL-safe slugs', () {
      final validator = v().string().slugify().build();
      expect(validator.validate('  Héllô   Wørld!!  ').value, equals('hello-world'));
    });

    test('slugify collapses multiple separators', () {
      final validator = v().string().slugify().build();
      expect(validator.validate('foo___bar---baz').value, equals('foo-bar-baz'));
    });

    test('stripHtml removes tags', () {
      final validator = v().string().stripHtml().build();
      expect(validator.validate('<p>Hello <strong>World</strong></p>').value,
          equals('Hello World'));
    });
  });
}
