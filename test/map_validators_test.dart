import 'package:test/test.dart';
import 'package:eskema/eskema.dart' hide isStringEmpty;

void main() {
  group('Map Validators', () {
    group('containsKey', () {
      test('passes when map contains the key', () {
        final validator = containsKey('name');
        final result = validator.validate({'name': 'Alice', 'age': 30});
        expect(result.isValid, true);
        expect(result.expectations, isEmpty);
      });

      test('fails when map does not contain the key', () {
        final validator = containsKey('name');
        final result = validator.validate({'age': 30});
        expect(result.isValid, false);
        expect(result.firstExpectation.code, 'value.contains_missing');
        expect(result.firstExpectation.message, 'contains key "name"');
      });

      test('fails when value is not a map', () {
        final validator = containsKey('name');
        final result = validator.validate('not a map');
        expect(result.isValid, false);
        expect(result.firstExpectation.code, 'type.mismatch');
      });
    });

    group('containsKeys', () {
      test('passes when map contains all keys', () {
        final validator = containsKeys(['name', 'age']);
        final result = validator.validate({'name': 'Alice', 'age': 30, 'city': 'NY'});
        expect(result.isValid, true);
        expect(result.expectations, isEmpty);
      });

      test('fails when map is missing some keys', () {
        final validator = containsKeys(['name', 'age']);
        final result = validator.validate({'name': 'Alice'});
        expect(result.isValid, false);
        expect(result.firstExpectation.code, 'value.contains_missing');
        expect(result.firstExpectation.message, 'contains keys: ["name","age"]');
      });

      test('fails when map is missing all keys', () {
        final validator = containsKeys(['name', 'age']);
        final result = validator.validate({'city': 'NY'});
        expect(result.isValid, false);
        expect(result.firstExpectation.code, 'value.contains_missing');
        expect(result.firstExpectation.message, 'contains keys: ["name","age"]');
      });

      test('fails when value is not a map', () {
        final validator = containsKeys(['name']);
        final result = validator.validate('not a map');
        expect(result.isValid, false);
        expect(result.firstExpectation.code, 'type.mismatch');
      });

      test('passes with empty keys list', () {
        final validator = containsKeys([]);
        final result = validator.validate({'name': 'Alice'});
        expect(result.isValid, true);
        expect(result.expectations, isEmpty);
      });
    });

    group('containsValues', () {
      test('passes when map contains all values', () {
        final validator = containsValues(['Alice', 30]);
        final result = validator.validate({'name': 'Alice', 'age': 30, 'city': 'NY'});
        expect(result.isValid, true);
        expect(result.expectations, isEmpty);
      });

      test('fails when map is missing some values', () {
        final validator = containsValues(['Alice', 25]);
        final result = validator.validate({'name': 'Alice', 'age': 30});
        expect(result.isValid, false);
        expect(result.firstExpectation.code, 'value.contains_missing');
        expect(result.firstExpectation.message, 'contains values: ["Alice",25]');
      });

      test('fails when map is missing all values', () {
        final validator = containsValues(['Alice', 25]);
        final result = validator.validate({'name': 'Bob', 'age': 30});
        expect(result.isValid, false);
        expect(result.firstExpectation.code, 'value.contains_missing');
        expect(result.firstExpectation.message, 'contains values: ["Alice",25]');
      });

      test('fails when value is not a map', () {
        final validator = containsValues(['Alice']);
        final result = validator.validate('not a map');
        expect(result.isValid, false);
        expect(result.firstExpectation.code, 'type.mismatch');
      });

      test('passes with empty values list', () {
        final validator = containsValues([]);
        final result = validator.validate({'name': 'Alice'});
        expect(result.isValid, true);
        expect(result.expectations, isEmpty);
      });

      test('handles null values correctly', () {
        final validator = containsValues([null, 'Alice']);
        final result = validator.validate({'name': 'Alice', 'value': null});
        expect(result.isValid, true);
        expect(result.expectations, isEmpty);
      });
    });
  });
}
