import 'package:eskema/validator.dart';
import 'package:eskema/validators.dart';
import 'package:test/test.dart';

class EskMapTest extends EskMap {
  final name = EskField(validators: [isType<String>()], id: 'name');

  EskMapTest({super.nullable});

  @override
  List<IEskValidator> get fields => [name];
}

void main() {
  group('EskField', () {
    test('basic works', () {
      final field = EskField(
        id: 'testField',
        validators: [isType<String>()],
      );
      final res1 = field.validate("");
      expect(res1.isValid, true);

      final res4 = field.validate(null);
      expect(res4.isValid, false);
    });

    test('nullable works', () {
      final field = EskField(
        id: 'testField',
        validators: [isType<String>()],
        nullable: true,
      );

      final res4 = field.validate(null);
      expect(res4.isValid, true);
    });

    test('non-nullable works', () {
      final field = EskField(
        id: 'testField',
        validators: [isType<String>()],
      ).copyWith(nullable: false);

      final res4 = field.validate(null);
      expect(res4.isValid, false);
    });
  });

  group('EskMap', () {
    test('basic works', () {
      final field = EskMapTest();
      final res1 = field.validate({});
      expect(res1.isValid, false);

      final res4 = field.validate({'name': 'bob'});
      expect(res4.isValid, true);
    });

    test('nullable works', () {
      final field = EskMapTest(nullable: true);
      final res1 = field.validate(null);
      expect(res1.isValid, true);
    });

    test('non-nullable works', () {
      final field = EskMapTest();
      final res1 = field.validate(null);
      expect(res1.isValid, false);
    });
  });
}
