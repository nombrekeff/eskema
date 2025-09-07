import 'package:eskema/eskema.dart';
import 'package:test/test.dart';

void main() {
  group('expanded cached validators', () {
    test(r'$isNotNull validates non-null and rejects null', () {
      expect($isNotNull.isValid(1), isTrue);
      expect($isNotNull.isNotValid(null), isTrue);
    });

    test(r'$isNonEmptyString basics', () {
      expect($isNonEmptyString.isValid('abc'), isTrue);
      expect($isNonEmptyString.isNotValid(''), isTrue);
      expect($isNonEmptyString.isNotValid(42), isTrue);
    });

    test(r'$optionalNonEmptyString allows null', () {
      expect($optionalNonEmptyString.isValid(null), isTrue);
      expect($optionalNonEmptyString.isNotValid(''), isTrue);
    });

    test(r'$isNonEmptyList basics', () {
      expect($isNonEmptyList.isValid([1]), isTrue);
      expect($isNonEmptyList.isNotValid([]), isTrue);
      expect($isNonEmptyList.isNotValid('nope'), isTrue);
    });

    test(r'$optionalNonEmptyList allows null', () {
      expect($optionalNonEmptyList.isValid(null), isTrue);
      expect($optionalNonEmptyList.isNotValid([]), isTrue);
    });
  });
}
