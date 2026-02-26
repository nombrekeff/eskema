import 'package:eskema/eskema.dart';
import 'package:eskema/serialization/default_registry.dart';
import 'package:eskema/serialization/registry.dart';
import 'package:eskema/serialization/serializer.dart';
import 'package:eskema/serialization/deserializer.dart';

void main() {
  // 1. Define a brand new custom validator
  final myPalindromeValidator = Validator((value) {
    if (value is! String) return Result.invalid(value, expectation: const Expectation(message: 'must be string'));
    final reversed = value.split('').reversed.join('');
    if (value != reversed) return Result.invalid(value, expectation: const Expectation(message: 'must be a palindrome'));
    return Result.valid(value);
  }).copyWith(name: 'isPalindrome', arguments: []);

  // 2. We can create a custom registry seamlessly merging the default!
  final customRegistry = ValidatorRegistry()
    ..merge(defaultRegistry)
    ..register(
      name: 'isPalindrome', 
      symbol: 'palin', 
      factory: (args) => myPalindromeValidator,
    );

  // 3. Serializing our strange custom logic works!
  final serialized = EskemaSerializer.serialize(myPalindromeValidator, registry: customRegistry);
  print('Serialized: $serialized'); // Outputs: palin

  // 4. Deserializing brings it right back as our proper logic!
  final deserialized = EskemaDeserializer.deserialize(serialized, registry: customRegistry);
  
  print('Validating "racecar" -> ${deserialized.validate("racecar").isValid}'); // Outputs true
  print('Validating "hello" -> ${deserialized.validate("hello").isValid}');   // Outputs false

  print('Custom functionality successfully tested! Registry injected flawlessly.');
}
