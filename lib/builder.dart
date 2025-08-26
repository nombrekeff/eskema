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

  B wrap(IValidator Function(IValidator) fn, {String? message}) {
    _chain.wrap(
      (c) => message != null ? fn(c) > Expectation(message: message) : fn(c),
    );
    return _self;
  }

  B add(IValidator validator, {String? message}) {
    _chain.add(
      message != null ? validator > Expectation(message: message) : validator,
    );
    return _self;
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

    return add(v);
  }

  B oneOf(Iterable<T> values, {String? message}) {
    return add(isOneOf(values), message: message);
  }

  /// Build resulting validator.
  IValidator build() => _chain.build();

  /// Convenience validate (sync only chain).
  Result validate(dynamic value) => build().validate(value);

  /// Convenience validateAsync (mixed / async).
  Future<Result> validateAsync(dynamic value) => build().validateAsync(value);
}

mixin TransformerMixin<B extends _BaseBuilder<B, T>, T> on _BaseBuilder<B, T> {
  B toIntCoerce({String? message}) {
    return wrap((c) => toInt(c), message: message);
  }

  B toDoubleCoerce({String? message}) {
    return wrap((c) => toDouble(c), message: message);
  }

  B toStringCoerce({String? message}) {
    return wrap((c) => esk.toString(c), message: message);
  }
}
mixin LengthMixin<B extends _BaseBuilder<B, T>, T> on _BaseBuilder<B, T> {
  // Length constraints
  B lengthMin(int min, {String? message}) {
    return add(length([isGte(min)]), message: message);
  }

  B lengthMax(int max, {String? message}) {
    return add(length([isLte(max)]), message: message);
  }

  B lengthRange(int min, int max, {String? message}) {
    return add(length([isInRange(min, max)]), message: message);
  }
}
mixin ChecksMixin<B extends _BaseBuilder<B, T>, T> on _BaseBuilder<B, T> {
  B notEmpty({String? message}) {
    return add(isNotEmpty(), message: message);
  }

  B empty({String? message}) {
    return add(isEmpty(), message: message);
  }

  B isTrue({String message = 'true'}) {
    return add(isEq(true), message: message);
  }

  B isFalse({String message = 'false'}) {
    return add(isEq(false), message: message);
  }
}
mixin NumberChecksMixin<B extends _BaseBuilder<B, T>, T> on _BaseBuilder<B, T> {
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
mixin StringChecksMixin<B extends _BaseBuilder<B, T>, T> on _BaseBuilder<B, T> {
  B matches(RegExp pattern, {String? message}) {
    return add(stringMatchesPattern(pattern), message: message);
  }

  // Future extension examples (uncomment / implement as needed):
  // StringBuilder email() { return add(isEmail()); }
  // StringBuilder url() { return add(isUrl()); }
}
mixin MapChecksMixin<B extends _BaseBuilder<B, T>, T> on _BaseBuilder<B, T> {
  B strict(Map<String, IValidator> schema) {
    return add(eskemaStrict(schema));
  }

  B schema(Map<String, IValidator> schema) {
    return add(eskema(schema));
  }
}
mixin IterableMixin<B extends _BaseBuilder<B, T>, T> on _BaseBuilder<B, T> {
  B each(IValidator elementValidator) {
    return add(listEach(elementValidator));
  }
}

/* ------------------------------- Builders -------------------------- */

class StringBuilder extends _BaseBuilder<StringBuilder, String>
    with LengthMixin, ChecksMixin, TransformerMixin, StringChecksMixin {
  StringBuilder(super.chain);
}

class NumberBuilder extends _BaseBuilder<NumberBuilder, num>
    with TransformerMixin, NumberChecksMixin {
  NumberBuilder(super.chain);
}

class IntBuilder extends NumberBuilder {
  IntBuilder(super.c);
  // Additional int‑specific helpers could go here (e.g., even(), odd()).
}

class DoubleBuilder extends NumberBuilder {
  DoubleBuilder(super.c);
}

class BoolBuilder extends _BaseBuilder<BoolBuilder, bool> with TransformerMixin {
  BoolBuilder(super.chain);
}

class IterableBuilder extends _BaseBuilder<IterableBuilder, Iterable>
    with LengthMixin, ChecksMixin, IterableMixin {
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
        ChecksMixin,
        TransformerMixin,
        StringChecksMixin,
        MapChecksMixin {
  GenericBuilder(super.chain);
}

class RootBuilder {
  /// Expect a String; returns a StringBuilder with string‑specific methods.
  StringBuilder string({String? message}) {
    return StringBuilder(
      _Chain()
        ..add(
          message != null ? $isString > Expectation(message: message) : $isString,
        ),
    );
  }

  /// Expect an int.
  IntBuilder int_({String? message}) {
    return IntBuilder(
      _Chain()
        ..add(
          message != null ? $isInt > Expectation(message: message) : $isInt,
        ),
    );
  }

  /// Expect a double.
  DoubleBuilder double_({String? message}) {
    return DoubleBuilder(
      _Chain()
        ..add(
          message != null ? $isDouble > Expectation(message: message) : $isDouble,
        ),
    );
  }

  /// Expect a number (int or double).
  NumberBuilder number({String? message}) {
    return NumberBuilder(
      _Chain()
        ..add(
          message != null ? $isNumber > Expectation(message: message) : $isNumber,
        ),
    );
  }

  /// Expect a bool.
  BoolBuilder bool_({String? message}) {
    return BoolBuilder(
      _Chain()
        ..add(
          message != null ? $isBool > Expectation(message: message) : $isBool,
        ),
    );
  }

  /// Expect a List.
  ListBuilder list({String? message}) {
    return ListBuilder(
      _Chain()
        ..add(
          message != null ? $isList > Expectation(message: message) : $isList,
        ),
    );
  }

  /// Expect a Map.
  MapBuilder map({String? message}) {
    return MapBuilder(
      _Chain()
        ..add(
          message != null ? $isMap > Expectation(message: message) : $isMap,
        ),
    );
  }

  /// Generic type guard (rarely needed; concrete helpers preferred).
  GenericBuilder type<T>({String? message}) {
    return GenericBuilder<T>(
      _Chain()
        ..add(
          message != null ? isType<T>() > Expectation(message: message) : isType<T>(),
        ),
    );
  }
}

/// Public entry function.
RootBuilder v() => RootBuilder();
