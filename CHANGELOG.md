<<<<<<< HEAD
## 2.0.1
### Fix
- Fixed issue with default expectation not being used when a result is invalid.

### Feature
- Added `resolve` validator. Which allows you to create a validator based on the parent value.
- Added `switchBy` validator. Which allows you to create a validator based on the value of a key in the parent map.
=======
>>>>>>> develop

## 2.0.0
## feat: Fluent Builder API and Comprehensive Validation Overhaul

This major update introduces a complete overhaul of the validation framework, centered around a new fluent, type-safe builder API. It significantly expands the library's capabilities with a wide range of new validators and transformers, while refactoring the entire codebase for improved structure, maintainability, and developer experience.

---

### ✨ Key Features

* **New Fluent Builder API**:
    * Introduced a new `builder()` entry point and a suite of **type-specific builders** (e.g., `StringBuilder`, `IntBuilder`, `DateTimeBuilder`, `MapBuilder`) to create validation chains with a more intuitive and type-safe approach.
    * Builders now implement the `IValidator` interface, making them **composable** and allowing them to be used interchangeably with standard validators.

* **Expanded Validator & Transformer Library**:
    * **Date Validators**: Comprehensive checks for past/future dates, date ranges, and same-day comparisons (`isDateBefore`, `isDateAfter`, `isDateBetween`, etc.).
    * **JSON Validators**: Deep validation for JSON structures, including checks for containers, object/array types, key existence, and array lengths (`isJsonObject`, `jsonHasKeys`, `jsonArrayLength`, etc.).
    * **Map Validators**: Helpers for schema-like map validation (`containsKey`, `containsValues`).
    * **String Normalizers**: A powerful set of string transformers, including `trim`, `collapseWhitespace`, `slugify`, `stripHtml`, `removeDiacritics`, and more.

* **Enhanced Error Handling & Custom Messages**:
    * Implemented a **centralized expectation code system** to standardize error types and prevent typos.
    * Added support for **custom validation messages** across all validators and combinators (`all`, `any`, `not`), allowing for more user-friendly error feedback.
    * Introduced error formatting utilities to simplify the presentation of validation failures.

---

### 🔄 Major Refactoring & Improvements

* **Modular Library Structure**: The core validator library has been broken down into a more logical structure with `base`, `combinator`, and `map` validator files for better organization and maintainability.
* **API Consistency**: Refactored method signatures, parameter names, and library declarations to follow a unified and consistent convention.
* **Code Quality & Readability**: Simplified internal validation logic, removed redundant code, improved formatting, and refactored transformers and validators for better clarity and consistency. The `Result` class was updated to use `Iterable` instead of `List` for expectations, improving flexibility.

---

### 🛠️ Tooling & Quality Assurance

* **CI Enhancements**: The CI workflow has been upgraded to include a **SonarQube scan** for static code analysis and a **lint step** to enforce code quality standards automatically.
* **Robust Testing**: Massively expanded the test suite to cover all new features, including:
    * Comprehensive tests for custom message propagation.
    * Behavioral tests for asynchronous combinators.
    * The introduction of **monkey fuzz testing** to stress-test validators and ensure their robustness against unexpected inputs.

---

### ⚠️ Breaking Changes

* The primary entry point for creating validation chains has been changed from `v()` to the more descriptive **`builder()`**. All previous `v()` calls will need to be updated.
* The refactoring of the library's internal file structure may require adjustments to import statements in existing code.

## 1.0.0
### Breaking


### Additions
- Added a few new validators: `isLowerCase`, `isUrl`, etc... see [validators docs](https://nombrekeff.github.io/eskema/validators)
- Added the concept of **transformer** which can map a value before passing it to the validator
  - Some built-in transfomers are available: `transform`, `isInt`, `isBool`, etc... see [transformers docs](https://nombrekeff.github.io/eskema/transformers)
- Improved Results, now contain a list of [Expectations](https://nombrekeff.github.io/eskema/expectation) describing what was expected, and where it was expected, alongisde a descriptive code and additional data context.
- Cached zero‑arg validators (e.g. `$isString`, etc.) [see cached validators](https://nombrekeff.github.io/eskema/cached_validators/)
- Added async support across all combinators (`&`, `|`, `any`, `all`, `none`, `not`), `eskema`, `eskemaStrict`, `eskemaList`, `listEach`, transformers.
- `validateAsync()` API.
- `AsyncValidatorException`.
- Machine‑readable `Expectation.code` & `Expectation.data`.
- Standard code taxonomy: `type.mismatch`, `value.pattern_mismatch`, etc...
- Safe `asyncValidator(...)` helper (wraps predicate + error capture).

### Changed
- Internal validators now return `FutureOr<Result>`; combinators always call `validateAsync` internally.
- Structural validators propagate and enrich error codes/paths more consistently.
- `withError` now preserves underlying codes (message override only).
- Standardized path joining for nested map/list errors.

### Fixed
- Optional / nullable short‑circuit logic with async branches.
- Path propagation for nested list/map failures.
- Inconsistent messages across some string/number validators.

## 0.1.0
* Validators are now classes instead of pure functions
* Added more validators
* Fixed inconsitencies
* Better docs and readme
* Improved ergonomics by adding `isValid`, `isNotValid`, and other methods.

## 0.0.1
* MVP, basic validators and mostly complete API
