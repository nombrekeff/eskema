/// Fluent, type‑aware validator builder.
///
/// Goal:
///   v().string().lengthMin(3).lengthMax(8).notEmpty().build()
///   v().int_().gte(18).lt(100).build()
///   v().number().between(0, 1, inclusive: false).build()
///   v().string()
///       .matches(RegExp(r'^[a-z0-9_]+$'))
///       .async((v) async => await isAvailable(v), 'value.available')
///       .build()
///
/// Design:
/// - Start with RootBuilder (v()) which only exposes type selectors.
/// - Each type selector returns a specialized builder exposing only
///   methods that make semantic sense for that type.
/// - Common operations (optional, nullable, custom, async, error, oneOf)
///   are mixed in via reusable mixins.
/// - All builders share the same internal _Chain so composition
///   continues seamlessly when switching (e.g., you could add future
///   cross‑type transitions if needed).
///
/// NOTE: This is an initial implementation focusing on built‑in types.
///       More domain‑specific builders (dates, UUIDs, collections with
///       element schemas) can be layered later.
///
/// Async:
/// - Async predicates are added like any other validator; the unified
///   pipeline means build() returns a normal IValidator that supports
///   validate() / validateAsync().
///
/// Future extensions (not yet implemented):
/// - list().each( validator )
/// - map().schema( {...} )
/// - string().email(), string().url(), etc.
/// - number().positive(), number().nonNegative(), etc.
// ignore_for_file: library_private_types_in_public_api

library builder;

// NOTE: Avoid importing the umbrella eskema.dart here because it re‑exports this
// file, which would create a circular import. Instead we import the specific
// source libraries we need. We import validators.dart twice: once unprefixed so
// existing calls (isGte, isLte, etc.) keep working, and once with the alias
// 'esk' so we can disambiguate symbols that clash with builder members (like
// the 'not' combinator) via esk.not().

import 'dart:async';

import 'validators.dart';
import 'validator.dart';
import 'expectation.dart';
import 'result.dart';
import 'extensions.dart';
import 'transformers.dart' as tr;
import 'validators.dart' as esk; // for esk.not / esk.contains, etc.
import 'validators/date.dart';
import 'validators/json.dart';

/// Internal accumulator for a builder chain.
///
/// We model the pipeline with at most one type‑changing transformer. Everything
/// added before the first *Coerce() call is considered pre‑coercion and will be
/// discarded once a coercion is requested (since those validators target the
/// original type). Validators added after coercion target the coerced type.
// Kind of coercion applied to the chain (single pivot allowed).
enum _CoercionKind { int_, double_, bool_, string_, datetime_, json_, custom }

/// Represents a custom pivot for extensibility.
///
/// Use this to define custom type coercions or transformations that can be plugged into the builder chain.
///
/// Example:
/// ```dart
/// class MyPivot extends CustomPivot {
///   MyPivot() : super(
///     (child) => Validator((value) => child.validate(value.toString())),
///     dropPre: true,
///     kind: 'toString',
///   );
/// }
///
/// final validator = v().use(MyPivot()).lengthMin(1).build();
/// ```
class CustomPivot {
  final IValidator Function(IValidator child) transformer;
  final bool dropPre;
  final String? kind; // optional, for documentation

  CustomPivot(this.transformer, {this.dropPre = true, this.kind});
}

class Chain {
  // Validators accumulated BEFORE any type coercion (original type domain).
  IValidator? _preValidators;
  // Validators accumulated AFTER coercion (new type domain).
  IValidator? _postValidators;
  // The single coercion transformer (wraps _postValidators when building).
  IValidator Function(IValidator child)? _coercion;
  // Which coercion (if any) has been applied.
  _CoercionKind? _coercionKind;
  // A prefix transformer applied BEFORE coercion (value pivot like pluckValue / pick / flatten).
  IValidator Function(IValidator child)? _prefix;
  // Whether pre-validators should be preserved when applying coercion
  bool _preservePreValidators = false;

