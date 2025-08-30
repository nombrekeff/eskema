import 'package:test/test.dart';
import 'package:eskema/eskema.dart';

void main() {
  group('toBoolStrict builder', () {
    final strictTrue = v().string().toBoolStrict().eq(true).build();
    final strictFalse = v().string().toBoolStrict().eq(false).build();

    test('accepts true/false strings', () {
      expect(strictTrue.validate('true').isValid, true);
      expect(strictFalse.validate('false').isValid, true);
    });

    test('rejects yes/no', () {
      expect(strictTrue.validate('yes').isValid, false);
      expect(strictFalse.validate('no').isValid, false);
    });

    test('rejects 1/0', () {
      expect(strictTrue.validate('1').isValid, false);
      expect(strictFalse.validate('0').isValid, false);
    });

    test('passes existing bool values', () {
      expect(strictTrue.validate(true).isValid, true);
      expect(strictFalse.validate(false).isValid, true);
    });
  });

  group('toBoolLenient builder', () {
    final lenientTrue = v().string().toBoolLenient().eq(true).build();
    final lenientFalse = v().string().toBoolLenient().eq(false).build();

    test('accepts true/false', () {
      expect(lenientTrue.validate('true').isValid, true);
      expect(lenientFalse.validate('false').isValid, true);
    });

    test('accepts yes/no variants', () {
      expect(lenientTrue.validate('yes').isValid, true);
      expect(lenientTrue.validate('Y').isValid, true);
      expect(lenientFalse.validate('no').isValid, true);
      expect(lenientFalse.validate('N').isValid, true);
    });

    test('accepts on/off', () {
      expect(lenientTrue.validate('on').isValid, true);
      expect(lenientFalse.validate('off').isValid, true);
    });

    test('accepts 1/0', () {
      expect(lenientTrue.validate('1').isValid, true);
      expect(lenientFalse.validate('0').isValid, true);
    });

    test('rejects unknown', () {
      expect(lenientTrue.validate('maybe').isValid, false);
    });
  });

  group('transformer functions direct', () {
    final strictFn = toBoolStrict(isEq(true));
    final lenientFn = toBoolLenient(isEq(true));

    test('function strict rejects yes', () {
      expect(strictFn.validate('yes').isValid, false);
      expect(strictFn.validate('true').isValid, true);
    });

    test('function lenient accepts yes', () {
      expect(lenientFn.validate('yes').isValid, true);
      expect(lenientFn.validate('on').isValid, true);
      expect(lenientFn.validate('off').isValid, false); // expecting true only
    });
  });
}
