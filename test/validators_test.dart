import 'package:eskema/util.dart';
import 'package:eskema/validators.dart';
import 'package:test/test.dart';

void main() {
  group('isType', () {
    test('isTypeNull works', () {
      final res1 = isTypeNull().validate("");
      expect(res1.isValid, false);

      final res2 = isTypeNull().validate(123);
      expect(res2.isValid, false);
      expect(res2.expected, 'null');

      final res3 = isTypeNull().validate(true);
      expect(res3.isValid, false);
      expect(res3.expected, 'null');

      final res4 = isTypeNull().validate(null);
      expect(res4.isValid, true);
    });

    test('isType<String> works', () {
      final res1 = isType<String>().validate("");
      expect(res1.isValid, true);

      final res2 = isType<String>().validate(123);
      expect(res2.isValid, false);
      expect(res2.expected, 'String');

      final res3 = isType<String>().validate(true);
      expect(res3.isValid, false);
      expect(res3.expected, 'String');
    });

    test('isType<int> works', () {
      final res1 = isType<int>().validate(123);
      expect(res1.isValid, true);

      final res2 = isType<int>().validate("123");
      expect(res2.isValid, false);
      expect(res2.expected, 'int');

      final res3 = isType<int>().validate(true);
      expect(res3.isValid, false);
      expect(res3.expected, 'int');
    });

    test('isType<num> works', () {
      final res1 = isType<num>().validate(123);
      expect(res1.isValid, true);

      final res2 = isType<num>().validate("123");
      expect(res2.isValid, false);
      expect(res2.expected, 'num');

      final res3 = isType<num>().validate(true);
      expect(res3.isValid, false);
      expect(res3.expected, 'num');
    });

    test('isType<double> works', () {
      final res1 = isType<double>().validate(123.12);
      expect(res1.isValid, true);

      final res2 = isType<double>().validate("123");
      expect(res2.isValid, false);
      expect(res2.expected, 'double');

      final res3 = isType<double>().validate(true);
      expect(res3.isValid, false);
      expect(res3.expected, 'double');

      final res4 = isType<double>().validate(123);
      expect(res4.isValid, false);
      expect(res4.expected, 'double');
    });

    test('isType<bool> works', () {
      final res1 = isType<bool>().validate(true);
      expect(res1.isValid, true);

      final res2 = isType<bool>().validate("123");
      expect(res2.isValid, false);
      expect(res2.expected, 'bool');

      final res3 = isType<bool>().validate(123);
      expect(res3.isValid, false);
      expect(res3.expected, 'bool');
    });

    test('isType<Map> works', () {
      final res1 = isType<Map>().validate({});
      expect(res1.isValid, true);

      final res2 = isType<Map>().validate("123");
      expect(res2.isValid, false);
      expect(res2.expected, 'Map<dynamic, dynamic>');

      final res3 = isType<Map>().validate(123);
      expect(res3.isValid, false);
      expect(res3.expected, 'Map<dynamic, dynamic>');
    });

    test('isType<List> works', () {
      final res1 = isType<List>().validate([]);
      expect(res1.isValid, true);

      final res2 = isType<List>().validate("123");
      expect(res2.isValid, false);
      expect(res2.expected, 'List<dynamic>');

      final res3 = isType<List>().validate(123);
      expect(res3.isValid, false);
      expect(res3.expected, 'List<dynamic>');
    });
  });

  group('Number validators', () {
    test('isLt works', () {
      final validator = isLt(10);

      expect(validator.validate(1).isValid, true);
      expect(validator.validate(9).isValid, true);

      final res2 = validator.validate(10);
      expect(res2.isValid, false);
      expect(res2.expected, 'less than 10');
    });

    test('isLte works', () {
      final validator = isLte(10);

      expect(validator.validate(1).isValid, true);
      expect(validator.validate(9).isValid, true);
      expect(validator.validate(10).isValid, true);

      final res2 = validator.validate(11);
      expect(res2.isValid, false);
      expect(res2.expected, 'less than or equal to 10');
      expect(
        res2.toString(),
        'Expected less than or equal to 10, got 11',
      );
    });

    test('isGt works', () {
      final validator = isGt(10);

      expect(validator.validate(11).isValid, true);
      expect(validator.validate(12).isValid, true);

      final res2 = validator.validate(10);
      expect(res2.isValid, false);
      expect(res2.expected, 'greater than 10');
    });

    test('isGte works', () {
      final validator = isGte(10);

      expect(validator.validate(10).isValid, true);
      expect(validator.validate(11).isValid, true);
      expect(validator.validate(12).isValid, true);

      final res2 = validator.validate(9);
      expect(res2.isValid, false);
      expect(res2.expected, 'greater than or equal to 10');
    });

    test('isEq works', () {
      final validator = isEq(10);

      expect(validator.validate(10).isValid, true);

      final res2 = validator.validate(11);
      expect(res2.isValid, false);
      expect(res2.expected, 'equal to 10');

      final res3 = validator.validate('11');
      expect(res3.isValid, false);
      expect(res3.expected, 'int');
    });
  });

  group('String validator', () {
    test('stringIsOfLength works', () {
      final validator = stringIsOfLength(2);

      expect(validator.validate("12").isValid, true);
      expect(validator.validate("ab").isValid, true);
      expect(validator.validate("--").isValid, true);

      final res1 = validator.validate('1');
      expect(res1.isValid, false);
      expect(res1.expected, 'String of length 2');

      final res2 = validator.validate('123');
      expect(res2.isValid, false);
      expect(res2.expected, 'String of length 2');

      final res3 = validator.validate(1232);
      expect(res3.isValid, false);
      expect(res3.expected, 'String');
    });

    test('stringContains works', () {
      final validator = stringContains("needle");

      expect(validator.validate("I used a needle").isValid, true);
      expect(validator.validate("needles are cool").isValid, true);
      expect(validator.validate("needle").isValid, true);

      final res1 = validator.validate('this is a useless string');
      expect(res1.isValid, false);
      expect(res1.expected, 'String to contain "needle"');

      final res2 = validator.validate(1232);
      expect(res2.isValid, false);
      expect(res2.expected, 'String');
    });

    test('stringNotContains works', () {
      final validator = stringNotContains("needle");

      final res1 = validator.validate('this is a useless string');
      expect(res1.isValid, true);
      expect(res1.expected, 'String to not contain "needle"');

      final res2 = validator.validate(1232);
      expect(res2.isValid, false);
      expect(res2.expected, 'String');

      expect(validator.validate("I used a needle").isValid, false);
      expect(validator.validate("needles are cool").isValid, false);
      expect(validator.validate("needle").isValid, false);
    });

    test('stringMatchesPattern works', () {
      final validator = stringMatchesPattern(RegExp(r"[\d]"));
      expect(validator.validate("123").isValid, true);
      expect(validator.validate("55555").isValid, true);

      final res2 = validator.validate('aaaaa');
      expect(res2.isValid, false);
      expect(res2.expected, 'String to match "RegExp: pattern=[\\d] flags="');
    });

    test('stringMatchesPattern works with custom message', () {
      final validator = stringMatchesPattern(
        RegExp(r"[\d]"),
        expectedMessage: "Incorrect numerical string",
      );
      expect(validator.validate("123").isValid, true);
      expect(validator.validate("55555").isValid, true);

      final res2 = validator.validate('aaaaa');
      expect(res2.isValid, false);
      expect(res2.expected, 'Incorrect numerical string');
    });

    test('isEq<String> works', () {
      final validator = isEq<String>('10');

      expect(validator.validate('10').isValid, true);

      final res2 = validator.validate(11);
      expect(res2.isValid, false);
      expect(res2.expected, 'String');

      final res3 = validator.validate('11');
      expect(res3.isValid, false);
      expect(res3.expected, 'equal to "10"');
    });

    test('isEq<Map> works', () {
      final map = {"test": "aaa"};
      final validator = isEq<Map>(map);

      final res1 = validator.validate(map);
      expect(res1.isValid, true);

      final res2 = validator.validate(11);
      expect(res2.isValid, false);
      expect(res2.expected, 'Map<dynamic, dynamic>');

      final res3 = validator.validate({});
      expect(res3.isValid, false);
      expect(res3.expected, 'equal to {"test":"aaa"}');
    });
  });

  group('List validators', () {
    group('listContains', () {
      test('empty list, needle not found', () {
        final listContainsNeedle = listContains('abc');

        final res1 = listContainsNeedle.validate([]);
        expect(res1.isValid, false);
        expect(res1.expected, 'List to contain "abc"');
      });
      test('list without needle, needle not found', () {
        final listContainsNeedle = listContains('abc');

        final res1 = listContainsNeedle.validate(['aaaa', 'bbbb', 'ccc']);
        expect(res1.isValid, false);
        expect(res1.expected, 'List to contain "abc"');
      });

      test('list wit needle, needle found', () {
        final listContainsNeedle = listContains('abc');

        final res1 = listContainsNeedle.validate(['aaaa', 'abc', 'ccc']);
        expect(res1.isValid, true);
      });
    });

    test('eskemaList works', () {
      final validator = eskemaList([isType<String>(), isType<int>()]);

      final res1 = validator.validate([]);
      expect(res1.isValid, false);
      expect(res1.expected, 'List of size 2');

      final res2 = validator.validate([1, 2]);
      expect(res2.isValid, false);
      expect(res2.expected, '[0] -> String');

      final res3 = validator.validate([1, 2, 3]);
      expect(res3.isValid, false);
      expect(res3.expected, 'List of size 2');

      final res4 = validator.validate(["1", 2]);
      expect(res4.isValid, true);
    });
  });

  group('Utility validators', () {
    test('not validator works', () {
      final validator = not(isType<String>());
      expect(validator.validate('10').isValid, false);
      expect(validator.validate(10).isValid, true);
      expect(validator.validate(false).isValid, true);
    });

    test('or', () {
      final field = any([isType<Map>(), isType<List>()]);

      expect(field.validate({}).isValid, true);
      expect(field.validate([]).isValid, true);
      expect(field.validate('').expected, 'Map<dynamic, dynamic> or List<dynamic>');
    });

    test('and', () {
      final field = all([isType<int>(), isGt(10)]);

      expect(field.validate(11).isValid, true);
      expect(field.validate(345).isValid, true);

      expect(field.validate('345').isValid, false);
      expect(field.validate('345').expected, 'int');
    });

    test('isEq for "primitives"', () {
      final field = isEq<int>(2);
      expect(field.validate({}).isValid, false);
      expect(field.validate({}).expected, 'int');
      expect(field.validate([]).isValid, false);
      expect(field.validate(1).expected, 'equal to 2');

      expect(field.validate(2).isValid, true);
    });

    test('isDeepEq for maps', () {
      final isEquals = isDeepEq<Map>({
        'a': 'b',
        'c': {'c1': 'aaaa'}
      });

      expect(isEquals.validate({}).isValid, false);
      expect(isEquals.validate({}).expected, 'equal to {"a":"b","c":{"c1":"aaaa"}}');
      expect(isEquals.validate([]).isValid, false);
      expect(
        isEquals.validate(1).expected,
        'Map<dynamic, dynamic>',
      );
      expect(
        isEquals.validate({
          'a': 'b',
          'c': {'c1': 'aaaa'}
        }).isValid,
        true,
      );
    });

    test('isOneOf', () {
      final oneOf = isOneOf<String>(['abc', 'def']);

      expect(oneOf.validate('abc').isValid, true);
      expect(oneOf.validate('def').isValid, true);
      expect(oneOf.validate('xyz').isValid, false);
      expect(oneOf.validate('xyz').expected, 'one of: ["abc","def"]');
    });

    test('isDeepEq for lists', () {
      final isEquals = isDeepEq<List>([1, 2]);

      expect(isEquals.validate([]).isValid, false);
      expect(isEquals.validate([]).expected, 'equal to [1,2]');
      expect(isEquals.validate({}).isValid, false);
      expect(
        isEquals.validate(1).expected,
        'List<dynamic>',
      );
      expect(
        isEquals.validate([1, 2]).isValid,
        true,
      );
    });

    test('isDeepEq for sets', () {
      final isEquals = isDeepEq<Set>({1, 2});

      expect(isEquals.validate({1}).isValid, false);
      expect(isEquals.validate({1}).expected, 'equal to {1, 2}');
      expect(isEquals.validate({1}).isValid, false);
      expect(
        isEquals.validate(1).expected,
        'Set<dynamic>',
      );
      expect(
        isEquals.validate({1, 2}).isValid,
        true,
      );
    });

    test('throwInstead', () {
      final isEquals = throwInstead(isDeepEq<Set>({1, 2}));
      expect(() => isEquals.validate({1}), throwsA(isA<ValidatorFailedException>()));
      expect(() => isEquals.validate({1, 2}), isNot(throwsA(isA<ValidatorFailedException>())));
    });
  });
}
