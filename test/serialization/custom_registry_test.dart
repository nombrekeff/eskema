import 'package:eskema/eskema.dart';
import 'package:eskema/serialization/default_registry.dart';
import 'package:eskema/serialization/core/registry.dart';
import 'package:eskema/serialization/serializers/eskema/eskema_encoder.dart';
import 'package:eskema/serialization/serializers/eskema/eskema_decoder.dart';
import 'package:test/test.dart';

void main() {
  // 1. Define a brand new custom validator
  final myPalindromeValidator = Validator((value) {
    if (value is! String) return Result.invalid(value, expectation: const Expectation(message: 'must be string'));
    final reversed = value.split('').reversed.join('');

    if (value != reversed) return Result.invalid(value, expectation: const Expectation(message: 'must be a palindrome'));

    return Result.valid(value);
  }).copyWith(name: 'isPalindrome', args: []);

  // 2. We can create a custom registry seamlessly merging the default!
  final customRegistry = ValidatorRegistry()
    ..merge(defaultRegistry)
    ..register(
      name: 'isPalindrome', 
      factory: (args) => myPalindromeValidator,
    );

  // 3. Serializing our strange custom logic works!
  final serialized = const EskemaEncoder(customSymbols: {'isPalindrome': 'palin'}).encode(myPalindromeValidator, registry: customRegistry);
  test('Custom functionality successfully tested! Registry injected flawlessly.', () {
    expect(serialized, 'palin');
  });

  // 4. Deserializing brings it right back as our proper logic!
  final deserialized = const EskemaDecoder(customSymbols: {'palin': 'isPalindrome'}).decode(serialized, registry: customRegistry);
  test('Custom functionality successfully tested! Registry injected flawlessly.', () {
    expect(deserialized, myPalindromeValidator);
    expect(deserialized.validate('racecar').isValid, true);
    expect(deserialized.validate('hello').isValid, false);
  });
}
