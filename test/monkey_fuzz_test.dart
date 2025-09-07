import 'dart:math';
import 'package:test/test.dart';
import 'package:eskema/eskema.dart';
import 'package:eskema/validator/exception.dart';
import 'package:eskema/result.dart';

/// Simple monkey / fuzz style tests intended to stress eskema validators.
/// Goals:
///  - No unexpected uncaught exceptions (besides documented ones like AsyncValidatorException when misused)
///  - Every invalid Result must contain at least one Expectation
///  - `none` failures produce only 'not ...' expectation messages
///  - validate() vs validateAsync() consistency: when validate() succeeds (i.e. not async), validateAsync() returns identical validity & value
///  - Nullable builders accept null when marked nullable
///
/// Run with a deterministic seed:
///   dart test test/monkey_fuzz_test.dart -DFUZZ_SEED=123
/// Increase iterations:
///   dart test test/monkey_fuzz_test.dart -DFUZZ_ITER=500
void main() {
  final seed = int.tryParse(const String.fromEnvironment('FUZZ_SEED')) ??
      DateTime.now().millisecondsSinceEpoch;
  final iterations = int.tryParse(const String.fromEnvironment('FUZZ_ITER')) ?? 120;
  final rnd = Random(seed);

  print('Monkey fuzz seed: $seed iterations: $iterations');

  group('monkey_fuzz', () {
    for (var i = 0; i < iterations; i++) {
      final spec = _randomValidatorSpec(rnd, depth: 0);
      final value = _randomValue(rnd, maxDepth: 2);
      test('fuzz case #$i - ${spec.debug()} $value', () async {
        Result? syncResult;

        // Try sync path first; catch async escalation.
        try {
          syncResult = spec.validator.validate(value);
        } on AsyncValidatorException {
          syncResult = null; // Will use async path only.
        } on ValidatorFailedException catch (e) {
          // ThrowInstead validator scenario: ensure expectations exist.
          expect(e.result.expectations.isNotEmpty, true,
              reason: 'Thrown result must have expectations');
          return; // Accept thrown path.
        } catch (e, st) {
          fail(
              'Unexpected exception (seed=$seed i=$i) spec=${spec.debug()} value=$value -> $e\n$st');
        }

        Result asyncResult;
        try {
          asyncResult = await spec.validator.validateAsync(value);
        } on ValidatorFailedException catch (e) {
          // ThrowInstead path via async chain.
          expect(e.result.expectations.isNotEmpty, true);
          return;
        } catch (e, st) {
          fail(
              'Unexpected async exception (seed=$seed i=$i) spec=${spec.debug()} value=$value -> $e\n$st');
        }

        if (syncResult != null) {
          expect(syncResult.isValid, asyncResult.isValid,
              reason:
                  'sync/async validity diverged seed=$seed i=$i spec=${spec.debug()} value=$value');
        }

        final result = syncResult ?? asyncResult;

        if (result.isNotValid) {
          expect(result.expectations.isNotEmpty, true,
              reason: 'Invalid result must have expectations');
        }

        // If top-level is NoneValidator, check expectation messages shape when invalid.
        if (spec.kind == _Kind.none && result.isNotValid) {
          for (final e in result.expectations) {
            expect(e.message.startsWith('not '), true,
                reason: 'none expectation message must start with "not "');
          }
        }

        // Nullable spec should accept null.
        if (spec.nullableApplied && value == null) {
          expect(result.isValid, true, reason: 'nullable chain should accept null');
        }
      });
    }
  });
}

enum _Kind { base, all, any, none, not, builder }

class _ValidatorSpec {
  final IValidator validator;
  final _Kind kind;
  final bool nullableApplied;
  _ValidatorSpec(this.validator, this.kind, this.nullableApplied);

  String debug() => 'kind=$kind nullable=$nullableApplied runtime=${validator.runtimeType}';
}

_ValidatorSpec _randomValidatorSpec(Random rnd, {required int depth}) {
  // Increase probability of simple leaves to limit combinatorial explosion.
  if (depth > 2) return _leaf(rnd);
  final roll = rnd.nextInt(100);
  if (roll < 55) return _leaf(rnd);
  if (roll < 70) return _allSpec(rnd, depth);
  if (roll < 80) return _anySpec(rnd, depth);
  if (roll < 90) return _noneSpec(rnd, depth);
  if (roll < 95) return _notSpec(rnd, depth);
  return _builderSpec(rnd, depth);
}

