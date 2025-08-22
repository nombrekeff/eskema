import 'package:eskema/eskema.dart';
import 'package:test/test.dart';

void main() {
  test('fields validates correctly', () {
    final stringField = isType<String>();
    final intField = isType<int>();
    final doubleField = isType<double>();
    final numField = isType<num>();
    final boolField = isType<bool>();

    expect(boolField.isNotValid('not-valid'), true);
    expect(boolField.isValid(true), true);

    expect(stringField.validate('not-valid').isValid, true);
    expect(stringField.validate(123).isValid, false);
    expect(stringField.validate(123).error, 'String');

    expect(intField.validate(123).isValid, true);
    expect(intField.validate(123.2).error, 'int');

    expect(doubleField.validate(123.2).isValid, true);
    expect(doubleField.validate(123).error, 'double');

    expect(numField.validate(123.2).isValid, true);
    expect(numField.validate(123).isValid, true);
    expect(numField.validate('not-valid').isValid, false);
  });

  test('nullable and non-nullable fields', () {
    final nonNullableField = isType<String>();
    final nullableField = isTypeOrNull<String>();

    final resNullable = nullableField.validate(null);
    expect(resNullable.isValid, true);

    final res = nonNullableField.validate(null);
    expect(res.isValid, false);
    expect(res.error, 'String');

    expect(nullableField.validate('test').isValid, true);
    expect(nonNullableField.validate('test').isValid, true);
  });

  test('nullable fields', () {
    final nullable1 = isType<String>().copyWith(nullable: true);
    final nullable2 = isType<String>().nullable();
    final nullable3 = nullable(isType<String>());

    final nullableField = EskField(
      validators: [isType<String>()],
      id: '<id>',
      nullable: true,
    ).copyWith(nullable: true);

    expect(nullableField.validate('test').isValid, true);
    expect(nullableField.validate(null).isValid, true);

    expect(nullable1.validate('test').isValid, true);
    expect(nullable1.validate(null).isValid, true);

    expect(nullable2.validate('test').isValid, true);
    expect(nullable2.validate(null).isValid, true);

    expect(nullable3.validate('test').isValid, true);
    expect(nullable3.validate(null).isValid, true);
  });

  test('fields validates int correctly', () {
    final intValidator = all([
      isType<int>(),
      isGte(2),
      isLte(4),
    ]);
    expect(intValidator.validate('not a valid number').isValid, false);
    expect(intValidator.validate(1).isValid, false);
    expect(intValidator.validate(5).isValid, false);
    expect(intValidator.validate(1).error, 'greater than or equal to 2');
    expect(intValidator.validate(5).error, 'less than or equal to 4');

    expect(intValidator.validate(2).isValid, true);
    expect(intValidator.validate(3).isValid, true);
    expect(intValidator.validate(4).isValid, true);
  });

  test('custom validator ', () {
    final customValidator = all([
      isType<int>(),
      EskValidator((value) {
        if (value is num && value == 42) {
          return EskResult.invalid('that is the number', value);
        }

        return EskResult.valid(value);
      }),
    ]);
    expect(customValidator.validate(42).error, 'that is the number');
    expect(customValidator.validate(12).isValid, true);
  });

  test('isDate', () {
    final dateValidator = all([
      isType<String>(),
      isDate(),
    ]);

    expect(dateValidator.validate('1969-07-20 20:18:04Z').isValid, true);
    expect(dateValidator.validate('sadasd').error, 'a valid DateTime formatted String');
    expect(dateValidator.validate(123).error, 'String');
    expect(dateValidator.validate(true).error, 'String');
  });

  test('validate map', () {
    final field = all([
      isType<Map>(),
    ]);
    expect(field.validate({}).isValid, true);
    expect(field.validate('sadasd').error, 'Map<dynamic, dynamic>');
    expect(field.validate(123).error, 'Map<dynamic, dynamic>');
    expect(field.validate(true).error, 'Map<dynamic, dynamic>');
  });
}
