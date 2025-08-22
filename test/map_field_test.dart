import 'package:test/test.dart' hide isNull;
import 'package:eskema/eskema.dart';

void main() {
  test('Basic MapField validates correctly', () {
    final mapField = all([
      eskema({
        'name': all([isType<String>()]),
        'vat': any([
          $isNull,
          isGte(0),
        ]),
        'age': all([
          isType<int>(),
          isGte(0),
        ]),
      }),
    ]);

    final invalidRes1 = mapField.validate({});
    expect(invalidRes1.isValid, false);
    expect(invalidRes1.description, '.name: String, .age: int (value: {})');

    final invalidRes2 = mapField.validate({'name': 'test'});
    expect(invalidRes2.isValid, false);
    expect(invalidRes2.description, '.age: int (value: {"name":"test"})');

    final invalidRes3 = mapField.validate({'name': 'test', 'age': -12});
    expect(invalidRes3.isValid, false);
    expect(invalidRes3.description,
        '.age: greater than or equal to 0 (value: {"name":"test","age":-12})');

    final invalidRes4 = mapField.validate(null);
    expect(invalidRes4.isValid, false);
    expect(invalidRes4.description, 'Map<dynamic, dynamic> (value: null)');

    final validRes1 = mapField.validate({'name': 'test', 'age': 12, 'vat': null});
    expect(validRes1.isValid, true);
  });

  test('Nested MapFields validates correctly', () {
    final isValidMap = nullable(
      eskema({
        'address': eskema({
          'city': all([$isString]),
          'street': all([isString()]),
          'number': all([
            isType<int>(),
            isGte(0),
          ]),
          'additional': nullable(
            eskema({
              'doorbel_number': all([isInt()])
            }),
          ),
        }),
      }),
    );

    final invalidRes4 = isValidMap.validate({
      'address': {
        'city': 'NY',
        'street': 132,
        'number': 32,
      },
    });
    expect(invalidRes4.isValid, false);
    expect(invalidRes4.shortDescription, '.address.street: String');

    final invalidRes5 = isValidMap.validate({
      'address': {
        'city': 'NY',
        'street': '8th ave',
        'number': 32,
        'additional': {},
      },
    });
    expect(invalidRes5.isValid, false);
    expect(invalidRes5.shortDescription, '.address.additional.doorbel_number: int');

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
    final validListField = eskema({
      'books': listEach(
        eskema({
          'name': all([isType<String>()]),
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
    expect(invalidRes1.shortDescription, '.books[0].name: String');
  });
}
