import 'package:eskema/eskema.dart';

/// Demonstrates encoding and decoding validators using the Eskema string format.
void main() {
  // ── Encoding ──────────────────────────────────────────────
  final encoder = const EskemaEncoder();

  // Simple validator
  final ageCheck = all([isInt(), isGte(18), isLte(120)]);
  final ageEncoded = encoder.encode(ageCheck);
  print('Age check: $ageEncoded');
  // Output: (int & >=(18) & <=(120))

  // String validator
  final emailCheck = all([isString(), isEmail()]);
  final emailEncoded = encoder.encode(emailCheck);
  print('Email check: $emailEncoded');
  // Output: (String & s_mail)

  // Map/schema validator
  final userSchema = eskema({
    'username': all([isString(), stringContains('_')]),
    'email': all([isString(), isEmail()]),
    'age': all([isInt(), isGte(18)]),
    'bio': isString().optional().nullable(),
  });

  final schemaEncoded = encoder.encode(userSchema);
  print('User schema: $schemaEncoded');
  // Output: {username: String & s~('_'), email: String & s_mail, age: int & >=(18), bio: *?String}

  // ── Decoding ──────────────────────────────────────────────
  final decoder = const EskemaDecoder();

  // Decode a simple validator
  final decodedAge = decoder.decode('int & >=(18) & <=(120)');
  print('\n--- Decoded age validator ---');
  print('25 valid: ${decodedAge.validate(25).isValid}'); // true
  print('10 valid: ${decodedAge.validate(10).isValid}'); // false

  // Decode a schema
  final decodedSchema = decoder.decode(
    '{username: String & s~(\'_\'), email: String & s_mail, age: int & >=(18)}',
  );

  print('\n--- Decoded schema validator ---');
  final validUser = {'username': 'john_doe', 'email': 'john@example.com', 'age': 25};
  final invalidUser = {'username': 'john', 'email': 'not-email', 'age': 12};

  print('Valid user: ${decodedSchema.validate(validUser).isValid}'); // true
  print('Invalid user: ${decodedSchema.validate(invalidUser).isValid}'); // false

  // ── Roundtrip ─────────────────────────────────────────────
  print('\n--- Roundtrip demo ---');
  final original = all([isGt(0), isLt(100)]);
  final encoded = encoder.encode(original);
  final decoded = decoder.decode(encoded);

  print('Encoded: $encoded'); // (>(0) & <(100))
  print('50 valid: ${decoded.validate(50).isValid}'); // true
  print(' 0 valid: ${decoded.validate(0).isValid}'); // false
}
