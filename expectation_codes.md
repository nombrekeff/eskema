# Eskema Built‑in Validators -> Expectation Codes & Data

This reference maps each built‑in validator (and structural / combinator behaviors) to the error `code` it produces when it fails, plus the shape of any `data` payload (machine‑readable metadata). Codes are namespaced for easy filtering.

Legend:
- `value.*`  – intrinsic value shape / content issues
- `type.*`   – Dart runtime type mismatch
- `structure.*` – container / schema shape problems
- `logic.*`  – logical composition outcomes or generic fallbacks
- (legacy) `value_not_in_set` – kept for now (will be migrated to namespaced form in a future minor release)

Data column lists keys you can expect; additional keys may appear (always additive) in future non‑breaking updates.

---
## Type Validators
| Validator | Failure Code | Data Keys | Notes |
|-----------|--------------|-----------|-------|
| `isType<T>()` (and shorthand: `isString`, `isInt`, `isDouble`, `isBool`, `isNumber`, `isList<T>`, `isMap<K,V>`, `isSet<T>`, `isFunction`, `isFuture<T>`, `isIterable<T>`, `isRecord`, `isSymbol`, `isEnum`, `isDateTime`) | `type.mismatch` | `expected`, `found` | Returned when runtime type differs. Shorthand helpers just pre‑bind `T`.

## Equality & Membership
| Validator | Failure Code | Data Keys | Notes |
|-----------|--------------|-----------|-------|
| `isEq(x)` | `value.equal_mismatch` | `expected`, `found`, `mode` = `shallow` | Simple `==` comparison (non deep collections). |
| `isDeepEq(x)` | `value.deep_equal_mismatch` | `expected`, `found`, `mode` = `deep` | Deep collection equality (uses `DeepCollectionEquality`). |
| `isOneOf([...])` | `value_not_in_set` | `options` (List<String>) | Legacy non‑namespaced code retained for compatibility. |
| `contains(item)` (generic, incl. strings & iterables) | `value.contains_missing` | `item` (stringified) | Applied when container supports `.contains` and fails. |
| `containsKey(key)` | `value.contains_missing` | `path` (key), `key` | Works after `isMap`. |
| `listContains(item)` | `value.contains_missing` | `needle` | Wrapper adds friendlier message. |
| `stringContains(str)` | `value.contains_missing` | `needle` | Wrapper adds friendlier message. |

## Length & Emptiness
| Validator / Scenario | Failure Code | Data Keys | Notes |
|----------------------|--------------|-----------|-------|
| `length([...])` (aggregated) | `value.length_out_of_range` | `length` (actual) | Wraps nested length validators; message lists nested expectations. |
| `listLength([...])`, `listIsOfLength(n)` | `value.length_out_of_range` | `length` | Delegates to `length`. |
| `stringLength([...])`, `stringIsOfLength(n)` | `value.length_out_of_range` | `length` | Delegates to `length`. |
| `listEmpty()` | `value.length_out_of_range` | `expected` = 0 | Emptiness specialized via list length. |
| `stringEmpty()` | `value.length_out_of_range` | `expected` = 0 | Emptiness specialized via string length. |

## Numeric Range & Comparison
| Validator | Failure Code | Data Keys | Notes |
|----------|--------------|-----------|-------|
| `isLt(max)` | `value.range_out_of_bounds` | `operator` = `<`, `limit` | Strict upper bound. |
| `isLte(max)` | `value.range_out_of_bounds` | `operator` = `<=`, `limit` | Inclusive upper bound. |
| `isGt(min)` | `value.range_out_of_bounds` | `operator` = `>`, `limit` | Strict lower bound. |
| `isGte(min)` | `value.range_out_of_bounds` | `operator` = `>=`, `limit` | Inclusive lower bound. |
| `isInRange(min,max)` | `value.range_out_of_bounds` | `operator` = `between_inclusive`, `min`, `max` | Inclusive range. |

