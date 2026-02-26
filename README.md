![](https://github.com/nombrekeff/eskema/raw/main/.github/Eskema.png)

[![codecov](https://codecov.io/gh/nombrekeff/eskema/branch/main/graph/badge.svg?token=ZF22N0G09J)](https://codecov.io/gh/nombrekeff/eskema) [![build](https://github.com/nombrekeff/eskema/actions/workflows/test_main.yml/badge.svg?branch=main)](https://github.com/nombrekeff/eskema/actions/workflows/test_main.yml) [![Pub Version](https://img.shields.io/pub/v/eskema?style=flat-square)](https://pub.dev/packages/eskema)

# Eskema
Composable runtime validation for Dart. Build readable schemas from tiny validator functions & operators and get precise, structured errors (message, code, path, data) for untyped JSON, configs, and user input. Fast sync path, seamless async, no boilerplate.

## Why
* Validate untyped JSON & config fast
* Concise composition (`&`, `|`, `not()`, `nullable()`, `optional()`)
* Sync fast path, auto async when needed
* Rich `Expectation` objects: message, code, path, data
* Extensively tested

## Install
```bash
dart pub add eskema
```

## Showcasing the Power of Eskema

Eskema shines when dealing with complex, real-world data shapes—allowing you to replace messy `if`/`else` validation logic with readable, composable flows. Here is a short but comprehensive example combining **transformers**, **contextual logic**, and **polymorphic validation**:

```dart
import 'package:eskema/eskema.dart';

void main() {
  final userSchema = eskema({
    // Transformers clean and coerce data before validation
    'username': trim(toLowerCase(isString() & not($isStringEmpty, message: 'Username cannot be empty'))),
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
  
  print(badResult.isValid); 
  // > false
  
  print(badResult);  
  // > .username: not String to be empty, .age: greater than or equal to 18, .postal_code: length [equal to 5], .account: Map<dynamic, dynamic>
}
```

### 🌟 Key Features
* **Transformers**: Coerce and clean up data (`toInt`, `trim`, `defaultTo`, `toLowerCase`) on the fly.
* **Contextual Validation**: Use `when` to conditionally validate fields based on siblings' values.
* **Polymorphic Schemas**: Clean up `if`/`else` structures with `switchBy`, seamlessly routing validation based on a discriminator field.
* **Operators & Composition**: Intuitively chain operations (`&`, `|`, `not()`).
* **Modifiers**: Precise control over existence and nullability (`optional()`, `nullable()`, `required()`).
* **Detailed Errors**: Structured `Expectation` objects detailing exact failure paths, codes, and data.
* **Sync & Async**: Blazingly fast sync execution with seamless async support when needed.

## Docs & help
* [Docs & guides](https://nombrekeff.github.io/eskema/)
* [API reference](https://pub.dev/documentation/eskema/latest/)
* [Wiki](https://github.com/nombrekeff/eskema/wiki)
* [Example Directory](https://github.com/nombrekeff/eskema/tree/main/example) - Check out transformers, conditional validation, and more.
* Issues / questions: https://github.com/nombrekeff/eskema/issues

## Contributing
Open an issue for discussion, then PR with tests. Keep additions composable. (Detailed guidelines live in the wiki / future CONTRIBUTING doc.)

## License
MIT – see `LICENSE`.

---
Star the repo if it helps you. ⭐
