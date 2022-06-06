import 'package:eskema/eskema.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('fields validates correctly', () {
    final stringField = Field([isTypeString()]);
    final intField = Field([isTypeInt()]);
    final doubleField = Field([isTypeDouble()]);
    final numField = Field([isTypeNum()]);
    final boolField = Field([isTypeBool()]);

    expect(boolField.validate('not-valid').isValid, false);
    expect(boolField.validate(true).isValid, true);

    expect(stringField.validate('not-valid').isValid, true);
    expect(stringField.validate(123).isValid, false);
    expect(stringField.validate(123).expected, 'String');

    expect(intField.validate(123).isValid, true);
    expect(intField.validate(123.2).expected, 'int');

    expect(doubleField.validate(123.2).isValid, true);
    expect(doubleField.validate(123).expected, 'double');

    expect(numField.validate(123.2).isValid, true);
    expect(numField.validate(123).isValid, true);
    expect(numField.validate('not-valid').isValid, false);
  });

  test('nullable and non-nullable fields', () {
    final nonNullableField = Field([isTypeString()]);
    final nullableField = Field([
      either(
        isTypeString(),
        isTypeNull(),
      ),
    ]);

    expect(nullableField.validate(null).isValid, true);

    final res = nonNullableField.validate(null);
    expect(res.isValid, false);
    expect(res.expected, 'String');

    expect(nullableField.validate('test').isValid, true);
    expect(nonNullableField.validate('test').isValid, true);
  });

  test('fields validates int correctly', () {
    final intValidator = Field([
      isTypeInt(),
      isMin(2),
      isMax(4),
    ]);
    expect(intValidator.validate('not a valid number').isValid, false);
    expect(intValidator.validate(1).isValid, false);
    expect(intValidator.validate(5).isValid, false);
    expect(intValidator.validate(1).expected, 'higher or equal 2');
    expect(intValidator.validate(5).expected, 'lower or equal 4');

    expect(intValidator.validate(2).isValid, true);
    expect(intValidator.validate(3).isValid, true);
    expect(intValidator.validate(4).isValid, true);
  });

  test('custom validator ', () {
    final customValidator = Field([
      isTypeInt(),
      (value) {
        if (value is num && value == 42) {
          return Result.invalid('that is the number');
        }

        return Result.valid;
      },
    ]);
    expect(customValidator.validate(42).expected, 'that is the number');
    expect(customValidator.validate(12).isValid, true);
  });

  test('isDate', () {
    final dateValidator = Field([
      isTypeString(),
      isDate(),
    ]);

    expect(dateValidator.validate('1969-07-20 20:18:04Z').isValid, true);
    expect(dateValidator.validate('sadasd').expected, 'a valid date');
    expect(dateValidator.validate(123).expected, 'String');
    expect(dateValidator.validate(true).expected, 'String');
  });

  test('validate map', () {
    final field = Field([
      isTypeMap(),
    ]);
    expect(field.validate({}).isValid, true);
    expect(field.validate('sadasd').expected, 'Map<dynamic, dynamic>');
    expect(field.validate(123).expected, 'Map<dynamic, dynamic>');
    expect(field.validate(true).expected, 'Map<dynamic, dynamic>');
  });

  test('either', () {
    final field = Field([
      either(isTypeMap(), isTypeList()),
    ]);
    expect(field.validate({}).isValid, true);
    expect(field.validate([]).isValid, true);
    expect(field.validate('').expected, 'Map<dynamic, dynamic> or List<dynamic>');
  });
}