  bool get _hasCoercion => _coercionKind != null;
  bool _isKind(_CoercionKind k) => _coercionKind == k;

  void add(IValidator v) {
    if (_hasCoercion) {
      _postValidators = _postValidators == null ? v : (_postValidators! & v);
    } else {
      _preValidators = _preValidators == null ? v : (_preValidators! & v);
    }
  }

  void wrap(IValidator Function(IValidator current) fn) {
    if (_hasCoercion) {
      if (_postValidators != null) _postValidators = fn(_postValidators!);
    } else if (_preValidators != null) {
      _preValidators = fn(_preValidators!);
    }
  }

  void setTransform(_CoercionKind kind, IValidator Function(IValidator child) transformer,
      {bool dropPre = true}) {
    if (_coercionKind == null) {
      // First pivot: drop pre validators (they targeted old domain)
      _coercionKind = kind;
      _coercion = transformer;
      _preservePreValidators = !dropPre;
      if (dropPre) _preValidators = null;
      return;
    }
    // Subsequent pivot: compose if either current or previous is custom; replace only if both are built-in
    if (kind == _CoercionKind.custom || _coercionKind == _CoercionKind.custom) {
      final previous = _coercion!;
      _coercion = (child) => previous(transformer(child));
    } else {
      _coercion = transformer;
    }
    _coercionKind = kind;
    _postValidators = null;
  }

  // Add a prefix value-mapping validator (runs before coercion & post validators).
  void addPrefix(IValidator Function(IValidator child) prefix) {
    if (_prefix == null) {
      _prefix = prefix;
    } else {
      final existing = _prefix!;
      _prefix = (child) => existing(prefix(child));
    }
  }

  IValidator build() {
    IValidator core;
    // Apply prefix first so coercion sees transformed value.
    IValidator tail() {
      if (_coercion != null) {
        final child = _postValidators ?? Validator.valid;
        final coerced = _coercion!(child);
        // If preserving pre-validators, apply them before coercion
        if (_preservePreValidators && _preValidators != null) {
          return _preValidators! & coerced;
        }
        return coerced;
      }
      return _preValidators ?? Validator.valid;
    }

    core = _prefix != null ? _prefix!(tail()) : tail();
    return core;
  }

  // Readable getters for coercion state (used by transformer mixin).
  bool get coercedToInt => _isKind(_CoercionKind.int_);
  bool get coercedToDouble => _isKind(_CoercionKind.double_);
  bool get coercedToBool => _isKind(_CoercionKind.bool_);
  bool get coercedToString => _isKind(_CoercionKind.string_);
  bool get coercedToDateTime => _isKind(_CoercionKind.datetime_);
  bool get coercedToJson => _isKind(_CoercionKind.json_);
}

