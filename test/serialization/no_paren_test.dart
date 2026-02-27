import 'package:eskema/eskema.dart';
import 'package:test/test.dart' as test;

void main() {
  test.group('Omitting Parentheses Support', () {
    test.test('decodes single value args without parentheses', () {
      final inputs = {
        '>0': isGt(0),
        '<100': isLt(100),
        '=5': isEq(5),
        '>=10': isGte(10),
        '<=20': isLte(20),
        '~\'path\'': contains('path'),
      };

      for (final entry in inputs.entries) {
        final val = decode(entry.key);
        test.expect(val.name, entry.value.name);
        test.expect(val.args, entry.value.args);
      }
    });

    test.test('decodes combined validators without parentheses', () {
      final str = '>0 & <100 & int';
      final val = decode(str);
      // It should be all([isGt(0), isLt(100), isInt])
      test.expect(val.name, 'all');
      final args = val.args.cast<IValidator>();
      test.expect(args.length, 3);
      test.expect(args[0].name, 'isGt');
      test.expect(args[1].name, 'isLt');
      // int is a symbol for isType<int>()
      test.expect(args[2].name, test.anyOf('int', 'isType'));
      if (args[2].name == 'isType') {
        test.expect(args[2].args[0], 'int');
      }
    });

    test.test('encoders omit parentheses for single value comparison', () {
      final gte = isGte(10);
      final encoder = const EskemaEncoder();
      
      // Current behavior: >=(10)
      // Goal behavior: >=10
      test.expect(encoder.encode(gte), '>=10');

      final combined = all([isGt(0), isLt(100), isInt()]);
      test.expect(encoder.encode(combined), '(>0 & <100 & int)');
    });
  });
}
