import 'package:eskema/eskema.dart';

/// Demonstrates encoding and decoding validators using the JSON format.
void main() {
  // ── Encoding ──────────────────────────────────────────────
  final encoder = const JsonEncoder();

  // Simple parameterized validator → JSON string
  final ageCheck = isGt(18);
  final ageJson = encoder.encode(ageCheck);
  print('Age check: $ageJson');
  // Output: [">",18]

  // Combined validators → infix-style JSON string
  final rangeCheck = all([isInt(), isGt(0), isLt(100)]);
  final rangeJson = encoder.encode(rangeCheck);
  print('Range check: $rangeJson');
  // Output: ["int","&",[">",0],"&",["<",100]]

  // Map/schema validator → JSON object string
  final userSchema = eskema({
    'username': all([isString(), stringContains('_')]),
    'email': all([isString(), isEmail()]),
    'age': all([isInt(), isGte(18), isLte(120)]),
    'bio': isString().optional().nullable(),
  });

  final schemaJson = encoder.encode(userSchema);
  print('User schema: $schemaJson');

  // ── Decoding ──────────────────────────────────────────────
  final decoder = const JsonDecoder();

  // Decode a simple validator from a JSON string
  final decodedAge = decoder.decode('[">", 18]');
  print('\n--- Decoded age validator ---');
  print('25 valid: ${decodedAge.validate(25).isValid}'); // true
  print('18 valid: ${decodedAge.validate(18).isValid}'); // false

  // Decode infix AND from JSON string
  final decodedRange = decoder.decode('[[">", 0], "&", ["<", 100]]');
  print('\n--- Decoded range validator ---');
  print('50 valid: ${decodedRange.validate(50).isValid}'); // true
  print(' 0 valid: ${decodedRange.validate(0).isValid}'); // false

  // Decode a schema from JSON string
  final decodedSchema = decoder.decode(
    '{"age": [["type", "int"], "&", [">", 0]], "name": [["type", "String"], "&", ["~", "\'B\'"]]}',
  );

  print('\n--- Decoded schema ---');
  print(
    "{'age': 10, 'name': 'Bob'} valid: ${decodedSchema.validate({
          'age': 10,
          'name': 'Bob',
        }).isValid}",
  ); // true
  print(
    "{'age': 0, 'name': 'Bob'}  valid: ${decodedSchema.validate({
          'age': 0,
          'name': 'Bob',
        }).isValid}",
  ); // false

  // Decode with nullable modifier
  final nullableSchema = decoder.decode('{"age": ["?", [">", 0]]}');

  print('\n--- Nullable field ---');
  print("{'age': 5}     valid: ${nullableSchema.validate({
        'age': 5
      }).isValid}"); // true
  print("{'age': null}  valid: ${nullableSchema.validate({
        'age': null
      }).isValid}"); // true
  print("{'age': 0}     valid: ${nullableSchema.validate({
        'age': 0
      }).isValid}"); // false

  // ── Roundtrip ─────────────────────────────────────────────
  print('\n--- Roundtrip demo ---');
  final original = all([isGt(0), isLt(100)]);
  final encoded = encoder.encode(original);
  print('JSON string: $encoded');

  final decoded = decoder.decode(encoded);
  print('50 valid: ${decoded.validate(50).isValid}'); // true
  print(' 0 valid: ${decoded.validate(0).isValid}'); // false

  // ── Error handling ────────────────────────────────────────
  print('\n--- Error handling ---');

  try {
    decoder.decode('12345');
  } on DecodeException catch (e) {
    print('Error type: ${e.type}');
    print('Error message: ${e.message}');
  }

  try {
    decoder.decode('[]');
  } on DecodeException catch (e) {
    print('Error type: ${e.type}');
    print('Error message: ${e.message}');
  }
}
