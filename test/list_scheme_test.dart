import 'package:flutter_test/flutter_test.dart';
import 'package:json_scheme/json_scheme.dart';
import 'package:json_scheme/validators.dart';

void main() {
  test('Basic ListScheme validates itself', () {
    final field = ListScheme(validators: [listIsOfSize(2)]);

    final invalidRes1 = field.validate([]);
    expect(invalidRes1.isValid, false);
    expect(invalidRes1.expected, 'List of size 2');

    final invalidRes2 = field.validate([1]);
    expect(invalidRes2.isValid, false);
    expect(invalidRes2.expected, 'List of size 2');

    final invalidRes3 = field.validate(123);
    expect(invalidRes3.isValid, false);
    expect(invalidRes3.expected, 'List<dynamic>');
    expect(invalidRes3.actual, 'int');

    final validRes1 = field.validate([1, "2"]);
    expect(validRes1.isValid, true);

    final validRes2 = field.validate(['1', '2']);
    expect(validRes2.isValid, true);
  });

  test('Basic ListScheme validates items', () {
    final field = ListScheme(
      fieldValidator: Field([
        isTypeInt(),
      ]),
    );
    final validRes1 = field.validate([1]);
    expect(validRes1.isValid, true);

    final validRes2 = field.validate([]);
    expect(validRes2.isValid, true);

    final invalidRes1 = field.validate(['string']);
    expect(invalidRes1.isValid, false);
    expect(invalidRes1.expected, '[0] to be int');
  });

  test('Nested ListScheme validates items', () {
    final field = ListScheme(
      fieldValidator: ListScheme(
        validators: [listIsOfSize(2)],
        fieldValidator: Field([
          isTypeInt(),
        ]),
      ),
    );
    final validRes1 = field.validate([
      [1, 1],
      [2, 1]
    ]);
    expect(validRes1.isValid, true);

    final validRes2 = field.validate([]);
    expect(validRes2.isValid, true);

    final invalidRes1 = field.validate([
      [1]
    ]);
    expect(invalidRes1.isValid, false);
    expect(invalidRes1.expected, '[0] to be List of size 2');

    final invalidRes2 = field.validate([
      [1, "aaaa"]
    ]);
    expect(invalidRes2.isValid, false);
    expect(invalidRes2.expected, '[0] to be List of size 2');
  });

  test('Map ListScheme', () {
    final field = ListScheme(
      fieldValidator: MapScheme({
        'city': Field([isTypeString()]),
        'street': Field([isTypeString()]),
      }),
    );
    final validRes1 = field.validate([
      {'city': 'NY', 'street': '8th ave'}
    ]);
    expect(validRes1.isValid, true);

    final invalidRes1 = field.validate([{}]);
    expect(invalidRes1.isValid, false);
    expect(invalidRes1.expected, '[0].city to be String');
  });
}
