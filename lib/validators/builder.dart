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

import 'dart:async';
import 'package:eskema/eskema.dart';
import 'package:eskema/eskema.dart' as esk;

/// Internal accumulator shared across all builder instances in a chain.
class _Chain {
  IValidator? _acc;

  void add(IValidator v) {
    _acc = _acc == null ? v : (_acc! & v);
  }

  IValidator build() => _acc ?? Validator.valid;
  bool get isEmpty => _acc == null;
  void wrap(IValidator Function(IValidator current) fn) {
    if (_acc != null) _acc = fn(_acc!);
  }
}

/// Base functionality shared by all typed builders.
abstract class _BaseBuilder<B extends _BaseBuilder<B, T>, T> {
  final _Chain _chain;
  _BaseBuilder(this._chain);

  B get _self => this as B;

  /// Mark current chain optional (skipped when key absent).
  B optional() {
    _chain.wrap((c) => c.optional());
    return _self;
  }

  /// Mark current chain nullable (null accepted as valid).
  B nullable() {
    _chain.wrap((c) => c.nullable());
    return _self;
  }

  /// Override final error message (retains codes).
  B error(String message) {
    _chain.wrap((c) => c > Expectation(message: message));
    return _self;
  }

  /// Add custom synchronous predicate.
  B custom(
    bool Function(dynamic v) test,
    String message, {
    String code = 'logic.predicate_failed',
  }) {
    final v = validator(
      test,
      (value) => expectation(message, value, null, code),
    );
    _chain.add(v);
    return _self;
  }

  /// Add custom asynchronous predicate.
  B async(
    Future<bool> Function(dynamic v) test,
    String message, {
    String code = 'logic.predicate_failed',
  }) {
    final v = Validator((value) async {
      final ok = await test(value);
      return ok
          ? Result.valid(value)
          : expectation(message, value, null, code).toInvalidResult();
    });
    _chain.add(v);
    return _self;
  }

  B oneOf(Iterable<T> values) {
    _chain.add(isOneOf(values));
    return _self;
  }

  /// Build resulting validator.
  IValidator build() => _chain.build();

  /// Convenience validate (sync only chain).
  Result validate(dynamic value) => build().validate(value);

  /// Convenience validateAsync (mixed / async).
  Future<Result> validateAsync(dynamic value) => build().validateAsync(value);
}

mixin TransformerMixin<B extends _BaseBuilder<B, T>, T> on _BaseBuilder<B, T> {
  B toIntCoerce() {
    _chain.wrap((c) => toInt(c));
    return _self;
  }

  B toDoubleCoerce() {
    _chain.wrap((c) => toDouble(c));
    return _self;
  }

  B toStringCoerce() {
    _chain.wrap((c) => esk.toString(c));
    return _self;
  }
}
mixin LengthMixin<B extends _BaseBuilder<B, T>, T> on _BaseBuilder<B, T> {
  // Length constraints
  B lengthMin(int min) {
    _chain.add(length([isGte(min)]));
    return _self;
  }

  B lengthMax(int max) {
    _chain.add(length([isLte(max)]));
    return _self;
  }

  B lengthRange(int min, int max) {
    _chain.add(length([isInRange(min, max)]));
    return _self;
  }
}
mixin EmptyChecksMixin<B extends _BaseBuilder<B, T>, T> on _BaseBuilder<B, T> {
  B notEmpty() {
    _chain.add(isNotEmpty());
    return _self;
  }

  B empty() {
    _chain.add(isEmpty());
    return _self;
  }
}
mixin NumberChecksMixin<B extends _BaseBuilder<B, T>, T> on _BaseBuilder<B, T> {
  B lt(num n) {
    _chain.add(isLt(n));
    return _self;
  }

  B lte(num n) {
    _chain.add(isLte(n));
    return _self;
  }

  B gt(num n) {
    _chain.add(isGt(n));
    return _self;
  }

  B gte(num n) {
    _chain.add(isGte(n));
    return _self;
  }

  B between(num min, num max) {
    _chain.add(isInRange(min, max));
    return _self;
  }
}
mixin StringChecksMixin<B extends _BaseBuilder<B, T>, T> on _BaseBuilder<B, T> {
  B matches(RegExp pattern) {
    _chain.add(stringMatchesPattern(pattern));
    return _self;
  }

  // Future extension examples (uncomment / implement as needed):
  // StringBuilder email() { _chain.add(isEmail()); return this; }
  // StringBuilder url() { _chain.add(isUrl()); return this; }
}
mixin MapChecksMixin<B extends _BaseBuilder<B, T>, T> on _BaseBuilder<B, T> {
  B strict(Map<String, IValidator> schema) {
    _chain.add(eskemaStrict(schema));
    return _self;
  }

  B schema(Map<String, IValidator> schema) {
    _chain.add(eskema(schema));
    return _self;
  }
}
mixin IterableMixin<B extends _BaseBuilder<B, T>, T> on _BaseBuilder<B, T> {
  B each(IValidator elementValidator) {
    _chain.add(listEach(elementValidator));
    return _self;
  }
}

