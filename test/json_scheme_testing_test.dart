import 'package:flutter_test/flutter_test.dart';
import 'package:json_scheme/json_scheme.dart';
import 'package:json_scheme/validators.dart';

void main() {
  test('fields validates correctly', () {
    final stringValidator = Field([isTypeString()]);
    final intValidator = Field([isTypeInt()]);
    final doubleValidator = Field([isTypeDouble()]);

    expect(stringValidator.validate('test'), null);
    expect(stringValidator.validate(123), 'expected String');
    expect(intValidator.validate(123), null);
    expect(intValidator.validate(123.2), 'expected int');
    expect(doubleValidator.validate(123.2), null);
  });

  test('nullable and non-nullable fields', () {
    final nonNullableField = Field([isTypeString()]);
    final nullableField = Field.nullable([isTypeString()]);

    expect(
      nullableField.validate(null),
      null,
    );
    expect(
      nonNullableField.validate(null),
      "value can't be null",
    );

    expect(
      nullableField.validate('test'),
      null,
    );
    expect(
      nonNullableField.validate('test'),
      null,
    );
  });

  test('fields validates int correctly', () {
    final intValidator = Field([
      isTypeInt(),
      isMin(2),
      isMax(4),
    ]);
    expect(intValidator.validate(1), 'value is under the min value of "2"');
    expect(intValidator.validate(2), null);
    expect(intValidator.validate(3), null);
    expect(intValidator.validate(4), null);
    expect(intValidator.validate(5), 'value is over the max value of "4"');
  });

  test('isMin of non number value ', () {
    expect(isMin(1)(''), null);
  });

  test('custom validator ', () {
    final customValidator = Field([
      isTypeInt(),
      (value) {
        if (value is num && value == 42) return 'that is the number';

        return null;
      },
    ]);
    expect(customValidator.validate(42), 'that is the number');
    expect(customValidator.validate(12), null);
  });

  test('isDate', () {
    final dateValidator = Field([
      isTypeString(),
      isDate(),
    ]);

    expect(dateValidator.validate('1969-07-20 20:18:04Z'), null);
    expect(dateValidator.validate('sadasd'), 'value is not a valid date');
    expect(dateValidator.validate(123), 'expected String');
    expect(dateValidator.validate(true), 'expected String');
  });

  test('validate map', () {
    final dateValidator = Field([
      isTypeMap(),
    ]);
    expect(dateValidator.validate({}), null);
    expect(dateValidator.validate('sadasd'), 'expected Map');
    expect(dateValidator.validate(123), 'expected Map');
    expect(dateValidator.validate(true), 'expected Map');
  });

  test('either', () {
    final field = Field([
      either(isTypeMap(), isTypeList()),
    ]);
    expect(field.validate({}), null);
    expect(field.validate([]), null);
    expect(field.validate(''), 'expected Map or expected List');
  });
}
