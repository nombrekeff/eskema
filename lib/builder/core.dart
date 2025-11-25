/// Core builder functionality and chain logic.
///
/// This file contains the fundamental building blocks for the fluent validator builder:
/// - Chain: Internal accumulator for builder chains
/// - CustomPivot: Extensibility mechanism for custom transformations
/// - BaseBuilder: Base functionality shared by all typed builders
library builder.core;

import 'dart:async';

import '../validators.dart';
import '../validator.dart';
import '../expectation.dart';
import '../result.dart';
import '../extensions.dart';
import '../validators.dart' as esk;

/// Internal accumulator for a builder chain.
///
/// This class manages the complex pipeline of validators and transformations in the builder pattern.
/// The chain supports at most one type-changing transformer (coercion) to maintain predictable behavior.
///
/// **Pipeline Structure:**
/// 1. **Prefix transformers** (value pivots like pluckValue, pick keys) - applied first
/// 2. **Pre-coercion validators** - validate the original type
/// 3. **Coercion transformer** - changes the type (optional, at most one)
/// 4. **Post-coercion validators** - validate the coerced type
///
/// **Coercion Rules:**
/// - Only one coercion is allowed per chain
/// - Pre-coercion validators are discarded when coercion is applied (they target the old type)
/// - If multiple coercions are attempted, they are composed or the later one replaces the earlier
/// - Custom coercions can be composed with built-in ones
///
/// Example chain flow:
/// ```dart
/// // Original: {"user": {"name": "Alice", "age": "25"}}
/// pluckValue("user")           // -> {"name": "Alice", "age": "25"}
/// .isMap()                     // pre-coercion validation
/// .toInt("age")                // coercion: String -> int
/// .gt(0)                       // post-coercion validation
/// ```
/// Encapsulates the state of a type coercion in the chain.

class Chain {
  // Validators accumulated BEFORE any type coercion (original type domain).
  IValidator? _preValidators;
  // Validators accumulated AFTER coercion (new type domain).
  IValidator? _postValidators;
  // A prefix transformer applied BEFORE coercion (value pivot like pluckValue / pick / flatten).
  IValidator Function(IValidator child)? _prefix;

  // The active coercion context, if any.
  CoercionContext? _coercion;

  bool get _hasCoercion => _coercion != null;
  bool _isKind(CoercionKind k) => _coercion?.kind == k;

  /// Adds a validator to the appropriate position in the chain.
  void add(IValidator v) {
    if (_hasCoercion) {
      _postValidators = _postValidators == null ? v : (_postValidators! & v);
    } else {
      _preValidators = _preValidators == null ? v : (_preValidators! & v);
    }
  }

  /// Wraps all validators at the current position with a wrapper function.
  void wrap(IValidator Function(IValidator current) fn) {
    if (_hasCoercion) {
      if (_postValidators != null) _postValidators = fn(_postValidators!);
    } else if (_preValidators != null) {
      _preValidators = fn(_preValidators!);
    }
  }

  /// Sets a type coercion transformer with optional pre-validator preservation.
  void setTransform(
    CoercionKind kind,
    IValidator Function(IValidator child) transformer, {
    bool dropPre = true,
  }) {
    if (_coercion == null) {
      // First pivot
      _coercion = CoercionContext(kind, transformer, preservePreValidators: !dropPre);
      if (dropPre) _preValidators = null;
      return;
    }

    // Subsequent pivot: compose if either current or previous is custom; replace only if both are built-in
    final currentKind = _coercion!.kind;
    if (kind == CoercionKind.custom || currentKind == CoercionKind.custom) {
      final previous = _coercion!.transformer;
      final composed = (IValidator child) => previous(transformer(child));
      // Preserve the 'preservePreValidators' setting from the first coercion
      _coercion = CoercionContext(kind, composed,
          preservePreValidators: _coercion!.preservePreValidators);
    } else {
      // Replace
      _coercion = CoercionContext(kind, transformer, preservePreValidators: !dropPre);
      if (dropPre) _preValidators = null;
    }
    _postValidators = null;
  }

  /// Adds a prefix value-mapping validator that runs before coercion and post-validators.
  void addPrefix(IValidator Function(IValidator child) prefix) {
    if (_prefix == null) {
      _prefix = prefix;
    } else {
      final existing = _prefix!;
      _prefix = (child) => existing(prefix(child));
    }
  }

  /// Builds the final validator by composing all chain elements in the correct order.
  IValidator build() {
    IValidator core;

    IValidator tail() {
      if (_coercion != null) {
        final ctx = _coercion!;
        final child = _postValidators ?? Validator.valid;
        final coerced = ctx.transformer(child);

        if (ctx.preservePreValidators && _preValidators != null) {
          return _preValidators! & coerced;
        }
        return coerced;
      }
      return _preValidators ?? Validator.valid;
    }

    core = _prefix != null ? _prefix!(tail()) : tail();
    return core;
  }

