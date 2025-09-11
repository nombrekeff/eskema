/// Top‑level built‑in validators and combinators.
///
/// Overview:
/// - Stateless type validators: `isString()`, `isInt()`, `isMap()`, etc.
///   Each has a cached `$` alias (`$isString`, `$isInt`) for zero‑arg reuse.
/// - Logical/comparison: `isGt`, `isGte`, `isLt`, `isLte`, `isEq`, `isDeepEq`.
/// - Collection / structure helpers: `contains`, `containsKey`, `listEach`, `eskema`, `eskemaList`.
/// - String/length: `stringIsOfLength`, `stringContains`, `stringMatches`.
/// - Numeric/string parsing predicates: `isIntString`, `isDoubleString`, `isNumString`.
/// - Date/time: `isDate` (parsable ISO 8601 string), `isDateTime` (actual DateTime type).
/// - Combinators:
///   * `all([...])`  AND composition (short‑circuits on first failure)
///   * `any([...])`  OR composition (returns first success, else aggregates failures)
///   * `none([...])` succeeds only if every validator fails
///   * `not(v)`      logical negation
/// - Null / presence semantics:
///   * `nullable(v)` (or `v.nullable()`) => key must exist; value may be null
///   * `optional(v)` (or `v.optional()`) => key may be missing; if present must pass `v`
/// - Schema helpers:
///   * `eskema({...})` for Map field validation (propagates nested error paths)
///   * `eskemaList([...])` positional list schema
///   * `listEach(v)` uniform element validation
/// - Utility wrappers:
///   * `withError(child, message)` replace expectation message
///
/// Value flow:
/// - Basic validators are pure predicates that attach `Expectations`.
/// - Combinators compose results; `all` stops early, `any` returns on first pass.
/// - Transformers (defined separately) can precede these validators; `all` will
///   forward transformed values to subsequent validators.
///
/// Conventions:
/// - Prefer `$isType` constants for zero‑arg validators in hot paths.
/// - For collection equality use `isDeepEq` instead of `isEq` on lists/maps/sets.
///
/// See README for detailed examples and nullable vs optional explanation.
///
/// This library is intentionally minimal: advanced behaviors (async validators,
/// transformers, refiners) live in their own files to keep this surface stable.
library validators;

import 'package:eskema/expectation.dart';
import 'package:eskema/result.dart';
import 'package:eskema/validator.dart';

export 'package:eskema/validators/structure.dart';
export 'package:eskema/validators/presence.dart';
export 'package:eskema/validators/combinator.dart';
export 'package:eskema/validators/number.dart';
export 'package:eskema/validators/string.dart';
export 'package:eskema/validators/type.dart';
export 'package:eskema/validators/comparison.dart';
export 'package:eskema/validators/list.dart';
export 'package:eskema/validators/map.dart';
export 'package:eskema/validators/cached.dart';
export 'package:eskema/validators/date.dart';

Validator validator(
  bool Function(dynamic value) comparisonFn,
  Expectation Function(dynamic value) errorFn,
) {
  return Validator(
    (value) => Result(
      isValid: comparisonFn(value),
      expectation: errorFn(value),
      value: value,
    ),
  );
}
