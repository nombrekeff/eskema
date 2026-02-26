import 'package:eskema/eskema.dart';
import 'package:eskema/serialization/serializer.dart';
import 'package:test/test.dart' as test;

void main() {
  test.group('EskemaSerializer', () {
    test.test('serializes primitive built-ins', () {
      test.expect(EskemaSerializer.serialize(isEq(5)), '=(5)');
      test.expect(EskemaSerializer.serialize(isGt(10)), '>(10)');
      test.expect(EskemaSerializer.serialize(isTrue()), 'T');
      test.expect(EskemaSerializer.serialize(isType<String>()), 'type(String)');
    });

    test.test('serializes combinators', () {
      final val = all([isGt(0), isLt(10)]);
      test.expect(EskemaSerializer.serialize(val), '(>(0) & <(10))');

      final anyVal = any([isEq('A'), isEq('B')]);
      test.expect(EskemaSerializer.serialize(anyVal), '(=(\'A\') | =(\'B\'))');
    });

    test.test('serializes maps and fields', () {
      final map = EskemaMapValidator();
      final str = EskemaSerializer.serialize(map);
      test.expect(str, '{age: >(0), name: type(String) & ~(\'B\')}');
    });

    test.test('serializes optional/nullable fields', () {
      final map = EskemaOptionalMapValidator();
      final str = EskemaSerializer.serialize(map);
      test.expect(str, '{age: ?>(0), name: *type(String)}');
    });

    test.test('serializes custom validators', () {
      final custom = CustomValidator();
      test.expect(EskemaSerializer.serialize(custom), '@myCustom(1, 2)');
    });
  });
}

class EskemaMapValidator extends MapValidator {
  final Field age = Field(id: 'age', validators: [isGt(0)]);
  final Field nameField = Field(id: 'name', validators: [$isString, contains('B')]);

  EskemaMapValidator() : super(id: '');

  @override
  List<IdValidator> get fields => [age, nameField];
}

class EskemaOptionalMapValidator extends MapValidator {
  final Field age = Field(id: 'age', validators: [isGt(0)], nullable: true);
  final Field nameField =
      Field(id: 'name', validators: [$isString], optional: true);

  EskemaOptionalMapValidator() : super(id: '');

  @override
  List<IdValidator> get fields => [age, nameField];
}

class CustomValidator extends Validator {
  CustomValidator()
      : super((v) => Result.valid(v), name: 'myCustom', arguments: [1, 2]);
}
