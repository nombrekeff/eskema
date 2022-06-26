import 'package:eskema/validators.dart';
import 'package:eskema/extensions.dart' show EskemaListExtension;
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('List extension "eachItemMatches" validates correctly', () {
    final testEskema = eskema({
      'city': isType<String>(),
      'street': isType<String>(),
    });

    final result = [
      {'city': 'NY', 'street': '8th ave'}
    ].eachItemMatches(testEskema);

    expect(result.isValid, true);
  });

  test('List extensions validates correctly', () {
    final testEskema = eskema({
      'city': isType<String>(),
      'street': isType<String>(),
    });

    final result = [
      {'city': 'NY', 'street': '8th ave'}
    ].matchesEskema([testEskema]);

    expect(result.isValid, true);

    final result2 = [
      {'city': 'NY', 'street': '8th ave'}
    ].matchesEskema([testEskema, testEskema]);

    expect(result2.isValid, false);
    expect(result2.expected, 'List of size 2');
  });
}