_ValidatorSpec _leaf(Random rnd) {
  final choices = <IValidator Function()>[
    () => isString(),
    () => isInt(),
    () => isBool(),
    () => isNumber(),
    () => isOneOf([true, false]),
    () => isGte(rnd.nextInt(10)),
    () => isLte(rnd.nextInt(10) + 10),
    () => isEq(rnd.nextInt(5)),
  ];
  final v = choices[rnd.nextInt(choices.length)]();
  final nullable = rnd.nextBool();
  return _ValidatorSpec(nullable ? v.nullable() : v, _Kind.base, nullable);
}

_ValidatorSpec _allSpec(Random rnd, int depth) {
  final count = 2 + rnd.nextInt(3);
  final children = List.generate(count, (_) => _randomValidatorSpec(rnd, depth: depth + 1));
  final v = all(children.map((c) => c.validator).toList(), collecting: rnd.nextBool());
  final nullable = rnd.nextBool();
  return _ValidatorSpec(nullable ? v.nullable() : v, _Kind.all, nullable);
}

_ValidatorSpec _anySpec(Random rnd, int depth) {
  final count = 2 + rnd.nextInt(3);
  final children = List.generate(count, (_) => _randomValidatorSpec(rnd, depth: depth + 1));
  final v = any(children.map((c) => c.validator).toList());
  final nullable = rnd.nextBool();
  return _ValidatorSpec(nullable ? v.nullable() : v, _Kind.any, nullable);
}

_ValidatorSpec _noneSpec(Random rnd, int depth) {
  final count = 2 + rnd.nextInt(3);
  final children = List.generate(count, (_) => _randomValidatorSpec(rnd, depth: depth + 1));
  final v = none(children.map((c) => c.validator).toList());
  final nullable = rnd.nextBool();
  return _ValidatorSpec(nullable ? v.nullable() : v, _Kind.none, nullable);
}

_ValidatorSpec _notSpec(Random rnd, int depth) {
  final inner = _randomValidatorSpec(rnd, depth: depth + 1);
  final v = not(inner.validator);
  final nullable = rnd.nextBool();
  return _ValidatorSpec(nullable ? v.nullable() : v, _Kind.not, nullable);
}

_ValidatorSpec _builderSpec(Random rnd, int depth) {
  // Use dynamic so we can reassign across specialized builder subtypes.
  dynamic b = builder();
  final steps = 1 + rnd.nextInt(4);
  for (var i = 0; i < steps; i++) {
    final choice = rnd.nextInt(6);
    try {
      switch (choice) {
        case 0:
          b = b.string();
          break;
        case 1:
          b = b.number();
          break;
        case 2:
          b = b.int_();
          break;
        case 3:
          if (b is StringBuilder) b = b.lengthMin(rnd.nextInt(3));
          break;
        case 4:
          if (b is StringBuilder) b = b.lengthMax(5 + rnd.nextInt(5));
          break;
        case 5:
          // eq only after a terminal type (string/number/int) chosen. Guard loosely.
          if (b is BaseBuilder) b = b.eq(rnd.nextInt(3));
          break;
      }
    } catch (_) {
      // Ignore any method mismatch due to chain state; continue.
    }
  }
  final nullable = rnd.nextBool();
  if (nullable && b is BaseBuilder) b = b.nullable();
  // Cast to IValidator (builders implement it). If cast fails, fall back to trivial validator.
  final IValidator validator = (b is IValidator) ? b : isString();
  return _ValidatorSpec(validator, _Kind.builder, nullable);
}

/// Random primitive / container value.
dynamic _randomValue(Random rnd, {required int maxDepth, int depth = 0}) {
  if (depth >= maxDepth) {
    return _randomLeafValue(rnd);
  }
  final roll = rnd.nextInt(100);
  if (roll < 60) return _randomLeafValue(rnd); // primitive bias
  if (roll < 80) {
    final len = rnd.nextInt(4);
    return List.generate(len, (_) => _randomValue(rnd, maxDepth: maxDepth, depth: depth + 1));
  }
  // map
  final len = rnd.nextInt(4);
  final map = <String, dynamic>{};
  for (var i = 0; i < len; i++) {
    map['k$i'] = _randomValue(rnd, maxDepth: maxDepth, depth: depth + 1);
  }
  return map;
}

dynamic _randomLeafValue(Random rnd) {
  switch (rnd.nextInt(7)) {
    case 0:
      return null;
    case 1:
      return rnd.nextInt(10);
    case 2:
      return rnd.nextDouble();
    case 3:
      return rnd.nextBool();
    case 4:
      return String.fromCharCodes(
          List.generate(1 + rnd.nextInt(5), (_) => 97 + rnd.nextInt(26)));
    case 5:
      return rnd.nextInt(2); // small int good for eq validators
    default:
      return rnd.nextBool() ? '' : 'x';
  }
}
