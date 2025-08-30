import 'package:test/test.dart';
import 'package:eskema/eskema.dart';

void main() {
  group('Builder basic type selection', () {
    test('string builder basic chain passes', () {
      final validator = v().string().lengthMin(2).lengthMax(5).not.empty().build();
      expect(validator.validate('hey').isValid, true);
      expect(validator.validate('h').isValid, false); // too short
      expect(validator.validate('toolong').isValid, false); // too long
      expect(validator.validate('').isValid, false); // empty
    });

    test('number builder comparisons', () {
      final validator = v().number().gte(10).lt(20).build();
      expect(validator.validate(10).isValid, true);
      expect(validator.validate(19.9).isValid, true);
      expect(validator.validate(9).isValid, false);
      expect(validator.validate(20).isValid, false);
    });

    test('int builder equality helpers', () {
      final validator = v().int_().eq(42).build();
      expect(validator.validate(42).isValid, true);
      expect(validator.validate(41).isValid, false);
    });

    test('negation flag consumed correctly', () {
      final validator = v().string().not.matches(RegExp(r'^abc')).build();
      expect(validator.validate('xyz').isValid, true); // does not match pattern
      expect(validator.validate('abc').isValid, false); // matches => negated fails
      // Ensure subsequent additions are not negated accidentally
      final validator2 = v().string().not.empty().lengthMin(1).build();
      expect(validator2.validate('a').isValid, true); // not(empty) passes, lengthMin ok
      expect(validator2.validate('').isValid, false); // empty triggers not(empty) failure first
    });
  });

  group('Builder optional / nullable', () {
    test('optional skips when null key missing (map context simulated)', () {
      final fieldValidator = v().string().lengthMin(2).optional().build();
      final esk = eskema({'name': fieldValidator});
      final result = esk.validate({});
      expect(result.isValid, true); // optional skipped
    });

    test('nullable accepts null', () {
      final validator = v().string().lengthMin(1).nullable().build();
      expect(validator.validate(null).isValid, true);
      expect(validator.validate('a').isValid, true);
      expect(validator.validate('').isValid, false); // lengthMin fails
    });
  });

  group('Builder list.each + contains', () {
    test('list each string min length', () {
      final validator = v().list().each(v().string().lengthMin(2).build()).build();
      expect(validator.validate(['aa', 'bbb']).isValid, true);
      expect(validator.validate(['a']).isValid, false);
    });

    test('map contains key via builder', () {
      final validator = v().map().containsKey('id').build();
      expect(validator.validate({'id': 1}).isValid, true);
      expect(validator.validate({'other': 1}).isValid, false);
    });
  });

  group('Builder oneOf / deepEq', () {
    test('oneOf works', () {
      final validator = v().string().oneOf(['red', 'green']).build();
      expect(validator.validate('red').isValid, true);
      expect(validator.validate('blue').isValid, false);
    });

    test('deepEq list', () {
      final validator = v().type<List<String>>().deepEq(['a', 'b']).build();
      expect(validator.validate(['a', 'b']).isValid, true);
      expect(validator.validate(['b', 'a']).isValid, false);
    });
  });

  group('Builder transformers & coercion', () {
    test('toInt accepts convertible strings', () {
      final validator = v().string().toInt().gte(10).lt(15).build();
      expect(validator.validate(12).isValid, true);
      expect(validator.validate(9).isValid, false);
      expect(validator.validate('12').isValid, true); // coerced
      expect(validator.validate('9').isValid, false); // coerced then range fail
      expect(validator.validate('abc').isValid, false); // not parsable
    });

    test('toDouble accepts convertible strings', () {
      final validator = v().string().toDouble().gte(1).lt(2).build();
      expect(validator.validate('1.5').isValid, true);
      expect(validator.validate('1').isValid, true);
      expect(validator.validate('3.14').isValid, false);
      expect(validator.validate('abc').isValid, false);
    });

    test('toInt actually coerces numeric strings', () {
      final validator = v().string().toInt().gte(10).lt(15).build();
      expect(validator.validate('12').isValid, true);
      expect(validator.validate('9').isValid, false);
      expect(validator.validate('abc').isValid, false);
    });

    test('toDouble coerces numeric strings', () {
      final validator = v().string().toDouble().gte(1).lt(2).build();
      expect(validator.validate('1.5').isValid, true);
      expect(validator.validate('3.14').isValid, false);
    });

    test('toBool parses boolean-like strings/ints', () {
      final validator = v().string().toBool().eq(true).build();
      expect(validator.validate('true').isValid, true);
      expect(validator.validate('false').isValid, false);
      // Numeric strings not currently coerced; only literal 'true'/'false'.
      expect(validator.validate('1').isValid, false);
      expect(validator.validate('0').isValid, false);
    });

    test('coercion override drops previous post-coercion constraints', () {
      // gte(10) is added after first toInt, but a later toDouble overrides
      // the transform and clears earlier post-coercion constraints.
      final validator = v().string().toInt().gte(10).toDouble().lt(10.5).build();
      // '9' would have failed gte(10) if it remained; passes because only lt(10.5) applies now.
      expect(validator.validate('9').isValid, true);
      expect(validator.validate('12').isValid, false); // 12.0 not < 10.5
    });

    test('repeated same coercion keeps existing constraints (idempotent)', () {
      final validator = v().string().toInt().gte(5).toInt().lt(10).build();
      expect(validator.validate('7').isValid, true); // within both bounds
      expect(validator.validate('4').isValid, false); // fails gte(5)
      expect(validator.validate('12').isValid, false); // fails lt(10)
    });

    test('toNum converts numeric strings to num', () {
      final validator = v().string().toNum().gt(3).lt(6).build();
      expect(validator.validate('4').isValid, true);
      expect(validator.validate('2').isValid, false);
      expect(validator.validate('7').isValid, false);
    });

    test('toBigInt parses big integers', () {
      final validator = v().string().toBigInt().build();
      expect(validator.validate('9007199254740991').isValid, true);
      expect(validator.validate('notint').isValid, false);
    });

    test('toUri parses URI strings', () {
      final validator = v().string().toUri().build();
      expect(validator.validate('https://example.com').isValid, true);
      expect(validator.validate('not a uri').isValid, false);
    });

    test('toDateOnly normalizes time', () {
      final validator = v().string().toDateOnly().build();
      expect(validator.validate(DateTime.now().toIso8601String()).isValid, true);
      expect(validator.validate('2024-02-30').isValid, false); // invalid date
    });

    test('toJsonDecoded decodes JSON strings', () {
      final validator = v().string().toJson().build();
      expect(validator.validate('{"a":1}').isValid, true);
      expect(validator.validate('[1,2,3]').isValid, true);
      expect(validator.validate('not json').isValid, false);
    });

    test('DateTimeBuilder basic before/after', () {
      final now = DateTime.now();
      final earlier = now.subtract(const Duration(days: 1));
      final later = now.add(const Duration(days: 1));
      final vBefore = v().dateTime().before(later).build();
      expect(vBefore.validate(now).isValid, true);
      final vAfter = v().dateTime().after(earlier).build();
      expect(vAfter.validate(now).isValid, true);
      expect(vAfter.validate(earlier.subtract(const Duration(seconds: 1))).isValid, false);
    });

    test('DateTimeBuilder betweenDates / sameDay / inPast/inFuture', () {
      final today = DateTime.now();
      final tomorrow = today.add(const Duration(days: 1));
      final yesterday = today.subtract(const Duration(days: 1));
      final between = v().dateTime().betweenDates(yesterday, tomorrow).build();
      expect(between.validate(today).isValid, true);
      expect(between.validate(tomorrow.add(const Duration(seconds: 1))).isValid, false);
      final same = v().dateTime().sameDay(today).build();
      expect(same.validate(today).isValid, true);
      expect(same.validate(tomorrow).isValid, false);
      final past = v().dateTime().inPast().build();
      expect(past.validate(yesterday).isValid, true);
      final future = v().dateTime().inFuture().build();
      expect(future.validate(tomorrow).isValid, true);
    });

    test('JsonDecodedBuilder object/array validators', () {
      final vJsonObj = v()
          .string()
          .toJson()
          .jsonContainer()
          .jsonObject()
          .jsonRequiresKeys(['a', 'b']).build();
      expect(vJsonObj.validate('{"a":1,"b":2}').isValid, true);
      expect(vJsonObj.validate('{"a":1}').isValid, false);
      final vJsonArr = v().string().toJson().jsonArray().jsonArrayLen(min: 2, max: 3).build();
      expect(vJsonArr.validate('[1,2]').isValid, true);
      expect(vJsonArr.validate('[1]').isValid, false);
      expect(vJsonArr.validate('[1,2,3,4]').isValid, false);
      final vJsonArrEach =
          v().string().toJson().jsonArray().jsonArrayEach(v().number().gte(0).build()).build();
      expect(vJsonArrEach.validate('[1,2,3]').isValid, true);
      expect(vJsonArrEach.validate('[1,-2,3]').isValid, false);
    });
  });

  group('Builder string mixin extras', () {
    test('email / lowerCase / upperCase', () {
      expect(v().string().email().build().validate('user@example.com').isValid, true);
      expect(v().string().email().build().validate('not-email').isValid, false);
      expect(v().string().lowerCase().build().validate('abc').isValid, true);
      expect(v().string().lowerCase().build().validate('Abc').isValid, false);
      expect(v().string().upperCase().build().validate('ABC').isValid, true);
      expect(v().string().upperCase().build().validate('AbC').isValid, false);
    });

    test('url strict vs non-strict', () {
      final nonStrict = v().string().url().build();
      expect(nonStrict.validate('example.com').isValid, true);
      final strict = v().string().strictUrl().build();
      expect(strict.validate('example.com').isValid, false);
      expect(strict.validate('https://example.com').isValid, true);
    });

    test('intString / doubleString / numString / boolString / isDate', () {
      expect(v().string().intString().build().validate('42').isValid, true);
      expect(v().string().intString().build().validate('42.1').isValid, false);
      expect(v().string().doubleString().build().validate('42.1').isValid, true);
      expect(v().string().numString().build().validate('3e2').isValid, true);
      expect(v().string().boolString().build().validate('true').isValid, true);
      expect(v().string().boolString().build().validate('yes').isValid, false);
      expect(v().string().isDate().build().validate(DateTime.now().toIso8601String()).isValid,
          true);
    });
  });

  group('Builder map schema / strict', () {
    test('schema vs strict extra key', () {
      final schemaValidator = v().map().schema({
        'id': v().int_().gte(0).build(),
      }).build();
      final strictValidator = v().map().strict({
        'id': v().int_().gte(0).build(),
      }).build();
      expect(schemaValidator.validate({'id': 1, 'extra': true}).isValid,
          true); // non-strict ignores
      expect(strictValidator.validate({'id': 1, 'extra': true}).isValid, false); // strict fails
      expect(strictValidator.validate({'id': -1}).isValid, false); // id constraint fails
    });
  });

  group('Builder contains / list / iterable', () {
    test('list contains element', () {
      final validator = v().list().contains('a').build();
      expect(validator.validate(['a', 'b']).isValid, true);
      expect(validator.validate(['b']).isValid, false);
    });
  });

  group('Builder bool / between / lengthRange', () {
    test('bool isTrue', () {
      final validator = v().bool_().isTrue().build();
      expect(validator.validate(true).isValid, true);
      expect(validator.validate(false).isValid, false);
    });

    test('between inclusive boundaries', () {
      final validator = v().number().between(5, 10).build();
      expect(validator.validate(5).isValid, true);
      expect(validator.validate(10).isValid, true);
      expect(validator.validate(4.999).isValid, false);
      expect(validator.validate(10.1).isValid, false);
    });

    test('lengthRange', () {
      final validator = v().string().lengthRange(2, 4).build();
      expect(validator.validate('ab').isValid, true);
      expect(validator.validate('abcd').isValid, true);
      expect(validator.validate('a').isValid, false);
      expect(validator.validate('abcde').isValid, false);
    });
  });

  group('Builder error() override & generic type', () {
    test('error override preserves code', () {
      final validator = v().number().gte(10).error('custom message').build();
      final r = validator.validate(5);
      expect(r.isValid, false);
      expect(r.expectations.first.message, 'custom message');
      expect(r.expectations.first.code, 'value.range_out_of_bounds');
    });

    test('generic type<T>() simple guard', () {
      final validator = v().type<int>().eq(7).build();
      expect(validator.validate(7).isValid, true);
      expect(validator.validate(8).isValid, false);
      expect(validator.validate('7').isValid, false);
    });
  });

  group('Builder edge cases & odd scenarios', () {
    test('stray not without following validator is ignored safely', () {
      final validator = v().string().not.build();
      expect(validator.validate('ok').isValid, true); // acts like plain string validator
    });

    test('double coercion idempotent', () {
      final validator = v().string().toInt().toInt().gte(5).build();
      expect(validator.validate('6').isValid, true);
      expect(validator.validate('4').isValid, false);
    });
    test('negated pattern validator triggers failure on match', () {
      final validator = v().string().not.matches(RegExp(r'^fail')).build();
      expect(validator.validate('ok').isValid, true);
      expect(validator.validate('failCase').isValid, false);
    });

    test('stacked error overrides keep last', () {
      final validator = v().number().gte(10).error('first').error('second').build();
      final r = validator.validate(5);
      expect(r.isValid, false);
      expect(r.expectations.first.message, 'second');
    });

    test('negated pattern match (not.matches)', () {
      final validator = v().string().not.matches(RegExp(r'^foo')).build();
      expect(validator.validate('bar').isValid, true);
      expect(validator.validate('foo123').isValid, false);
    });

    test('oneOf empty set always fails', () {
      final validator = v().string().oneOf(const []).build();
      expect(validator.validate('anything').isValid, false);
    });

    test('base type only (no extra constraints)', () {
      final validator = v().string().build();
      expect(validator.validate('hi').isValid, true);
      expect(validator.validate(1).isValid, false);
    });

    test('optional applied last (otherwise earlier optional lost)', () {
      final validator = v().string().lengthMin(2).nullable().optional().build();
      final schema = eskema({'name': validator});
      expect(schema.validate({}).isValid, true); // optional skip now works
      expect(validator.validate(null).isValid, true); // nullable accepted
      expect(validator.validate('a').isValid, false); // fails length
    });

    test('optional respected with no later constraints', () {
      final validator = v().string().optional().build();
      final schema = eskema({'name': validator});
      expect(schema.validate({}).isValid, true);
    });

    test('empty builder (no constraints) using type only', () {
      final validator = v().string().build();
      expect(validator.validate('x').isValid, true);
      expect(validator.validate(1).isValid, false);
    });

    test('map strict missing key fails', () {
      final validator = v().map().strict({'id': v().int_().gte(0).build()}).build();
      expect(validator.validate({}).isValid, false);
    });

    test('map strict with optional field missing passes', () {
      final validator = v().map().strict({
        'id': v().int_().gte(0).build(),
        'nick': v().string().lengthMin(2).optional().build(),
      }).build();
      expect(validator.validate({'id': 1}).isValid, true);
    });

    test('list each with optional validator: null element fails', () {
      final validator = v().list().each(v().string().lengthMin(2).optional().build()).build();
      expect(validator.validate(['ab', 'cd']).isValid, true);
      expect(validator.validate(['a']).isValid, false); // lengthMin
      expect(validator.validate(['ab', null]).isValid,
          false); // optional does not allow null element
    });

    test('lengthMin then lengthMax order reversed still works', () {
      final validator = v().string().lengthMax(5).lengthMin(2).build();
      expect(validator.validate('ab').isValid, true);
      expect(validator.validate('toolong').isValid, false);
      expect(validator.validate('a').isValid, false);
    });
  });
}
