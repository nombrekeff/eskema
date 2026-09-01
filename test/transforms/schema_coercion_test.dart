import 'package:eskema/eskema.dart' hide isTrue, isFalse, contains, isNull;
import 'package:test/test.dart';

void main() {
  group('SchemaCoercion & IValidator.coerce', () {
    test('coerces nested maps and applies field transformers', () {
      final schema = eskema({
        'user': eskema({
          'name': trim(isString()),
          'age': toInt(isGte(18)),
        }),
        'tag': toLowerCaseString(isString()),
      });

      final input = {
        'user': {
          'name': '  John Doe  ',
          'age': '30',
          'extraUserField': 'ignored',
        },
        'tag': 'ADMIN',
        'rootExtra': 999,
      };

      final result = schema.coerce(input, stripUnknownKeys: true);

      expect(result.isValid, isTrue);
      expect(result.value, {
        'user': {
          'name': 'John Doe',
          'age': 30,
        },
        'tag': 'admin',
      });
    });

    test('supports polymorphic switchBy branches', () {
      final schema = switchBy('kind', {
        'sms': eskema({
          'kind': isString(),
          'phoneNumber': trim(isString()),
        }),
        'email': eskema({
          'kind': isString(),
          'emailAddress': trim(toLowerCaseString(isEmail())),
        }),
      });

      final emailInput = {
        'kind': 'email',
        'emailAddress': '  ALICE@EXAMPLE.COM ',
        'unknownField': 123,
      };

      final emailResult = schema.coerce(emailInput, stripUnknownKeys: true);
      expect(emailResult.isValid, isTrue);
      expect(emailResult.value, {
        'kind': 'email',
        'emailAddress': 'alice@example.com',
      });

      final smsInput = {
        'kind': 'sms',
        'phoneNumber': ' +123456789 ',
        'extra': 'strip',
      };

      final smsResult = schema.coerce(smsInput, stripUnknownKeys: true);
      expect(smsResult.isValid, isTrue);
      expect(smsResult.value, {
        'kind': 'sms',
        'phoneNumber': '+123456789',
      });
    });

    test('preserves unknown keys when stripUnknownKeys is false', () {
      final schema = eskema({
        'id': toInt(isGte(1)),
      });

      final input = {
        'id': '42',
        'meta': 'preserved',
        'score': 100,
      };

      final result = schema.coerce(input, stripUnknownKeys: false);
      expect(result.isValid, isTrue);
      expect(result.value, {
        'id': 42,
        'meta': 'preserved',
        'score': 100,
      });
    });

    test('returns invalid result on schema validation failure', () {
      final schema = eskema({
        'age': toInt(isGte(18)),
      });

      final input = {
        'age': '12',
      };

      final result = schema.coerce(input);
      expect(result.isNotValid, isTrue);
    });
  });
}
