import 'package:test/test.dart' hide isMap, isNotEmpty;
import 'package:eskema/eskema.dart';
import 'package:eskema/validators.dart' as v;

void main() {
  group('Primitive type validators', () {
    test('isInt passes for int, fails for numeric string', () {
      expect(isInt().validate(5).isValid, true);
      expect(isInt().validate('5').isValid, false);
    });

    test('isMap passes for map, fails for list', () {
      expect(isMap().validate({'a': 1}).isValid, true);
      expect(isMap().validate([1, 2]).isValid, false);
    });
  });

  group('eskema (map schema)', () {
    final userValidator = eskema({
      'id': isInt(),
      'name': $isString,
      'age': optional(isInt() & isGte(0)),
      'email': nullable($isString),
    });

    test('valid map passes', () {
      final res = userValidator.validate({
        'id': 1,
        'name': 'Alice',
        'email': null,
      });
      expect(res.isValid, true);
    });

    test('missing required key fails', () {
      final res = userValidator.validate({
        'name': 'Alice',
      });
      expect(res.isValid, false);
    });

    test('present invalid type fails', () {
      final res = userValidator.validate({
        'id': '1',
        'name': 'Alice',
      });
      expect(res.isValid, false);
    });

    test('optional key missing passes', () {
      final res = userValidator.validate({
        'id': 2,
        'name': 'Bob',
        'email': 'bob@example.com',
      });
      expect(res.isValid, true);
    });

    test('nullable key null passes, missing fails', () {
      final resNull = userValidator.validate({
        'id': 3,
        'name': 'Carla',
        'email': null,
      });
      final resMissing = userValidator.validate({
        'id': 3,
        'name': 'Carla',
      });
      expect(resNull.isValid, true);
      expect(resMissing.isValid, false);
    });
  });

  group('eskemaList (heterogeneous list)', () {
    final pair = eskemaList([
      $isString,
      isInt(),
    ]);

    test('valid list passes', () {
      expect(pair.validate(['id', 10]).isValid, true);
    });

    test('wrong length fails', () {
      expect(pair.validate(['id']).isValid, false);
    });

    test('wrong type fails', () {
      expect(pair.validate([10, 'id']).isValid, false);
    });
  });

  group('listEach', () {
    final ints = every(isInt() & isGte(0));

    test('valid int list passes', () {
      expect(ints.validate([0, 1, 2]).isValid, true);
    });

    test('invalid element fails', () {
      expect(ints.validate([0, -1, 2]).isValid, false);
    });

    test('non-list fails', () {
      expect(ints.validate('not a list').isValid, false);
    });
  });

  group('Transform validators (map / getField)', () {
    final ageValidator = getField(
      'age',
      toInt(isGte(18)),
    );

    test('map with numeric age (int) passes', () {
      expect(ageValidator.validate({'age': 21}).isValid, true);
    });

    test('map with numeric age (string) passes after toInt', () {
      expect(ageValidator.validate({'age': '30'}).isValid, true);
    });

    test('map with invalid age (string) fails', () {
      final res = ageValidator.validate({'age': 'abc'});
      expect(res.isValid, false);
    });

    test('missing age fails', () {
      expect(ageValidator.validate({'name': 'X'}).isValid, false);
    });

    test('getField with invalid type', () {
      expect(ageValidator.validate(123).isValid, false);
      expect(ageValidator.validate(123).description, 'Map<dynamic, dynamic>');
    });
  });

  group('Nested getField + transform', () {
    final nested = getField(
      'user',
      getField(
        'age',
        toInt(isGte(18) & isLte(99)),
      ),
    );

    test('nested valid passes', () {
      final res = nested.validate({
        'user': {'age': '45'}
      });
      expect(res.isValid, true);
    });

    test('nested invalid fails (too high)', () {
      final res = nested.validate({
        'user': {'age': '120'}
      });
      expect(res.isValid, false);
      expect(res.description, 'user.age: less than or equal to 99');
    });

    test('missing nested key fails', () {
      final res = nested.validate({'user': {}});
      expect(res.isValid, false);
    });
  });

  group('trim + string validators', () {
    final username = trim(stringIsOfLength(5));

    test('trims and validates length', () {
      expect(username.validate('  abcde  ').isValid, true);
    });

    test('insufficient length fails', () {
      expect(username.validate('  ab ').isValid, false);
    });
  });

  group('toBool transformer', () {
    final validator = toBool(isEq(true));

    test('should handle boolean true', () {
      expect(validator.validate(true).isValid, isTrue);
    });

    test('should handle integer 1', () {
      expect(validator.validate(1).isValid, isTrue);
    });

    test('should handle string "true"', () {
      expect(validator.validate('true').isValid, isTrue);
    });

    test('should handle string "TRUE" (case-insensitive)', () {
      expect(validator.validate('TRUE').isValid, isTrue);
    });

    test('should fail for boolean false', () {
      final falseValidator = toBool(isEq(false));
      expect(falseValidator.validate(false).isValid, isTrue);
    });

    test('should fail for integer 0', () {
      final falseValidator = toBool(isEq(false));
      expect(falseValidator.validate(0).isValid, isTrue);
    });

    test('should fail for string "false"', () {
      final falseValidator = toBool(isEq(false));
      expect(falseValidator.validate('false').isValid, isTrue);
    });

    test('should fail for other values', () {
      expect(validator.validate('other').isValid, isFalse);
      expect(validator.validate(123).isValid, isFalse);
    });
  });

  group('defaultTo transformer', () {
    final validator = defaultTo('default', v.isString() & v.not(v.$isStringEmpty));

    test('should use default value for null', () {
      expect(validator.validate(null).isValid, isTrue);
    });

    test('should not use default value for non-null', () {
      expect(validator.validate('provided').isValid, isTrue);
    });

    test('should fail if value after default is invalid', () {
      final failingValidator = defaultTo('', v.isString() & v.not(v.$isStringEmpty));
      expect(failingValidator.validate(null).isValid, isFalse);
    });
  });

  group('split transformer', () {
    final validator = split(',', every(toInt(isGte(0))));

    test('should split and validate a string', () {
      expect(validator.validate('1,2,3').isValid, isTrue);
    });

    test('should fail if splitting results in invalid items', () {
      expect(validator.validate('1,-2,3').isValid, isFalse);
    });

    test('should fail if not a string', () {
      expect(validator.validate(123).isValid, isFalse);
    });
  });
}