mixin TransformerMixin<B extends _BaseBuilder<B, T>, T> on _BaseBuilder<B, T> {
  IntBuilder toInt({String? message}) {
    if (_chain.coercedToInt) return IntBuilder(chain: _chain); // idempotent
    _chain.setTransform(_CoercionKind.int_, (child) => tr.toInt(child));
    return IntBuilder(chain: _chain);
  }

  IntBuilder toIntStrict({String? message}) {
    if (_chain.coercedToInt) return IntBuilder(chain: _chain);
    _chain.setTransform(_CoercionKind.int_, (child) => tr.toIntStrict(child));
    return IntBuilder(chain: _chain);
  }

  IntBuilder toIntSafe({String? message}) {
    if (_chain.coercedToInt) return IntBuilder(chain: _chain);
    _chain.setTransform(_CoercionKind.int_, (child) => tr.toIntSafe(child));
    return IntBuilder(chain: _chain);
  }

  DoubleBuilder toDouble({String? message}) {
    if (_chain.coercedToDouble) return DoubleBuilder(chain: _chain);
    _chain.setTransform(_CoercionKind.double_, (child) => tr.toDouble(child));
    return DoubleBuilder(chain: _chain);
  }

  BoolBuilder toBool({String? message}) {
    if (_chain.coercedToBool) return BoolBuilder(chain: _chain);
    _chain.setTransform(_CoercionKind.bool_, (child) => tr.toBool(child));
    return BoolBuilder(chain: _chain);
  }

  BoolBuilder toBoolStrict({String? message}) {
    if (_chain.coercedToBool) return BoolBuilder(chain: _chain);
    _chain.setTransform(_CoercionKind.bool_, (child) => tr.toBoolStrict(child));
    return BoolBuilder(chain: _chain);
  }

  BoolBuilder toBoolLenient({String? message}) {
    if (_chain.coercedToBool) return BoolBuilder(chain: _chain);
    _chain.setTransform(_CoercionKind.bool_, (child) => tr.toBoolLenient(child));
    return BoolBuilder(chain: _chain);
  }

  StringBuilder toString_({String? message}) {
    // Use the toString() transformer from transformers.dart (imported unprefixed)
    // but qualify via a helper variable to avoid confusion with Object.toString.
    if (_chain.coercedToString) return StringBuilder(chain: _chain);
    _chain.setTransform(_CoercionKind.string_, (child) => tr.toString(child));
    return StringBuilder(chain: _chain);
  }

  // Additional primitive pivots (drop previous constraints like other pivots)
  NumberBuilder toNum() {
    if (_chain.coercedToDouble || _chain.coercedToInt) return NumberBuilder(chain: _chain);
    _chain.setTransform(_CoercionKind.double_, (child) => tr.toNum(child));
    return NumberBuilder(chain: _chain);
  }

  // For BigInt we reuse NumberBuilder semantics but user must add BigInt-specific constraints manually.
  NumberBuilder toBigInt() {
    // Represent BigInt coercion using double_ slot to avoid new enum value (keeps simplicity)
    if (_chain.coercedToDouble) return NumberBuilder(chain: _chain);
    _chain.setTransform(_CoercionKind.double_, (child) => tr.toBigInt(child));
    return NumberBuilder(chain: _chain);
  }

  // DateOnly pivot (DateTime truncated to midnight)
  GenericBuilder<DateTime> toDateOnly() {
    _chain.setTransform(_CoercionKind.string_, (child) => tr.toDateOnly(child));
    return GenericBuilder<DateTime>(chain: _chain);
  }

  // JSON decode pivot (Map/List)
  JsonDecodedBuilder toJson() {
    if (_chain.coercedToJson) return JsonDecodedBuilder(chain: _chain);
    _chain.setTransform(_CoercionKind.json_, (child) => tr.toJsonDecoded(child));
    return JsonDecodedBuilder(chain: _chain);
  }

  // DateTime pivot (string -> DateTime parse)
  DateTimeBuilder toDateTime() {
    if (_chain.coercedToDateTime) return DateTimeBuilder(chain: _chain);
    _chain.setTransform(_CoercionKind.datetime_, (child) => tr.toDateTime(child));
    return DateTimeBuilder(chain: _chain);
  }

  // Custom pivot for extensibility
  GenericBuilder<dynamic> use(CustomPivot pivot) {
    _chain.setTransform(_CoercionKind.custom, pivot.transformer, dropPre: pivot.dropPre);
    return GenericBuilder<dynamic>(chain: _chain);
  }
}
mixin LengthMixin<B extends _BaseBuilder<B, T>, T> on _BaseBuilder<B, T> {
  B length(List<IValidator> lengthValidators, {String? message}) {
    return add(esk.length(lengthValidators), message: message);
  }

  B lengthMin(int min, {String? message}) {
    return length([isGte(min)], message: message);
  }

  B lengthMax(int max, {String? message}) {
    return length([isLte(max)], message: message);
  }

  B lengthRange(int min, int max, {String? message}) {
    return length([isInRange(min, max)], message: message);
  }
}
mixin EmptyMixin<B extends _BaseBuilder<B, T>, T> on _BaseBuilder<B, T> {
  B empty({String? message}) {
    return add(isEmpty(), message: message);
  }
}
mixin ComparisonMixin<B extends _BaseBuilder<B, T>, T> on _BaseBuilder<B, T> {}
mixin ContainsMixin<B extends _BaseBuilder<B, T>, T> on _BaseBuilder<B, T> {
  B contains(value, {String? message}) {
    return add(esk.contains(value), message: message ?? 'A value that contains value: $value');
  }
}

