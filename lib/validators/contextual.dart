import 'package:eskema/eskema.dart';

/// Creates a conditional validator. It's conditional based on some other field in the eskema.
///
/// The [condition] validator is run against the parent map.
/// - If the condition is met, [then] is used to validate the current field's value.
/// - If the condition is not met, [otherwise] is used.
///
/// **Usage Examples:**
/// ```dart
/// // Conditional validation based on user type
/// final userValidator = eskema({
///   'userType': $isString,
///   'permissions': when(
///     isEq('admin'),           // Condition: if userType is 'admin'
///     isList(),                // Then: permissions must be a list
///     isEq(null),              // Otherwise: permissions must be null
///   ),
/// });
///
/// // Age-based validation
/// final personValidator = eskema({
///   'age': $isInt,
///   'licenseNumber': when(
///     isGte(18),               // Condition: if age >= 18
///     stringLength([isEq(8)]), // Then: license must be 8 characters
///     isEq(null),              // Otherwise: license must be null
///   ),
/// });
///
/// // Complex conditional logic
/// final paymentValidator = eskema({
///   'method': $isString,
///   'cardNumber': when(
///     isEq('credit_card'),     // If payment method is credit card
///     stringMatchesPattern(r'^\d{16}$'), // Then: validate 16-digit card number
///     isEq(null),              // Otherwise: card number should be null
///   ),
/// });
/// ```
IValidator when(
  IValidator condition, {
  required IValidator then,
  required IValidator otherwise,
  String? message,
}) {
  final base = WhenValidator(condition: condition, then: then, otherwise: otherwise);

  // Wrap with a proxy that intercepts misuse (validate()) and parent usage (validateWithParent)
  return message == null ? base : WhenWithMessage(base, message);
}

/// Make a validator required when a condition is met.
///
/// **Usage Examples:**
/// ```dart
/// final schema = eskema({
///   'age': $isInt,
///   'licenseNumber': requiredWhen(
///     isGte(18),               // Condition: if age >= 18
///     stringLength([isEq(8)]), // Then: license must be 8 characters
///   ),
/// });
/// ```
IValidator requiredWhen(
  IValidator condition, {
  required IValidator validator,
  String? message,
}) {
  return when(
    condition, 
    then: required(validator), 
    otherwise: optional(validator), 
    message: message
  );
}

/// Creates a polymorphic (switch-case) validator that depends on the value of a key in the parent map.
///
/// **Usage Examples:**
/// ```dart
/// final schema = switchBy('type', {
///   'business': eskema({
///     'taxId': required(isString()) & stringLength([isGte(5)]),
///   }),
///   'person': eskema({
///     'name': required(isString() & stringLength([isGte(5)])),
///   }),
/// });
/// final result = schema.validate({'type': 'business', 'taxId': '123456789'});
/// print(result);
/// ```
IValidator switchBy(String key, Map<String, IValidator> by) {
  return $isMap &
      containsKeys([key], message: 'Missing key: "$key"') &
      Validator((value) {
        final type = value[key];
        final v = by[type];
        final r = v?.validate(value);

        if (r == null) {
          return Result.invalid(
            value,
            expectation: const Expectation(message: 'unknown type'),
          );
        }

        return r.isValid ? Result.valid(value) : r;
      });
}

/// Creates a provider validator that depends on the parent object.
///
/// **Usage Examples:**
/// ```dart
/// final $config = resolve((parent) {
///   switch (parent['role']) {
///     case 'admin': return $adminConfig;
///     case 'user':  return $userConfig;
///   }
/// });
/// ```
ResolveValidator resolve(IValidator? Function(Map parentObject) resolver) {
  return ResolveValidator(resolver: resolver);
}
