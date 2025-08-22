import 'package:test/test.dart';
import 'package:eskema/eskema.dart';

void main() {
  test('Basic ListField validates itself', () {
    final field = listIsOfLength(2);

    final invalidRes1 = field.validate([]);
    expect(invalidRes1.isValid, false);
    expect(invalidRes1.shortDescription, 'length [equal to 2 (value: 0)]');

    final invalidRes2 = field.validate([1]);
    expect(invalidRes2.isValid, false);
    expect(invalidRes2.shortDescription, 'length [equal to 2 (value: 1)]');

    final invalidRes3 = field.validate(123);
    expect(invalidRes3.isValid, false);
    expect(invalidRes3.shortDescription, 'List<dynamic>');

    final validRes1 = field.validate([1, "2"]);
    expect(validRes1.isValid, true);

    final validRes2 = field.validate(['1', '2']);
    expect(validRes2.isValid, true);
  });

  test('Nullable list with typed and null fields', () {
    final isListValid = nullable(all([
      listIsOfLength(2),
      listEach(isTypeOrNull<String>()),
    ]));

    final validRes1 = isListValid.validate(null);
    expect(validRes1.isValid, true);

    final validRes2 = isListValid.validate(['1', null]);
    expect(validRes2.isValid, true);

    final invalidRes1 = isListValid.validate(['1', null, 3]);
    expect(invalidRes1.isValid, false);
    expect(invalidRes1.shortDescription, 'length [equal to 2 (value: 3)]');
  });

  test('Basic ListField validates items', () {
    final isValidList = listEach(isType<int>());

    final validRes1 = isValidList.validate([1]);
    expect(validRes1.isValid, true);
    expect(isValidList.validate([1, 2, 3]).isValid, true);

    final validRes2 = isValidList.validate([]);
    expect(validRes2.isValid, true);

    final invalidRes1 = isValidList.validate(['string']);
    expect(invalidRes1.isValid, false);
    expect(invalidRes1.shortDescription, '[0]: int');
  });

  test('Nested ListField validates items', () {
    final isListValid = listEach(
      all([
        listIsOfLength(2),
        listEach(isType<int>()),
      ]),
    );

    final validRes1 = isListValid.validate([
      [1, 1],
      [2, 1]
    ]);
    expect(validRes1.isValid, true);

    final validRes2 = isListValid.validate([]);
    expect(validRes2.isValid, true);

    final invalidRes1 = isListValid.validate([
      [1]
    ]);
    expect(invalidRes1.isValid, false);
    expect(invalidRes1.shortDescription, '[0]: length [equal to 2 (value: 1)]');

    final invalidRes2 = isListValid.validate([
      [1, "aaaa"]
    ]);
    expect(invalidRes2.isValid, false);
    expect(invalidRes2.shortDescription, '[0][1]: int');
  });

  test('Map ListField', () {
    final isValidList = listEach(
      eskema({
        'city': isType<String>(),
        'street': isType<String>(),
      }),
    );
    final validRes1 = isValidList.validate([
      {'city': 'NY', 'street': '8th ave'}
    ]);
    expect(validRes1.isValid, true);

    final invalidRes1 = isValidList.validate([{}]);
    expect(invalidRes1.isValid, false);
    expect(invalidRes1.shortDescription, '[0].city: String, [0].street: String');
  });
}