mixin BoolMixin<B extends _BaseBuilder<B, T>, T> on _BaseBuilder<B, T> {
  B isTrue({String message = 'true'}) {
    return add(isEq(true), message: message);
  }
}
mixin NumberMixin<B extends _BaseBuilder<B, T>, T> on _BaseBuilder<B, T> {
  B lt(num n, {String? message}) {
    return add(isLt(n), message: message);
  }

  B lte(num n, {String? message}) {
    return add(isLte(n), message: message);
  }

  B gt(num n, {String? message}) {
    return add(isGt(n), message: message);
  }

  B gte(num n, {String? message}) {
    return add(isGte(n), message: message);
  }

  B between(num min, num max, {String? message}) {
    return add(isInRange(min, max), message: message);
  }
}
mixin StringMixin<B extends _BaseBuilder<B, T>, T> on _BaseBuilder<B, T> {
  B matches(RegExp pattern, {String? message}) {
    return add(stringMatchesPattern(pattern), message: message);
  }

  B email({String? message}) {
    return add($isEmail, message: message);
  }

  B lowerCase({String? message}) {
    return add(isLowerCase(), message: message);
  }

  B upperCase({String? message}) {
    return add(isUpperCase(), message: message);
  }

  B url({String? message, bool strict = false}) {
    return add(isUrl(strict: strict), message: message);
  }

  B strictUrl({String? message}) {
    return url(message: message, strict: true);
  }

  B intString({String? message}) {
    return add($isIntString, message: message);
  }

  B doubleString({String? message}) {
    return add($isDoubleString, message: message);
  }

  B numString({String? message}) {
    return add($isNumString, message: message);
  }

  B boolString({String? message}) {
    return add($isBoolString, message: message);
  }

  B isDate({String? message}) {
    return add($isDate, message: message);
  }

  // --- Normalizers via transformer helpers (string-preserving) ---
  B trim() => wrap((c) => tr.trimString(c));
  B collapseWhitespace() => wrap((c) => tr.collapseWhitespace(c));
  B toLowerCase() => wrap((c) => tr.toLowerCaseString(c));
  B toUpperCase() => wrap((c) => tr.toUpperCaseString(c));
}
mixin MapMixin<B extends _BaseBuilder<B, T>, T> on _BaseBuilder<B, T> {
  B strict(Map<String, IValidator> schema) {
    return add(eskemaStrict(schema));
  }

  B schema(Map<String, IValidator> schema) {
    return add(eskema(schema));
  }

  B containsKey(key, {String? message}) {
    return add(esk.containsKey(key), message: message ?? 'A value that contains key: $key');
  }

  // Map/object transformers
  B pick(Iterable<String> keys) {
    return wrap((c) => tr.pickKeys(keys, c));
  }

  B pluck(String key) {
    // Keep backward type (MapBuilder) to allow chaining map operations; provide
    // a separate pluckValue() that returns a GenericBuilder for further numeric/string ops.
    _chain.wrap((child) => tr.pluckKey(key, child));
    return _self;
  }

  GenericBuilder<dynamic> pluckValue(String key) {
    // Pivot value early so subsequent coercions (e.g., toIntStrict) see the plucked scalar.
    // Also add a containsKey guard in pre-validators for clearer error when missing.
    add(esk.containsKey(key));
    _chain.addPrefix((child) => tr.pluckKey(key, child));
    return GenericBuilder<dynamic>(chain: _chain);
  }

  B flattenKeys([String delimiter = '.']) {
    return wrap((c) => tr.flattenMapKeys(delimiter, c));
  }
}

