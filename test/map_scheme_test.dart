import 'package:flutter_test/flutter_test.dart';
import 'package:json_scheme/json_scheme.dart';

void main() {
  test('Basic MapScheme validates correctly', () {
    final field = MapScheme({
      'name': Field([isTypeString()]),
      'vat': Field.nullable([isTypeDouble()]),
      'age': Field([
        isTypeInt(),
        isMin(0),
      ]),
    });

    final invalidRes1 = field.validate({});
    expect(invalidRes1.isValid, false);
    expect(invalidRes1.expected, 'name -> String');

    final invalidRes2 = field.validate({'name': 'test'});
    expect(invalidRes2.isValid, false);
    expect(invalidRes2.expected, 'age -> int');

    final invalidRes3 = field.validate({'name': 'test', 'age': -12});
    expect(invalidRes3.isValid, false);
    expect(invalidRes3.expected, 'age -> higher or equal 0');
    expect(invalidRes3.toString(), 'Expected age -> higher or equal 0');

    final validRes1 = field.validate({'name': 'test', 'age': 12});
    expect(validRes1.isValid, true);
  });

  test('Nested MapSchemes validates correctly', () {
    final field = MapScheme({
      'address': MapScheme.nullable({
        'city': Field([isTypeString()]),
        'street': Field([isTypeString()]),
        'number': Field([
          isTypeInt(),
          isMin(0),
        ]),
        'additional': MapScheme.nullable({
          'doorbel_number': Field([isTypeInt()])
        }),
      })
    });

    final invalidRes4 = field.validate({
      'address': {
        'city': 'NY',
        'street': 132,
        'number': 32,
      },
    });
    expect(invalidRes4.isValid, false);
    expect(invalidRes4.expected, 'address -> street -> String');

    final invalidRes5 = field.validate({
      'address': {
        'city': 'NY',
        'street': '8th ave',
        'number': 32,
        'additional': {},
      },
    });
    expect(invalidRes5.isValid, false);
    expect(invalidRes5.expected, 'address -> additional -> doorbel_number -> int');
  });
  
  test('Map with ListScheme', () {
    final field = MapScheme({
      'books': ListScheme(
        fieldValidator: MapScheme({
          'name': Field([isTypeString()]),
        }),
      ),
    });

    final validRes1 = field.validate({'books': []});
    expect(validRes1.isValid, true);

    final validRes2 = field.validate({
      'books': [
        {'name': 'bookname'}
      ],
    });
    expect(validRes2.isValid, true);

    final invalidRes1 = field.validate({
      'books': [{}]
    });
    expect(invalidRes1.isValid, false);
    expect(invalidRes1.expected, 'books -> [0] -> name -> String');
  });
}
