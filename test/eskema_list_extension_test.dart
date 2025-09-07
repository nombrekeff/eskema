import 'package:eskema/extensions.dart';
import 'package:eskema/validators.dart';
import 'package:test/test.dart';

void main() {
  test('List extensions validates correctly', () {
    final testEskema = eskema({
      'city': isType<String>(),
      'street': isType<String>(),
    });

    final result = [
      {'city': 'NY', 'street': '8th ave'}
    ].validate(testEskema);

    expect(result.isValid, true);

    final result2 = [
      {'city': 'NY', 'street': 123}
    ].validate(testEskema);

    expect(result2.isValid, false);
    expect(result2.description, '[0].street: String');
  });
}
