import 'package:test/test.dart';
import 'package:eskema/eskema.dart';

void main() {
  group('Builder basic type selection', () {
    test('string builder basic chain passes', () {
      final validator = builder().string().lengthMin(2).lengthMax(5).not.empty().build();
      expect(validator.validate('hey').isValid, true);
      expect(validator.validate('h').isValid, false); // too short
      expect(validator.validate('toolong').isValid, false); // too long
      expect(validator.validate('').isValid, false); // empty
    });

    test('number builder comparisons', () {
      final validator = builder().number().gte(10).lt(20).build();
      expect(validator.validate(10).isValid, true);
      expect(validator.validate(19.9).isValid, true);
      expect(validator.validate(9).isValid, false);
      expect(validator.validate(20).isValid, false);
    });

    test('int builder equality helpers', () {
      final validator = builder().int_().eq(42).build();
      expect(validator.validate(42).isValid, true);
      expect(validator.validate(41).isValid, false);
    });

    test('negation flag consumed correctly', () {
      final validator = builder().string().not.matches(RegExp(r'^abc')).build();
      expect(validator.validate('xyz').isValid, true); // does not match pattern
      expect(validator.validate('abc').isValid, false); // matches => negated fails
      // Ensure subsequent additions are not negated accidentally
      final validator2 = builder().string().not.empty().lengthMin(1).build();
      expect(validator2.validate('a').isValid, true); // not(empty) passes, lengthMin ok
      expect(validator2.validate('').isValid, false); // empty triggers not(empty) failure first
    });
  });

  group('Builder optional / nullable', () {
    test('optional skips when null key missing (map context simulated)', () {
      final fieldValidator = builder().string().lengthMin(2).optional().build();
      final esk = eskema({'name': fieldValidator});
      final result = esk.validate({});
      expect(result.isValid, true); // optional skipped
    });

    test('nullable accepts null', () {
      final validator = builder().string().lengthMin(1).nullable().build();
      expect(validator.validate(null).isValid, true);
      expect(validator.validate('a').isValid, true);
      expect(validator.validate('').isValid, false); // lengthMin fails
    });
  });

  group('Builder list.each + contains', () {
    test('list each string min length', () {
      final validator = builder().list().each(builder().string().lengthMin(2).build()).build();
      expect(validator.validate(['aa', 'bbb']).isValid, true);
      expect(validator.validate(['a']).isValid, false);
    });

    test('map contains key via builder', () {
      final validator = builder().map().containsKey('id').build();
      expect(validator.validate({'id': 1}).isValid, true);
      expect(validator.validate({'other': 1}).isValid, false);
    });
  });

  group('Builder oneOf / deepEq', () {
    test('oneOf works', () {
      final validator = builder().string().oneOf(['red', 'green']).build();
      expect(validator.validate('red').isValid, true);
      expect(validator.validate('blue').isValid, false);
    });

    test('deepEq list', () {
      final validator = builder().type<List<String>>().deepEq(['a', 'b']).build();
      expect(validator.validate(['a', 'b']).isValid, true);
      expect(validator.validate(['b', 'a']).isValid, false);
    });
  });

  group('Builder transformers & coercion', () {
    test('toInt accepts convertible strings', () {
      final validator = builder().string().toInt().gte(10).lt(15).build();
      expect(validator.validate(12).isValid, true);
      expect(validator.validate(9).isValid, false);
      expect(validator.validate('12').isValid, true); // coerced
      expect(validator.validate('9').isValid, false); // coerced then range fail
      expect(validator.validate('abc').isValid, false); // not parsable
    });

    test('toDouble accepts convertible strings', () {
      final validator = builder().string().toDouble().gte(1).lt(2).build();
      expect(validator.validate('1.5').isValid, true);
      expect(validator.validate('1').isValid, true);
      expect(validator.validate('3.14').isValid, false);
      expect(validator.validate('abc').isValid, false);
    });

    test('toInt actually coerces numeric strings', () {
      final validator = builder().string().toInt().gte(10).lt(15).build();
      expect(validator.validate('12').isValid, true);
      expect(validator.validate('9').isValid, false);
      expect(validator.validate('abc').isValid, false);
    });

    test('toDouble coerces numeric strings', () {
      final validator = builder().string().toDouble().gte(1).lt(2).build();
      expect(validator.validate('1.5').isValid, true);
      expect(validator.validate('3.14').isValid, false);
    });

    test('toBool parses boolean-like strings/ints', () {
      final validator = builder().string().toBool().eq(true).build();
      expect(validator.validate('true').isValid, true);
      expect(validator.validate('false').isValid, false);
      // Numeric strings not currently coerced; only literal 'true'/'false'.
      expect(validator.validate('1').isValid, false);
      expect(validator.validate('0').isValid, false);
    });

    test('coercion override drops previous post-coercion constraints', () {
      // gte(10) is added after first toInt, but a later toDouble overrides
      // the transform and clears earlier post-coercion constraints.
      final validator = builder().string().toInt().gte(10).toDouble().lt(10.5).build();
      // '9' would have failed gte(10) if it remained; passes because only lt(10.5) applies now.
      expect(validator.validate('9').isValid, true);
      expect(validator.validate('12').isValid, false); // 12.0 not < 10.5
    });

    test('repeated same coercion keeps existing constraints (idempotent)', () {
      final validator = builder().string().toInt().gte(5).toInt().lt(10).build();
      expect(validator.validate('7').isValid, true); // within both bounds
      expect(validator.validate('4').isValid, false); // fails gte(5)
      expect(validator.validate('12').isValid, false); // fails lt(10)
    });

    test('toNum converts numeric strings to num', () {
      final validator = builder().string().toNum().gt(3).lt(6).build();
      expect(validator.validate('4').isValid, true);
      expect(validator.validate('2').isValid, false);
      expect(validator.validate('7').isValid, false);
    });

    test('toBigInt parses big integers', () {
      final validator = builder().string().toBigInt().build();
      expect(validator.validate('9007199254740991').isValid, true);
      expect(validator.validate('notint').isValid, false);
    });

    test('toJsonDecoded decodes JSON strings', () {
      final validator = builder().string().toJson().build();
      expect(validator.validate('{"a":1}').isValid, true);
      expect(validator.validate('[1,2,3]').isValid, true);
      expect(validator.validate('not json').isValid, false);
    });

    test('DateTimeBuilder basic before/after', () {
      final now = DateTime.now();
      final earlier = now.subtract(const Duration(days: 1));
      final later = now.add(const Duration(days: 1));
      final vBefore = builder().dateTime().before(later).build();
      expect(vBefore.validate(now).isValid, true);
      final vAfter = builder().dateTime().after(earlier).build();
      expect(vAfter.validate(now).isValid, true);
      expect(vAfter.validate(earlier.subtract(const Duration(seconds: 1))).isValid, false);
    });

    test('DateTimeBuilder betweenDates / sameDay / inPast/inFuture', () {
      final today = DateTime.now();
      final tomorrow = today.add(const Duration(days: 1));
      final yesterday = today.subtract(const Duration(days: 1));
      final between = builder().dateTime().betweenDates(yesterday, tomorrow).build();
      expect(between.validate(today).isValid, true);
      expect(between.validate(tomorrow.add(const Duration(seconds: 1))).isValid, false);
      final same = builder().dateTime().sameDay(today).build();
      expect(same.validate(today).isValid, true);
      expect(same.validate(tomorrow).isValid, false);
      final past = builder().dateTime().inPast().build();
      expect(past.validate(yesterday).isValid, true);
      final future = builder().dateTime().inFuture().build();
      expect(future.validate(tomorrow).isValid, true);
    });

    test('JsonDecodedBuilder object/array validators', () {
      final vJsonObj = builder()
          .string()
          .toJson()
          .jsonContainer()
          .jsonObject()
          .jsonRequiresKeys(['a', 'b']).build();
      expect(vJsonObj.validate('{"a":1,"b":2}').isValid, true);
      expect(vJsonObj.validate('{"a":1}').isValid, false);
      final vJsonArr = builder().string().toJson().jsonArray().jsonArrayLen(min: 2, max: 3).build();
      expect(vJsonArr.validate('[1,2]').isValid, true);
      expect(vJsonArr.validate('[1]').isValid, false);
      expect(vJsonArr.validate('[1,2,3,4]').isValid, false);
      final vJsonArrEach =
          builder().string().toJson().jsonArray().jsonArrayEach(builder().number().gte(0).build()).build();
      expect(vJsonArrEach.validate('[1,2,3]').isValid, true);
      expect(vJsonArrEach.validate('[1,-2,3]').isValid, false);
    });
  });

  group('Builder string mixin extras', () {
    test('email / lowerCase / upperCase', () {
      expect(builder().string().email().build().validate('user@example.com').isValid, true);
      expect(builder().string().email().build().validate('not-email').isValid, false);
      expect(builder().string().lowerCase().build().validate('abc').isValid, true);
      expect(builder().string().lowerCase().build().validate('Abc').isValid, false);
      expect(builder().string().upperCase().build().validate('ABC').isValid, true);
      expect(builder().string().upperCase().build().validate('AbC').isValid, false);
    });

    test('url strict vs non-strict', () {
      final nonStrict = builder().string().url().build();
      expect(nonStrict.validate('example.com').isValid, true);
      final strict = builder().string().strictUrl().build();
      expect(strict.validate('example.com').isValid, false);
      expect(strict.validate('https://example.com').isValid, true);
    });

    test('intString / doubleString / numString / boolString / isDate', () {
      expect(builder().string().intString().build().validate('42').isValid, true);
      expect(builder().string().intString().build().validate('42.1').isValid, false);
      expect(builder().string().doubleString().build().validate('42.1').isValid, true);
      expect(builder().string().numString().build().validate('3e2').isValid, true);
      expect(builder().string().boolString().build().validate('true').isValid, true);
      expect(builder().string().boolString().build().validate('yes').isValid, false);
      expect(builder().string().isDate().build().validate(DateTime.now().toIso8601String()).isValid,
          true);
    });
  });

  group('Builder map schema / strict', () {
    test('schema vs strict extra key', () {
      final schemaValidator = builder().map().schema({
        'id': builder().int_().gte(0).build(),
      }).build();
      final strictValidator = builder().map().strict({
        'id': builder().int_().gte(0).build(),
      }).build();
      expect(schemaValidator.validate({'id': 1, 'extra': true}).isValid,
          true); // non-strict ignores
      expect(strictValidator.validate({'id': 1, 'extra': true}).isValid, false); // strict fails
      expect(strictValidator.validate({'id': -1}).isValid, false); // id constraint fails
    });
  });

  group('Builder contains / list / iterable', () {
    test('list contains element', () {
      final validator = builder().list().contains('a').build();
      expect(validator.validate(['a', 'b']).isValid, true);
      expect(validator.validate(['b']).isValid, false);
    });
  });

  group('Builder bool / between / lengthRange', () {
    test('bool isTrue', () {
      final validator = builder().bool().isTrue().build();
      expect(validator.validate(true).isValid, true);
      expect(validator.validate(false).isValid, false);
    });

    test('between inclusive boundaries', () {
      final validator = builder().number().between(5, 10).build();
      expect(validator.validate(5).isValid, true);
      expect(validator.validate(10).isValid, true);
      expect(validator.validate(4.999).isValid, false);
      expect(validator.validate(10.1).isValid, false);
    });

    test('lengthRange', () {
      final validator = builder().string().lengthRange(2, 4).build();
      expect(validator.validate('ab').isValid, true);
      expect(validator.validate('abcd').isValid, true);
      expect(validator.validate('a').isValid, false);
      expect(validator.validate('abcde').isValid, false);
    });
  });

  group('Builder error() override & generic type', () {
    test('error override preserves code', () {
      final validator = builder().number().gte(10).error('custom message').build();
      final r = validator.validate(5);
      expect(r.isValid, false);
      expect(r.expectations.first.message, 'custom message');
      expect(r.expectations.first.code, 'value.range_out_of_bounds');
    });

    test('generic type<T>() simple guard', () {
      final validator = builder().type<int>().eq(7).build();
      expect(validator.validate(7).isValid, true);
      expect(validator.validate(8).isValid, false);
      expect(validator.validate('7').isValid, false);
    });
  });

  group('Builder edge cases & odd scenarios', () {
    test('stray not without following validator is ignored safely', () {
      final validator = builder().string().not.build();
      expect(validator.validate('ok').isValid, true); // acts like plain string validator
    });

    test('double coercion idempotent', () {
      final validator = builder().string().toInt().toInt().gte(5).build();
      expect(validator.validate('6').isValid, true);
      expect(validator.validate('4').isValid, false);
    });
    test('negated pattern validator triggers failure on match', () {
      final validator = builder().string().not.matches(RegExp(r'^fail')).build();
      expect(validator.validate('ok').isValid, true);
      expect(validator.validate('failCase').isValid, false);
    });

    test('stacked error overrides keep last', () {
      final validator = builder().number().gte(10).error('first').error('second').build();
      final r = validator.validate(5);
      expect(r.isValid, false);
      expect(r.expectations.first.message, 'second');
    });

    test('negated pattern match (not.matches)', () {
      final validator = builder().string().not.matches(RegExp(r'^foo')).build();
      expect(validator.validate('bar').isValid, true);
      expect(validator.validate('foo123').isValid, false);
    });

    test('oneOf empty set always fails', () {
      final validator = builder().string().oneOf(const []).build();
      expect(validator.validate('anything').isValid, false);
    });

    test('base type only (no extra constraints)', () {
      final validator = builder().string().build();
      expect(validator.validate('hi').isValid, true);
      expect(validator.validate(1).isValid, false);
    });

    test('optional applied last (otherwise earlier optional lost)', () {
      final validator = builder().string().lengthMin(2).nullable().optional().build();
      final schema = eskema({'name': validator});
      expect(schema.validate({}).isValid, true); // optional skip now works
      expect(validator.validate(null).isValid, true); // nullable accepted
      expect(validator.validate('a').isValid, false); // fails length
    });

    test('optional respected with no later constraints', () {
      final validator = builder().string().optional().build();
      final schema = eskema({'name': validator});
      expect(schema.validate({}).isValid, true);
    });

    test('empty builder (no constraints) using type only', () {
      final validator = builder().string().build();
      expect(validator.validate('x').isValid, true);
      expect(validator.validate(1).isValid, false);
    });

    test('map strict missing key fails', () {
      final validator = builder().map().strict({'id': builder().int_().gte(0).build()}).build();
      expect(validator.validate({}).isValid, false);
    });

    test('map strict with optional field missing passes', () {
      final validator = builder().map().strict({
        'id': builder().int_().gte(0).build(),
        'nick': builder().string().lengthMin(2).optional().build(),
      }).build();
      expect(validator.validate({'id': 1}).isValid, true);
    });

    test('list each with optional validator: null element fails', () {
      final validator = builder().list().each(builder().string().lengthMin(2).optional().build()).build();
      expect(validator.validate(['ab', 'cd']).isValid, true);
      expect(validator.validate(['a']).isValid, false); // lengthMin
      expect(validator.validate(['ab', null]).isValid,
          false); // optional does not allow null element
    });

    test('lengthMin then lengthMax order reversed still works', () {
      final validator = builder().string().lengthMax(5).lengthMin(2).build();
      expect(validator.validate('ab').isValid, true);
      expect(validator.validate('toolong').isValid, false);
      expect(validator.validate('a').isValid, false);
    });
  });

  group('Custom Pivot Extensibility', () {
    test('basic custom pivot transforms value before validation', () {
      final uppercasePivot = CustomPivot(
        (child) => Validator((value) {
          if (value is String) {
            return child.validate(value.toUpperCase());
          }
          return child.validate(value);
        }),
        dropPre: true,
        kind: 'uppercase',
      );

      final validator = builder().string().use(uppercasePivot).lengthMin(3).build();

      // 'hi' becomes 'HI' and fails lengthMin(3)
      expect(validator.validate('hi').isValid, false);
      expect(validator.validate('hi').value, 'HI');

      // 'hello' becomes 'HELLO' and passes
      expect(validator.validate('hello').isValid, true);
      expect(validator.validate('hello').value, 'HELLO');
    });

    test('custom pivot with dropPre: false preserves pre-validators', () {
      final toIntPivot = CustomPivot(
        (child) => Validator((value) {
          if (value is String) {
            final parsed = int.tryParse(value);
            return child.validate(parsed ?? value);
          }
          return child.validate(value);
        }),
        dropPre: false, // Keep pre-validators
        kind: 'toInt',
      );

      final validator = builder().string().lengthMin(2).use(toIntPivot).gte(10).build();

      // String pre-validator passes, then toInt pivot, then numeric validator
      expect(validator.validate('123').isValid, true); // '123'.length >= 2, then int(123) >= 10
      expect(validator.validate('123').value, 123);

      // String pre-validator fails
      expect(validator.validate('1').isValid, false); // '1'.length < 2
      expect(validator.validate('1').description, 'Length must be greater than or equal to 2');
    });

    test('custom pivot with dropPre: true drops pre-validators', () {
      final toIntPivot = CustomPivot(
        (child) => Validator((value) {
          if (value is String) {
            final parsed = int.tryParse(value);
            return child.validate(parsed ?? value);
          }
          return child.validate(value);
        }),
        dropPre: true, // Drop pre-validators (default)
        kind: 'toInt',
      );

      final validator = builder().string().lengthMin(2).use(toIntPivot).gte(10).build();

      // Pre-validators are dropped, so '1' passes string check but fails numeric
      expect(validator.validate('1').isValid, false); // int(1) < 10
      expect(validator.validate('123').isValid, true); // int(123) >= 10
    });

    test('custom pivot chains with built-in pivots', () {
      final parseDoublePivot = CustomPivot(
        (child) => Validator((value) {
          if (value is String) {
            final parsed = double.tryParse(value);
            return child.validate(parsed ?? value);
          }
          return child.validate(value);
        }),
        dropPre: true,
        kind: 'parseDouble',
      );

      final validator = builder().string().use(parseDoublePivot).toInt().gte(5).build();

      // '10.0' -> double 10.0 -> int 10 -> passes
      expect(validator.validate('10.0').isValid, true);
      expect(validator.validate('10.0').value, 10);

      // '3.5' -> double 3.5 -> fails toIntStrict (not whole number)
      expect(validator.validate('3.5').isValid, false);
    });

    test('custom pivot with non-string input', () {
      final multiplyByTwoPivot = CustomPivot(
        (child) => Validator((value) {
          if (value is num) {
            return child.validate(value * 2);
          }
          return child.validate(value);
        }),
        dropPre: true,
        kind: 'multiplyByTwo',
      );

      final validator = builder().number().use(multiplyByTwoPivot).lt(10).build();

      // 3 * 2 = 6 < 10, passes
      expect(validator.validate(3).isValid, true);
      expect(validator.validate(3).value, 6);

      // 6 * 2 = 12 >= 10, fails
      expect(validator.validate(6).isValid, false);
    });

    test('custom pivot preserves error messages', () {
      final failingPivot = CustomPivot(
        (child) => Validator((value) {
          // Always fail with custom message
          return Result.invalid(value, expectation: const Expectation(message: 'Custom pivot failed'));
        }),
        dropPre: true,
        kind: 'failing',
      );

      final validator = builder().string().use(failingPivot).build();
      final result = validator.validate('test');

      expect(result.isValid, false);
      expect(result.description, 'Custom pivot failed');
    });

    test('multiple custom pivots in chain (latest wins)', () {
      final addPrefixPivot = CustomPivot(
        (child) => transform((value) => 'prefix_$value', child),
        dropPre: true,
        kind: 'addPrefix',
      );

      final toUpperPivot = CustomPivot(
        (child) => transform((value) => value.toUpperCase(), child),
        dropPre: true,
        kind: 'toUpper',
      );

      final validator = builder().string().use(addPrefixPivot).use(toUpperPivot).lengthMin(10).build();

      // 'test' -> 'prefix_test' -> 'PREFIX_TEST' -> length check
      expect(validator.validate('test').isValid, true);
      expect(validator.validate('test').value, 'PREFIX_TEST');

      // 'x' -> 'prefix_x' -> 'PREFIX_X' -> too short
      expect(validator.validate('x').isValid, false);
    });
  });
}
