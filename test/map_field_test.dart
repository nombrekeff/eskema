import 'package:test/test.dart' hide isNull;
import 'package:eskema/eskema.dart' as eskema;

void main() {
  test('Basic MapField validates correctly', () {
    final mapField = eskema.all([
      eskema.eskema({
        'name': eskema.all([eskema.isType<String>()]),
        'vat': eskema.any([
          eskema.$isNull,
          eskema.isGte(0),
        ]),
        'age': eskema.all([
          eskema.isType<int>(),
          eskema.isGte(0),
        ]),
      }),
    ]);

    final invalidRes1 = mapField.validate({});
    expect(invalidRes1.isValid, false);
    expect(invalidRes1.description, '.name: String, .age: int');

    final invalidRes2 = mapField.validate({'name': 'test'});
    expect(invalidRes2.isValid, false);
    expect(invalidRes2.description, '.age: int');

    final invalidRes3 = mapField.validate({'name': 'test', 'age': -12});
    expect(invalidRes3.isValid, false);
    expect(invalidRes3.description, '.age: greater than or equal to 0');

    final invalidRes4 = mapField.validate(null);
    expect(invalidRes4.isValid, false);
    expect(invalidRes4.description, 'Map<dynamic, dynamic>');

    final validRes1 =
        mapField.validate({'name': 'test', 'age': 12, 'vat': null});
    expect(validRes1.isValid, true);
  });

  test('Nested MapFields validates correctly', () {
    final isValidMap = eskema.eskema({
      'address': eskema.eskema({
        'city': eskema.all([eskema.$isString]),
        'street': eskema.all([eskema.isString()]),
        'number': eskema.all([
          eskema.isType<int>(),
          eskema.isGte(0),
        ]),
        'additional': eskema.nullable(
          eskema.eskema({
            'doorbel_number': eskema.all([eskema.isInt()])
          }),
        ),
      }),
    });

    final invalidRes4 = isValidMap.validate({
      'address': {
        'city': 'NY',
        'street': 132,
        'number': 32,
      },
    });
    expect(invalidRes4.isValid, false);
    expect(invalidRes4.description,
        '.address.street: String, .address.additional: Map<dynamic, dynamic>');

    final invalidRes5 = isValidMap.validate({
      'address': {
        'city': 'NY',
        'street': '8th ave',
        'number': 32,
        'additional': {},
      },
    });
    expect(invalidRes5.isValid, false);
    expect(invalidRes5.description, '.address.additional.doorbel_number: int');

    final validRes1 = isValidMap.validate({
      'address': {
        'city': 'NY',
        'street': '8th ave',
        'number': 32,
        'additional': {
          'doorbel_number': 1,
        },
      },
    });
    expect(validRes1.isValid, true);
  });

  test('Map with ListField', () {
    final validListField = eskema.eskema({
      'books': eskema.listEach(
        eskema.eskema({
          'name': eskema.all([eskema.isType<String>()]),
        }),
      ),
    });

    final validRes1 = validListField.validate({'books': []});
    expect(validRes1.isValid, true);

    final validRes2 = validListField.validate({
      'books': [
        {'name': 'bookname'}
      ],
    });
    expect(validRes2.isValid, true);

    final invalidRes1 = validListField.validate({
      'books': [{}]
    });
    expect(invalidRes1.isValid, false);
    expect(invalidRes1.description, '.books[0].name: String');
  });

  test('optional works', () {
    final validListField = eskema.eskema({
      'optional': eskema.optional(eskema.isString()),
    });

    expect(validListField.validate({'optional': 'test'}).isValid, true);
    expect(validListField.validate({'optional': ''}).isValid, true);
    expect(validListField.validate({}).isValid, true);

    expect(validListField.validate({'optional': 123}).isValid, false);
    expect(validListField.validate({'optional': null}).isValid, false);
  });

  test('optional and nullable works', () {
    final validListField = eskema.eskema({
      'optional': eskema.optional(eskema.nullable(eskema.isString())),
    });

    expect(validListField.validate({'optional': 'test'}).isValid, true);
    expect(validListField.validate({'optional': ''}).isValid, true);
    expect(validListField.validate({'optional': null}).isValid, true);
    expect(validListField.validate({}).isValid, true);

    expect(validListField.validate({'optional': 123}).isValid, false);
  });

  test('nullable works', () {
    final validListField = eskema.eskema({
      'nullable': eskema.nullable(eskema.isString()),
    });

    expect(validListField.validate({'nullable': 'test'}).isValid, true);
    expect(validListField.validate({'nullable': ''}).isValid, true);
    expect(validListField.validate({'nullable': null}).isValid, true);

    expect(validListField.validate({}).isValid, false);
    expect(validListField.validate({}).description, '.nullable: String');
    expect(validListField.validate({'nullable': 123}).isValid, false);
  });

  test('nullable single fields works', () {
    final field = eskema.nullable(eskema.isString());

    expect(field.validate('').isValid, true);
    expect(field.validate(null, exists: true).isValid, true);
    expect(field.validate(null, exists: false).isValid, false);
  });

  test('optional single fields works', () {
    final field = eskema.optional(eskema.isString());

    expect(field.isValid(''), true);
    expect(field.isValid(false), false);
    expect(field.isValid(null), false);
  });

  group('eskemaStrict Validator', () {
    final validator = eskema.eskemaStrict({
      'name': eskema.isString(),
      'age': eskema.isInt(),
    });

    test('should pass for a map with exact keys', () {
      final map = {'name': 'John', 'age': 30};
      expect(validator.validate(map).isValid, isTrue);
    });

    test('should fail for a map with unknown keys', () {
      final map = {'name': 'John', 'age': 30, 'city': 'New York'};
      final result = validator.validate(map);
      expect(result.isValid, isFalse);
      expect(result.expectations.first.message, 'has unknown keys: city');
    });

    test('should fail if inner validator fails', () {
      final map = {'name': 'John', 'age': '30'};
      final result = validator.validate(map);
      expect(result.isValid, isFalse);
      expect(result.description, '.age: int');
    });
  });
}