/* ------------------------------- Builders -------------------------- */

/// String builder.
class StringBuilder extends _BaseBuilder<StringBuilder, String>
    with LengthMixin, EmptyChecksMixin, TransformerMixin, StringChecksMixin {
  StringBuilder(super.chain);
}

/// Generic number builder (int or double).
class NumberBuilder extends _BaseBuilder<NumberBuilder, num>
    with TransformerMixin, NumberChecksMixin {
  NumberBuilder(super.chain);
}

/// Specialized int builder (currently reuses NumberBuilder operations).
class IntBuilder extends NumberBuilder {
  IntBuilder(super.c);
  // Additional int‑specific helpers could go here (e.g., even(), odd()).
}

/// Specialized double builder (placeholder for future float-specific ops).
class DoubleBuilder extends NumberBuilder {
  DoubleBuilder(super.c);
}

class BoolBuilder extends _BaseBuilder<BoolBuilder, bool> with TransformerMixin {
  BoolBuilder(super.chain);

  BoolBuilder isTrue({String message = 'expected true'}) {
    _chain.add(validator(
      (v) => v == true,
      (v) => expectation(message, v, null, 'logic.predicate_failed'),
    ));
    return this;
  }

  BoolBuilder isFalse({String message = 'expected false'}) {
    _chain.add(validator(
      (v) => v == false,
      (v) => expectation(message, v, null, 'logic.predicate_failed'),
    ));
    return this;
  }
}

class IterableBuilder extends _BaseBuilder<IterableBuilder, Iterable>
    with LengthMixin, EmptyChecksMixin, IterableMixin {
  IterableBuilder(super.chain);
}

class ListBuilder extends IterableBuilder {
  ListBuilder(super.chain);
  // Add list specific stuff here.
}

class SetBuilder extends IterableBuilder {
  SetBuilder(super.chain);
  // Add set specific stuff here.
}

class MapBuilder extends _BaseBuilder<MapBuilder, Map> with TransformerMixin, MapChecksMixin {
  MapBuilder(super.chain);
}

class GenericBuilder<T> extends _BaseBuilder<GenericBuilder<T>, T>
    with
        NumberChecksMixin,
        LengthMixin,
        EmptyChecksMixin,
        TransformerMixin,
        StringChecksMixin,
        MapChecksMixin {
  GenericBuilder(super.chain);
}

/// Entry builder prior to selecting a concrete type.
class RootBuilder {
  /// Expect a String; returns a StringBuilder with string‑specific methods.
  StringBuilder string() {
    return StringBuilder(_Chain()..add($isString));
  }

  /// Expect an int.
  IntBuilder int_() {
    return IntBuilder(_Chain()..add($isInt));
  }

  /// Expect a double.
  DoubleBuilder double_() {
    return DoubleBuilder(_Chain()..add($isDouble));
  }

  /// Expect a number (int or double).
  NumberBuilder number() {
    return NumberBuilder(_Chain()..add($isNumber));
  }

  /// Expect a bool.
  BoolBuilder bool_() {
    return BoolBuilder(_Chain()..add($isBool));
  }

  /// Expect a List.
  ListBuilder list() {
    return ListBuilder(_Chain()..add($isList));
  }

  /// Expect a Map.
  MapBuilder map() {
    return MapBuilder(_Chain()..add($isMap));
  }

  /// Generic type guard (rarely needed; concrete helpers preferred).
  RootBuilder type<T>() {
    GenericBuilder<T>(_Chain()..add(isType<T>()));
    return this;
  }
}

/// Public entry function.
RootBuilder v() => RootBuilder();
