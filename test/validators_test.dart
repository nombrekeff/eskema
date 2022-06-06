import 'package:eskema/validators.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('isType', () {
    test('isTypeString works', () {
      final res1 = isTypeString().call("");
      expect(res1.isValid, true);

      final res2 = isTypeString().call(123);
      expect(res2.isValid, false);
      expect(res2.expected, 'String');

      final res3 = isTypeString().call(true);
      expect(res3.isValid, false);
      expect(res3.expected, 'String');
    });

    test('isTypeInt works', () {
      final res1 = isTypeInt().call(123);
      expect(res1.isValid, true);

      final res2 = isTypeInt().call("123");
      expect(res2.isValid, false);
      expect(res2.expected, 'int');

      final res3 = isTypeInt().call(true);
      expect(res3.isValid, false);
      expect(res3.expected, 'int');
    });

    test('isTypeNum works', () {
      final res1 = isTypeNum().call(123);
      expect(res1.isValid, true);

      final res2 = isTypeNum().call("123");
      expect(res2.isValid, false);
      expect(res2.expected, 'num');

      final res3 = isTypeNum().call(true);
      expect(res3.isValid, false);
      expect(res3.expected, 'num');
    });

    test('isTypeDouble works', () {
      final res1 = isTypeDouble().call(123.12);
      expect(res1.isValid, true);

      final res2 = isTypeDouble().call("123");
      expect(res2.isValid, false);
      expect(res2.expected, 'double');

      final res3 = isTypeDouble().call(true);
      expect(res3.isValid, false);
      expect(res3.expected, 'double');

      final res4 = isTypeDouble().call(123);
      expect(res4.isValid, false);
      expect(res4.expected, 'double');
    });

    test('isTypeBool works', () {
      final res1 = isTypeBool().call(true);
      expect(res1.isValid, true);

      final res2 = isTypeBool().call("123");
      expect(res2.isValid, false);
      expect(res2.expected, 'bool');

      final res3 = isTypeBool().call(123);
      expect(res3.isValid, false);
      expect(res3.expected, 'bool');
    });

    test('isTypeMap works', () {
      final res1 = isTypeMap().call({});
      expect(res1.isValid, true);

      final res2 = isTypeMap().call("123");
      expect(res2.isValid, false);
      expect(res2.expected, 'Map<dynamic, dynamic>');

      final res3 = isTypeMap().call(123);
      expect(res3.isValid, false);
      expect(res3.expected, 'Map<dynamic, dynamic>');
    });

    test('isTypeList works', () {
      final res1 = isTypeList().call([]);
      expect(res1.isValid, true);

      final res2 = isTypeList().call("123");
      expect(res2.isValid, false);
      expect(res2.expected, 'List<dynamic>');

      final res3 = isTypeList().call(123);
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
      expect(res2.expected, 'lower than 10');
    });

    test('isGt works', () {
      final validator = isGt(10);

      expect(validator.call(11).isValid, true);
      expect(validator.call(12).isValid, true);

      final res2 = validator.call(10);
      expect(res2.isValid, false);
      expect(res2.expected, 'greater than 10');
    });

    test('isEq works', () {
      final validator = isEq(10);

      expect(validator.call(10).isValid, true);

      final res2 = validator.call(11);
      expect(res2.isValid, false);
      expect(res2.expected, 'equal to 10');

      final res3 = validator.call('11');
      expect(res3.isValid, false);
      expect(res3.expected, 'equal to 10');
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

    test('isStringEq works', () {
      final validator = isStringEq('10');

      expect(validator.call('10').isValid, true);

      final res2 = validator.call(11);
      expect(res2.isValid, false);
      expect(res2.expected, 'equal to "10"');

      final res3 = validator.call('11');
      expect(res3.isValid, false);
      expect(res3.expected, 'equal to "10"');
    });
  });
}
