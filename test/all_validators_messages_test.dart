import 'package:eskema/eskema.dart'
    hide contains; // hide validator contains to avoid matcher clash
import 'package:test/test.dart' as t;

class _ValidatorCase {
  final String name;
  final IValidator Function() build;
  final dynamic failingValue;
  final String expectedMessage;
  _ValidatorCase(this.name, this.build, this.failingValue, this.expectedMessage);
}

void main() {
  t.group('Custom message support validators', () {
    final cases = <_ValidatorCase>[
      _ValidatorCase(
          'isType<int>', () => isType<int>(message: 'custom int type'), 'x', 'custom int type'),
      _ValidatorCase('isEq', () => isEq(5, message: 'equal five'), 3, 'equal five'),
      _ValidatorCase(
          'isDeepEq(list)', () => isDeepEq([1, 2], message: 'deep list'), [1, 3], 'deep list'),
      _ValidatorCase('isLt', () => isLt(3, message: 'lt 3'), 5, 'lt 3'),
      _ValidatorCase('isLte', () => isLte(1, message: 'lte 1'), 2, 'lte 1'),
      _ValidatorCase('isGt', () => isGt(10, message: 'gt 10'), 5, 'gt 10'),
      _ValidatorCase('isGte', () => isGte(2, message: 'gte 2'), 1, 'gte 2'),
      _ValidatorCase('isInRange', () => isInRange(5, 8, message: 'range 5-8'), 3, 'range 5-8'),
      _ValidatorCase('stringContains', () => stringContains('abc', message: 'must contain abc'),
          'zzz', 'must contain abc'),
      _ValidatorCase(
          'stringEmpty', () => isStringEmpty(message: 'must be empty'), 'not', 'must be empty'),
      _ValidatorCase(
          'isLowerCase', () => isLowerCase(message: 'lower only'), 'ABC', 'lower only'),
      _ValidatorCase(
          'isUpperCase', () => isUpperCase(message: 'upper only'), 'abc', 'upper only'),
      _ValidatorCase('isEmail', () => isEmail(message: 'bad email'), 'nope', 'bad email'),
      _ValidatorCase(
          'isUrl', () => isUrl(strict: true, message: 'bad url'), 'example.com', 'bad url'),
      _ValidatorCase('isUuidV4', () => isUuidV4(message: 'bad uuid'), 'not-a-uuid', 'bad uuid'),
      _ValidatorCase('isIntString', () => isIntString(message: 'int str'), 'abc', 'int str'),
      _ValidatorCase(
          'isDoubleString', () => isDoubleString(message: 'double str'), 'abc', 'double str'),
      _ValidatorCase('isNumString', () => isNumString(message: 'num str'), 'abc', 'num str'),
      _ValidatorCase(
          'isBoolString', () => isBoolString(message: 'bool str'), 'maybe', 'bool str'),
      _ValidatorCase('isDate', () => isDate(message: 'date str'), 'not-date', 'date str'),
      _ValidatorCase(
          'listContains', () => listContains(3, message: 'needs 3'), [1, 2], 'needs 3'),
      _ValidatorCase('listEmpty', () => listEmpty(message: 'empty list'), [1], 'empty list'),
      _ValidatorCase('containsKey', () => containsKey('id', message: 'needs id'), {'name': 'x'},
          'needs id'),
      _ValidatorCase('containsKeys', () => containsKeys(['a', 'b'], message: 'needs a,b'),
          {'a': 1}, 'needs a,b'),
      _ValidatorCase('containsValues', () => containsValues([1, 2], message: 'needs values'),
          {'x': 1, 'y': 3}, 'needs values'),
      _ValidatorCase(
          'isDateBefore',
          () => isDateBefore(DateTime(2020, 1, 1), message: 'before 2020'),
          DateTime(2025),
          'before 2020'),
      _ValidatorCase(
          'isDateAfter',
          () => isDateAfter(DateTime(2025, 1, 1), message: 'after 2025'),
          DateTime(2020),
          'after 2025'),
      _ValidatorCase(
          'isDateBetween',
          () => isDateBetween(DateTime(2020, 1, 1), DateTime(2020, 1, 5),
              message: 'between range'),
          DateTime(2020, 1, 10),
          'between range'),
      _ValidatorCase(
          'isDateSameDay',
          () => isDateSameDay(DateTime(2020, 1, 1), message: 'same day'),
          DateTime(2020, 1, 2),
          'same day'),
      _ValidatorCase('isDateInPast', () => isDateInPast(message: 'past'),
          DateTime.now().add(const Duration(days: 1)), 'past'),
      _ValidatorCase(
          'isDateInFuture', () => isDateInFuture(message: 'future'), DateTime(2000), 'future'),
      _ValidatorCase(
          'eskemaStrict',
          () => eskemaStrict({'id': isInt()}, message: 'unknown keys'),
          {'id': 1, 'extra': true},
          'unknown keys'),
      _ValidatorCase(
          'listEach', () => listEach(isInt(), message: 'all int'), [1, 'x', 3], 'all int'),
      _ValidatorCase(
          'eskema (field override)',
          () => eskema({'age': isGte(18, message: 'adult')}, message: 'schema fail'),
          {'age': 10},
          'schema fail'),
    ];

    for (final c in cases) {
      t.test(c.name, () {
        final validator = c.build();
        final result = validator.validate(c.failingValue);
        t.expect(result.isValid, t.isFalse, reason: 'Expected failure for ${c.name}');
        final msg = result.firstExpectation.message;

        t.expect(msg, c.expectedMessage);
      });
    }
  });

  t.group('Transformer expectation defaults', () {
    final txCases = <_ValidatorCase>[
      _ValidatorCase('toString custom',
          () => toString(isEq('EXPECTED'), message: 'custom toString'), 123, 'custom toString'),
      _ValidatorCase('trimString', () => trimString(isEq('X'), message: 'custom trim'), '  y ',
          'custom trim'),
      _ValidatorCase('collapseWhitespace',
          () => collapseWhitespace(isEq('a b'), message: 'cw msg'), 'a   c', 'cw msg'),
      _ValidatorCase('toLowerCaseString',
          () => toLowerCaseString(isEq('zzz'), message: 'lower msg'), 'ABC', 'lower msg'),
      _ValidatorCase('toUpperCaseString',
          () => toUpperCaseString(isEq('ZZZ'), message: 'upper msg'), 'abc', 'upper msg'),
      _ValidatorCase('trim', () => trim(isEq('z'), message: 'trim expectation'), ' y ',
          'trim expectation'),
      _ValidatorCase(
          'toLowerCase',
          () => toLowerCase(isEq('zzz'), message: 'lowercase expectation'),
          'ABC',
          'lowercase expectation'),
      _ValidatorCase(
          'toUpperCase',
          () => toUpperCase(isEq('ZZZ'), message: 'uppercase expectation'),
          'abc',
          'uppercase expectation'),
      _ValidatorCase('split', () => split(',', listIsOfLength(3), message: 'split msg'), 'a,b',
          'split msg'),
      _ValidatorCase('toIntStrict', () => toIntStrict(isGte(10), message: 'int strict msg'),
          'abc', 'int strict msg'),
      _ValidatorCase('toIntSafe', () => toIntSafe(isGte(10), message: 'int safe msg'), 'abc',
          'int safe msg'),
      _ValidatorCase('toInt', () => toInt(isGte(10), message: 'int msg'), 'abc', 'int msg'),
      _ValidatorCase(
          'toDouble', () => toDouble(isGte(10), message: 'double msg'), 'abc', 'double msg'),
      _ValidatorCase('toNum', () => toNum(isGte(10), message: 'num msg'), 'abc', 'num msg'),
      _ValidatorCase('toBigInt', () => toBigInt(isType<BigInt>(), message: 'bigint msg'), 'abc',
          'bigint msg'),
      _ValidatorCase(
          'toBoolStrict',
          () => toBoolStrict(isType<bool>(), message: 'bool strict msg'),
          'abc',
          'bool strict msg'),
      _ValidatorCase(
          'toBoolLenient',
          () => toBoolLenient(isType<bool>(), message: 'bool lenient msg'),
          'abc',
          'bool lenient msg'),
      _ValidatorCase(
          'toBool', () => toBool(isType<bool>(), message: 'bool msg'), 'abc', 'bool msg'),
      _ValidatorCase('toDateTime', () => toDateTime(isDateInFuture(), message: 'datetime msg'),
          'not-date', 'datetime msg'),
      _ValidatorCase(
          'toDateOnly',
          () => toDateOnly(isType<DateTime>(), message: 'dateonly msg'),
          'not-date',
          'dateonly msg'),
      _ValidatorCase('pickKeys',
          () => pickKeys(['a', 'b'], containsKey('a'), message: 'pick msg'), 5, 'pick msg'),
      _ValidatorCase('pluckKey', () => pluckKey('a', isInt(), message: 'pluck msg'), {'x': 1},
          'pluck msg'),
      _ValidatorCase('flattenMapKeys', () => flattenMapKeys('.', isMap(), message: 'flat msg'),
          1, 'flat msg'),
      _ValidatorCase('toJsonDecoded', () => toJsonDecoded(isMap(), message: 'json msg'),
          'not-json', 'json msg'),
      _ValidatorCase('defaultTo', () => defaultTo(5, isGte(10), message: 'default msg'), null,
          'default msg'),
    ];

    for (final c in txCases) {
      t.test(c.name, () {
        final validator = c.build();
        final result = validator.validate(c.failingValue);
        t.expect(result.isValid, t.isFalse,
            reason: 'Expected failure for transformer ${c.name}');
        final msg = result.firstExpectation.message;

        t.expect(msg, c.expectedMessage);
      });
    }
  });
}
