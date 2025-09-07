/// ### Transformers
///
/// Value–coercion helpers that run BEFORE the provided `child` [validator].
/// They:
///  * Accept a broader set of input types (e.g. int / num / String for toInt)
///  * Produce a (possibly) transformed value
///  * Pass that value to the `child` [validator]
///
/// Failure model:
///  * The “pre‑check” part (e.g. `$isInt | $isNumber | $isIntString`) ensures
///    only plausible values reach the mapper. If that OR [validator] fails,
///    the chain stops there (no transform executed).
///  * The `transform(...)` function itself NEVER throws; it may return `null`.
///    If it returns `null`, the `child` [validator] receives `null` (and will
///    typically fail unless it is `nullable()`).
///
/// Composition patterns:
///  * Coerce then constrain:
///      final age = toInt(isGte(0) & isLte(130));
///  * Add null support after coercion:
///      final maybeDate = toDateTime(isType&lt;DateTime>()).nullable();
///  * Field extraction + transform:
///      final userAge = getField('age', toInt(isGte(18)));
///
/// Expectations:
///  * If you supply a `message` parameter to a transformer factory, an overriding
///    expectation is attached. Omitting `message` preserves the underlying validators'
///    original expectations (backward compatible behavior).
///
/// NOTE: These are “inline transformers” — they do not mutate external data,
/// only the value flowing through the validator pipeline.
library transformers;

export 'transformers/core.dart';
export 'transformers/number.dart';
export 'transformers/boolean.dart';
export 'transformers/string.dart';
export 'transformers/datetime.dart';
export 'transformers/json.dart';
export 'transformers/map.dart';
export 'transformers/utility.dart';
