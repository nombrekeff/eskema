import 'package:eskema/eskema.dart';
import 'package:test/test.dart' as test;

void main() {
  test.group('EskemaEncoder', () {
    test.test('serializes primitive built-ins', () {
      test.expect(const EskemaEncoder().encode(isEq(5)), '=5');
      test.expect(const EskemaEncoder().encode(isGt(10)), '>10');
      test.expect(const EskemaEncoder().encode(isTrue()), 'T');
      test.expect(const EskemaEncoder().encode(isType<String>()), 'String');
    });

    test.test('serializes combinators', () {
      final val = all([isGt(0), isLt(10)]);
      test.expect(const EskemaEncoder().encode(val), '(>0 & <10)');

      final anyVal = any([isEq('A'), isEq('B')]);
      test.expect(const EskemaEncoder().encode(anyVal), '(=\'A\' | =\'B\')');
    });

    test.test('serializes maps and fields', () {
      final map = EskemaMapValidator();
      final str = const EskemaEncoder().encode(map);
      test.expect(str, '{age: >0, name: String & ~\'B\'}');
    });

    test.test('serializes optional/nullable fields', () {
      final map = EskemaOptionalMapValidator();
      final str = const EskemaEncoder().encode(map);
      test.expect(str, '{age: ?>0, name: *String}');
    });

    test.test('serializes custom validators', () {
      final custom = CustomValidator();
      test.expect(const EskemaEncoder().encode(custom), '@myCustom(1, 2)');
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
      : super((v) => Result.valid(v), name: 'myCustom', args: [1, 2]);
}
