import 'package:eskema/eskema.dart';
import 'package:eskema/validators.dart' as v;
import 'package:test/test.dart';

void main() {
  group('when validator', () {
    final addressValidator = eskema({
      'street': v.isString() & v.isNotEmpty(),
      'country': v.isOneOf(['USA', 'Canada']),
      'postal_code': when(
        getField('country', v.isEq('USA')),
        then: v.stringIsOfLength(5) > Expectation(message: 'a 5-digit US zip code'),
        otherwise: v.stringIsOfLength(6) > Expectation(message: 'a 6-character Canadian postal code'),
      ),
    });

    test('should succeed for USA address with correct postal code', () {
      final address = {
        'street': '123 Main St',
        'country': 'USA',
        'postal_code': '90210',
      };
      final result = addressValidator.validate(address);
      expect(result.isValid, isTrue);
    });

    test('should fail for USA address with incorrect postal code', () {
      final address = {
        'street': '123 Main St',
        'country': 'USA',
        'postal_code': 'M5H2N2', // Canadian format
      };
      final result = addressValidator.validate(address);
      expect(result.isValid, isFalse);
      expect(result.expectations.first.message, 'a 5-digit US zip code');
      expect(result.expectations.first.path, '.postal_code');
    });

    test('should succeed for Canada address with correct postal code', () {
      final address = {
        'street': '456 Queen St',
        'country': 'Canada',
        'postal_code': 'M5H2N2',
      };
      final result = addressValidator.validate(address);
      expect(result.isValid, isTrue);
    });

    test('should fail for Canada address with incorrect postal code', () {
      final address = {
        'street': '456 Queen St',
        'country': 'Canada',
        'postal_code': '90210', // US format
      };
      final result = addressValidator.validate(address);
      expect(result.isValid, isFalse);
      expect(result.description, '.postal_code: a 6-character Canadian postal code');
    });

    test('should fail if when is used outside of an eskema map validator', () {
      final validator = when(
        not(v.isNull()),
        then: v.isString(),
        otherwise: v.isInt(),
      );
      final result = validator.validate('some value');
      expect(result.isValid, isFalse);
      expect(result.description,
          '`when` validator can only be used inside an `eskema` map validator');
    });
  });
}
