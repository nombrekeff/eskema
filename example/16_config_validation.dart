import 'package:eskema/eskema.dart';

///
/// Real-world Example: Configuration Validation
///
/// This example validates a server configuration map, which might be loaded
/// from a YAML or JSON file.
///
/// It demonstrates:
/// - Nested configuration objects.
/// - Validating port ranges.
/// - Conditional validation (SSL certs required only if SSL is enabled).
///
void main() {
  print('--- Configuration Validation Example ---');

  // 1. Define Schema
  final configSchema = eskema({
    // Server Host: Required, string, not empty
    'host': required(isString() & not($isStringEmpty)),

    // Server Port: Required, int, valid range (1-65535)
    'port': required(
      isInt() & isGte(1) & isLte(65535),
      message: 'Port must be between 1 and 65535',
    ),

    // Environment: One of 'dev', 'staging', 'prod'. Default to 'dev'.
    'env': defaultTo('dev', isOneOf(['dev', 'staging', 'prod'])),

    // SSL Configuration:
    // If 'ssl_enabled' is true, then 'ssl_cert' and 'ssl_key' are required.
    'ssl_enabled': defaultTo(false, isBool()),

    'ssl_cert': requiredWhen(
      getField('ssl_enabled', isEq(true)),
      validator: isString() & not($isStringEmpty),
      message: 'SSL Cert required when SSL is enabled',
    ),
    'ssl_key': requiredWhen(
      getField('ssl_enabled', isEq(true)),
      validator: isString() & not($isStringEmpty),
      message: 'SSL Key required when SSL is enabled',
    ),
  });

  // 2. Define Data
  final devConfig = {
    'host': 'localhost',
    'port': 8080,
    // env defaults to dev
    // ssl_enabled defaults to false
  };

  final prodConfigInvalid = {
    'host': 'api.example.com',
    'port': 443,
    'env': 'prod',
    'ssl_enabled': true,
    // Missing cert and key!
  };

  // 3. Validate
  print('\n--- Dev Config (Defaults) ---');
  final devRes = configSchema.validate(devConfig);
  print('Valid: ${devRes.isValid}');
  print('Resolved Config: ${devRes.value}'); // Shows defaults applied

  print('\n--- Prod Config (Invalid) ---');
  final prodRes = configSchema.validate(prodConfigInvalid);
  print('Valid: ${prodRes.isValid}');
  print('Errors:');
  for (final e in prodRes.expectations) {
    print('  - ${e.path}: ${e.message}');
  }

  print('-' * 20);
}