// DateTime specific comparisons & helpers
mixin DateTimeMixin<B extends _BaseBuilder<B, T>, T> on _BaseBuilder<B, T> {
  B before(DateTime dt, {bool inclusive = false, String? message}) {
    return add(isDateBefore(dt, inclusive: inclusive), message: message);
  }

  B after(DateTime dt, {bool inclusive = false, String? message}) {
    return add(isDateAfter(dt, inclusive: inclusive), message: message);
  }

  B betweenDates(DateTime start, DateTime end,
      {bool inclusiveStart = true, bool inclusiveEnd = true, String? message}) {
    assert(!end.isBefore(start), 'end must be >= start');
    return add(
        isDateBetween(start, end, inclusiveStart: inclusiveStart, inclusiveEnd: inclusiveEnd),
        message: message);
  }

  B sameDay(DateTime dt, {String? message}) {
    return add(isDateSameDay(dt), message: message);
  }

  B inPast({bool allowNow = true, String? message}) {
    return add(isDateInPast(allowNow: allowNow), message: message);
  }

  B inFuture({bool allowNow = true, String? message}) {
    return add(isDateInFuture(allowNow: allowNow), message: message);
  }
}

// JSON decoded (Map/List) specific helpers
mixin JsonMixin<B extends _BaseBuilder<B, T>, T> on _BaseBuilder<B, T> {
  B jsonContainer({String? message}) => add(isJsonContainer(), message: message);
  B jsonObject({String? message}) => add(isJsonObject(), message: message);
  B jsonArray({String? message}) => add(isJsonArray(), message: message);
  B jsonRequiresKeys(Iterable<String> keys, {String? message}) =>
      add(jsonHasKeys(keys), message: message);
  B jsonArrayLen({int? min, int? max, String? message}) => add(
        jsonArrayLength(min: min, max: max),
        message: message,
      );
  B jsonArrayEach(IValidator elementValidator, {String? message}) => add(
        jsonArrayEvery(elementValidator),
        message: message,
      );
}
mixin IterableMixin<B extends _BaseBuilder<B, T>, T> on _BaseBuilder<B, T> {
  B each(IValidator elementValidator) {
    return add(listEach(elementValidator));
  }
}

/* ------------------------------- Builders -------------------------- */
/// Base functionality shared by all typed builders.
abstract class _BaseBuilder<B extends _BaseBuilder<B, T>, T> {
  final Chain _chain;
  bool _negated;

  bool get negated => _negated;
  set negated(val) {
    _negated = val;
  }

  _BaseBuilder({bool? negated = false, Chain? chain})
      : _chain = chain ?? Chain(),
        _negated = negated ?? false;

  B get _self => this as B;

  /// Return a negated version of the builder
  /// (the negation flag is consumed by the next added validator)
  B get not => _self..negated = true;

  B wrap(IValidator Function(IValidator) fn, {String? message}) {
    _chain.wrap((c) => _maybeAddMessage(_maybeNegate(fn(c)), message));
    return _self..negated = false;
  }

  B add(IValidator validator, {String? message}) {
    _chain.add(_maybeAddMessage(_maybeNegate(validator), message));
    return _self..negated = false;
  }

  /// Mark current chain optional (skipped when key absent).
  B optional({String? message}) {
    return wrap((c) => c.optional(), message: message);
  }

  /// Mark current chain nullable (null accepted as valid).
  B nullable({String? message}) {
    return wrap(
      (c) => c.nullable(),
      message: message,
    );
  }

  /// Override final error message (retains codes).
  B error(String message) {
    return wrap((c) => c > Expectation(message: message));
  }

  B oneOf(Iterable<T> values, {String? message}) {
    return add(isOneOf(values), message: message);
  }

  B eq(T value, {String? message}) {
    return add(isEq(value), message: message ?? value.toString());
  }

  B deepEq(T value, {String? message}) {
    return add(isDeepEq(value), message: message ?? value.toString());
  }

  /// Build resulting validator.
  IValidator build() => _chain.build();

  /// Convenience validate (sync only chain).
  Result validate(dynamic value) => build().validate(value);

  /// Convenience validateAsync (mixed / async).
  Future<Result> validateAsync(dynamic value) => build().validateAsync(value);

