import 'package:eskema/validators.dart';
import 'package:eskema/extensions.dart' show EskemaMapExtension;
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
}
