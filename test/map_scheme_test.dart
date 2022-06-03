import 'package:flutter_test/flutter_test.dart';
import 'package:json_scheme/json_scheme.dart';
import 'package:json_scheme/validators.dart';

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
    expect(invalidRes1.expected, 'name to be String');

    final invalidRes2 = field.validate({'name': 'test'});
    expect(invalidRes2.isValid, false);
    expect(invalidRes2.expected, 'age to be int');

    final invalidRes3 = field.validate({'name': 'test', 'age': -12});
    expect(invalidRes3.isValid, false);
    expect(invalidRes3.expected, 'age to be higher or equal 0');

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
    expect(invalidRes4.expected, 'address.street to be String');

    final invalidRes5 = field.validate({
      'address': {
        'city': 'NY',
        'street': '8th ave',
        'number': 32,
        'additional': {},
      },
    });
    expect(invalidRes5.isValid, false);
    expect(invalidRes5.expected, 'address.additional.doorbel_number to be int');
  });
}
