import 'package:eskema/eskema.dart';
import 'package:eskema/serialization/serializer.dart';
import 'package:eskema/serialization/deserializer.dart';
import 'package:test/test.dart' as test;

void main() {
  test.group('EskemaDeserializer', () {
    test.test('deserializes primitive built-ins', () {
      final valStr = '=(5)';
      final val = EskemaDeserializer.deserialize(valStr);
      test.expect(EskemaSerializer.serialize(val), valStr);
      test.expect(val.validate(5).isValid, test.isTrue);
      test.expect(val.validate(4).isValid, test.isFalse);
      
      final gtStr = '>(10)';
      final gtVal = EskemaDeserializer.deserialize(gtStr);
      test.expect(EskemaSerializer.serialize(gtVal), gtStr);
      test.expect(gtVal.validate(11).isValid, test.isTrue);
      test.expect(gtVal.validate(10).isValid, test.isFalse);

      final tStr = 'T';
      final tVal = EskemaDeserializer.deserialize(tStr);
      test.expect(EskemaSerializer.serialize(tVal), tStr);
      test.expect(tVal.validate(true).isValid, test.isTrue);
      test.expect(tVal.validate(false).isValid, test.isFalse);

      final typeStr = 'type(String)';
      final typeVal = EskemaDeserializer.deserialize(typeStr);
      test.expect(EskemaSerializer.serialize(typeVal), typeStr);
      test.expect(typeVal.validate('hello').isValid, test.isTrue);
      test.expect(typeVal.validate(123).isValid, test.isFalse);
    });

    test.test('deserializes combinators', () {
      final allStr = '(>(0) & <(10))';
      final val = EskemaDeserializer.deserialize(allStr);
      test.expect(EskemaSerializer.serialize(val), allStr);
      test.expect(val.validate(5).isValid, test.isTrue);
      test.expect(val.validate(0).isValid, test.isFalse);
      test.expect(val.validate(10).isValid, test.isFalse);

      final anyStr = '(=(\'A\') | =(\'B\'))';
      final anyVal = EskemaDeserializer.deserialize(anyStr);
      test.expect(EskemaSerializer.serialize(anyVal), anyStr);
      test.expect(anyVal.validate('A').isValid, test.isTrue);
      test.expect(anyVal.validate('B').isValid, test.isTrue);
      test.expect(anyVal.validate('C').isValid, test.isFalse);
    });

    test.test('deserializes maps and fields', () {
      final str = '{age: >(0), name: type(String) & ~(\'B\')}';
      final val = EskemaDeserializer.deserialize(str);
      test.expect(EskemaSerializer.serialize(val), str);
      test.expect(val.validate({'age': 10, 'name': 'Bob'}).isValid, test.isTrue);
      test.expect(val.validate({'age': 0, 'name': 'Bob'}).isValid, test.isFalse);
      test.expect(val.validate({'age': 10, 'name': 'Alice'}).isValid, test.isFalse);
      test.expect(val.validate({'age': 10, 'name': 123}).isValid, test.isFalse);
    });

    test.test('deserializes optional/nullable fields', () {
      final str = '{age: ?>(0), name: *type(String)}';
      final val = EskemaDeserializer.deserialize(str);
      test.expect(EskemaSerializer.serialize(val), str);
      // Optional/nullable logic testing
      test.expect(val.validate({'age': 10}).isValid, test.isTrue); // name optional
      test.expect(val.validate({'age': null, 'name': 'Bob'}).isValid, test.isTrue); // age nullable
      test.expect(val.validate({'age': 0}).isValid, test.isFalse); // age still > 0 if present + not null
    });

    test.test('deserializes custom validators', () {
      final customStr = '@myCustom(1, 2)';
      final val = EskemaDeserializer.deserialize(customStr, customFactories: {
        'myCustom': (args) => CustomValidator(args),
      });
      test.expect(EskemaSerializer.serialize(val), customStr);
      test.expect(val.validate('anything').isValid, test.isTrue); // custom dummy always valid
    });
  });
}

class CustomValidator extends Validator {
  CustomValidator(List<dynamic> args)
      : super((v) => Result.valid(v), name: 'myCustom', arguments: args);
}
