import 'package:eskema/eskema.dart';
import 'package:test/test.dart';

void main() {
  group('Additional String Format Validators', () {
    group('isEmail', () {
      final validator = isEmail();
      test('should pass for a valid email', () {
        expect(validator.validate('test@example.com').isValid, isTrue);
      });
      test('should fail for an invalid email', () {
        expect(validator.validate('test@.com').isValid, isFalse);
        expect(validator.validate('test@example').isValid, isFalse);
        expect(validator.validate('test.example.com').isValid, isFalse);
      });
      test('should fail for non-string input', () {
        expect($isEmail.validate(123).isValid, isFalse);
      });
    });

    group('isUrl', () {
      final strictUrl = isUrl(strict: true);

      test('should pass for a valid strict URL', () {
        expect($isStrictUrl.validate('http://example.com').isValid, isTrue);
        expect($isStrictUrl.validate('https://example.com/path').isValid, isTrue);
        expect($isStrictUrl.validate('example.com').isValid, isFalse);
      });

      test('should pass for non-strict URL', () {
        expect($isUrl.validate('123').isValid, isTrue);
        expect($isUrl.validate('example.com').isValid, isTrue);
      });

      test('should fail for non-string input', () {
        expect(strictUrl.validate(123).isValid, isFalse);
      });
    });

    group('isUuid', () {
      test('should pass for a valid UUID v4', () {
        expect(isUuidV4().validate('123e4567-e89b-42d3-a456-556642440000').isValid, isTrue);
      });
      test('should fail for an invalid UUID', () {
        expect($isUuidV4.validate('not-a-uuid').isValid, isFalse);
        // Not a v4 UUID
        expect($isUuidV4.validate('123e4567-e89b-12d3-a456-556642440000').isValid, isFalse);
      });
      test('should fail for non-string input', () {
        expect($isUuidV4.validate(123).isValid, isFalse);
      });
    });
  });

  group('isInRange Validator', () {
    final validator = isInRange(10, 20);
    test('should pass for a number within the range', () {
      expect(validator.validate(15).isValid, isTrue);
      expect(validator.validate(10).isValid, isTrue);
      expect(validator.validate(20).isValid, isTrue);
    });
    test('should fail for a number outside the range', () {
      expect(validator.validate(5).isValid, isFalse);
      expect(validator.validate(25).isValid, isFalse);
    });
    test('should fail for non-numeric input', () {
      expect(validator.validate('15').isValid, isFalse);
    });
  });
}
