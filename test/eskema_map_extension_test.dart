import 'package:eskema/extensions.dart';
import 'package:eskema/validators.dart';
import 'package:test/test.dart';

void main() {
  test('Basic MapField validates correctly', () {
    final testEskema = eskema({
      'name': all([isType<String>()]),
      'vat': all([
        isTypeOrNull<double>(),
      ]),
      'age': all([
        isType<int>(),
        isGte(0),
      ]),
    });

    final result =
        {'name': 'test', 'age': 12, 'vat': null}.validate(testEskema);
    expect(result.isValid, true);
  });

  test('MapField with additional properties validates correctly', () {
    final testEskema = eskema({
      'name': all([isType<String>()]),
      'vat': all([
        isTypeOrNull<double>(),
      ]),
      'age': all([
        isType<int>(),
        isGte(0),
      ]),
    });

    final result = {'name': 'test', 'age': 12, 'vat': null}.isValid(testEskema);
    expect(result, true);

    final result2 = {
      'name': 'test',
      'age': 12,
      'vat': null,
    }.isNotValid(testEskema);
    expect(result2, false);
  });
}
