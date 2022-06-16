import 'package:eskema/validators.dart';
import 'package:eskema/extensions.dart' show EskemaMapExtension;
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Basic MapField validates correctly', () {
    final testEskema = {
      'name': all([isType<String>()]),
      'vat': all([
        isTypeOrNull<double>(),
      ]),
      'age': all([
        isType<int>(),
        isGte(0),
      ]),
    };

    final result = {'name': 'test', 'age': 12, 'vat': null}.matchesEskema(testEskema);
    expect(result.isValid, true);
  });
}
