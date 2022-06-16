import 'package:eskema/util.dart';
import 'package:eskema/validators.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('isType', () {
    test('isTypeNull works', () {
      final res1 = isTypeNull().call("");
      expect(res1.isValid, false);

      final res2 = isTypeNull().call(123);
      expect(res2.isValid, false);
      expect(res2.expected, 'null');

      final res3 = isTypeNull().call(true);
      expect(res3.isValid, false);
      expect(res3.expected, 'null');

      final res4 = isTypeNull().call(null);
      expect(res4.isValid, true);
    });

    test('isType<String> works', () {
      final res1 = isType<String>().call("");
      expect(res1.isValid, true);

      final res2 = isType<String>().call(123);
      expect(res2.isValid, false);
      expect(res2.expected, 'String');

      final res3 = isType<String>().call(true);
      expect(res3.isValid, false);
      expect(res3.expected, 'String');
    });

    test('isType<int> works', () {
      final res1 = isType<int>().call(123);
      expect(res1.isValid, true);

      final res2 = isType<int>().call("123");
      expect(res2.isValid, false);
      expect(res2.expected, 'int');

      final res3 = isType<int>().call(true);
      expect(res3.isValid, false);
      expect(res3.expected, 'int');
    });

    test('isType<num> works', () {
      final res1 = isType<num>().call(123);
      expect(res1.isValid, true);

      final res2 = isType<num>().call("123");
      expect(res2.isValid, false);
      expect(res2.expected, 'num');

      final res3 = isType<num>().call(true);
      expect(res3.isValid, false);
      expect(res3.expected, 'num');
    });

    test('isType<double> works', () {
      final res1 = isType<double>().call(123.12);
      expect(res1.isValid, true);

      final res2 = isType<double>().call("123");
      expect(res2.isValid, false);
      expect(res2.expected, 'double');

      final res3 = isType<double>().call(true);
      expect(res3.isValid, false);
      expect(res3.expected, 'double');

      final res4 = isType<double>().call(123);
      expect(res4.isValid, false);
      expect(res4.expected, 'double');
    });

    test('isType<bool> works', () {
      final res1 = isType<bool>().call(true);
      expect(res1.isValid, true);

      final res2 = isType<bool>().call("123");
      expect(res2.isValid, false);
      expect(res2.expected, 'bool');

      final res3 = isType<bool>().call(123);
      expect(res3.isValid, false);
      expect(res3.expected, 'bool');
    });

    test('isType<Map> works', () {
      final res1 = isType<Map>().call({});
      expect(res1.isValid, true);

      final res2 = isType<Map>().call("123");
      expect(res2.isValid, false);
      expect(res2.expected, 'Map<dynamic, dynamic>');

      final res3 = isType<Map>().call(123);
      expect(res3.isValid, false);
      expect(res3.expected, 'Map<dynamic, dynamic>');
    });

    test('isType<List> works', () {
      final res1 = isType<List>().call([]);
      expect(res1.isValid, true);

      final res2 = isType<List>().call("123");
      expect(res2.isValid, false);
      expect(res2.expected, 'List<dynamic>');

      final res3 = isType<List>().call(123);
      expect(res3.isValid, false);
      expect(res3.expected, 'List<dynamic>');
    });
  });

  group('Number validators', () {
    test('isLt works', () {
      final validator = isLt(10);

      expect(validator.call(1).isValid, true);
      expect(validator.call(9).isValid, true);

      final res2 = validator.call(10);
      expect(res2.isValid, false);
      expect(res2.expected, 'less than 10');
    });

    test('isLte works', () {
      final validator = isLte(10);

      expect(validator.call(1).isValid, true);
      expect(validator.call(9).isValid, true);
      expect(validator.call(10).isValid, true);

      final res2 = validator.call(11);
      expect(res2.isValid, false);
      expect(res2.expected, 'less than or equal to 10');
      expect(
        res2.toString(),
        'Expected less than or equal to 10, got 11',
      );
    });

    test('isGt works', () {
      final validator = isGt(10);

      expect(validator.call(11).isValid, true);
      expect(validator.call(12).isValid, true);

      final res2 = validator.call(10);
      expect(res2.isValid, false);
      expect(res2.expected, 'greater than 10');
    });

    test('isGte works', () {
      final validator = isGte(10);

      expect(validator.call(10).isValid, true);
      expect(validator.call(11).isValid, true);
      expect(validator.call(12).isValid, true);

      final res2 = validator.call(9);
      expect(res2.isValid, false);
      expect(res2.expected, 'greater than or equal to 10');
    });

    test('isEq works', () {
      final validator = isEq(10);

      expect(validator.call(10).isValid, true);

      final res2 = validator.call(11);
      expect(res2.isValid, false);
      expect(res2.expected, 'equal to 10');

      final res3 = validator.call('11');
      expect(res3.isValid, false);
      expect(res3.expected, 'int');
    });
  });

  group('String validator', () {
    test('stringIsOfLength works', () {
      final validator = stringIsOfLength(2);

      expect(validator.call("12").isValid, true);
      expect(validator.call("ab").isValid, true);
      expect(validator.call("--").isValid, true);

      final res1 = validator.call('1');
      expect(res1.isValid, false);
      expect(res1.expected, 'String of length 2');

      final res2 = validator.call('123');
      expect(res2.isValid, false);
      expect(res2.expected, 'String of length 2');

      final res3 = validator.call(1232);
      expect(res3.isValid, false);
      expect(res3.expected, 'String');
    });

    test('stringContains works', () {
      final validator = stringContains("needle");

      expect(validator.call("I used a needle").isValid, true);
      expect(validator.call("needles are cool").isValid, true);
      expect(validator.call("needle").isValid, true);

      final res1 = validator.call('this is a useless string');
      expect(res1.isValid, false);
      expect(res1.expected, 'String to contain "needle"');

      final res2 = validator.call(1232);
      expect(res2.isValid, false);
      expect(res2.expected, 'String');
    });

    test('stringNotContains works', () {
      final validator = stringNotContains("needle");

      final res1 = validator.call('this is a useless string');
      expect(res1.isValid, true);
      expect(res1.expected, 'String to not contain "needle"');

      final res2 = validator.call(1232);
      expect(res2.isValid, false);
      expect(res2.expected, 'String');

      expect(validator.call("I used a needle").isValid, false);
      expect(validator.call("needles are cool").isValid, false);
      expect(validator.call("needle").isValid, false);
    });

    test('stringMatchesPattern works', () {
      final validator = stringMatchesPattern(RegExp(r"[\d]"));
      expect(validator.call("123").isValid, true);
      expect(validator.call("55555").isValid, true);

      final res2 = validator.call('aaaaa');
      expect(res2.isValid, false);
      expect(res2.expected, 'String to match "RegExp: pattern=[\\d] flags="');
    });

    test('stringMatchesPattern works with custom message', () {
      final validator = stringMatchesPattern(
        RegExp(r"[\d]"),
        expectedMessage: "Incorrect numerical string",
      );
      expect(validator.call("123").isValid, true);
      expect(validator.call("55555").isValid, true);

      final res2 = validator.call('aaaaa');
      expect(res2.isValid, false);
      expect(res2.expected, 'Incorrect numerical string');
    });

    test('isEq<String> works', () {
      final validator = isEq<String>('10');

      expect(validator.call('10').isValid, true);

      final res2 = validator.call(11);
      expect(res2.isValid, false);
      expect(res2.expected, 'String');

      final res3 = validator.call('11');
      expect(res3.isValid, false);
      expect(res3.expected, 'equal to "10"');
    });

    test('isEq<Map> works', () {
      final map = {"test": "aaa"};
      final validator = isEq<Map>(map);

      final res1 = validator.call(map);
      expect(res1.isValid, true);

      final res2 = validator.call(11);
      expect(res2.isValid, false);
      expect(res2.expected, 'Map<dynamic, dynamic>');

      final res3 = validator.call({});
      expect(res3.isValid, false);
      expect(res3.expected, 'equal to {"test":"aaa"}');
    });
  });

  group('List validators', () {
    group('listContains', () {
      test('empty list, needle not found', () {
        final listContainsNeedle = listContains('abc');

        final res1 = listContainsNeedle([]);
        expect(res1.isValid, false);
        expect(res1.expected, 'List to contain "abc"');
      });
      test('list without needle, needle not found', () {
        final listContainsNeedle = listContains('abc');

        final res1 = listContainsNeedle(['aaaa', 'bbbb', 'ccc']);
        expect(res1.isValid, false);
        expect(res1.expected, 'List to contain "abc"');
      });

      test('list wit needle, needle found', () {
        final listContainsNeedle = listContains('abc');

        final res1 = listContainsNeedle(['aaaa', 'abc', 'ccc']);
        expect(res1.isValid, true);
      });
    });

    test('eskemaList works', () {
      final validator = eskemaList([isType<String>(), isType<int>()]);

      final res1 = validator.call([]);
      expect(res1.isValid, false);
      expect(res1.expected, 'List of size 2');

      final res2 = validator.call([1, 2]);
      expect(res2.isValid, false);
      expect(res2.expected, '[0] -> String');

      final res3 = validator.call([1, 2, 3]);
      expect(res3.isValid, false);
      expect(res3.expected, 'List of size 2');

      final res4 = validator.call(["1", 2]);
      expect(res4.isValid, true);
    });
  });

  group('Utility validators', () {
    test('not validator works', () {
      final validator = not(isType<String>());
      expect(validator.call('10').isValid, false);
      expect(validator.call(10).isValid, true);
      expect(validator.call(false).isValid, true);
    });

    test('or', () {
      final field = or(isType<Map>(), isType<List>());

      expect(field.call({}).isValid, true);
      expect(field.call([]).isValid, true);
      expect(field.call('').expected, 'Map<dynamic, dynamic> or List<dynamic>');
    });

    test('and', () {
      final field = and(isType<int>(), isGt(10));

      expect(field.call(11).isValid, true);
      expect(field.call(345).isValid, true);

      expect(field.call('345').isValid, false);
      expect(field.call('345').expected, 'int');
    });

    test('isEq for "primitives"', () {
      final field = isEq<int>(2);
      expect(field.call({}).isValid, false);
      expect(field.call({}).expected, 'int');
      expect(field.call([]).isValid, false);
      expect(field.call(1).expected, 'equal to 2');

      expect(field.call(2).isValid, true);
    });

    test('isDeepEq for maps', () {
      final isEquals = isDeepEq<Map>({
        'a': 'b',
        'c': {'c1': 'aaaa'}
      });

      expect(isEquals({}).isValid, false);
      expect(isEquals({}).expected, 'equal to {"a":"b","c":{"c1":"aaaa"}}');
      expect(isEquals([]).isValid, false);
      expect(
        isEquals(1).expected,
        'Map<dynamic, dynamic>',
      );
      expect(
        isEquals({
          'a': 'b',
          'c': {'c1': 'aaaa'}
        }).isValid,
        true,
      );
    });

    test('isDeepEq for lists', () {
      final isEquals = isDeepEq<List>([1, 2]);

      expect(isEquals([]).isValid, false);
      expect(isEquals([]).expected, 'equal to [1,2]');
      expect(isEquals({}).isValid, false);
      expect(
        isEquals(1).expected,
        'List<dynamic>',
      );
      expect(
        isEquals([1, 2]).isValid,
        true,
      );
    });

    test('isDeepEq for sets', () {
      final isEquals = isDeepEq<Set>({1, 2});

      expect(isEquals({1}).isValid, false);
      expect(isEquals({1}).expected, 'equal to {1, 2}');
      expect(isEquals({1}).isValid, false);
      expect(
        isEquals(1).expected,
        'Set<dynamic>',
      );
      expect(
        isEquals({1, 2}).isValid,
        true,
      );
    });

    test('throwInstead', () {
      final isEquals = throwInstead(isDeepEq<Set>({1, 2}));
      expect(() => isEquals({1}), throwsA(isA<ValidatorFailedException>()));
      expect(() => isEquals({1, 2}), isNot(throwsA(isA<ValidatorFailedException>())));
    });
  });
}
