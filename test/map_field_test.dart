import 'package:flutter_test/flutter_test.dart';
import 'package:eskema/eskema.dart';

void main() {
  test('Basic MapField validates correctly', () {
    final mapField = all([
      eskema({
        'name': all([isType<String>()]),
        'vat': or(
          isTypeNull(),
          isGte(0),
        ),
        'age': all([
          isType<int>(),
          isGte(0),
        ]),
      }),
    ]);

    final invalidRes1 = mapField.call({});
    expect(invalidRes1.isValid, false);
    expect(invalidRes1.expected, 'name -> String');

    final invalidRes2 = mapField.call({'name': 'test'});
    expect(invalidRes2.isValid, false);
    expect(invalidRes2.expected, 'age -> int');

    final invalidRes3 = mapField.call({'name': 'test', 'age': -12});
    expect(invalidRes3.isValid, false);
    expect(invalidRes3.expected, 'age -> greater than or equal to 0');
    expect(invalidRes3.toString(), 'Expected age -> greater than or equal to 0, got -12');

    final invalidRes4 = mapField.call(null);
    expect(invalidRes4.isValid, false);
    expect(invalidRes4.expected, 'Map');

    final validRes1 = mapField.call({'name': 'test', 'age': 12, 'vat': null});
    expect(validRes1.isValid, true);
  });

  test('Nested MapFields validates correctly', () {
    final isValidMap = nullable(
      eskema({
        'address': eskema({
          'city': all([isType<String>()]),
          'street': all([isType<String>()]),
          'number': all([
            isType<int>(),
            isGte(0),
          ]),
          'additional': nullable(
            eskema({
              'doorbel_number': all([isType<int>()])
            }),
          ),
        }),
      }),
    );

    final invalidRes4 = isValidMap({
      'address': {
        'city': 'NY',
        'street': 132,
        'number': 32,
      },
    });
    expect(invalidRes4.isValid, false);
    expect(invalidRes4.expected, 'address -> street -> String');
    expect(invalidRes4.toString(), 'Expected address -> street -> String, got 132');

    final invalidRes5 = isValidMap({
      'address': {
        'city': 'NY',
        'street': '8th ave',
        'number': 32,
        'additional': {},
      },
    });
    expect(invalidRes5.isValid, false);
    expect(invalidRes5.expected, 'address -> additional -> doorbel_number -> int');
    expect(
      invalidRes5.toString(),
      'Expected address -> additional -> doorbel_number -> int, got null',
    );

    final validRes1 = isValidMap({
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

    final validRes1 = validListField.call({'books': []});
    expect(validRes1.isValid, true);

    final validRes2 = validListField.call({
      'books': [
        {'name': 'bookname'}
      ],
    });
    expect(validRes2.isValid, true);

    final invalidRes1 = validListField.call({
      'books': [{}]
    });
    expect(invalidRes1.isValid, false);
    expect(invalidRes1.expected, 'books -> [0] -> name -> String');
    expect(
      invalidRes1.toString(),
      'Expected books -> [0] -> name -> String, got {}',
    );
  });
}
