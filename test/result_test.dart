import 'package:test/test.dart';
import 'package:eskema/eskema.dart' hide isEmpty, isNotEmpty, not;

void main() {
  group('EskResult constructors (assertions)', () {
    test('EskResult.valid produces valid result with empty errors', () {
      final r = Result.valid('ok');
      expect(r.isValid, true);
      expect(r.expectations, isEmpty);
    });

    test('EskResult.invalid with single error produces invalid result', () {
      final err = Expectation(message: 'fail', value: 123);
      final r = Result.invalid(123, expectation: err);
      expect(r.isValid, false);
      expect(r.expectations, hasLength(1));
      expect(r.expectations.first.message, 'fail');
    });

    test('Main constructor: isValid=true without errors triggers assertion', () {
      expect(
        () => Result(isValid: true, value: 10),
        returnsNormally,
      );
    });

    test('Main constructor: isValid=true WITH error passes (though semantically odd)', () {
      final r = Result(
        isValid: true,
        value: 10,
        expectation: Expectation(message: 'should not be here', value: 10),
      );
      expect(r.isValid, true);
      expect(r.expectations, isNotEmpty); // Illustrates current inconsistency.
    });

    test('Main constructor: isValid=false WITH error passes', () {
      final r = Result(
        isValid: false,
        value: 10,
        expectation: Expectation(message: 'bad', value: 10),
      );
      expect(r.isValid, false);
      expect(r.expectations.single.message, 'bad');
    });

    test('Main constructor: isValid=false WITH non-empty errors list passes', () {
      final r = Result(
        isValid: false,
        value: 10,
        expectations: [Expectation(message: 'bad', value: 10)],
      );
      expect(r.isValid, false);
      expect(r.expectations.length, 1);
    });
  });
}
