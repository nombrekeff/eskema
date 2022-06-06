[![codecov](https://codecov.io/gh/nombrekeff/eskema/branch/main/graph/badge.svg?token=ZF22N0G09J)](https://codecov.io/gh/nombrekeff/eskema)[![build](https://github.com/nombrekeff/eskema/actions/workflows/test_main.yml/badge.svg?branch=main)](https://github.com/nombrekeff/eskema/actions/workflows/test_main.yml)

**Eskema** is a tool to help you validate dynamic data with a simple yet powerful API. 

It's initially intended to validate dynamic JSON returned from an API, passed in by a user or any other scenario where you might need to validate dynamic data. But it's not limited to JSON data, you can validate anything you want to.

## Features
* Simple API
* Composable
* Extensible
* Safe
* Handle nullable fields 
* Fully tested
* No dependencies

## Getting started
To use the package there's not much to do apart from installing the package or adding it to pubspec.yml. For a guide on how to do it, check [the install instructions](https://pub.dev/packages/eskema/install)

### Concepts
Before starting I want to explain a couple of concepts and terms used in the package.

**Typedefs**
* `Validator` -> A function that takes in a dynamic value and returns an `IResult`

**Interfaces**
* `IResult` -> Interface representing the result of a validation, tells us if the validation was valid and contains an optional `expected` message
* `IValidatable` -> Interface that represents an object that can be used to validate a `Field`

**Classes**
* `Result` -> Implementation of `IResult`, package uses this class for the pre-made validators (_but you can implement you own if needed_)
* `Field` -> Implementation of `IValidatable` for a single value
* `MapField` -> Implementation of `IValidatable` for a Map value
* `ListField` -> Implementation of `IValidatable` for a List value

## Usage
An example explains more than words, here are a couple of simple examples.
For more detailed examples check the [`/examples`]() folder. <!--TODO: ADD examples LINK-->

### Single Value Field
> If you only want to validate a single value, you probably don't need **Eskema**.

To validate a single value, you can use the `Field` class. Fields accept a list of Validators, these validators will be run against the value and they must all be valid for the Field to be considered valid.

This field validates that the value is a String and that it is a valid DateTime formatted string. 
```dart
final field = Field([ isTypeString(), isDate() ]);

expect(field.validate('1969-07-20 20:18:04Z').isValid, true);
expect(field.validate('sadasd').expected, 'a valid date');
```

### MapField
The most common use case will probably be validating JSON or dynamic maps. For this, you can use the `MapField` class.

In this example we validate a Map with optional fields and with nested fields.
```dart
final field = MapField({
  'name': Field([isTypeString()]),
  'address': MapField.nullable({
    'city': Field([isTypeString()]),
    'street': Field([isTypeString()]),
    'number': Field([
      isTypeInt(),
      isMin(0),
    ]),
    'additional': MapField.nullable({
      'doorbel_number': Field([isTypeInt()])
    }),
  })
});

final invalidResult = field.validate({});
invalidResult.isValid;    // false
invalidResult.isNotValid; // true
invalidResult.expected;   // name -> String
invalidResult.message;    // Expected name -> String

final validResult = field.validate({ 'name': 'bobby' });
validResult.isValid;    // true
validResult.isNotValid; // false
validResult.expected;   // Valid
```

### ListField
The other common use case is validating dynamic Lists. For this, you can use the `FieldField` class.

This example validates that the provided value is a List of size 2, and each item must be of type int:
```dart
 final listField = ListField(
  // Validation run for each field in the list
  fieldValidator: Field([isTypeInt()]),
  
  // Validation run for the list itself
  validators: [listIsOfSize(2)],

  // Mark the field as nullable, you can also use the named constructor `ListField.nullable()`
  nullable: true,
);

listField.validate(null).isValid;      // true
listField.validate([]).isValid;        // true
listField.validate([1, 2]).isValid;    // true
listField.validate([1, "2"]).isValid;  // false
listField.validate([1, "2"]).expected; // [1] -> int
```

### Validators
Fields accept a list of [Validators], these validators are in charge of validating a value against a condition. 
For example, checking if a value is of a certain type if they are formatted in some way or any other condition you might think of.

**Eskema** offers a set of common Validators located in `lib/src/validators.dart`. You are not limited to only using these validators, custom ones can be created very easily. 

Let's see how to create a validator to check if a string matches a pattern:

```dart
Validator validateRegexp(RegExp regexp) {
  return (value) {
    return Result(
      isValid: regexp.hasMatch(value),  
      expected: 'match pattern $regexp', // the message explaining what this validator expected
    );
  };
}
```

> If you want a validator you built to be part of the package, please send in a PR and I will consider adding it!!

### More examples
For more examples check out the [`/examples`]() folder. Or check out the [docs]()

## Package Name
**Eskema** is the Vasque word for "Schema". I did not know what to call the package, and after looking for a bit I found the Vasque word for schema and decided to use it!

## Additional information

* For more information check the [docs]() out. 
* If you find a bug please file an [issue]() or send a PR my way.
* Contributions are welcomed, feel free to send in fixes, new features, custom validators, etc...