  Chain copyWith() {
    final c = Chain();
    c._preValidators = _preValidators?.copyWith();
    c._postValidators = _postValidators?.copyWith();
    c._prefix = _prefix;
    c._coercion = _coercion; // CoercionContext is immutable
    return c;
  }

  // Readable getters for coercion state
  bool isKind(CoercionKind k) => _isKind(k);
}

/// Kind of coercion applied to the chain (single pivot allowed).
enum CoercionKind { int_, double_, bool_, string_, datetime_, json_, custom }

class CoercionContext {
  final CoercionKind kind;
  final IValidator Function(IValidator child) transformer;
  final bool preservePreValidators;

  CoercionContext(this.kind, this.transformer, {required this.preservePreValidators});
}

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

/// Base functionality shared by all typed builders.
///
/// This class provides the core builder pattern functionality including:
/// - Method chaining for fluent API
/// - Negation support (using `not`)
/// - Error message customization
/// - Optional/nullable modifiers
/// - Final validator building
///
/// **Builder Pattern Usage:**
/// ```dart
/// // Basic chaining
/// final validator = v().string().lengthMin(5).email().build();
///
/// // Negation
/// final notEmpty = v().string().not().empty().build();
///
/// // Custom error messages
/// final customError = v().string().lengthMin(5).error("Name too short").build();
///
/// // Optional fields
/// final optionalField = v().string().optional().lengthMin(2).build();
/// ```
class BaseBuilder<B extends BaseBuilder<B, T>, T> extends IValidator {
  BaseBuilder({bool negated = false, Chain? chain, bool? optional, bool? nullable})
      : chain = chain ?? Chain(),
        _negated = negated,
        _optional = optional ?? false,
        _nullable = nullable ?? false;

  final Chain chain;
  bool _negated;
  bool _optional;
  bool _nullable;

  bool get negated => _negated;
  set negated(val) {
    _negated = val;
  }

  B get self => this as B;

  /// Return a negated version of the builder
  /// (the negation flag is consumed by the next added validator)
  B get not => self..negated = true;

  /// Wrap the current chain with a custom function.
  B wrap(IValidator Function(IValidator) fn, {String? message}) {
    chain.wrap((c) => _maybeAddMessage(_maybeNegate(fn(c)), message));
    return self..negated = false;
  }

  /// Add a validator to the chain.
  B add(IValidator validator, {String? message}) {
    chain.add(_maybeAddMessage(_maybeNegate(validator), message));
    return self..negated = false;
  }

  /// Mark current chain optional (skipped when key absent).
  @override
  B optional<_>() {
    this._optional = true;
    return self;
  }

  /// Mark current chain nullable (null accepted as valid).
  @override
  B nullable<_>({String? message}) {
    this._nullable = true;
    return self;
  }

  /// Override final error message (retains codes).
  B error(String message) {
    return wrap((c) => c > Expectation(message: message));
  }

  /// Require the value to be one of the specified options.
  B oneOf(Iterable<T> values, {String? message}) {
    return add(isOneOf(values), message: message);
  }

  /// Require the value to be equal to the specified value.
  B eq(T value, {String? message}) {
    return add(isEq(value), message: message ?? value.toString());
  }

  /// Require the value to be deeply equal to the specified value.
  B deepEq(T value, {String? message}) {
    return add(isDeepEq(value), message: message ?? value.toString());
  }

  /// Build resulting validator.
  IValidator build() => _maybeNullOrOptional(chain.build());

  /// Convenience validate (sync only chain).
  @override
  Result validate(dynamic value, {bool? exists}) {
    return build().validate(value, exists: exists ?? true);
  }

  /// Convenience validateAsync (mixed / async).
  @override
  Future<Result> validateAsync(dynamic value, {bool? exists}) {
    return build().validateAsync(value, exists: exists ?? true);
  }

  @override
  FutureOr<Result> validator(value) {
    // Short-circuit here for mid-chain nullable usage when the builder is consumed
    // directly as an IValidator and the caller invokes `validator()` (bypassing
    // the IValidator.validate() null handling logic). This happens inside some
    // composite validators (e.g. map/field validators) that call child.validator
    // for performance. Without this, a chain like `builder().string().nullable().lengthMin(2)`
    // would still run the `string()` validator on null and incorrectly fail.
    if (value == null && _nullable) {
      return Result.valid(value);
    }

    return build().validator(value);
  }

  IValidator _maybeNullOrOptional(IValidator validator) {
    return validator.copyWith(
      nullable: _nullable,
      optional: _optional,
    );
  }

  IValidator _maybeAddMessage(IValidator validator, String? message) {
    return (message != null && message.isNotEmpty)
        ? validator > Expectation(message: message)
        : validator;
  }

  IValidator _maybeNegate(IValidator validator) {
    return negated ? esk.not(validator) : validator;
  }

  @override
  IValidator copyWith({bool? nullable, bool? optional}) {
    return BaseBuilder<B, T>(
      negated: negated,
      chain: chain.copyWith(),
      optional: optional ?? _optional,
      nullable: nullable ?? _nullable,
    );
  }
}
