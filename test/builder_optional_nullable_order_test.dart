import 'package:test/test.dart';
import 'package:eskema/eskema.dart';

/// Tests asserting desired (but currently broken) behaviour: optional()/nullable()
/// should apply to the ENTIRE builder result regardless of where in the fluent
/// chain they're invoked. These are RED tests today – implementation will be
/// updated to make them pass.
void main() {
  group('Builder optional/nullable position invariance', () {
    test('optional applied mid-chain still skips missing key', () {
      // Desired: placing optional() before later constraints keeps whole validator optional
      final fieldValidator = builder().string().optional().lengthMin(2).build();
      final sch = eskema({'name': fieldValidator});
      // Missing key should be valid (skip) once behaviour is fixed
      expect(sch.validate({}).isValid, isTrue, reason: 'optional() mid-chain should mark full chain optional');
    });

    test('nullable applied mid-chain still accepts null', () {
      final v = builder().string().nullable().lengthMin(2).build();
      final rNull = v.validate(null);
      expect(rNull.isValid, isTrue, reason: 'nullable() mid-chain should allow null');
      final rShort = v.validate('a');
      expect(rShort.isValid, isFalse, reason: 'subsequent constraints still enforced for non-null');
      final rOk = v.validate('ab');
      expect(rOk.isValid, isTrue);
    });

    test('optional + nullable mid-chain both honoured', () {
      final v = builder().string().nullable().optional().lengthMin(2).build();
      final sch = eskema({'nickname': v});
      // Missing key => skip (optional)
      expect(sch.validate({}).isValid, isTrue, reason: 'missing key should be skipped');
      // Null value (present) => valid (nullable)
      expect(sch.validate({'nickname': null}).isValid, isTrue, reason: 'null present should be valid');
      // Short string fails length
      expect(sch.validate({'nickname': 'a'}).isValid, isFalse);
      // Adequate string passes
      expect(sch.validate({'nickname': 'ab'}).isValid, isTrue);
    });

    test('ordering invariance: optional before vs after later constraints are equivalent', () {
      final midChainOptional = builder().string().optional().lengthMin(2).lengthMax(5).build();
      final tailOptional = builder().string().lengthMin(2).lengthMax(5).optional().build();

      final sch1 = eskema({'x': midChainOptional});
      final sch2 = eskema({'x': tailOptional});

      // Both should treat missing key the same
      expect(sch1.validate({}).isValid, isTrue, reason: 'mid-chain optional should skip');
      expect(sch2.validate({}).isValid, isTrue, reason: 'tail optional should skip');

      // Both apply constraints when key present
      expect(sch1.validate({'x': 'a'}).isValid, isFalse);
      expect(sch2.validate({'x': 'a'}).isValid, isFalse);
      expect(sch1.validate({'x': 'abc'}).isValid, isTrue);
      expect(sch2.validate({'x': 'abc'}).isValid, isTrue);
    });

    test('ordering invariance: nullable before vs after later constraints are equivalent', () {
      final midChainNullable = builder().string().nullable().lengthMin(2).lengthMax(5).build();
      final tailNullable = builder().string().lengthMin(2).lengthMax(5).nullable().build();

      expect(midChainNullable.validate(null).isValid, isTrue);
      expect(tailNullable.validate(null).isValid, isTrue);

      expect(midChainNullable.validate('a').isValid, isFalse);
      expect(tailNullable.validate('a').isValid, isFalse);

      expect(midChainNullable.validate('abc').isValid, isTrue);
      expect(tailNullable.validate('abc').isValid, isTrue);
    });

    test('idempotency: multiple optional/nullable calls don\'t break semantics', () {
      final v = builder().string().optional().nullable().lengthMin(2).optional().nullable().build();
      final sch = eskema({'field': v});
      expect(sch.validate({}).isValid, isTrue, reason: 'still optional');
      expect(sch.validate({'field': null}).isValid, isTrue, reason: 'still nullable');
      expect(sch.validate({'field': 'a'}).isValid, isFalse, reason: 'constraints still enforced');
      expect(sch.validate({'field': 'ab'}).isValid, isTrue);
    });
  });
}
