import 'package:eskema/eskema.dart';
import 'package:test/test.dart' hide contains, isTrue, isFalse;

void main() {
  group('Comprehensive Serialization Test', () {
    final registry = defaultRegistry;
    final eskemaEncoder = const EskemaEncoder();
    final eskemaDecoder = const EskemaDecoder();
    final jsonEncoder = const JsonEncoder();
    final jsonDecoder = const JsonDecoder();

    void testValidator(String desc, IValidator validator) {
      group(desc, () {
        test('Eskema serialization - $desc', () {
          final encoded = eskemaEncoder.encode(validator, registry: registry);
          final decoded = eskemaDecoder.decode(encoded, registry: registry);
          expect(decoded.name, validator.name, reason: 'Name mismatch');
          expect(decoded.args.length, validator.args.length, reason: 'Args length mismatch');
        });

        test('JSON serialization - $desc', () {
          final encoded = jsonEncoder.encode(validator, registry: registry);
          final decoded = jsonDecoder.decode(encoded, registry: registry);
          expect(decoded.name, validator.name, reason: 'Name mismatch in JSON');
          expect(decoded.args.length, validator.args.length, reason: 'Args length mismatch in JSON');
        });
      });
    }

    // Type
    testValidator('isType<int>', isType<int>());
    testValidator('isType<String>', isType<String>());

    // Comparison
    testValidator('isEq(10)', isEq(10));
    testValidator('isDeepEq({"a": 1})', isDeepEq({'a': 1}));
    testValidator('isTrue()', isTrue());
    testValidator('isFalse()', isFalse());
    testValidator('contains("foo")', contains('foo'));
    testValidator('isOneOf([1, 2, 3])', isOneOf([1, 2, 3]));

    // Number
    testValidator('isLt(10)', isLt(10));
    testValidator('isLte(10)', isLte(10));
    testValidator('isGt(5)', isGt(5));
    testValidator('isGte(5)', isGte(5));
    testValidator('isInRange(1, 10)', isInRange(1, 10));

    // String
    testValidator('stringLength([isGt(5)])', stringLength([isGt(5)]));
    testValidator('stringIsOfLength(10)', stringIsOfLength(10));
    testValidator('stringContains("test")', stringContains('test'));
    testValidator('stringMatchesPattern(RegExp("a"))', stringMatchesPattern(RegExp('a')));
    testValidator('isLowerCase()', isLowerCase());
    testValidator('isUpperCase()', isUpperCase());
    testValidator('isEmail()', isEmail());
    testValidator('isUrl()', isUrl());
    testValidator('isUuidV4()', isUuidV4());
    testValidator('isIntString()', isIntString());
    testValidator('isDoubleString()', isDoubleString());
    testValidator('isNumString()', isNumString());
    testValidator('isBoolString()', isBoolString());
    testValidator('isDate()', isDate());

    // Date
    final dt = DateTime(2025, 1, 1);
    testValidator('isDateBefore(dt)', isDateBefore(dt));
    testValidator('isDateAfter(dt)', isDateAfter(dt));
    testValidator('isDateBetween(dt, dt)', isDateBetween(dt, dt));
    testValidator('isDateSameDay(dt)', isDateSameDay(dt));
    testValidator('isDateInPast()', isDateInPast());
    testValidator('isDateInFuture()', isDateInFuture());

    // JSON
    testValidator('isJsonObject()', isJsonObject());
    testValidator('isJsonArray()', isJsonArray());
    testValidator('jsonHasKeys(["a", "b"])', jsonHasKeys(['a', 'b']));
    testValidator('jsonArrayLength(min: 1, max: 5)', jsonArrayLength(min: 1, max: 5));
    testValidator('jsonArrayEvery(isString())', jsonArrayEvery(isString()));

    // Combinators
    testValidator('all([isGt(0), isLt(100)])', all([isGt(0), isLt(100)]));
    testValidator('any([isEq("A"), isEq("B")])', any([isEq('A'), isEq('B')]));
    testValidator('none([isEmail()])', none([isEmail()]));
    testValidator('not(isEmail())', not(isEmail()));
    
    // Structure
    testValidator('eskema({"name": isString()})', eskema({'name': isString()}));
    testValidator('eskemaStrict({"name": isString()})', eskemaStrict({'name': isString()}));
    testValidator('eskemaList([isString(), isInt()])', eskemaList([isString(), isInt()]));
    testValidator('listEach(isString())', listEach(isString()));

    // Contextual
    testValidator('switchBy("type", {"A": isString()})', switchBy('type', {'A': isString()}));
  });
}
