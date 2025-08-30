import 'package:test/test.dart';
import 'package:eskema/eskema.dart';

void main() {
  group('pivot chaining order', () {
    test('string -> int -> double (latest wins)', () {
      final validator = v().string().toIntStrict().toDouble().build();
      final r = validator.validate('42');
      expect(r.isValid, true);
      expect(r.value, 42.0);
    });

    test('int -> double -> int (latest wins)', () {
      final validator = v().int_().toDouble().toIntStrict().build();
      final r = validator.validate(5);
      expect(r.isValid, true);
      expect(r.value, 5); // back to int
    });
  });
}
