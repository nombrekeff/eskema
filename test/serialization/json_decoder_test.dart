import 'package:eskema/eskema.dart';
import 'package:eskema/serialization/core/decode_exception.dart';
import 'package:eskema/serialization/serializers/json/json_encoder.dart';
import 'package:eskema/serialization/serializers/json/json_decoder.dart';
import 'package:test/test.dart' as test;

void main() {
  test.group('JsonDecoder', () {
    test.test('decodes no-arg built-ins from single-element lists', () {
      final val = const JsonDecoder().decode(['T']);
      test.expect(val.validate(true).isValid, test.isTrue);
      test.expect(val.validate(false).isValid, test.isFalse);

      final val2 = const JsonDecoder().decode(['F']);
      test.expect(val2.validate(false).isValid, test.isTrue);
      test.expect(val2.validate(true).isValid, test.isFalse);
    });

    test.test('decodes parameterized validators from lists', () {
      final val = const JsonDecoder().decode(['>', 10]);
      test.expect(val.validate(11).isValid, test.isTrue);
      test.expect(val.validate(10).isValid, test.isFalse);

      final eqVal = const JsonDecoder().decode(['=', "'hello'"]);
      test.expect(eqVal.validate('hello').isValid, test.isTrue);
      test.expect(eqVal.validate('world').isValid, test.isFalse);
    });

    test.test('decodes infix & operator with nested lists', () {
      final val = const JsonDecoder().decode([['>', 0], '&', ['<', 10]]);
      test.expect(val.validate(5).isValid, test.isTrue);
      test.expect(val.validate(0).isValid, test.isFalse);
      test.expect(val.validate(10).isValid, test.isFalse);
    });

    test.test('decodes infix | operator', () {
      final val = const JsonDecoder().decode([['=', "'A'"], '|', ['=', "'B'"]]);
      test.expect(val.validate('A').isValid, test.isTrue);
      test.expect(val.validate('B').isValid, test.isTrue);
      test.expect(val.validate('C').isValid, test.isFalse);
    });

    test.test('decodes map validators', () {
      final val = const JsonDecoder().decode({
        'age': ['>', 0],
        'name': [['type', 'String'], '&', ['~', "'B'"]],
      });
      test.expect(val.validate({'age': 10, 'name': 'Bob'}).isValid, test.isTrue);
      test.expect(val.validate({'age': 0, 'name': 'Bob'}).isValid, test.isFalse);
      test.expect(val.validate({'age': 10, 'name': 'Alice'}).isValid, test.isFalse);
    });

    test.test('decodes map with modifier wrappers', () {
      final val = const JsonDecoder().decode({
        'age': ['?', ['>', 0]],
      });
      test.expect(val.validate({'age': 5}).isValid, test.isTrue);
      test.expect(val.validate({'age': null}).isValid, test.isTrue);
      test.expect(val.validate({'age': 0}).isValid, test.isFalse);
    });

    test.test('decodes custom validators', () {
      final val = const JsonDecoder().decode(['@myCustom', 1, 2], customFactories: {
        'myCustom': (args) => CustomValidator(args),
      });
      test.expect(val.validate('anything').isValid, test.isTrue);
    });

    test.test('roundtrip encode then decode', () {
      final original = all([isGt(0), isLt(100)]);
      final encoded = const JsonEncoder().encode(original);
      final decoded = const JsonDecoder().decode(encoded);

      test.expect(decoded.validate(50).isValid, test.isTrue);
      test.expect(decoded.validate(0).isValid, test.isFalse);
      test.expect(decoded.validate(100).isValid, test.isFalse);
    });

    test.test('roundtrip map with modifiers', () {
      final map = RoundtripMap();
      final encoded = const JsonEncoder().encode(map);
      final decoded = const JsonDecoder().decode(encoded);

      test.expect(decoded.validate({'age': 5}).isValid, test.isTrue);
      test.expect(decoded.validate({'age': null}).isValid, test.isTrue);
      test.expect(decoded.validate({'age': 0}).isValid, test.isFalse);
    });

    test.test('throws DecodeException on invalid input', () {
      test.expect(
        () => const JsonDecoder().decode(12345),
        test.throwsA(test.isA<DecodeException>()),
      );

      test.expect(
        () => const JsonDecoder().decode([]),
        test.throwsA(test.isA<DecodeException>()),
      );
    });
  });
}

class CustomValidator extends Validator {
  CustomValidator(List<dynamic> args)
      : super((v) => Result.valid(v), name: 'myCustom', arguments: args);
}

class RoundtripMap extends MapValidator {
  final Field age = Field(id: 'age', validators: [isGt(0)], nullable: true);

  RoundtripMap() : super(id: '');

  @override
  List<IdValidator> get fields => [age];
}
