import 'package:eskema/eskema.dart';
import 'package:test/test.dart' as test;

void main() {
  test.group('EskemaDecoder', () {
    test.test('deserializes primitive built-ins', () {
      final valStr = '=5';
      final val = const EskemaDecoder().decode(valStr);
      test.expect(const EskemaEncoder().encode(val), valStr);
      test.expect(val.validate(5).isValid, test.isTrue);
      test.expect(val.validate(4).isValid, test.isFalse);
      
      final gtStr = '>10';
      final gtVal = const EskemaDecoder().decode(gtStr);
      test.expect(const EskemaEncoder().encode(gtVal), gtStr);
      test.expect(gtVal.validate(11).isValid, test.isTrue);
      test.expect(gtVal.validate(10).isValid, test.isFalse);

      final tStr = 'T';
      final tVal = const EskemaDecoder().decode(tStr);
      test.expect(const EskemaEncoder().encode(tVal), tStr);
      test.expect(tVal.validate(true).isValid, test.isTrue);
      test.expect(tVal.validate(false).isValid, test.isFalse);

      final typeStr = 'String';
      final typeVal = const EskemaDecoder().decode(typeStr);
      test.expect(const EskemaEncoder().encode(typeVal), typeStr);
      test.expect(typeVal.validate('hello').isValid, test.isTrue);
      test.expect(typeVal.validate(123).isValid, test.isFalse);
    });

    test.test('deserializes combinators', () {
      final allStr = '(>0 & <10)';
      final val = const EskemaDecoder().decode(allStr);
      test.expect(const EskemaEncoder().encode(val), allStr);
      test.expect(val.validate(5).isValid, test.isTrue);
      test.expect(val.validate(0).isValid, test.isFalse);
      test.expect(val.validate(10).isValid, test.isFalse);

      final anyStr = '(=\'A\' | =\'B\')';
      final anyVal = const EskemaDecoder().decode(anyStr);
      test.expect(const EskemaEncoder().encode(anyVal), anyStr);
      test.expect(anyVal.validate('A').isValid, test.isTrue);
      test.expect(anyVal.validate('B').isValid, test.isTrue);
      test.expect(anyVal.validate('C').isValid, test.isFalse);
    });

    test.test('deserializes maps and fields', () {
      final str = '{age: >0, name: String & ~\'B\'}';
      final val = const EskemaDecoder().decode(str);
      test.expect(const EskemaEncoder().encode(val), str);
      test.expect(val.validate({'age': 10, 'name': 'Bob'}).isValid, test.isTrue);
      test.expect(val.validate({'age': 0, 'name': 'Bob'}).isValid, test.isFalse);
      test.expect(val.validate({'age': 10, 'name': 'Alice'}).isValid, test.isFalse);
      test.expect(val.validate({'age': 10, 'name': 123}).isValid, test.isFalse);
    });

    test.test('deserializes optional/nullable fields', () {
      final str = '{age: ?>0, name: *String}';
      final val = const EskemaDecoder().decode(str);
      test.expect(const EskemaEncoder().encode(val), str);
      // Optional/nullable logic testing
      test.expect(val.validate({'age': 10}).isValid, test.isTrue); // name optional
      test.expect(val.validate({'age': null, 'name': 'Bob'}).isValid, test.isTrue); // age nullable
      test.expect(val.validate({'age': 0}).isValid, test.isFalse); // age still > 0 if present + not null
    });

    test.test('deserializes custom validators', () {
      final customStr = '@myCustom(1, 2)';
      final val = const EskemaDecoder().decode(customStr, customFactories: {
        'myCustom': (args) => CustomValidator(args),
      });
      test.expect(const EskemaEncoder().encode(val), customStr);
      test.expect(val.validate('anything').isValid, test.isTrue); // custom dummy always valid
    });

    test.test('global decode helper deserializes implicitly', () {
      final valStr = '>(5)';
      final val = decode(valStr);
      test.expect(val.validate(10).isValid, test.isTrue);
      test.expect(val.validate(5).isValid, test.isFalse);
    });

    test.test('throws EskemaParseException on malformed eskema strings', () {
      final badStrings = {
        '': DecodeExceptionType.unexpectedEndOfInput,
        '>(5': DecodeExceptionType.missingClosingParenthesis,
        '(>(5)': DecodeExceptionType.missingClosingParenthesis, // missing combinator or parenthesis
        '{name String}': DecodeExceptionType.missingColon, // missing colon
        '{name: String': DecodeExceptionType.missingClosingBrace, // missing closing brace
        '{: String}': DecodeExceptionType.missingIdentifier, // missing identifier
        '@unknown(1)': DecodeExceptionType.unknownCustomValidator, // unknown custom validator
        '>("unclosed string)': DecodeExceptionType.unclosedString, // unclosed string
      };
      
      for (final entry in badStrings.entries) {
        final badStr = entry.key;
        final expectedType = entry.value;

        test.expect(
          () => const EskemaDecoder().decode(badStr),
          test.throwsA(
            test.predicate((dynamic e) {
              if (e is! DecodeException) return false;

              return e.type == expectedType;
            }),
          ),
          reason: 'Should throw accurate DecodeException with type \$expectedType for "\$badStr"',
        );
      }
    });


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
        final val = const EskemaDecoder().decode(entry.key);
        test.expect(val.name, entry.value.name);
        test.expect(val.args, entry.value.args);
      }
    });

    test.test('decodes combined validators without parentheses', () {
      final str = '>0 & <100 & int';
      final val = const EskemaDecoder().decode(str);
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
      
      test.expect(encoder.encode(gte), '>=10');

      final combined = all([isGt(0), isLt(100), isInt()]);
      test.expect(encoder.encode(combined), '(>0 & <100 & int)');
    });
  });
}

class CustomValidator extends Validator {
  CustomValidator(List<dynamic> args)
      : super((v) => Result.valid(v), name: 'myCustom', args: args);
}