## Pattern & Format
| Validator | Failure Code | Data Keys | Notes |
|-----------|--------------|-----------|-------|
| `stringMatchesPattern(pattern)` | `value.pattern_mismatch` | `pattern` | Generic pattern validation (regex or `Pattern`). |
| `isLowerCase()` | `value.case_mismatch` | `expected_case` = `lower` | Matches `^[a-z]+$`. |
| `isUpperCase()` | `value.case_mismatch` | `expected_case` = `upper` | Matches `^[A-Z]+$`. |
| `isUrl()` / `isStrictUrl()` | `value.format_invalid` | `format` = `url` | Non‑strict vs strict absolute URL parse. |
| `isEmail()` | `value.pattern_mismatch` | `pattern` (internal regex) | Simple email regex (not full RFC). |
| `isUuidV4()` | `value.pattern_mismatch` | `pattern` | Uses UUID v4 regex. |
| `isIntString()` | `value.format_invalid` | `format` = `int` | Parses trimmed string via `int.tryParse`. |
| `isDoubleString()` | `value.format_invalid` | `format` = `double` | Uses `double.tryParse`. |
| `isNumString()` | `value.format_invalid` | `format` = `num` | Uses `num.tryParse`. |
| `isDate()` | `value.format_invalid` | `format` = `date_time` | Uses `DateTime.tryParse`. |

## Structure (Maps & Lists)
| Validator / Collector | Failure Code | Data Keys | Notes |
|-----------------------|--------------|-----------|-------|
| `eskemaStrict` (unknown keys) | `structure.unknown_key` | `keys` (List<String>) | Triggered when extra keys not in schema. |
| `eskema` field failure (child has code) | child code | (child data) | Path is prefixed with `.<field>`. |
| `eskema` field failure (child has no code) | `structure.map_field_failed` | (child data) | Fallback when child expectation lacks code. |
| `eskemaList([...])` item failure (child has code) | child code | (child data) | Path prefixed with `[index]`. |
| `eskemaList([...])` item failure (child no code) | `structure.list_item_failed` | (child data) | Fallback. |
| `listEach(validator)` item failure (child has code) | child code | (child data) | Iterates arbitrary length list. |
| `listEach(validator)` item failure (child no code) | `structure.list_item_failed` | (child data) | Fallback. |
| Missing required key (non‑optional) | Usually `type.mismatch` (from underlying validator) | `expected`, `found` | Currently no distinct `required_missing` code; absence validated as `null` with `exists:false` path. |

## Combinators & Logic
| Combinator | Failure Code | Data Keys | Notes |
|------------|--------------|-----------|-------|
| `not(v)` (when child succeeds) | `logic.not_expected` (if child had none) or child's code (if present) | child's data | Wraps message with `not ...`. |
| `any([...])` | (aggregated child codes) | (child data) | Fails only if all fail; expectations combined. |
| `all([...])` | First failing child code | Child data | Short‑circuits on first failure. |
| `none([...])` | Combined negated child codes | Child data | Applies `not` to each child. |
| `throwInstead(v)` | (throws) | — | Throws `ValidatorFailedException` instead of returning result. |
| `withExpectation(v, Expectation)` (operator `>`) | Propagates child code | Child data | Replaces message but preserves code if child failed. |

## Presence Wrappers
| Wrapper | Behavior | Notes |
|---------|----------|-------|
| `optional(v)` | Skips validation (valid) if value missing or null (still invalid if null and `v` forbids null unless handled separately). | Does not emit a code when skipped. |
| `nullable(v)` | Valid if value is `null`, otherwise delegates to `v`. | No code on skip. |

## Generic / Fallback Codes
| Code | When Emitted | Data |
|------|--------------|------|
| `logic.predicate_failed` | Internal fallback when a structural property is absent (e.g., length requested on non‑length value, contains on unsupported type). | None.

---
## Notes & Future Evolution
- `value_not_in_set` remains legacy; expect migration to `value.not_in_set` (alias) in a future minor release.
- A distinct `structure.required_missing` code can be introduced later without breaking existing behavior—currently absence is surfaced through the underlying validator (often `type.mismatch`).
- Consumers should tolerate unknown extra `data` keys (forward compatibility) and treat missing optional keys defensively.

## Quick Example (Machine Processing)
```dart
final r = (isInt() & isGt(10)).validate(5);
final code = r.firstExpectation.code; // value.range_out_of_bounds
final info = r.firstExpectation.data; // { operator: '>', limit: 10 }
```

If anything is missing or you’d like a JSON export helper, let me know.
