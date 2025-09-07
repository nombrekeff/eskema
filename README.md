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

## Core example (from `example/readme_example.dart`)

```dart
import 'package:eskema/eskema.dart';

void main() {
  final userValidator = eskema({
    'username': isString(),                  // basic type check
    'lastname': $isString,                   // cached zero‑arg variant
    'age': all([isInt(), isGte(0)]),         // multi validator (AND)
    'theme': isString() & (isEq('light') | isEq('dark')), // operators
    'premium': nullable($isBool),            // key must exist; value may be null
    'birthday': optional(isDate()),          // key may be absent
  });

  final ok = userValidator.validate({
    'username': 'bob', 'lastname': 'builder', 'theme': 'light', 'age': 42,
  });
  print(ok); // missing premium (nullable != optional)

  final res = userValidator.validate({'username': 'alice', 'age': -1});
  print(res.isValid);        // false
  print(res.expectations);   // structured reasons (age invalid, missing keys, etc.)
}
```

### How it works
1. Build a schema with `eskema({...})` (map of field -> validator)
2. Compose validators with functions (`isString()`, `isGte(0)`, `all([...])`) or operators (`&`, `|`)
3. Add modifiers: `nullable()` (value may be null) vs `optional()` (key may be absent)
4. Call `validate(value)` (sync chain) or `validateAsync(value)` if any link is async
5. Inspect `Result.isValid` & `Result.expectations` or throw via `validateOrThrow()`

### Reading failures
Each failure is an `Expectation` having:
* message – human text
* code – stable identifier (see expectation codes doc)
* path – location (e.g. `.user.address[0].city`)
* data – structured metadata

## More examples
See the `example/` directory for:
* transformers (`toInt`, `defaultTo`, `trim`)
* conditional validation (`when` + `getField`)
* custom validators & builders
* list & strict schema validation

## Docs & help
* [Docs & guides](https://nombrekeff.github.io/eskema/)
* [API reference](https://pub.dev/documentation/eskema/latest/)
* [Wiki](https://github.com/nombrekeff/eskema/wiki)
* Issues / questions: https://github.com/nombrekeff/eskema/issues

## Contributing
Open an issue for discussion, then PR with tests. Keep additions composable. (Detailed guidelines live in the wiki / future CONTRIBUTING doc.)

## License
MIT – see `LICENSE`.

---
Star the repo if it helps you. ⭐
