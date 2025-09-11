import 'package:eskema/eskema.dart';
import 'package:test/test.dart';

// Tests verifying builders (which now implement IValidator) can be composed directly
// without calling build() explicitly, alongside regular validators and combinators.
void main() {
  group('Builder composability as IValidator', () {
    test('builder used directly inside all()', () {
      final v = all([
        builder().string().lengthMin(2), // no .build()
        builder().string().lengthMax(5),
      ]);
      expect(v.validate('abc').isValid, true);
      expect(v.validate('a').isValid, false);
      expect(v.validate('toolongvalue').isValid, false);
    });

    test('builder & validator operator composition', () {
      final v = builder().string().lengthMin(2) & isEq('ok');
      expect(v.validate('ok').isValid, true);
      expect(v.validate('no').isValid, false);
    });

    test('validator & builder (reverse order)', () {
      final v = isString() & builder().string().lengthMin(3);
      expect(v.validate('hey').isValid, true);
      expect(v.validate('hi').isValid, false); // length
      expect(v.validate(123).isValid, false);  // type
    });

    test('any with mixed builder + plain validators', () async {
      final v = any([
        builder().string().lengthMin(4),
        isEq('yo'),
      ]);
      expect(v.validate('yo').isValid, true);   // second succeeds
      expect(v.validate('longer').isValid, true); // first succeeds
      expect(v.validate('no').isValid, false);
    });

    test('none with builder child collecting valid expectations (builder pass triggers none failure)', () {
      final v = none([
        $string().eq('block'), // will pass only on 'block'
        isEq('forbid'),
      ]);
      expect(v.validate('ok').isValid, true, reason: 'neither child passes => none succeeds');
      expect(v.validate('block').isValid, false, reason: 'first child passes => none fails');
    });

    test('builder optional mid-chain still optional when composed', () {
      final fieldBuilder = builder().string().optional().lengthMin(2);
      final esk = eskema({'name': fieldBuilder});
      expect(esk.validate({}).isValid, true); // skip
      expect(esk.validate({'name': 'a'}).isValid, false); // length
      expect(esk.validate({'name': 'ab'}).isValid, true);
    });

    test('builder nullable mid-chain still nullable when composed (desired future behaviour)', () {
      final fieldBuilder = builder().string().nullable().lengthMin(2);
      final esk = eskema({'name': fieldBuilder});
      
      final rNull = esk.validate({'name': null});
      // Current implementation may fail (pending fix). We assert desired outcome to drive implementation.
      expect(rNull.isValid, true, reason: 'null should be accepted once mid-chain nullable is fixed');
      expect(esk.validate({'name': 'a'}).isValid, false);
      expect(esk.validate({'name': 'ab'}).isValid, true);
    });

    test('async composition: builder & async validator', () async {
      final asyncFailing = Validator((v) async => Result.invalid(v, expectation: const Expectation(message: 'bad')));
      final v = builder().string().lengthMin(2) & asyncFailing;
      final r = await v.validateAsync('ok');
      expect(r.isValid, false);
      expect(r.description?.contains('bad'), true);
    });

    test('copyWith on builder retains chain and flags', () {
      final b = builder().string().lengthMin(2).optional();
      final copy = (b as IValidator).copyWith(nullable: true);
      final esk = eskema({'name': copy});
      expect(esk.validate({}).isValid, true); // optional
      expect(copy.validate(null).isValid, true); // now nullable
      expect(copy.validate('a').isValid, false); // length
      expect(copy.validate('ab').isValid, true);
    });
  });
}
