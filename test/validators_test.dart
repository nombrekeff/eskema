import 'package:eskema/eskema.dart';
import 'package:test/test.dart' hide isList, isNull, contains;

void main() {
  group('isType', () {
    test('isNull works', () {
      final res1 = isNull().validate("");
      expect(res1.isValid, false);

      final res2 = isNull().validate(123);
      expect(res2.isValid, false);
      expect(res2.description, 'Null (value: 123)');

      final res3 = isNull().validate(true);
      expect(res3.isValid, false);
      expect(res3.description, 'Null (value: true)');

      final res4 = isNull().validate(null);
      expect(res4.isValid, true);
    });

    test('isType<String> works', () {
      final res1 = isType<String>().validate("");
      expect(res1.isValid, true);

      final res2 = isType<String>().validate(123);
      expect(res2.isValid, false);
      expect(res2.description, 'String (value: 123)');

      final res3 = isType<String>().validate(true);
      expect(res3.isValid, false);
      expect(res3.description, 'String (value: true)');
    });

    test('isType<int> works', () {
      final res1 = isType<int>().validate(123);
      expect(res1.isValid, true);

      final res2 = isType<int>().validate("123");
      expect(res2.isValid, false);
      expect(res2.description, 'int (value: "123")');

      final res3 = isType<int>().validate(true);
      expect(res3.isValid, false);
      expect(res3.description, 'int (value: true)');
    });

    test('isType<num> works', () {
      final res1 = isType<num>().validate(123);
      expect(res1.isValid, true);

      final res2 = isType<num>().validate("123");
      expect(res2.isValid, false);
      expect(res2.description, 'num (value: "123")');

      final res3 = isType<num>().validate(true);
      expect(res3.isValid, false);
      expect(res3.description, 'num (value: true)');
    });

    test('isType<double> works', () {
      final res1 = isType<double>().validate(123.12);
      expect(res1.isValid, true);

      final res2 = isType<double>().validate("123");
      expect(res2.isValid, false);
      expect(res2.description, 'double (value: "123")');

      final res3 = isType<double>().validate(true);
      expect(res3.isValid, false);
      expect(res3.description, 'double (value: true)');

      final res4 = isType<double>().validate(123);
      expect(res4.isValid, false);
      expect(res4.description, 'double (value: 123)');
    });

    test('isType<bool> works', () {
      final res1 = isType<bool>().validate(true);
      expect(res1.isValid, true);

      final res2 = isType<bool>().validate("123");
      expect(res2.isValid, false);
      expect(res2.description, 'bool (value: "123")');

      final res3 = isType<bool>().validate(123);
      expect(res3.isValid, false);
      expect(res3.description, 'bool (value: 123)');
    });

    test('isType<Map> works', () {
      final res1 = isType<Map>().validate({});
      expect(res1.isValid, true);

      final res2 = isType<Map>().validate("123");
      expect(res2.isValid, false);
      expect(res2.description, 'Map<dynamic, dynamic> (value: "123")');

      final res3 = isType<Map>().validate(123);
      expect(res3.isValid, false);
      expect(res3.description, 'Map<dynamic, dynamic> (value: 123)');
    });

    test('isType<List> works', () {
      final res1 = isType<List>().validate([]);
      expect(res1.isValid, true);

      final res2 = isType<List>().validate("123");
      expect(res2.isValid, false);
      expect(res2.description, 'List<dynamic> (value: "123")');

      final res3 = isType<List>().validate(123);
      expect(res3.isValid, false);
      expect(res3.description, 'List<dynamic> (value: 123)');
    });
  });

  group('Number validators', () {
    test('isLt works', () {
      final validator = isLt(10);

      expect(validator.validate(1).isValid, true);
      expect(validator.validate(9).isValid, true);

      final res2 = validator.validate(10);
      expect(res2.isValid, false);
      expect(res2.description, 'less than 10 (value: 10)');
    });

    test('isLte works', () {
      final validator = isLte(10);

      expect(validator.validate(1).isValid, true);
      expect(validator.validate(9).isValid, true);
      expect(validator.validate(10).isValid, true);

      final res2 = validator.validate(11);
      expect(res2.isValid, false);
      expect(res2.description, 'less than or equal to 10 (value: 11)');
    });

    test('isGt works', () {
      final validator = isGt(10);

      expect(validator.validate(11).isValid, true);
      expect(validator.validate(12).isValid, true);

      final res2 = validator.validate(10);
      expect(res2.isValid, false);
      expect(res2.description, 'greater than 10 (value: 10)');
    });

    test('isGte works', () {
      final validator = isGte(10);

      expect(validator.validate(10).isValid, true);
      expect(validator.validate(11).isValid, true);
      expect(validator.validate(12).isValid, true);

      final res2 = validator.validate(9);
      expect(res2.isValid, false);
      expect(res2.description, 'greater than or equal to 10 (value: 9)');
    });

    test('isEq works', () {
      final validator = isEq(10);

      expect(validator.validate(10).isValid, true);

      final res2 = validator.validate(11);
      expect(res2.isValid, false);
      expect(res2.description, 'equal to 10 (value: 11)');

      final res3 = validator.validate('11');
      expect(res3.isValid, false);
      expect(res3.description, 'int (value: "11")');
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
      expect(res1.shortDescription, 'length [equal to 2 (value: 1)]');

      final res2 = validator.validate('123');
      expect(res2.isValid, false);
      expect(res2.shortDescription, 'length [equal to 2 (value: 3)]');

      final res3 = validator.validate(1232);
      expect(res3.isValid, false);
      expect(res3.shortDescription, 'String');
    });

    test('stringLength works', () {
      final stringLengthGt10 = stringLength([isGt(10)]);
      final stringLengthEq5 = stringLength([isEq(5)]);

      expect(stringLengthEq5.validate("12345").isValid, true);
      expect(stringLengthEq5.validate("1234").isValid, false);
      expect(stringLengthEq5.validate("123456").isValid, false);
      expect(stringLengthEq5.validate(12345).description, 'String (value: 12345)');

      expect(stringLengthGt10.validate("12345678901").isValid, true);
      expect(stringLengthGt10.validate("123456789012").isValid, true);
      expect(stringLengthGt10.validate("1234567890").isValid, false);
    });

    test('stringContains works', () {
      final validator = stringContains("needle");

      expect(validator.validate("I used a needle").isValid, true);
      expect(validator.validate("needles are cool").isValid, true);
      expect(validator.validate("needle").isValid, true);

      final res1 = validator.validate('this is a useless string');
      expect(res1.isValid, false);
      expect(
        res1.description,
        'String to contain "needle" (value: "this is a useless string")',
      );

      final res2 = validator.validate(1232);
      expect(res2.isValid, false);
      expect(res2.description, 'String (value: 1232)');
    });

    test('stringMatchesPattern works', () {
      final validator = stringMatchesPattern(RegExp(r"[\d]"));
      expect(validator.validate("123").isValid, true);
      expect(validator.validate("55555").isValid, true);

      final res2 = validator.validate('aaaaa');
      expect(res2.isValid, false);
      expect(
        res2.description,
        'String to match "RegExp: pattern=[\\d] flags=" (value: "aaaaa")',
      );
    });

    test('stringMatchesPattern works with custom message', () {
      final validator = stringMatchesPattern(
        RegExp(r"[\d]"),
        error: "Incorrect numerical string",
      );
      expect(validator.validate("123").isValid, true);
      expect(validator.validate("55555").isValid, true);

      final res2 = validator.validate('aaaaa');
      expect(res2.isValid, false);
      expect(res2.description, 'Incorrect numerical string (value: "aaaaa")');
    });

    test('stringEmpty', () {
      final field = stringEmpty();

      expect(field.validate('').isValid, true);
      expect(field.validate('1').isValid, false);
      expect(field.validate('1').description, 'String to be empty (value: "1")');
    });

    test('\$stringEmpty', () {
      final field = $stringEmpty;
      expect(field.validate('').isValid, true);
      expect(field.validate('1').isValid, false);
      expect(field.validate('1').description, 'String to be empty (value: "1")');
    });
  });

  group('List validators', () {
    group('listContains', () {
      test('empty list, needle not found', () {
        final listContainsNeedle = listContains('abc');

        final res1 = listContainsNeedle.validate([]);
        expect(res1.isValid, false);
        expect(res1.description, 'List to contain "abc" (value: [])');
      });
      test('list without needle, needle not found', () {
        final listContainsNeedle = listContains('abc');

        final res1 = listContainsNeedle.validate(['aaaa', 'bbbb', 'ccc']);
        expect(res1.isValid, false);
        expect(res1.description, 'List to contain "abc" (value: ["aaaa","bbbb","ccc"])');
      });

      test('invalid data type', () {
        final listContainsNeedle = listContains('abc');
        final res1 = listContainsNeedle.validate({});
        expect(res1.isValid, false);
        expect(res1.description, 'List<dynamic> (value: {})');
      });

      test('list wit needle, needle found', () {
        final listContainsNeedle = listContains('abc');

        final res1 = listContainsNeedle.validate(['aaaa', 'abc', 'ccc']);
        expect(res1.isValid, true);
      });
    });

    test('listEmpty', () {
      final field = listEmpty();

      expect(field.validate([]).isValid, true);
      expect(field.validate([1]).isValid, false);
      expect(field.validate([1]).shortDescription, 'List to be empty');
    });

    test('\$listEmpty', () {
      final field = $listEmpty;
      expect(field.validate([]).isValid, true);
      expect(field.validate([1]).isValid, false);
      expect(field.validate([1]).shortDescription, 'List to be empty');
    });

    test('eskemaList works', () {
      final validator = eskemaList([isType<String>(), isType<int>()]);

      final res1 = validator.validate([]);
      expect(res1.isValid, false);
      expect(res1.shortDescription, 'length [equal to 2 (value: 0)]');

      final res2 = validator.validate([1, 2]);
      expect(res2.isValid, false);
      expect(res2.shortDescription, '[0]: String');

      final res3 = validator.validate([1, 2, 3]);
      expect(res3.isValid, false);
      expect(res3.shortDescription, 'length [equal to 2 (value: 3)]');

      final res4 = validator.validate(["1", 2]);
      expect(res4.isValid, true);
    });
  });

  group('Utility validators', () {
    test('not validator works', () {
      final validator = not(isType<String>());
      expect(validator.validate('10').isValid, false);
      expect(validator.validate(10).isValid, true);
      expect(validator.validate(true).isValid, true);

      final res = validator.validate('false');
      expect(res.shortDescription, 'not String');
    });

    test('any', () {
      final field = any([isType<Map>(), isType<List>()]);

      expect(field.validate({}).isValid, true);
      expect(field.validate([]).isValid, true);
      expect(
        field.validate('').shortDescription,
        'Map<dynamic, dynamic>, List<dynamic>',
      );
    });

    test('all', () {
      final field = all([isType<int>(), isGt(10)]);

      expect(field.validate(11).isValid, true);
      expect(field.validate(345).isValid, true);

      expect(field.validate('345').isValid, false);
      expect(field.validate('345').shortDescription, 'int');
    });

    test('none', () {
      final field = none([isType<int>(), isBool()]);

      expect(field.validate('').isValid, true);
      expect(field.validate({}).isValid, true);

      expect(field.validate(1).isValid, false);
      expect(field.validate(false).isValid, false);

      final res = field.validate(false);
      expect(res.description, 'not bool (value: false)');
    });

    test('isEq for "primitives"', () {
      final field = isEq<int>(2);
      expect(field.validate({}).isValid, false);
      expect(field.validate({}).description, 'int (value: {})');
      expect(field.validate([]).isValid, false);
      expect(field.validate(1).description, 'equal to 2 (value: 1)');

      expect(field.validate(2).isValid, true);
    });

    test('isDeepEq for maps', () {
      final isEquals = isDeepEq<Map>({
        'a': 'b',
        'c': {'c1': 'aaaa'}
      });

      expect(isEquals.validate({}).isValid, false);
      expect(isEquals.validate({}).shortDescription, 'equal to {"a":"b","c":{"c1":"aaaa"}}');
      expect(isEquals.validate([]).isValid, false);
      expect(
        isEquals.validate(1).shortDescription,
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
      expect(oneOf.validate('xyz').shortDescription, 'one of: ["abc","def"]');
    });

    test('isDeepEq for lists', () {
      final isEquals = isDeepEq<List>([1, 2]);

      expect(isEquals.validate([]).isValid, false);
      expect(isEquals.validate([]).shortDescription, 'equal to [1,2]');
      expect(isEquals.validate({}).isValid, false);
      expect(
        isEquals.validate(1).shortDescription,
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
      expect(isEquals.validate({1}).shortDescription, 'equal to {1, 2}');
      expect(isEquals.validate({1}).isValid, false);
      expect(
        isEquals.validate(1).shortDescription,
        'Set<dynamic>',
      );
      expect(
        isEquals.validate({1, 2}).isValid,
        true,
      );
    });

    test('length', () {
      final field = length([isEq(2)]);

      expect(field.validate('12').isValid, true);
      expect(field.validate([1, 2]).isValid, true);

      expect(field.validate(1).isValid, false);
      expect(field.validate(false).isValid, false);
      expect(field.validate(false).shortDescription, 'bool does not have a length property');
    });

    test('contains', () {
      final field = contains('2');

      expect(field.validate('12').isValid, true);
      expect(field.validate([1, '2']).isValid, true);

      expect(field.validate([1]).isValid, false);
      expect(field.validate(false).isValid, false);
      expect(field.validate(false).shortDescription, 'bool does not have a contains property');
    });

    test('isEq<String> works', () {
      final validator = isEq<String>('10');

      expect(validator.validate('10').isValid, true);

      final res2 = validator.validate(11);
      expect(res2.isValid, false);
      expect(res2.shortDescription, 'String');

      final res3 = validator.validate('11');
      expect(res3.isValid, false);
      expect(res3.shortDescription, 'equal to "10"');
    });

    test('isEq<Map> works', () {
      final map = {"test": "aaa"};
      final validator = isEq<Map>(map);

      final res1 = validator.validate(map);
      expect(res1.isValid, true);

      final res2 = validator.validate(11);
      expect(res2.isValid, false);
      expect(res2.shortDescription, 'Map<dynamic, dynamic>');

      final res3 = validator.validate({});
      expect(res3.isValid, false);
      expect(res3.shortDescription, 'equal to {"test":"aaa"}');
    });

    test('validateOrThrow', () {
      final isEquals = isDeepEq<Set>({1, 2});

      expect(() => isEquals.validateOrThrow({1}), throwsA(isA<ValidatorFailedException>()));

      expect(() => isEquals.validateOrThrow({1, 2}),
          isNot(throwsA(isA<ValidatorFailedException>())));
    });

    test('throwInstead', () {
      final isEquals = throwInstead(isDeepEq<Set>({1, 2}));
      expect(() => isEquals.validate({1}), throwsA(isA<ValidatorFailedException>()));
      expect(() => isEquals.validate({1, 2}), isNot(throwsA(isA<ValidatorFailedException>())));
    });
  });

  group('isType shorthands', () {
    test('isString works', () {
      final res1 = isString().validate("");
      expect(res1.isValid, true);

      final res2 = isString().validate(123);
      expect(res2.isValid, false);
      expect(res2.shortDescription, 'String');
    });

    test('\$isString works', () {
      final res1 = $isString.validate("");
      expect(res1.isValid, true);

      final res2 = $isString.validate(123);
      expect(res2.isValid, false);
      expect(res2.shortDescription, 'String');
    });

    test('isInt works', () {
      final res1 = isInt().validate("");
      expect(res1.isValid, false);
      expect(res1.shortDescription, 'int');

      final res2 = isInt().validate(123);
      expect(res2.isValid, true);
    });

    test('\$isInt works', () {
      final res1 = $isInt.validate(123);
      expect(res1.isValid, true);

      final res2 = $isInt.validate("123");
      expect(res2.isValid, false);
      expect(res2.shortDescription, 'int');
    });

    test('isBool works', () {
      final res1 = isBool().validate("");
      expect(res1.isValid, false);
      expect(res1.shortDescription, 'bool');

      final res2 = isBool().validate(true);
      expect(res2.isValid, true);
    });

    test('\$isBool works', () {
      final res1 = $isBool.validate("");
      expect(res1.isValid, false);
      expect(res1.shortDescription, 'bool');

      final res2 = $isBool.validate(true);
      expect(res2.isValid, true);
    });

    test('isDouble works', () {
      final res1 = isDouble().validate("");
      expect(res1.isValid, false);
      expect(res1.shortDescription, 'double');

      final res2 = isDouble().validate(1.23);
      expect(res2.isValid, true);
    });

    test('\$isDouble works', () {
      final res1 = $isDouble.validate("");
      expect(res1.isValid, false);
      expect(res1.shortDescription, 'double');

      final res2 = $isDouble.validate(1.23);
      expect(res2.isValid, true);
    });

    test('isNum works', () {
      final res1 = isNumber().validate("");
      expect(res1.isValid, false);
      expect(res1.shortDescription, 'num');

      final res2 = isNumber().validate(1.23);
      expect(res2.isValid, true);

      final res3 = isNumber().validate(123);
      expect(res3.isValid, true);
    });

    test('\$isNumber works', () {
      final res1 = $isNumber.validate("");
      expect(res1.isValid, false);
      expect(res1.shortDescription, 'num');

      final res2 = $isNumber.validate(1.23);
      expect(res2.isValid, true);

      final res3 = $isNumber.validate(123);
      expect(res3.isValid, true);
    });

    test('isFuture works', () {
      final res1 = isFuture().validate("");
      expect(res1.isValid, false);
      expect(res1.shortDescription, 'Future<dynamic>');

      final res2 = isFuture().validate(Future.value(1.23));
      expect(res2.isValid, true);
    });

    test('\$isFuture works', () {
      final res1 = $isFuture.validate("");
      expect(res1.isValid, false);
      expect(res1.shortDescription, 'Future<dynamic>');

      final res2 = $isFuture.validate(Future.value(1.23));
      expect(res2.isValid, true);
    });

    test('isEnum works', () {
      final res1 = isEnum().validate("");
      expect(res1.isValid, false);
      expect(res1.shortDescription, 'Enum');

      final res2 = isEnum().validate(EnumA.value1);
      expect(res2.isValid, true);
    });

    test('\$isEnum works', () {
      final res1 = $isEnum.validate("");
      expect(res1.isValid, false);
      expect(res1.shortDescription, 'Enum');

      final res2 = $isEnum.validate(EnumA.value1);
      expect(res2.isValid, true);
    });

    test('isList works', () {
      final res1 = isList<int>().validate("");
      expect(res1.isValid, false);
      expect(res1.shortDescription, 'List<int>');

      final res2 = isList<int>().validate([1, 2, 3]);
      expect(res2.isValid, true);
    });

    test('\$isList works', () {
      final res1 = $isList.validate("");
      expect(res1.isValid, false);
      expect(res1.shortDescription, 'List<dynamic>');

      final res2 = $isList.validate([1, 2, 3]);
      expect(res2.isValid, true);
    });

    test('isSet works', () {
      final res1 = isSet<int>().validate("");
      expect(res1.isValid, false);
      expect(res1.shortDescription, 'Set<int>');

      final res2 = isSet<int>().validate({1, 2, 3});
      expect(res2.isValid, true);
    });

    test('\$isSet works', () {
      final res1 = $isSet.validate("");
      expect(res1.isValid, false);
      expect(res1.shortDescription, 'Set<dynamic>');

      final res2 = $isSet.validate({1, 2, 3});
      expect(res2.isValid, true);
    });

    test('isRecord works', () {
      final res1 = isRecord().validate("");
      expect(res1.isValid, false);
      expect(res1.shortDescription, 'Record');

      final res2 = isRecord().validate(('first', a: 2, b: true, 'last'));
      expect(res2.isValid, true);
    });

    test('\$isRecord works', () {
      final res1 = $isRecord.validate("");
      expect(res1.isValid, false);
      expect(res1.shortDescription, 'Record');

      final res2 = $isRecord.validate(('first', a: 2, b: true, 'last'));
      expect(res2.isValid, true);
    });

    test('isIterable works', () {
      final res1 = isIterable<int>().validate("");
      expect(res1.isValid, false);
      expect(res1.shortDescription, 'Iterable<int>');

      final res2 = isIterable<int>().validate([1, 2, 3]);
      expect(res2.isValid, true);
    });

    test('\$isIterable works', () {
      final res1 = $isIterable.validate("");
      expect(res1.isValid, false);
      expect(res1.shortDescription, 'Iterable<dynamic>');

      final res2 = $isIterable.validate([1, 2, 3]);
      expect(res2.isValid, true);
    });

    test('isSymbol works', () {
      final res1 = isSymbol().validate("");
      expect(res1.isValid, false);
      expect(res1.shortDescription, 'Symbol');

      final res2 = isSymbol().validate(#mySymbol);
      expect(res2.isValid, true);
    });

    test('\$isSymbol works', () {
      final res1 = $isSymbol.validate("");
      expect(res1.isValid, false);
      expect(res1.shortDescription, 'Symbol');

      final res2 = $isSymbol.validate(#mySymbol);
      expect(res2.isValid, true);
    });

    test('isFunction works', () {
      final res1 = isFunction().validate("");
      expect(res1.isValid, false);
      expect(res1.shortDescription, 'Function');

      final res2 = isFunction().validate(() {});
      expect(res2.isValid, true);
    });

    test('\$isFunction works', () {
      final res1 = $isFunction.validate("");
      expect(res1.isValid, false);
      expect(res1.shortDescription, 'Function');

      final res2 = $isFunction.validate(() {});
      expect(res2.isValid, true);
    });

    test('\$isMap works', () {
      final res1 = $isMap.validate("");
      expect(res1.isValid, false);
      expect(res1.shortDescription, 'Map<dynamic, dynamic>');

      final res2 = $isMap.validate({'key': 'value'});
      expect(res2.isValid, true);
    });
  });
}

enum EnumA { value1, value2 }
