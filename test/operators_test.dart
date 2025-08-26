import 'package:eskema/eskema.dart';
import 'package:test/test.dart' hide isNotEmpty, isEmpty;

void main() {
  test('& works', () {
    final username = ($isString & isNotEmpty());

    expect(username.validate('valid_username').isValid, true);
    expect(username.validate('').isValid, false);
    expect(username.validate('').description, 'length [greater than 0]');
  });

  test('| works', () {
    final stringOrInt = ($isString | isInt());

    expect(stringOrInt.validate('bad').isValid, true);
    expect(stringOrInt.validate(123).isValid, true);
    expect(stringOrInt.validate(true).isValid, false);
    expect(stringOrInt.validate([]).description, 'String, int');
  });

  test('& | combined works', () {
    final username = ($isInt | (isString() & isEmpty()));

    expect(username.validate(123).isValid, true);
    expect(username.validate('').isValid, true);
    expect(username.validate(123.2).isValid, false);
    expect(username.validate('bad').isValid, false);
  });
}
