import 'package:eskema/eskema.dart';
import 'package:eskema/expectation.dart';
import 'package:test/test.dart';

void main() {
  group('Operators', () {
    test('& adds validators to single all validator', () {
      final r = (isType<String>() & isType<int>());
      expect(r.validators.length, 2);

      final r2 = r & isType<double>();
      expect(r2.validators.length, 3);
    });

    group('& operator combines children correctly', () {
      test('combines two simple validators into AllValidator', () {
        final validator1 = isType<String>();
        final validator2 = isGte(5); // Simple validator, not composite
        final combined = validator1 & validator2;

        expect(combined, isA<AllValidator>());
        expect(combined.validators.length, 2);
        expect(combined.validators.elementAt(0), equals(validator1));
        expect(combined.validators.elementAt(1), equals(validator2));
      });

      test('combines AllValidator with simple validator', () {
        final validator1 = isType<String>();
        final validator2 = isGte(5);
        final validator3 = isLte(100);
        
        final firstCombined = validator1 & validator2;
        final finalCombined = firstCombined & validator3;

        expect(finalCombined, isA<AllValidator>());
        expect(finalCombined.validators.length, 3);
        expect(finalCombined.validators.elementAt(0), equals(validator1));
        expect(finalCombined.validators.elementAt(1), equals(validator2));
        expect(finalCombined.validators.elementAt(2), equals(validator3));
      });

      test('combines simple validator with AllValidator', () {
        final validator1 = isType<String>();
        final validator2 = isGte(5);
        final validator3 = isLte(100);
        
        final allValidator = validator2 & validator3;
        final finalCombined = validator1 & allValidator;

        expect(finalCombined, isA<AllValidator>());
        expect(finalCombined.validators.length, 3);
        expect(finalCombined.validators.elementAt(0), equals(validator2));
        expect(finalCombined.validators.elementAt(1), equals(validator3));
        expect(finalCombined.validators.elementAt(2), equals(validator1));
      });

      test('combines two AllValidators', () {
        final validator1 = isType<String>();
        final validator2 = isDate();
        final validator3 = isEq(100);
        final validator4 = isEq(50);

        print("---------------");
        final allValidator1 = validator1 & validator2;
        final allValidator2 = validator3 & validator4;
        final finalCombined = allValidator1 & allValidator2;

        expect(finalCombined, isA<AllValidator>());
        expect(finalCombined.validators.length, 4);
        expect(finalCombined.validators.elementAt(0), equals(validator1));
        expect(finalCombined.validators.elementAt(1), equals(validator2));
        expect(finalCombined.validators.elementAt(2), equals(validator3));
        expect(finalCombined.validators.elementAt(3), equals(validator4));
      });

      test('combined validator validates correctly - success case', () {
        final combined = isType<int>() & isGte(5) & isLte(100);
        
        final result = combined.validate(50);
        expect(result.isValid, true);
        expect(result.value, equals(50));
      });

      test('combined validator validates correctly - failure cases', () {
        final combined = isType<int>() & isGte(5) & isLte(100);
        
        // Wrong type
        final result1 = combined.validate('hello');
        expect(result1.isValid, false);
        expect(result1.expectationCount, 1); // Should short-circuit on first failure
        
        // Right type, too small
        final result2 = combined.validate(3);
        expect(result2.isValid, false);
        expect(result2.expectationCount, 1); // Should short-circuit on second validator
        
        // Right type, too large
        final result3 = combined.validate(150);
        expect(result3.isValid, false);
        expect(result3.expectationCount, 1); // Should fail on third validator
      });

      test('combined validator with collecting mode', () {
        final combined = isType<String>() & isGte(10) & isLte(5); // Impossible: gte 10 and lte 5
        // Convert to collecting mode
        final collecting = AllValidator(combined.validators, collecting: true);
        
        final result = collecting.validate('hello'); // String, length 5
        expect(result.isValid, false);
        // Should collect failures from both numeric validators since string 'hello' can't be >= 10
        expect(result.expectationCount, greaterThan(0));
      });

      test('preserves validator properties during combination', () {
        final validator1 = isType<String>();
        final validator2 = isGte(5);
        final combined = validator1 & validator2;

        expect(combined, isA<AllValidator>());
        expect(combined.validators.length, 2);
        expect(combined.validators.elementAt(0), equals(validator1));
        expect(combined.validators.elementAt(1), equals(validator2));
      });

      test('chaining multiple & operations', () {
        final validator = isType<int>() 
            & isGte(0) 
            & isLte(100) 
            & isEq(50);

        expect(validator, isA<AllValidator>());
        expect(validator.validators.length, 4);
        
        final result = validator.validate(50);
        expect(result.isValid, true);
        
        final failResult = validator.validate(75);
        expect(failResult.isValid, false);
      });

      test('mixed operator usage with | and &', () {
        final validator = (isType<String>() & stringIsOfLength(5)) 
            | (isType<int>() & isGte(100));

        // Should accept valid string
        final result1 = validator.validate('Hello');
        expect(result1.isValid, true);
        
        // Should accept valid int
        final result2 = validator.validate(150);
        expect(result2.isValid, true);
        
        // Should reject invalid cases
        final result3 = validator.validate('Hi'); // String too short
        expect(result3.isValid, false);
        
        final result4 = validator.validate(50); // Int too small
        expect(result4.isValid, false);
        
        final result5 = validator.validate(true); // Wrong type entirely
        expect(result5.isValid, false);
      });

      test('& operator with complex validation logic', () async {
        final complexValidator = validator((v) => v.toString().length > 5 && v.toString().contains('test'), (v) => Expectation(message: 'must be long and contain test', value: v));

        final combined = isType<String>() & complexValidator;
        
        expect(combined, isA<AllValidator>());
        expect(combined.validators.length, 2);
        
        final result1 = combined.validate('hello test world');
        expect(result1.isValid, true);
        
        final result2 = combined.validate('test');
        expect(result2.isValid, false); // Too short
        
        final result3 = combined.validate('hello world');
        expect(result3.isValid, false); // Doesn't contain 'test'
        
        final result4 = combined.validate(123);
        expect(result4.isValid, false); // Wrong type
      });

      test('& operator maintains correct order of validators', () {
        final v1 = validator((v) => v == 'first', (v) => Expectation(message: 'first', value: v));
        final v2 = validator((v) => v == 'second', (v) => Expectation(message: 'second', value: v));
        final v3 = validator((v) => v == 'third', (v) => Expectation(message: 'third', value: v));
        
        final combined = v1 & v2 & v3;
        
        expect(combined.validators.length, 3);
        
        // Test that validators are called in order by checking short-circuit behavior
        final result = combined.validate('test');
        expect(result.isValid, false);
        expect(result.firstExpectation.message, 'first'); // Should fail on first validator
      });
    });
  });
}