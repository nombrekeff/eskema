import 'package:test/test.dart';
import 'package:eskema/eskema.dart';

// Simulate async validator on plucked value
IValidator asyncGte(int min) => Validator((value) async {
  await Future<void>.delayed(const Duration(milliseconds: 1));
  if (value is num && value >= min) return Result.valid(value);
  return Result.invalid(value, expectation: Expectation(message: '>= $min', value: value));
});

void main() {
  group('pluckValue async + missing key', () {
    final validator = v().map().pluckValue('count').toIntStrict().build();

    test('missing key async path invalid', () async {
      final r = await validator.validateAsync({'other': 1});
      expect(r.isValid, false);
    });

    test('present key async success', () async {
      final v2 = v().map().pluckValue('count').toIntStrict().gte(2).build();
      final ok = await v2.validateAsync({'count': '3'});
      expect(ok.isValid, true);
      final bad = await v2.validateAsync({'count': '1'});
      expect(bad.isValid, false);
    });
  });
}
