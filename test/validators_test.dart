import 'package:eskema/eskema.dart';
import 'package:test/test.dart' hide isList, isNull, contains;

void main() {
  group('isType', () {
    test('isNull works', () {
      final res1 = isNull().validate('');
      expect(res1.isValid, false);

      final res2 = isNull().validate(123);
      expect(res2.isValid, false);
      expect(res2.description, 'Null');

      final res3 = isNull().validate(true);
      expect(res3.isValid, false);
      expect(res3.description, 'Null');

      final res4 = isNull().validate(null);
      expect(res4.isValid, true);
    });

    test('isType<String> works', () {
      final res1 = isType<String>().validate('');
      expect(res1.isValid, true);

      final res2 = isType<String>().validate(123);
      expect(res2.isValid, false);
      expect(res2.description, 'String');

      final res3 = isType<String>().validate(true);
      expect(res3.isValid, false);
      expect(res3.description, 'String');
    });

    test('isType<int> works', () {
      final res1 = isType<int>().validate(123);
      expect(res1.isValid, true);

      final res2 = isType<int>().validate('123');
      expect(res2.isValid, false);
      expect(res2.description, 'int');

      final res3 = isType<int>().validate(true);
      expect(res3.isValid, false);
      expect(res3.description, 'int');
    });

    test('isType<num> works', () {
      final res1 = isType<num>().validate(123);
      expect(res1.isValid, true);

      final res2 = isType<num>().validate('123');
      expect(res2.isValid, false);
      expect(res2.description, 'num');

      final res3 = isType<num>().validate(true);
      expect(res3.isValid, false);
      expect(res3.description, 'num');
    });

    test('isType<double> works', () {
      final res1 = isType<double>().validate(123.12);
      expect(res1.isValid, true);

      final res2 = isType<double>().validate('123');
      expect(res2.isValid, false);
      expect(res2.description, 'double');

      final res3 = isType<double>().validate(true);
      expect(res3.isValid, false);
      expect(res3.description, 'double');

      final res4 = isType<double>().validate(123);
      expect(res4.isValid, false);
      expect(res4.description, 'double');
    });

    test('isType<bool> works', () {
      final res1 = isType<bool>().validate(true);
      expect(res1.isValid, true);

      final res2 = isType<bool>().validate('123');
      expect(res2.isValid, false);
      expect(res2.description, 'bool');

      final res3 = isType<bool>().validate(123);
      expect(res3.isValid, false);
      expect(res3.description, 'bool');
    });

    test('isType<Map> works', () {
      final res1 = isType<Map>().validate({});
      expect(res1.isValid, true);

      final res2 = isType<Map>().validate('123');
      expect(res2.isValid, false);
      expect(res2.description, 'Map<dynamic, dynamic>');

      final res3 = isType<Map>().validate(123);
      expect(res3.isValid, false);
      expect(res3.description, 'Map<dynamic, dynamic>');
    });

    test('isType<List> works', () {
      final res1 = isType<List>().validate([]);
      expect(res1.isValid, true);

      final res2 = isType<List>().validate('123');
      expect(res2.isValid, false);
      expect(res2.description, 'List<dynamic>');

      final res3 = isType<List>().validate(123);
      expect(res3.isValid, false);
      expect(res3.description, 'List<dynamic>');
    });
  });

  group('Number validators', () {
    test('isLt works', () {
      final validator = isLt(10);

      expect(validator.validate(1).isValid, true);
      expect(validator.validate(9).isValid, true);

      final res2 = validator.validate(10);
      expect(res2.isValid, false);
      expect(res2.description, 'less than 10');
    });

    test('isLte works', () {
      final validator = isLte(10);

      expect(validator.validate(1).isValid, true);
      expect(validator.validate(9).isValid, true);
      expect(validator.validate(10).isValid, true);

      final res2 = validator.validate(11);
      expect(res2.isValid, false);
      expect(res2.description, 'less than or equal to 10');
    });

    test('isGt works', () {
      final validator = isGt(10);

      expect(validator.validate(11).isValid, true);
      expect(validator.validate(12).isValid, true);

      final res2 = validator.validate(10);
      expect(res2.isValid, false);
      expect(res2.description, 'greater than 10');
    });

    test('isGte works', () {
      final validator = isGte(10);

      expect(validator.validate(10).isValid, true);
      expect(validator.validate(11).isValid, true);
      expect(validator.validate(12).isValid, true);

      final res2 = validator.validate(9);
      expect(res2.isValid, false);
      expect(res2.description, 'greater than or equal to 10');
    });

    test('isEq works', () {
      final validator = isEq(10);

      expect(validator.validate(10).isValid, true);

      final res2 = validator.validate(11);
      expect(res2.isValid, false);
      expect(res2.description, 'equal to 10');

      final res3 = validator.validate('11');
      expect(res3.isValid, false);
      expect(res3.description, 'equal to 10');
    });
  });

  group('String validator', () {
    test('stringIsOfLength works', () {
      final validator = stringIsOfLength(2);

      expect(validator.validate('12').isValid, true);
      expect(validator.validate('ab').isValid, true);
      expect(validator.validate('--').isValid, true);

      final res1 = validator.validate('1');
      expect(res1.isValid, false);
      expect(res1.description, 'String length [to be 2]');

      final res2 = validator.validate('123');
      expect(res2.isValid, false);
      expect(res2.description, 'String length [to be 2]');

      final res3 = validator.validate(1232);
      expect(res3.isValid, false);
      expect(res3.description, 'String');
    });

    test('stringLength works', () {
      final stringLengthGt10 = stringLength([isGt(10)]);
      final stringLengthEq5 = stringLength([isEq(5)]);

      expect(stringLengthEq5.validate('12345').isValid, true);
      expect(stringLengthEq5.validate('1234').isValid, false);
      expect(stringLengthEq5.validate('123456').isValid, false);
      expect(stringLengthEq5.validate(12345).description, 'String');

      expect(stringLengthGt10.validate('12345678901').isValid, true);
      expect(stringLengthGt10.validate('123456789012').isValid, true);
      expect(stringLengthGt10.validate('1234567890').isValid, false);
    });

    test('stringContains works', () {
      final validator = stringContains('needle');

      expect(validator.validate('I used a needle').isValid, true);
      expect(validator.validate('needles are cool').isValid, true);
      expect(validator.validate('needle').isValid, true);

      final res1 = validator.validate('this is a useless string');
      expect(res1.isValid, false);
      expect(
        res1.description,
        'String to contain "needle"',
      );

      final res2 = validator.validate(1232);
      expect(res2.isValid, false);
      expect(res2.description, 'String');
    });

    test('stringMatchesPattern works', () {
      final validator = stringMatchesPattern(RegExp(r'[\d]'));
      expect(validator.validate('123').isValid, true);
      expect(validator.validate('55555').isValid, true);

      final res2 = validator.validate('aaaaa');
      expect(res2.isValid, false);
      expect(
        res2.description,
        'String to match "RegExp: pattern=[\\d] flags="',
      );
    });

    test('stringMatchesPattern works with custom message', () {
      final validator = stringMatchesPattern(
        RegExp(r'[\d]'),
        message: 'Incorrect numerical string',
      );
      expect(validator.validate('123').isValid, true);
      expect(validator.validate('55555').isValid, true);

      final res2 = validator.validate('aaaaa');
      expect(res2.isValid, false);
      expect(res2.description, 'Incorrect numerical string');
    });

    test('stringEmpty', () {
      final field = isStringEmpty();

      expect(field.validate('').isValid, true);
      expect(field.validate('1').isValid, false);
      expect(field.validate('1').description, 'String to be empty');
    });

    test('not(\$isStringEmpty)', () {
      final field = not($isStringEmpty);
      expect(field.validate('').isValid, false);
      expect(field.validate('').description, 'not String to be empty');
      expect(field.validate('1').isValid, true);
    });
  });

  group('List validators', () {
    group('listContains', () {
      test('empty list, needle not found', () {
        final listContainsNeedle = listContains('abc');

        final res1 = listContainsNeedle.validate([]);
        expect(res1.isValid, false);
        expect(res1.description, 'List to contain "abc"');
      });
      test('list without needle, needle not found', () {
        final listContainsNeedle = listContains('abc');

        final res1 = listContainsNeedle.validate(['aaaa', 'bbbb', 'ccc']);
        expect(res1.isValid, false);
        expect(res1.description, 'List to contain "abc"');
      });

      test('invalid data type', () {
        final listContainsNeedle = listContains('abc');
        final res1 = listContainsNeedle.validate({});
        expect(res1.isValid, false);
        expect(res1.description, 'List<dynamic>');
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
      expect(field.validate([1]).description, 'List to be empty');
    });

    test('\$listEmpty', () {
      final field = $listEmpty;
      expect(field.validate([]).isValid, true);
      expect(field.validate([1]).isValid, false);
      expect(field.validate([1]).description, 'List to be empty');
    });

    test('eskemaList works', () {
      final validator = eskemaList([isType<String>(), isType<int>()]);

      final res1 = validator.validate([]);
      expect(res1.isValid, false);
      expect(res1.description, 'length [equal to 2]');

      final res2 = validator.validate([1, 2]);
      expect(res2.isValid, false);
      expect(res2.description, '[0]: String');

      final res3 = validator.validate([1, 2, 3]);
      expect(res3.isValid, false);
      expect(res3.description, 'length [equal to 2]');

      final res4 = validator.validate(['1', 2]);
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
      expect(res.description, 'not String');
    });

    test('any', () {
      final field = any([isType<Map>(), isType<List>()]);

      expect(field.validate({}).isValid, true);
      expect(field.validate([]).isValid, true);
      expect(
        field.validate('').description,
        'Map<dynamic, dynamic>, List<dynamic>',
      );
    });

    test('all', () {
      final field = all([isType<int>(), isGt(10)]);

      expect(field.validate(11).isValid, true);
      expect(field.validate(345).isValid, true);

      expect(field.validate('345').isValid, false);
      expect(field.validate('345').description, 'int');
    });

    test('none', () {
      final field = none([isType<int>(), isBool()]);

      expect(field.validate('').isValid, true);
      expect(field.validate({}).isValid, true);

      expect(field.validate(1).isValid, false);
      expect(field.validate(false).isValid, false);

      final res = field.validate(false);
      expect(res.description, 'not bool');
    });

    test('isEq for "primitives"', () {
      final field = isEq<int>(2);
      expect(field.validate({}).isValid, false);
      expect(field.validate({}).description, 'equal to 2');
      expect(field.validate([]).isValid, false);
      expect(field.validate(1).description, 'equal to 2');

      expect(field.validate(2).isValid, true);
    });

    test('isDeepEq for maps', () {
      final isEquals = isDeepEq<Map>({
        'a': 'b',
        'c': {'c1': 'aaaa'}
      });

      expect(isEquals.validate({}).isValid, false);
      expect(isEquals.validate({}).description, 'equal to {"a":"b","c":{"c1":"aaaa"}}');
      expect(isEquals.validate([]).isValid, false);
      expect(
        isEquals.validate(1).description,
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
      expect(oneOf.validate('xyz').description, 'one of: ["abc","def"]');
    });

    test('isDeepEq for lists', () {
      final isEquals = isDeepEq<List>([1, 2]);

      expect(isEquals.validate([]).isValid, false);
      expect(isEquals.validate([]).description, 'equal to [1,2]');
      expect(isEquals.validate({}).isValid, false);
      expect(
        isEquals.validate(1).description,
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
      expect(isEquals.validate({1}).description, 'equal to {1, 2}');
      expect(isEquals.validate({1}).isValid, false);
      expect(
        isEquals.validate(1).description,
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
      expect(field.validate(false).description, 'bool does not have a length property');
    });

    test('contains', () {
      final field = contains('2');

      expect(field.validate('12').isValid, true);
      expect(field.validate([1, '2']).isValid, true);

      expect(field.validate([1]).isValid, false);
      expect(field.validate(false).isValid, false);
      expect(field.validate(false).description, 'bool does not have a contains property');
    });

    test('isEq<String> works', () {
      final validator = isEq<String>('10');

      expect(validator.validate('10').isValid, true);

      final res2 = validator.validate(11);
      expect(res2.isValid, false);
      expect(res2.description, 'equal to "10"');

      final res3 = validator.validate('11');
      expect(res3.isValid, false);
      expect(res3.description, 'equal to "10"');
    });

    test('isEq<Map> works', () {
      final map = {'test': 'aaa'};
      final validator = isEq<Map>(map);

      final res1 = validator.validate(map);
      expect(res1.isValid, true);

      final res2 = validator.validate(11);
      expect(res2.isValid, false);
      expect(res2.description, 'equal to {"test":"aaa"}');

      final res3 = validator.validate({});
      expect(res3.isValid, false);
      expect(res3.description, 'equal to {"test":"aaa"}');
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
      final res1 = isString().validate('');
      expect(res1.isValid, true);

      final res2 = isString().validate(123);
      expect(res2.isValid, false);
      expect(res2.description, 'String');
    });

    test('\$isString works', () {
      final res1 = $isString.validate('');
      expect(res1.isValid, true);

      final res2 = $isString.validate(123);
      expect(res2.isValid, false);
      expect(res2.description, 'String');
    });

    test('isInt works', () {
      final res1 = isInt().validate('');
      expect(res1.isValid, false);
      expect(res1.description, 'int');

      final res2 = isInt().validate(123);
      expect(res2.isValid, true);
    });

    test('\$isInt works', () {
      final res1 = $isInt.validate(123);
      expect(res1.isValid, true);

      final res2 = $isInt.validate('123');
      expect(res2.isValid, false);
      expect(res2.description, 'int');
    });

    test('isBool works', () {
      final res1 = isBool().validate('');
      expect(res1.isValid, false);
      expect(res1.description, 'bool');

      final res2 = isBool().validate(true);
      expect(res2.isValid, true);
    });

    test('\$isBool works', () {
      final res1 = $isBool.validate('');
      expect(res1.isValid, false);
      expect(res1.description, 'bool');

      final res2 = $isBool.validate(true);
      expect(res2.isValid, true);
    });

    test('isDouble works', () {
      final res1 = isDouble().validate('');
      expect(res1.isValid, false);
      expect(res1.description, 'double');

      final res2 = isDouble().validate(1.23);
      expect(res2.isValid, true);
    });

    test('\$isDouble works', () {
      final res1 = $isDouble.validate('');
      expect(res1.isValid, false);
      expect(res1.description, 'double');

      final res2 = $isDouble.validate(1.23);
      expect(res2.isValid, true);
    });

    test('isNum works', () {
      final res1 = isNumber().validate('');
      expect(res1.isValid, false);
      expect(res1.description, 'num');

      final res2 = isNumber().validate(1.23);
      expect(res2.isValid, true);

      final res3 = isNumber().validate(123);
      expect(res3.isValid, true);
    });

    test('\$isNumber works', () {
      final res1 = $isNumber.validate('');
      expect(res1.isValid, false);
      expect(res1.description, 'num');

      final res2 = $isNumber.validate(1.23);
      expect(res2.isValid, true);

      final res3 = $isNumber.validate(123);
      expect(res3.isValid, true);
    });

    test('isFuture works', () {
      final res1 = isFuture().validate('');
      expect(res1.isValid, false);
      expect(res1.description, 'Future<dynamic>');

      final res2 = isFuture().validate(Future.value(1.23));
      expect(res2.isValid, true);
    });

    test('\$isFuture works', () {
      final res1 = $isFuture.validate('');
      expect(res1.isValid, false);
      expect(res1.description, 'Future<dynamic>');

      final res2 = $isFuture.validate(Future.value(1.23));
      expect(res2.isValid, true);
    });

    test('isEnum works', () {
      final res1 = isEnum().validate('');
      expect(res1.isValid, false);
      expect(res1.description, 'Enum');

      final res2 = isEnum().validate(EnumA.value1);
      expect(res2.isValid, true);
    });

    test('\$isEnum works', () {
      final res1 = $isEnum.validate('');
      expect(res1.isValid, false);
      expect(res1.description, 'Enum');

      final res2 = $isEnum.validate(EnumA.value1);
      expect(res2.isValid, true);
    });

    test('isList works', () {
      final res1 = isList<int>().validate('');
      expect(res1.isValid, false);
      expect(res1.description, 'List<int>');

      final res2 = isList<int>().validate([1, 2, 3]);
      expect(res2.isValid, true);
    });

    test('\$isList works', () {
      final res1 = $isList.validate('');
      expect(res1.isValid, false);
      expect(res1.description, 'List<dynamic>');

      final res2 = $isList.validate([1, 2, 3]);
      expect(res2.isValid, true);
    });

    test('isSet works', () {
      final res1 = isSet<int>().validate('');
      expect(res1.isValid, false);
      expect(res1.description, 'Set<int>');

      final res2 = isSet<int>().validate({1, 2, 3});
      expect(res2.isValid, true);
    });

    test('\$isSet works', () {
      final res1 = $isSet.validate('');
      expect(res1.isValid, false);
      expect(res1.description, 'Set<dynamic>');

      final res2 = $isSet.validate({1, 2, 3});
      expect(res2.isValid, true);
    });

    test('isRecord works', () {
      final res1 = isRecord().validate('');
      expect(res1.isValid, false);
      expect(res1.description, 'Record');

      final res2 = isRecord().validate(('first', a: 2, b: true, 'last'));
      expect(res2.isValid, true);
    });

    test('\$isRecord works', () {
      final res1 = $isRecord.validate('');
      expect(res1.isValid, false);
      expect(res1.description, 'Record');

      final res2 = $isRecord.validate(('first', a: 2, b: true, 'last'));
      expect(res2.isValid, true);
    });

    test('isIterable works', () {
      final res1 = isIterable<int>().validate('');
      expect(res1.isValid, false);
      expect(res1.description, 'Iterable<int>');

      final res2 = isIterable<int>().validate([1, 2, 3]);
      expect(res2.isValid, true);
    });

    test('\$isIterable works', () {
      final res1 = $isIterable.validate('');
      expect(res1.isValid, false);
      expect(res1.description, 'Iterable<dynamic>');

      final res2 = $isIterable.validate([1, 2, 3]);
      expect(res2.isValid, true);
    });

    test('isSymbol works', () {
      final res1 = isSymbol().validate('');
      expect(res1.isValid, false);
      expect(res1.description, 'Symbol');

      final res2 = isSymbol().validate(#mySymbol);
      expect(res2.isValid, true);
    });

    test('\$isSymbol works', () {
      final res1 = $isSymbol.validate('');
      expect(res1.isValid, false);
      expect(res1.description, 'Symbol');

      final res2 = $isSymbol.validate(#mySymbol);
      expect(res2.isValid, true);
    });

    test('isFunction works', () {
      final res1 = isFunction().validate('');
      expect(res1.isValid, false);
      expect(res1.description, 'Function');

      final res2 = isFunction().validate(() {});
      expect(res2.isValid, true);
    });

    test('\$isFunction works', () {
      final res1 = $isFunction.validate('');
      expect(res1.isValid, false);
      expect(res1.description, 'Function');

      final res2 = $isFunction.validate(() {});
      expect(res2.isValid, true);
    });

    test('\$isMap works', () {
      final res1 = $isMap.validate('');
      expect(res1.isValid, false);
      expect(res1.description, 'Map<dynamic, dynamic>');

      final res2 = $isMap.validate({'key': 'value'});
      expect(res2.isValid, true);
    });
  });
}

enum EnumA { value1, value2 }
