
![](https://github.com/nombrekeff/eskema/raw/main/.github/Eskema.png)


[![codecov](https://codecov.io/gh/nombrekeff/eskema/branch/main/graph/badge.svg?token=ZF22N0G09J)](https://codecov.io/gh/nombrekeff/eskema) [![build](https://github.com/nombrekeff/eskema/actions/workflows/test_main.yml/badge.svg?branch=main)](https://github.com/nombrekeff/eskema/actions/workflows/test_main.yml) ![Pub Version](https://img.shields.io/pub/v/eskema?style=flat-square)

# Eskema 

Eskema is a small, composable runtime validation library for Dart. It helps you validate dynamic values (JSON, Maps, Lists, primitives) with readable validators and clear error messages.


## Use cases

Here are some common usecases for Eskema:

- **Validate untyped API JSON** before mapping to models (catch missing/invalid fields early).
- **Guard inbound request payloads** (HTTP handlers, jobs) with clear, fail-fast errors.
- **Validate runtime config and feature flags** from files or remote sources.

----

## Install

```bash
dart pub add eskema
```

## Quick start

Validate a map using a schema-like validator and read a detailed result or a boolean.

### 1. Create a simple eskema <!-- omit in toc -->
```dart
import 'package:eskema/eskema.dart';

final userValidator = eskema({
	// use built-in validator funtions
    'username': isString(),

	// Some zero-arg validators also have aliases: e.g. `$isBool`, `$isString` - prefer for zero-arg validators
	'lastname': $isString,

    // Combine validators using `all`, `any` and `none`
    'age': all([isInt(), isGte(0)]),

    // or use operators for simplicity, same as using `all`, `any` and `none`, but shorter!!
    'theme': (isString() & (isEq('light') | isEq('dark'))),

    // Make validators nullable, if the field is missing it's considered invalid, use `optional` instead
	// This will be valid if 'premium' exists in the map and is null or returns the result of the child validator
    'premium': nullable($isBool),

	// If you want to allow the field to not exist in the map, and accept null or empty strings
	// You can use the `optional` validator
    'birthday': optional(isDate()),
});
```

### 2. Validate the eskema <!-- omit in toc -->

The simplest way to check if a validator is valid, is by using the `isValid` method:
```dart
final ok = userValidator.isValid({ 'username': 'bob', 'age': 42, 'theme': 'light', 'premium': false });
print("User is valid: $ok");  // true
```

You can use the `.validate` method to get a descriptive error message:
```dart
final res = userValidator.validate({
'username': 'alice',
'age': -1,
});
print(res); // false - "Expected age -> greater than or equal to 0, got -1"
```

You can also make the validation throw
```dart
try {
	userValidator.validateOrThrow({'username': 'bob'});
} catch (e) {
	print(e); // ValidatorFailedException with a helpful message
}
```

## Table of contents
- [Eskema](#eskema)
	- [Use cases](#use-cases)
	- [Install](#install)
	- [Quick start](#quick-start)
	- [Table of contents](#table-of-contents)
	- [API overview](#api-overview)
	- [Examples](#examples)
		- [Custom validators](#custom-validators)
			- [Zero-arg validator](#zero-arg-validator)
			- [Validator with args](#validator-with-args)
		- [Class-based validators](#class-based-validators)
		- [Nullable vs optional](#nullable-vs-optional)


## API overview

> Check the [docs]() for the technical documentation.

- Core
	- `IEskValidator` / `EskValidator` — object-based validators that return `EskResult`
	- `EskResult` — `.isValid`, `.isNotValid`, `.expected`, `.value`, nice `toString()`

- Common validators (examples)
	- Types: `isType<T>()` e.g. `isType<String>()`; shorthands: `isString()`, `isInt()`, `isDouble()`, `isBool()`
	- Nullability: `isNull()`; make any validator nullable with `nullable(v)` or `v.nullable()`
	- Numbers: `isGt(n)`, `isGte(n)`, `isLt(n)`, `isLte(n)`
	- Equality: `isEq(value)`, deep equality `isDeepEq(value)`
	- Strings: `stringIsOfLength(n)`, `stringContains(sub)`, `stringNotContains(sub)`, `stringMatchesPattern(pattern)`
	- Lists: `listIsOfLength(n)`, `listEach(itemValidator)`, `eskemaList([...])`
	- Maps: `eskema({ 'key': validator, ... })`

- Composition
	- `all([...])` — AND composition (stops on first failure)
	- `any([...])` — OR composition (passes if any succeed)
	- `not(v)` — invert a validator
	- 
	- `nullable(v)` or `v.nullable()` — allow `null`, if field is missing it's considered invalid
	- `optional(v)` or `v.optional()` — allow `null`, empty string, and missing fields

- Results & helpers
	- `.validate(value)` → `EskResult`
	- `.isValid(value)` / `.isNotValid(value)` → bool
	- `.validateOrThrow(value)` throws on invalid input

Tip: Some zero-arg validators also have canonical aliases (e.g. `$isString`, `$isBool`) for concise usage.

## Examples

### Custom validators 

#### Zero-arg validator 
```dart
final isHelloWorld = all([
  $isString,
  EskValidator((value) => EskResult(
    isValid: value == 'Hello world',
    expected: 'Hello world',
    value: value,
  )),
]);

print(isHelloWorld.isValid('Hello world'));  // true
print(isHelloWorld.validate('hey'));         // false - 'Expected Hello world, got "hey"'
```

#### Validator with args 
```dart
IEskValidator isInRange(num min, num max) {
  return all([
    isType<num>(),
    EskValidator((value) => EskResult(
      isValid: value >= min && value <= max,
      expected: 'number to be between $min and $max',
      value: value,
    )),
  ]);
}

print(isInRange(0, 5).isValid(2)); // true
print(isInRange(0, 5).validate(6)); // false - "Expected number to be between 0 and 5, got 6"
```

### Class-based validators 

Prefer a class for complex/structured validation? Use `EskMap` with `EskField`.

```dart
import 'package:eskema/eskema.dart';

enum Theme { light, dark }

class SettingsValidator extends EskMap {
	final theme = EskField(
	    id: 'theme', 
	    validators: [isOneOf(Theme.values)],
    );

	final notificationsEnabled = EskField(
		id: 'notificationsEnabled',
		nullable: true,
		validators: [isBool()],
	);

	SettingsValidator({required super.id, super.nullable});

	@override
	get fields => [theme, notificationsEnabled];
}

class UserValidator extends EskMap {
	final name = EskField(id: 'name', validators: [isString()]);
	final settings = SettingsValidator(id: 'settings', nullable: true);

	@override
	get fields => [name, settings];
}

final v = UserValidator();
final result = v.validate({ 'name': 'Test', 'settings': { 'theme': Theme.dark } });
print(result.isValid); // true
```



### Validate untyped API JSON <!-- omit in toc -->

```dart
import 'package:eskema/eskema.dart';

final apiUser = eskema({
	'id': isInt(),
	'email': stringMatchesPattern(
		RegExp(r'^[^@\\s]+@[^@\\s]+\\.[^@\\s]+$'),
		error: 'a valid email',
	),
	'name': isString(),
	'roles': listEach(isString()).nullable(),
});

final result = apiUser.validate(apiJson);
if (result.isNotValid) log('invalid user: $result');
```

### Validate runtime config and feature flags <!-- omit in toc -->

```dart
final config = eskema({
	'featureX': isBool(),
	'theme': isOneOf(['light', 'dark']),
	'retry': all([isInt(), isGte(0)]),
	'allowedHosts': listEach(isString()).nullable(),
});

final isConfigValid = config.isValid(configMap);
assert(isConfigValid, 'Invalid config: $cfgRes');
```

### Nullable vs optional

Short summary

- nullable (`v.nullable()` / `nullable(v)`): the key must be present in the map, but the value may be `null`.
- optional (`optional(v)` / `v.optional()`): the key may be omitted; if it's present the inner validator is run. `optional` does not automatically allow `null` — the inner validator controls that.

How this works under the hood

- When validating a map, `eskema` calls each field's `.validate(value, exists: value.containsKey(key))`. The `exists` flag tells the field whether the key was present.
- `nullable` returns valid only when the key exists and the value is `null`.
- `optional` returns valid when the key is missing (`exists == false`). If the key exists, the inner validator runs normally.

Examples

```dart
// 1) Required (default): key must exist and pass
final required = eskema({'name': isString()});
required.validate({}); // invalid: missing 'name'

// 2) Nullable: key must exist, value may be null
final nullableField = eskema({'bio': isString().nullable()});
nullableField.validate({'bio': null}); // valid
nullableField.validate({}); // invalid (missing 'bio')

// Single-field: validate knows about presence via `exists`
final field = isString().nullable();
field.validate(null, exists: true); // valid
field.validate(null, exists: false); // invalid (treated as missing)

// 3) Optional: key may be omitted; if present it must validate
final optionalField = eskema({'age': optional(isInt())});
optionalField.validate({}); // valid (age omitted)
optionalField.validate({'age': 30}); // valid
optionalField.validate({'age': null}); // invalid (optional does NOT imply nullable)

// Combine optional + nullable if you want both behaviors
final optNullable = eskema({'age': optional(isInt().nullable())});
optNullable.validate({}); // valid (omitted)
optNullable.validate({'age': null}); // valid (present + null allowed)
```

Notes

- Empty strings or other values are validated by the inner validator (e.g. `isString()` accepts `''`). `optional` does not change that behavior.

## More <!-- omit in toc -->

- See [`example/`](./example/) for runnable demos
- Check [`test/`](./test/) for behavior coverage
