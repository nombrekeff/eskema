import 'package:eskema/validator.dart';

/// If the field is not present (null) it will be considered valid
/// If you want to allow empty strings as valid, use [optional] instead
///
/// **Example**
/// ```dart
/// final isValid = nullable(isString()).validate(null);  // true
/// final isValid = nullable(isString()).validate('');    // true
/// final isValid = nullable(isString()).validate(false); // false
///
/// // It works a bit differently on maps:
///
/// final validListField = eskema({
///    'nullable': nullable(isString()),
/// });
///
/// validListField.isValid({'nullable': 'test'}); // true
/// validListField.isValid({'nullable': ''});     // true
/// validListField.isValid({'nullable': null});   // true
///
/// // If the field does not exists on the map, it's considered invalid.
/// // You can use the `optional` validator to allow missing fields.
/// validListField.isValid({});                   // false
/// ```
IValidator nullable(IValidator validator) => validator.nullable();

/// If the field is not present, it will be considered valid, if present, it executes the [validator].
/// It's different from nullable in that it also checks for empty strings
///
/// **Example**
/// ```dart
/// final isValid = optional(isString()).isValid('');    // true
/// final isValid = optional(isString()).isValid(false); // false
/// final isValid = optional(isString()).isValid(null);  // false
///
/// final validListField = eskema({
///   'optional': optional(isString()),
/// });
///
/// validListField.isValid({'optional': 'test'});  // true
/// validListField.isValid({'optional': ''});      // true
/// validListField.isValid({'optional ': null});   // false
/// // If the field is missing from a map, it's considered valid.
/// validListField.isValid({});                    // true
/// ```
IValidator optional(IValidator validator) => validator.optional();
