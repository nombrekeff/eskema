import 'package:flutter_test/flutter_test.dart';
import 'package:eskema/eskema.dart';

void main() {
  test('Basic ListField validates itself', () {
    final field = listIsOfLength(2);

    final invalidRes1 = field.call([]);
    expect(invalidRes1.isValid, false);
    expect(invalidRes1.expected, 'List of size 2');

    final invalidRes2 = field.call([1]);
    expect(invalidRes2.isValid, false);
    expect(invalidRes2.expected, 'List of size 2');

    final invalidRes3 = field.call(123);
    expect(invalidRes3.isValid, false);
    expect(invalidRes3.expected, 'List<dynamic>');

    final validRes1 = field.call([1, "2"]);
    expect(validRes1.isValid, true);

    final validRes2 = field.call(['1', '2']);
    expect(validRes2.isValid, true);
  });

  test('Nullable list with typed and null fields', () {
    final isListValid = nullable(all([
      listIsOfLength(2),
      listEach(isTypeOrNull<String>()),
    ]));

    final validRes1 = isListValid.call(null);
    expect(validRes1.isValid, true);

    final validRes2 = isListValid.call(['1', null]);
    expect(validRes2.isValid, true);

    final invalidRes1 = isListValid.call(['1', null, 3]);
    expect(invalidRes1.isValid, false);
    expect(invalidRes1.expected, 'List of size 2');
  });

  test('Basic ListField validates items', () {
    final isValidList = listEach(isType<int>());

    final validRes1 = isValidList([1]);
    expect(validRes1.isValid, true);
    expect(isValidList([1, 2, 3]).isValid, true);

    final validRes2 = isValidList([]);
    expect(validRes2.isValid, true);

    final invalidRes1 = isValidList(['string']);
    expect(invalidRes1.isValid, false);
    expect(invalidRes1.expected, '[0] -> int');
  });

  test('Nested ListField validates items', () {
    final isListValid = listEach(
      all([
        listIsOfLength(2),
        listEach(isType<int>()),
      ]),
    );

    final validRes1 = isListValid([
      [1, 1],
      [2, 1]
    ]);
    expect(validRes1.isValid, true);

    final validRes2 = isListValid([]);
    expect(validRes2.isValid, true);

    final invalidRes1 = isListValid([
      [1]
    ]);
    expect(invalidRes1.isValid, false);
    expect(invalidRes1.expected, '[0] -> List of size 2');

    final invalidRes2 = isListValid([
      [1, "aaaa"]
    ]);
    expect(invalidRes2.isValid, false);
    expect(invalidRes2.expected, '[0] -> [1] -> int');
  });

  test('Map ListField', () {
    final isValidList = listEach(
      eskema({
        'city': isType<String>(),
        'street': isType<String>(),
      }),
    );
    final validRes1 = isValidList.call([
      {'city': 'NY', 'street': '8th ave'}
    ]);
    expect(validRes1.isValid, true);

    final invalidRes1 = isValidList.call([{}]);
    expect(invalidRes1.isValid, false);
    expect(invalidRes1.expected, '[0] -> city -> String');
  });
}
