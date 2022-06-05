import 'package:flutter_test/flutter_test.dart';
import 'package:json_scheme/json_scheme.dart';

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

    final validRes1 = field.validate([1, "2"]);
    expect(validRes1.isValid, true);

    final validRes2 = field.validate(['1', '2']);
    expect(validRes2.isValid, true);
  });

  test('Nullable ListScheme ', () {
    final field = ListScheme.nullable(validators: [listIsOfSize(2)]);

    final validRes1 = field.validate(null);
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
    expect(field.validate([1, 2, 3]).isValid, true);

    final validRes2 = field.validate([]);
    expect(validRes2.isValid, true);

    final invalidRes1 = field.validate(['string']);
    expect(invalidRes1.isValid, false);
    expect(invalidRes1.expected, '[0] -> int');
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
    expect(invalidRes1.expected, '[0] -> List of size 2');

    final invalidRes2 = field.validate([
      [1, "aaaa"]
    ]);
    expect(invalidRes2.isValid, false);
    expect(invalidRes2.expected, '[0] -> [1] -> int');
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
    expect(invalidRes1.expected, '[0] -> city -> String');
  });

  test('Map with ListScheme', () {
    final field = MapScheme({
      'books': ListScheme(
        fieldValidator: MapScheme({
          'name': Field([isTypeString()]),
        }),
      ),
    });
    final validRes1 = field.validate({
      'books': [],
    });
    expect(validRes1.isValid, true);

    final validRes2 = field.validate({
      'books': [
        {'name': 'bookname'}
      ],
    });
    expect(validRes2.isValid, true);

    final invalidRes1 = field.validate({
      'books': [{}],
    });
    expect(invalidRes1.isValid, false);
    expect(invalidRes1.expected, 'books -> [0] -> name -> String');
  });
}