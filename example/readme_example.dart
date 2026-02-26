import 'package:eskema/eskema.dart';

void main() {
  final userSchema = eskema({
    // Transformers clean and coerce data before validation
    'username': trim(toLowerCase(isString() & not($isStringEmpty))),
    'age': toInt(isGte(18, message: 'Age must be greater than or equal to 18')),
    
    // Default values
    'theme': defaultTo('light', isOneOf(['light', 'dark'])),

    // Contextual validation cleans up if/else logic easily
    'postal_code': when(
       getField('country', isEq('USA')),
       then: isString() & stringLength([isEq(5)]),
       otherwise: isString(),
    ),

    // switchBy enables clean polymorphic validation based on a field's value
    'account': switchBy('type', {
      'business': eskema({
        'taxId': required(isString() & stringLength([isGte(9)])),
      }),
      'personal': eskema({
        'ssn': required(isString()),
      }),
    }),
  });

  // Validating a complex untyped payload
  final result = userSchema.validate({
    'username': '  Alice  ',      // Trims and lowercases to 'alice'
    'age': '24',                 // Coerced to int 24
    'country': 'USA',
    'postal_code': '12345',
    'account': {
      'type': 'business',
      'taxId': '123456789'
    }
  });

  print(result.isValid); // true (All transformations and conditional logic passed!)
  
  // Example of a failing case highlighting expectations
  final badResult = userSchema.validate({
    'username': '   ',
    'age': '17',
    'country': 'USA',
    'postal_code': '1234'
  });
  
  print(badResult.isValid); // false
  
  print(badResult);  
  // .username: not String to be empty, .age: greater than or equal to 18, .postal_code: length [equal to 5], .account: Map<dynamic, dynamic>
}
