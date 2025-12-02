import 'package:eskema/eskema.dart' hide contains;
import 'package:test/test.dart';

void main() {
  group('resolve validator', () {
    final adminSchema = eskema({
      'role': isEq('admin'),
      'secret': isString(),
    });

    final userSchema = eskema({
      'role': isEq('user'),
      'bio': isString(),
    });

    final schema = eskema({
      'role': isOneOf(['admin', 'user']),
      'data': resolve((parent) {
        if (parent['role'] == 'admin') {
          return adminSchema;
        } else {
          return userSchema;
        }
      }),
    });

    test('should validate using admin schema when role is admin', () {
      final validAdmin = {
        'role': 'admin',
        'data': {'role': 'admin', 'secret': '123'}
      };
      expect(schema.validate(validAdmin).isValid, isTrue);

      final invalidAdmin = {
        'role': 'admin',
        'data': {'role': 'admin', 'bio': 'I am admin'} // 'bio' not in adminSchema
      };
      expect(schema.validate(invalidAdmin).isValid, isFalse);
    });

    test('should validate using user schema when role is user', () {
      final validUser = {
        'role': 'user',
        'data': {'role': 'user', 'bio': 'Hello'}
      };
      expect(schema.validate(validUser).isValid, isTrue);

      final invalidUser = {
        'role': 'user',
        'data': {'role': 'user', 'secret': 'shh'} // 'secret' not in userSchema
      };
      expect(schema.validate(invalidUser).isValid, isFalse);
    });

    test('should pass if resolver returns null', () {
      final nullResolverSchema = eskema({
        'any': resolve((parent) => null),
      });
      expect(nullResolverSchema.validate({'any': 'thing'}).isValid, isTrue);
    });

    test('should fail if used outside of eskema map', () {
      final v = resolve((p) => isString());
      final result = v.validate('test');
      expect(result.isValid, isFalse);
      expect(result.description, contains('can only be used inside an `eskema` map validator'));
    });

    test('async validation in resolved validator', () async {
      final asyncValSchema = eskema({
        'val': resolve((parent) {
          return Validator((v) async {
            await Future.delayed(const Duration(milliseconds: 10));
            return v == 'ok' ? Result.valid(v) : Result.invalid(v);
          });
        }),
      });

      final result = await asyncValSchema.validateAsync({'val': 'ok'});
      expect(result.isValid, isTrue);

      final failResult = await asyncValSchema.validateAsync({'val': 'no'});
      expect(failResult.isValid, isFalse);
    });
  });
}
