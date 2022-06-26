[![codecov](https://codecov.io/gh/nombrekeff/eskema/branch/main/graph/badge.svg?token=ZF22N0G09J)](https://codecov.io/gh/nombrekeff/eskema)[![build](https://github.com/nombrekeff/eskema/actions/workflows/test_main.yml/badge.svg?branch=main)](https://github.com/nombrekeff/eskema/actions/workflows/test_main.yml)

**Eskema** is a tool to help you validate dynamic data with a simple yet powerful API. 

It as initially intended to validate dynamic JSON returned from an API, passed in by a user or any other scenario where you might need to validate dynamic data. But it's not limited to JSON data, you can validate any type of dinamic data.

## Features
* Simple API
* Composable / Extensible
* Safe
* Fully tested

## Getting started
To use the package there's not much to do apart from installing the package or adding it to pubspec.yml. For a guide on how to do it, check [the install instructions](https://pub.dev/packages/eskema/install)

## Concepts
### Validator
Mostly everything in Eskema are [Validators], which are functions that take in a value and return a [IResult].

The following are all validators:
```dart
isType<String>();
listOfLength(2);
listEach(isType<String>());
all([isType<List>(), isListOfLength(2)]);
```

### IResult
This is a class that represents the result of a validation


## Usage
An example explains more than 100 words, so here are a couple of simple examples.
For more detailed examples check the [`/examples`](./example) folder.

### Single Value Field
> NOTE: that if you only want to validate a single value, you probably don't need **Eskema**.

Otherwise let's check how to validate a single value. You can use validators individually:
```dart
final isString = isType<String>();
const result1 = isString('valid string');
const result2 = isString(123);
```


Or you can combine validators: 

```dart
all([isType<String>(), isDate()]);     // all validators must be valid
or(isType<String>(), isType<int>());   // either validator must be valid
and(isType<String>(), isType<int>());  // both validator must be valid


// This validator checks that, the value is a list of strings, with length 2, and contains item "test"
listEach(
  all([
    isType<String>(),
    isOfLength(2),
    listContains('test'),
  ]),
);
```

## Validators

### isType<T>
This validator checks that a value is of a certain type
```dart
isType<String>();
isType<int>();
isType<double>();
isType<List>();
isType<Map>();
```

### isTypeOrNull<T>
This validator checks that a value is of a certain type or is null
```dart
isTypeOrNull<String>();
isTypeOrNull<int>();
```

### nullable
This validator allows to make validators allow null values
```dart
nullable(eskema({...}));
```
* The validator above, allows a map or null

### eskema
The most common use case will probably be validating JSON or dynamic maps. For this, you can use the `eskema` validator.

In this example we validate a Map with optional fields and with nested fields.
```dart
final validateMap = eskema({
  'name': isTypeString(),
  'address': nullable(
    eskema({
      'city': isTypeString(),
      'street': isTypeString(),
      'number': all([
        isTypeInt(),
        isMin(0),
      ]),
      'additional': nullable(
        eskema({
          'doorbel_number': Field([isTypeInt()])
        })
      ),
    })
  )
});

final invalidResult = validateMap.call({});
invalidResult.isValid;    // false
invalidResult.isNotValid; // true
invalidResult.expected;   // name -> String
invalidResult.message;    // Expected name -> String

final validResult = validateMap.call({ 'name': 'bobby' });
validResult.isValid;    // true
validResult.isNotValid; // false
validResult.expected;   // Valid
```

### listEach
The other common use case is validating dynamic Lists. For this, you can use the `listEach` class.

This example validates that the provided value is a List of length 2, and each item must be of type int:
```dart
final isValidList = all([
    listOfLength(2),
    listEach(isTypeInt()),
]);

isValidList.validate(null).isValid;      // true
isValidList.validate([]).isValid;        // true
isValidList.validate([1, 2]).isValid;    // true
isValidList.validate([1, "2"]).isValid;  // false
isValidList.validate([1, "2"]).expected; // [1] -> int
```



### Additional Validators
For a complete list of validators, check the docs

### Custom Validators
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

