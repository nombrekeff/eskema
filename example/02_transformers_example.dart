import 'package:eskema/eskema.dart';

///
/// This example showcases the power of transformers.
///
/// Transformers are special validators that can change or coerce the input
/// value before passing it on to a child validator. This is extremely useful
/// for handling data from sources like JSON, where numbers might be encoded
/// as strings.
///
void main() {
  // --- `toInt` Transformer ---
  // The `toInt` transformer attempts to convert a value (like a String or double)
  // into an integer before validating it.
  print('--- `toInt` Transformer ---');
  final intValidator = toInt(isGte(18));

  // This string will be parsed into the integer 25, which passes `isGte(18)`.
  print('Validating "25": ${intValidator.validate('25')}'); // Valid

  // This string will be parsed into the integer 10, which fails `isGte(18)`.
  print('Validating "10": ${intValidator.validate('10')}'); // Invalid

  // This string cannot be parsed as an integer, so it fails the initial check.
  print('Validating "abc": ${intValidator.validate('abc')}'); // Invalid
  print('-' * 20);

  // --- `trim` and `toLowerCase` Transformers ---
  // Transformers can be chained to clean up data.
  print('--- `trim` and `toLowerCase` Transformers ---');
  final usernameValidator = trim(toLowerCase(isEq('admin')));

  // The input is first trimmed to "  ADMIN", then converted to "admin",
  // which passes the `isEq('admin')` check.
  final result = usernameValidator.validate('  ADMIN  ');
  print('Validating "  ADMIN  ": $result'); // Valid
  print('-' * 20);

  // --- `defaultTo` Transformer ---
  // The `defaultTo` transformer provides a fallback value if the input is null.
  print('--- `defaultTo` Transformer ---');
  final settingsValidator = eskema({
    // If 'theme' is missing or null, it will default to 'light' before validation.
    'theme': defaultTo('light', isOneOf(['light', 'dark'])),
  });

  // The 'theme' key is missing, so `defaultTo` provides 'light'.
  print("Validating {}: ${settingsValidator.validate({})}"); // Valid

  // The 'theme' key is present, so its value is used.
  print(
      "Validating {'theme': 'dark'}: ${settingsValidator.validate({'theme': 'dark'})}"); // Valid

  // The provided theme is invalid.
  print(
      "Validating {'theme': 'blue'}: ${settingsValidator.validate({'theme': 'blue'})}"); // Invalid
  print('-' * 20);
}
