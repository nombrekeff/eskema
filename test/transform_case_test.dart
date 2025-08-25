import 'package:eskema/eskema.dart';
import 'package:test/test.dart';

void main() {
  group('Case transformers', () {
    group('toLowerCase', () {
      test('should transform a string to lowercase', () {
        final validator = toLowerCase(isLowerCase());
        final result = validator.validate('HELLO');
        expect(result.isValid, isTrue);
      });

      test('should fail if the input is not a string', () {
        final validator = toLowerCase($isLowerCase);
        final result = validator.validate(123);
        expect(result.isValid, isFalse);
      });

      test('should fail if the child validator fails', () {
        final validator = toLowerCase(isUpperCase());
        final result = validator.validate('HELLO');
        expect(result.isValid, isFalse);
      });
    });

    group('toUpperCase', () {
      test('should transform a string to uppercase', () {
        final validator = toUpperCase($isUpperCase);
        final result = validator.validate('hello');
        expect(result.isValid, isTrue);
      });

      test('should fail if the input is not a string', () {
        final validator = toUpperCase(isUpperCase());
        final result = validator.validate(123);
        expect(result.isValid, isFalse);
      });

      test('should fail if the child validator fails', () {
        final validator = toUpperCase(isLowerCase());
        final result = validator.validate('hello');
        expect(result.isValid, isFalse);
      });
    });
  });
}
