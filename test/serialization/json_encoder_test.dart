import 'package:eskema/eskema.dart';
import 'package:test/test.dart' as test;

void main() {
  test.group('JsonEncoder', () {
    test.test('encodes no-arg built-ins as single-element lists', () {
      test.expect(const JsonEncoder().encode(isTrue()), test.equals('["T"]'));
      test.expect(const JsonEncoder().encode(isFalse()), test.equals('["F"]'));
    });

    test.test('encodes parameterized built-ins as lists', () {
      test.expect(const JsonEncoder().encode(isEq(5)), test.equals('["=",5]'));
      test.expect(
          const JsonEncoder().encode(isGt(10)), test.equals('[">",10]'));
      test.expect(const JsonEncoder().encode(isType<String>()),
          test.equals('"String"'));
    });

    test.test('encodes logical operators with infix style', () {
      final val = all([isTrue(), isGt(5), isLt(10)]);
      test.expect(
        const JsonEncoder().encode(val),
        test.equals('[["T"],"&",[">",5],"&",["<",10]]'),
      );

      final anyVal = any([isEq('A'), isEq('B')]);
      test.expect(
        const JsonEncoder().encode(anyVal),
        test.equals('[["=","\'A\'"],"|",["=","\'B\'"]]'),
      );
    });

    test.test('encodes map validators to JSON objects', () {
      final map = JsonMapValidator();
      final encoded = const JsonEncoder().encode(map);
      test.expect(
        encoded,
        test.equals('{"age":["int","&",[">",18]],"status":"String"}'),
      );
    });

    test.test('encodes field modifiers as prefix wrappers', () {
      final map = JsonOptionalMapValidator();
      final encoded = const JsonEncoder().encode(map);
      test.expect(
        encoded,
        test.equals(
            '{"name":["*","String"],"age":["?","int"],"complex":["?*",["int","&",[">",0]]]}'),
      );
    });

    test.test('encodes string literal arguments with single quotes', () {
      test.expect(
        const JsonEncoder().encode(isEq('int')),
        test.equals('["=","\'int\'"]'),
      );
    });

    test.test('encodes custom validators', () {
      final custom =
          Validator((v) => Result.valid(v), name: 'myCustom', args: [1, 'val']);
      test.expect(
        const JsonEncoder().encode(custom),
        test.equals('["@myCustom",1,"\'val\'"]'),
      );
    });
    test.test('encodes eskema validators with map arguments', () {
      final schema = eskema({
        'name': isString(),
        'age': all([isInt(), isGt(0)]),
      });
      final encoded = const JsonEncoder().encode(schema);

      // Should not throw, and should produce valid JSON
      test.expect(encoded, test.isNotEmpty);
      test.expect(encoded, test.contains('"name"'));
      test.expect(encoded, test.contains('"age"'));
    });

    test.test('encodes validators with RegExp arguments', () {
      final val = stringMatchesPattern(RegExp(r'^[a-z]+$'));
      final encoded = const JsonEncoder().encode(val);

      test.expect(encoded, test.isNotEmpty);
      test.expect(encoded, test.contains('s~/'));
    });
  });
}

class JsonMapValidator extends MapValidator {
  final Field age = Field(id: 'age', validators: [
    all([isInt(), isGt(18)])
  ]);
  final Field status = Field(id: 'status', validators: [isType<String>()]);

  JsonMapValidator() : super(id: '');

  @override
  List<IdValidator> get fields => [age, status];
}

class JsonOptionalMapValidator extends MapValidator {
  final Field nameField =
      Field(id: 'name', validators: [isString()], optional: true);
  final Field age = Field(id: 'age', validators: [isInt()], nullable: true);
  final Field complex = Field(
      id: 'complex',
      validators: [
        all([isInt(), isGt(0)])
      ],
      nullable: true,
      optional: true);

  JsonOptionalMapValidator() : super(id: '');

  @override
  List<IdValidator> get fields => [nameField, age, complex];
}
