import 'dart:async';
import 'package:eskema/eskema.dart';
import 'package:test/test.dart';

IValidator asyncPassBool(bool pass) => Validator((v) async {
      await Future.delayed(const Duration(milliseconds: 5));
      return pass
          ? Result.valid(v)
          : Result.invalid(v, expectations: [Expectation(message: 'fail', value: v)]);
    });

void main() {
  group('when async', () {
    final schema = eskema({
      'country': isOneOf(['USA', 'Canada']),
      'postal': when(
        asyncPassBool(true),
        then: stringIsOfLength(5) > Expectation(message: 'len5'),
        otherwise: stringIsOfLength(6) > Expectation(message: 'len6'),
      ),
    });

    test('then branch async condition', () async {
      final r = await schema.validateAsync({'country': 'USA', 'postal': '12345'});
      expect(r.isValid, true);
    });

    test('then branch async condition fail length', () async {
      final r = await schema.validateAsync({'country': 'USA', 'postal': '1234'});
      expect(r.isValid, false);
      expect(r.description.contains('len5'), true);
    });
  });
}