  IValidator _maybeAddMessage(IValidator validator, String? message) {
    return (message != null && message.isNotEmpty)
        ? validator > Expectation(message: message)
        : validator;
  }

  IValidator _maybeNegate(IValidator validator) {
    return negated ? esk.not(validator) : validator;
  }
}

class StringBuilder extends _BaseBuilder<StringBuilder, String>
    with
        LengthMixin,
        EmptyMixin,
        ComparisonMixin,
        TransformerMixin,
        StringMixin,
        ContainsMixin {
  StringBuilder({super.negated = false, super.chain}) : super();
}

class NumberBuilder extends _BaseBuilder<NumberBuilder, num>
    with TransformerMixin, NumberMixin, ComparisonMixin {
  NumberBuilder({super.chain}) : super();
}

class IntBuilder extends NumberBuilder {
  IntBuilder({super.chain}) : super();
}

class DoubleBuilder extends NumberBuilder {
  DoubleBuilder({super.chain}) : super();
}

class BoolBuilder extends _BaseBuilder<BoolBuilder, bool> with TransformerMixin, BoolMixin {
  BoolBuilder({super.chain}) : super();
}

class DateTimeBuilder extends _BaseBuilder<DateTimeBuilder, DateTime>
    with TransformerMixin, DateTimeMixin, ComparisonMixin {
  DateTimeBuilder({super.chain}) : super();
}

class IterableBuilder extends _BaseBuilder<IterableBuilder, Iterable>
    with LengthMixin, EmptyMixin, ComparisonMixin, IterableMixin, ContainsMixin {}

class ListBuilder extends IterableBuilder {}

class SetBuilder extends IterableBuilder {}

class MapBuilder extends _BaseBuilder<MapBuilder, Map>
    with TransformerMixin, MapMixin, EmptyMixin, ComparisonMixin {}

class JsonDecodedBuilder extends _BaseBuilder<JsonDecodedBuilder, dynamic>
    with TransformerMixin, JsonMixin, ComparisonMixin, MapMixin, IterableMixin {
  JsonDecodedBuilder({super.chain}) : super();
}

class GenericBuilder<T> extends _BaseBuilder<GenericBuilder<T>, T>
    with
        NumberMixin,
        LengthMixin,
        EmptyMixin,
        ComparisonMixin,
        TransformerMixin,
        StringMixin,
        MapMixin,
        DateTimeMixin,
        JsonMixin {
  GenericBuilder({super.chain});
}

class RootBuilder {
  /// Expect a String; returns a StringBuilder with string‑specific methods.
  StringBuilder string({String? message}) {
    return StringBuilder()..add($isString, message: message);
  }

  /// Expect an int.
  IntBuilder int_({String? message}) {
    return IntBuilder()..add($isInt, message: message);
  }

  /// Expect a double.
  DoubleBuilder double_({String? message}) {
    return DoubleBuilder()..add($isDouble, message: message);
  }

  /// Expect a number (int or double).
  NumberBuilder number({String? message}) {
    return NumberBuilder()..add($isNumber, message: message);
  }

  /// Expect a bool.
  BoolBuilder bool_({String? message}) {
    return BoolBuilder()..add($isBool, message: message);
  }

  /// Expect a Iterable.
  IterableBuilder iterable({String? message}) {
    return IterableBuilder()..add($isIterable, message: message);
  }

  /// Expect a List.
  ListBuilder list({String? message}) {
    return ListBuilder()..add($isList, message: message);
  }

  /// Expect a Map.
  MapBuilder map({String? message}) {
    return MapBuilder()..add($isMap, message: message);
  }

  /// Expect a DateTime.
  DateTimeBuilder dateTime({String? message}) {
    return DateTimeBuilder()..add(isType<DateTime>(), message: message);
  }

  /// Generic type guard (rarely needed; concrete helpers preferred).
  GenericBuilder type<T>({String? message}) {
    return GenericBuilder<T>()..add(isType<T>(), message: message);
  }
}

/// Public entry function.
RootBuilder v() => RootBuilder();
