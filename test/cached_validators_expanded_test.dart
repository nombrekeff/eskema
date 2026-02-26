import 'package:eskema/eskema.dart' as eskema;
import 'package:test/test.dart';

void main() {
  group('expanded cached validators', () {
    test(r'$isNotNull validates non-null and rejects null', () {
      expect(eskema.$isNotNull.isValid(1), isTrue);
      expect(eskema.$isNotNull.isNotValid(null), isTrue);
    });

    test(r'$isNonEmptyString basics', () {
      expect(eskema.$isNonEmptyString.isValid('abc'), isTrue);
      expect(eskema.$isNonEmptyString.isNotValid(''), isTrue);
      expect(eskema.$isNonEmptyString.isNotValid(42), isTrue);
    });

    test(r'$optionalNonEmptyString allows null', () {
      expect(eskema.$optionalNonEmptyString.isValid(null), isTrue);
      expect(eskema.$optionalNonEmptyString.isNotValid(''), isTrue);
    });

    test(r'$isNonEmptyList basics', () {
      expect(eskema.$isNonEmptyList.isValid([1]), isTrue);
      expect(eskema.$isNonEmptyList.isNotValid([]), isTrue);
      expect(eskema.$isNonEmptyList.isNotValid('nope'), isTrue);
    });

    test(r'$optionalNonEmptyList allows null', () {
      expect(eskema.$optionalNonEmptyList.isValid(null), isTrue);
      expect(eskema.$optionalNonEmptyList.isNotValid([]), isTrue);
    });
  });
}
