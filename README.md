
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
    'username': isString(),

    // Combine validators using `all` and `any`
    'age': all([isInt(), isGte(0)]),

    // or use operators for simplicity:
    'theme': (isString() & (isEq('light') | isEq('dark'))).nullable(),

    // Some zero-arg validators also have canonical aliases: e.g. `$isBool`, `$isString`
    'premium': nullable($isBool),

    // Make a validator nullable
    'email': stringMatchesPattern(
      RegExp(r"^[^@\s]+@[^@\s]+\.[^@\s]+$"),
      error: 'a valid email address',
    ).nullable(),
});
```

### 2. Validate the eskema <!-- omit in toc -->

The simplest way to check if a validator is valid, is by using the `isValid` method:
```dart
final ok = userValidator.isValid({ 'username': 'bob', 'age': 42 });
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
	- `nullable(v)` or `v.nullable()` — allow `null`

- Results & helpers
	- `.validate(value)` → `EskResult`
	- `.isValid(value)` / `.isNotValid(value)` → bool
	- `.validateOrThrow(value)` throws on invalid input

Tip: Some zero-arg validators also have canonical aliases (e.g. `$isString`, `$isBool`) for concise usage.

## Examples

### Custom validators <!-- omit in toc -->

#### Zero-arg validator <!-- omit in toc -->
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

#### Validator with args <!-- omit in toc -->
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

### Class-based validators <!-- omit in toc -->

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

## More <!-- omit in toc -->

- See [`example/`](./example/) for runnable demos
- Check [`test/`](./test/) for behavior coverage
