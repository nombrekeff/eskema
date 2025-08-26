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
