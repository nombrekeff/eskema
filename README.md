![](https://github.com/nombrekeff/eskema/raw/main/.github/Eskema.png)

[![codecov](https://codecov.io/gh/nombrekeff/eskema/branch/main/graph/badge.svg?token=ZF22N0G09J)](https://codecov.io/gh/nombrekeff/eskema) [![build](https://github.com/nombrekeff/eskema/actions/workflows/test_main.yml/badge.svg?branch=main)](https://github.com/nombrekeff/eskema/actions/workflows/test_main.yml) [![Pub Version](https://img.shields.io/pub/v/eskema?style=flat-square)](https://pub.dev/packages/eskema)

# Eskema

Eskema is a small, composable runtime validation library for Dart. It helps you validate dynamic values (JSON, Maps, Lists, primitives) with readable validators and clear error messages.

## Use cases

Here are some common usecases for Eskema:

-   **Validate untyped API JSON** before mapping to models (catch missing/invalid fields early).
-   **Guard inbound request payloads** (HTTP handlers, jobs) with clear, fail-fast errors.
-   **Validate runtime config and feature flags** from files or remote sources.

---

## Install

```bash
dart pub add eskema
```

## Quick start

Validate a map using a schema-like validator and get back a detailed result.

### 1. Create a validator

```dart
import 'package:eskema/eskema.dart';

final userValidator = eskema({
  // Use built-in validator functions
  'username': isString() & isNotEmpty(),

  // Some zero-arg validators also have cached aliases (e.g. $isBool, $isString)
  'lastname': $isString,

  // Combine validators using operators for simplicity and readability
  'age': isInt() & isGte(0),
  'theme': isString() & isIn(['light', 'dark']),

  // The key must exist, but the value may be null.
  'bio': nullable(isString()),

  // The key may be missing entirely. If present, it must be a valid DateTime string.
  'birthday': optional(isDateTimeString()),
});
```

### 2. Validate your data

Use the `.validate()` method to get a `Result` object, which contains the validation status, errors, and the original value.

```dart
final result = userValidator.validate({
  'username': 'alice',
  'lastname': 'smith',
  'age': -1, // Invalid
  'theme': 'system', // Invalid
  'bio': null, // Valid
  // 'birthday' is missing, which is valid for an optional field
});

if (!result.isValid) {
  print(result);
  // Result(
  //   isValid: false,
  //   value: { ... },
  //   expectations: [
  //     age: must be greater than or equal to 0,
  //     theme: must be one of [light, dark]
  //   ]
  // )
}
```

You can also get a simple boolean or have it throw an exception on failure.

```dart
// Get a boolean result
final ok = userValidator.isValid({'username': 'bob', 'lastname': 'p', 'age': 42, 'theme': 'light'});
print("User is valid: $ok"); // true

// Throw an exception on failure
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
		- [1. Create a validator](#1-create-a-validator)
		- [2. Validate your data](#2-validate-your-data)
	- [Table of contents](#table-of-contents)
	- [API overview](#api-overview)
	- [Async validation](#async-validation)
		- [Creating an async validator](#creating-an-async-validator)
		- [Mixing sync \& async combinators](#mixing-sync--async-combinators)
		- [When to prefer validateAsync()](#when-to-prefer-validateasync)
		- [Error handling](#error-handling)
		- [Upgrading existing code](#upgrading-existing-code)
	- [Transformers](#transformers)
	- [Conditional Validation](#conditional-validation)
	- [Examples](#examples)
		- [Custom validators](#custom-validators)
		- [Nullable vs optional](#nullable-vs-optional)
	- [Contributing](#contributing)
		- [Reporting Bugs](#reporting-bugs)
		- [Feature Requests](#feature-requests)
		- [Pull Requests](#pull-requests)
		- [Project-Specific Guidelines](#project-specific-guidelines)
			- [Requesting New Validators](#requesting-new-validators)
			- [Code Style](#code-style)

## API overview

> Check the [docs](https://pub.dev/documentation/eskema/latest/) for the full technical documentation.

-   Core
    -   `IValidator` — The base class for all validators.
    -   `Result` — The output of a validation, containing `.isValid`, `.expectations`, and `.value`.
    -   `eskema({ 'key': validator, ... })` — Validates maps against a schema.
    -   `eskemaStrict({ 'key': validator, ... })` — Like `eskema`, but fails on unknown keys.

-   Common Validators
    -   Types: `isString()`, `isInt()`, `isDouble()`, `isBool()`, `isList()`, `isMap()`, `isDateTime()`
    -   Presence: `isNull()`, `isNotNull()`, `isNotEmpty()`, `isPresent()`
    -   Composition: `&` (AND), `|` (OR), `not()`
    -   Comparison: `isGt(n)`, `isGte(n)`, `isLt(n)`, `isLte(n)`, `isEq(v)`, `isDeepEq(v)`, `isInRange(min, max)`
    -   Strings: `hasLength(n)`, `contains(s)`, `startsWith(s)`, `endsWith(s)`, `matchesPattern(re)`, `isEmail()`, `isUrl()`, `isUuid()`, `isDateTimeString()`
    -   Lists: `listEach(v)`, `listIsOfLength(n)`, `contains(v)`

-   Modifiers
    -   `v.nullable()` — Allows the value to be `null` (key must be present).
    -   `v.optional()` — Allows the key to be missing.
    -   `v > 'custom error'` — Overrides the default error message.

-   Results & Helpers
    -   `.validate(value)` → `Result`
    -   `.validateAsync(value)` → `Future<Result>` (use when any validator is async)
    -   `.isValid(value)` → `bool`
    -   `.validateOrThrow(value)` → throws `ValidatorFailedException` on invalid input.
    -   `AsyncValidatorException` — thrown if you call `.validate()` on a chain that contains async validators.

## Async validation

Eskema supports mixing synchronous and asynchronous validators without forcing everything to become async. Validators internally return `FutureOr<Result>` and only upgrade to a `Future` when an async boundary is encountered.

Key points:

- Use `.validate()` for purely synchronous validator chains (fast path, no allocations for Futures).
- If any validator in the chain is async (uses `async` / returns a `Future<Result>`), call `.validateAsync()` instead.
- Calling `.validate()` on a chain that resolves an async validator throws `AsyncValidatorException` with a helpful message.
- Synchronous and async validators compose seamlessly; you do not need separate APIs for "async versions" of built-ins.

### Creating an async validator

You can make any custom validator async simply by returning a `Future<Result>` (e.g. using `async`). For example, checking a username against an in‑memory or remote store:

```dart
// Simulated async uniqueness check
final $isUsernameAvailable = Validator((value) async {
  await Future<void>.delayed(const Duration(milliseconds: 10));
  const taken = {'alice', 'root'};
  if (value is String && !taken.contains(value)) {
    return Result.valid(value);
  }
  return Result.invalid(value, expectation: Expectation(message: 'not available', value: value));
});

final userValidator = eskema({
  'username': isString() & isNotEmpty() & $isUsernameAvailable,
  'age': isInt() & isGte(0),
});

// Because one link is async, use validateAsync()
final r = await userValidator.validateAsync({'username': 'new_user', 'age': 30});
print(r.isValid); // true

// Calling validate() here would throw AsyncValidatorException
```

### Mixing sync & async combinators

Combinators like `all`, `any`, `none`, `not`, schema validators (`eskema`, `eskemaStrict`, `eskemaList`, `listEach`) and `when` all propagate async seamlessly. They stay synchronous until a child returns a `Future` and only then switch to async.

### When to prefer validateAsync()

- Any time you intentionally include an async validator.
- If you want a uniform `Future` interface regardless of sync/async (e.g. in higher‑level code). It is safe but you lose the micro‑optimization of the sync fast path.

### Error handling

- Use `validateAsync()` + check `r.isValid`.
- Or, wrap an async chain with `throwInstead(v)` and handle `ValidatorFailedException` inside a `try/catch`.
- Misuse (calling `.validate()` on async chain) → `AsyncValidatorException`.

### Upgrading existing code

Most existing synchronous validators require no changes. Only update call sites to `.validateAsync()` where you introduce an async validator.

## Transformers

Transformers coerce or modify a value *before* it's passed to a child validator. This is useful for converting strings to numbers, trimming whitespace, or providing default values.

```dart
// Coerce a string to an integer, then validate the number
final ageValidator = toInt(isInt() & isGte(18));
ageValidator.validate('25'); // Valid, value becomes 25
ageValidator.validate('invalid'); // Invalid

// Provide a default value for a missing or null field
final settingsValidator = eskema({
  'theme': defaultTo('light', isIn(['light', 'dark'])),
});
settingsValidator.validate({}); // Valid, theme becomes 'light'

// Split a string into a list and validate each item
final tagsValidator = split(',', listEach(isString() & isNotEmpty()));
tagsValidator.validate('dart,flutter,eskema'); // Valid
```

Available transformers:

-   `toInt(child)`
-   `toDouble(child)`
-   `toNum(child)`
-   `toBool(child)`
-   `toDateTime(child)`
-   `trim(child)`
-   `toLowerCase(child)`
-   `toUpperCase(child)`
-   `defaultTo(defaultValue, child)`
-   `split(separator, child)`
-   `getField(key, child)`

## Conditional Validation

The `when` validator allows you to apply different validation rules based on the value of another field in the same map.

```dart
final addressValidator = eskema({
  'country': isIn(['USA', 'Canada']),
  'postal_code': when(
    // Condition (on the parent map)
    getField('country', isEq('USA')),
    // `then` validator (for the `postal_code` field)
    then: isString() & hasLength(5) > 'a 5-digit US zip code',
    // `otherwise` validator (for the `postal_code` field)
    otherwise: isString() & hasLength(6) > 'a 6-character Canadian postal code',
  ),
});

// This is valid
addressValidator.validate({
  'country': 'USA',
  'postal_code': '90210',
});

// This is also valid
addressValidator.validate({
  'country': 'Canada',
  'postal_code': 'M5H2N2',
});

// This is invalid
addressValidator.validate({
  'country': 'USA',
  'postal_code': 'M5H2N2',
});
```

## Examples

### Custom validators

You can create your own validators by composing existing ones or by creating a new `Validator` instance.

```dart
// 1. By composition
IValidator isPositive() => isInt() & isGte(0);

// 2. With the `validator` helper
IValidator isDivisibleBy(int n) {
  return validator(
    (value) => value is int && value % n == 0,
    (value) => Expectation(message: 'must be divisible by $n', value: value),
  );
}

// 3. With a custom class (for more complex logic)
class MyCustomValidator extends Validator {
  MyCustomValidator() : super((value) {
    if (value == 'magic') {
      return Result.valid(value);
    }
    return Result.invalid(value, expectations: [Expectation(message: 'not magic', value: value)]);
  });
}
```

### Nullable vs optional

The distinction between `nullable` and `optional` is important for map validation.

-   **`nullable()`**: The key **must** be present in the map, but its value can be `null`.
-   **`optional()`**: The key **may be missing** from the map. If it is present, its value must not be `null` (unless `nullable` is also used).

```dart
final validator = eskema({
  'required_but_nullable': isString().nullable(),
  'optional_and_not_nullable': isString().optional(),
  'optional_and_nullable': isString().nullable().optional(),
});

// Key must exist, value can be null
validator.validate({ 'required_but_nullable': null }); // Valid
validator.validate({}); // Invalid: 'required_but_nullable' is missing

// Key can be missing. If present, value cannot be null.
validator.validate({ 'optional_and_not_nullable': 'hello' }); // Valid
validator.validate({}); // Valid
validator.validate({ 'optional_and_not_nullable': null }); // Invalid

// Key can be missing. If present, value can be null.
validator.validate({ 'optional_and_nullable': null }); // Valid
validator.validate({}); // Valid
```


## Contributing

Contributions are welcome! Whether you've found a bug, have a feature request, or want to contribute code, please feel free to open an issue or a pull request.

### Reporting Bugs

If you find a bug, please open an issue on the [GitHub repository](https://github.com/nombrekeff/eskema/issues). Include a clear description of the problem, steps to reproduce it, and the expected behavior.

### Feature Requests

If you have an idea for a new feature or an improvement to an existing one, please open an issue to start a discussion. This allows us to align on the feature before any code is written.

### Pull Requests

1.  **Fork** the repository and create your branch from `main`.
2.  **Install dependencies**: `dart pub get`
3.  **Make your changes**. Please add tests for any new features or bug fixes.
4.  **Run tests**: `dart test`
5.  **Ensure your code is formatted**: `dart format .`
6.  **Submit a pull request** with a clear description of your changes.

### Project-Specific Guidelines

#### Requesting New Validators

Before requesting a new validator, please consider the following:

1.  **Can it be composed?** Many complex validations can be achieved by combining existing validators with `&`, `|`, and `not()`. If it can be easily composed, a new validator might not be necessary.
2.  **Is it a common use case?** We aim to include validators that are widely applicable (e.g., `isEmail`, `isUrl`). Provide a real-world example of where the validator would be useful.
3.  **Propose an API.** Suggest a name and signature for the new validator. For example: `isCreditCard()`, `hasMinLength(5)`.

#### Code Style

This project follows the official [Dart style guide](https://dart.dev/guides/language/effective-dart/style). All code should be formatted with `dart format .` before committing.