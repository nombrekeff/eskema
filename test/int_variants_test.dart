import 'package:test/test.dart';
import 'package:eskema/eskema.dart';

void main() {
  group('toIntStrict builder', () {
    final strict = v().string().toIntStrict().gte(10).lt(20).build();

    test('accepts pure int string', () {
      expect(strict.validate('12').isValid, true);
    });

    test('rejects decimal string', () {
      expect(strict.validate('12.0').isValid, false);
    });

    test('rejects double value', () {
      expect(strict.validate(12.0).isValid, false);
    });

    test('accepts int', () {
      expect(strict.validate(15).isValid, true);
    });
  });

  group('toIntSafe builder', () {
    final safe = v().string().toIntSafe().build();

    test('accepts within safe range', () {
      expect(safe.validate('9007199254740991').isValid, true);
      expect(safe.validate('-9007199254740991').isValid, true);
    });

    test('rejects outside safe range', () {
      expect(safe.validate('9007199254740992').isValid, false);
      expect(safe.validate('-9007199254740992').isValid, false);
    });

    test('rejects decimal string', () {
      expect(safe.validate('1.0').isValid, false);
    });
  });

  group('transformer functions direct', () {
    final strictFn = toIntStrict(isEq(42));
    final safeFn = toIntSafe(isEq(10));

    test('strict function works', () {
      expect(strictFn.validate('42').isValid, true);
      expect(strictFn.validate('42.0').isValid, false);
    });

    test('safe function range guard', () {
      expect(safeFn.validate('10').isValid, true);
      expect(safeFn.validate('9007199254740992').isValid, false);
    });
  });
}
