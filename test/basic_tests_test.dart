import 'package:eskema/eskema.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('fields validates correctly', () {
    final stringField = isType<String>();
    final intField = isType<int>();
    final doubleField = isType<double>();
    final numField = isType<num>();
    final boolField = isType<bool>();

    expect(boolField.call('not-valid').isValid, false);
    expect(boolField.call(true).isValid, true);

    expect(stringField.call('not-valid').isValid, true);
    expect(stringField.call(123).isValid, false);
    expect(stringField.call(123).expected, 'String');

    expect(intField.call(123).isValid, true);
    expect(intField.call(123.2).expected, 'int');

    expect(doubleField.call(123.2).isValid, true);
    expect(doubleField.call(123).expected, 'double');

    expect(numField.call(123.2).isValid, true);
    expect(numField.call(123).isValid, true);
    expect(numField.call('not-valid').isValid, false);
  });

  test('nullable and non-nullable fields', () {
    final nonNullableField = isType<String>();
    final nullableField = isTypeOrNull<String>();

    expect(nullableField.call(null).isValid, true);

    final res = nonNullableField.call(null);
    expect(res.isValid, false);
    expect(res.expected, 'String');

    expect(nullableField.call('test').isValid, true);
    expect(nonNullableField.call('test').isValid, true);
  });

  test('fields validates int correctly', () {
    final intValidator = all([
      isType<int>(),
      isGte(2),
      isLte(4),
    ]);
    expect(intValidator.call('not a valid number').isValid, false);
    expect(intValidator.call(1).isValid, false);
    expect(intValidator.call(5).isValid, false);
    expect(intValidator.call(1).expected, 'greater than or equal to 2');
    expect(intValidator.call(5).expected, 'less than or equal to 4');

    expect(intValidator.call(2).isValid, true);
    expect(intValidator.call(3).isValid, true);
    expect(intValidator.call(4).isValid, true);
  });

  test('custom validator ', () {
    final customValidator = all([
      isType<int>(),
      (value) {
        if (value is num && value == 42) {
          return Result.invalid('that is the number');
        }

        return Result.valid;
      },
    ]);
    expect(customValidator.call(42).expected, 'that is the number');
    expect(customValidator.call(12).isValid, true);
  });

  test('isDate', () {
    final dateValidator = all([
      isType<String>(),
      isDate(),
    ]);

    expect(dateValidator.call('1969-07-20 20:18:04Z').isValid, true);
    expect(dateValidator.call('sadasd').expected, 'a valid date');
    expect(dateValidator.call(123).expected, 'String');
    expect(dateValidator.call(true).expected, 'String');
  });

  test('validate map', () {
    final field = all([
      isType<Map>(),
    ]);
    expect(field.call({}).isValid, true);
    expect(field.call('sadasd').expected, 'Map<dynamic, dynamic>');
    expect(field.call(123).expected, 'Map<dynamic, dynamic>');
    expect(field.call(true).expected, 'Map<dynamic, dynamic>');
  });


}
