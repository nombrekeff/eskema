import 'package:eskema/eskema.dart';
import 'package:eskema/serialization/eskema_encoder.dart';
import 'package:eskema/serialization/eskema_decoder.dart';
import 'package:test/test.dart' as test;

void main() {
  test.group('EskemaDecoder', () {
    test.test('deserializes primitive built-ins', () {
      final valStr = '=(5)';
      final val = const EskemaDecoder().decode(valStr);
      test.expect(const EskemaEncoder().encode(val), valStr);
      test.expect(val.validate(5).isValid, test.isTrue);
      test.expect(val.validate(4).isValid, test.isFalse);
      
      final gtStr = '>(10)';
      final gtVal = const EskemaDecoder().decode(gtStr);
      test.expect(const EskemaEncoder().encode(gtVal), gtStr);
      test.expect(gtVal.validate(11).isValid, test.isTrue);
      test.expect(gtVal.validate(10).isValid, test.isFalse);

      final tStr = 'T';
      final tVal = const EskemaDecoder().decode(tStr);
      test.expect(const EskemaEncoder().encode(tVal), tStr);
      test.expect(tVal.validate(true).isValid, test.isTrue);
      test.expect(tVal.validate(false).isValid, test.isFalse);

      final typeStr = 'type(String)';
      final typeVal = const EskemaDecoder().decode(typeStr);
      test.expect(const EskemaEncoder().encode(typeVal), typeStr);
      test.expect(typeVal.validate('hello').isValid, test.isTrue);
      test.expect(typeVal.validate(123).isValid, test.isFalse);
    });

    test.test('deserializes combinators', () {
      final allStr = '(>(0) & <(10))';
      final val = const EskemaDecoder().decode(allStr);
      test.expect(const EskemaEncoder().encode(val), allStr);
      test.expect(val.validate(5).isValid, test.isTrue);
      test.expect(val.validate(0).isValid, test.isFalse);
      test.expect(val.validate(10).isValid, test.isFalse);

      final anyStr = '(=(\'A\') | =(\'B\'))';
      final anyVal = const EskemaDecoder().decode(anyStr);
      test.expect(const EskemaEncoder().encode(anyVal), anyStr);
      test.expect(anyVal.validate('A').isValid, test.isTrue);
      test.expect(anyVal.validate('B').isValid, test.isTrue);
      test.expect(anyVal.validate('C').isValid, test.isFalse);
    });

    test.test('deserializes maps and fields', () {
      final str = '{age: >(0), name: type(String) & ~(\'B\')}';
      final val = const EskemaDecoder().decode(str);
      test.expect(const EskemaEncoder().encode(val), str);
      test.expect(val.validate({'age': 10, 'name': 'Bob'}).isValid, test.isTrue);
      test.expect(val.validate({'age': 0, 'name': 'Bob'}).isValid, test.isFalse);
      test.expect(val.validate({'age': 10, 'name': 'Alice'}).isValid, test.isFalse);
      test.expect(val.validate({'age': 10, 'name': 123}).isValid, test.isFalse);
    });

    test.test('deserializes optional/nullable fields', () {
      final str = '{age: ?>(0), name: *type(String)}';
      final val = const EskemaDecoder().decode(str);
      test.expect(const EskemaEncoder().encode(val), str);
      // Optional/nullable logic testing
      test.expect(val.validate({'age': 10}).isValid, test.isTrue); // name optional
      test.expect(val.validate({'age': null, 'name': 'Bob'}).isValid, test.isTrue); // age nullable
      test.expect(val.validate({'age': 0}).isValid, test.isFalse); // age still > 0 if present + not null
    });

    test.test('deserializes custom validators', () {
      final customStr = '@myCustom(1, 2)';
      final val = const EskemaDecoder().decode(customStr, customFactories: {
        'myCustom': (args) => CustomValidator(args),
      });
      test.expect(const EskemaEncoder().encode(val), customStr);
      test.expect(val.validate('anything').isValid, test.isTrue); // custom dummy always valid
    });
  });
}

class CustomValidator extends Validator {
  CustomValidator(List<dynamic> args)
      : super((v) => Result.valid(v), name: 'myCustom', arguments: args);
}
