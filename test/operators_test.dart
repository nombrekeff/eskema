import 'package:eskema/eskema.dart';
import 'package:test/test.dart' hide isNotEmpty, isEmpty;

void main() {
  test('& works', () {
    final username = ($isString & isNotEmpty());

    expect(username.validate('valid_username').isValid, true);
    expect(username.validate('').isValid, false);
    expect(username.validate('').expected, 'length greater than 0');
  });

  test('| works', () {
    final stringOrInt = ($isString | isInteger());

    expect(stringOrInt.validate('bad').isValid, true);
    expect(stringOrInt.validate(123).isValid, true);
    expect(stringOrInt.validate(true).isValid, false);
    expect(stringOrInt.validate([]).expected, 'String or int');
  });

  test('& | combined works', () {
    final username = ($isInteger | (isString() & isEmpty()));

    expect(username.validate(123).isValid, true);
    expect(username.validate('').isValid, true);
    expect(username.validate(123.2).isValid, false);
    expect(username.validate('bad').isValid, false);
  });
}
