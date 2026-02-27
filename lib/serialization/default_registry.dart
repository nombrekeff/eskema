import 'package:eskema/eskema.dart';
import 'package:eskema/serialization/core/registry.dart';

/// The global registry containing all built-in eskema validators.
/// 
/// Custom registries can be built by instantiating new `ValidatorRegistry`
/// objects, or this standard default can be expanded via `defaultRegistry.merge(...)`.
final ValidatorRegistry defaultRegistry = ValidatorRegistry()..registerDefaults();

extension _ValidatorRegistryDefaults on ValidatorRegistry {
  /// Defines all standard symbols, names, and instantiation rules.
  void registerDefaults() {
    // Basic Combinators (Note: encoder has hardcoded handling for & and | syntax,
    // but they can still be mapped here for decoder lookup)
    register(name: 'all', factory: (args) => all(args.cast<IValidator>()));
    register(name: 'any', factory: (args) => any(args.cast<IValidator>()));
    register(name: 'none', factory: (args) => none(args.cast<IValidator>()));
    register(name: 'not', factory: (args) => not(args[0] as IValidator));

    // Structural and Expectation
    register(name: 'throwInstead', factory: (args) => throwInstead(args[0] as IValidator));
    register(name: 'withExpectation', factory: (args) => withExpectation(args[0] as IValidator, args[1] as Expectation));
    register(name: 'when', factory: (args) => when(args[0] as IValidator, then: args[1] as IValidator, otherwise: args[2] as IValidator));
    register(name: 'switchBy', factory: (args) => switchBy(args[0] as String, args[1] as Map<String, IValidator>));

    // Comparison and Math
    register(name: 'isEq', factory: (args) => isEq(args[0]));
    register(name: 'isDeepEq', factory: (args) => isDeepEq(args[0]));
    register(name: 'isGt', factory: (args) => isGt<num>(args[0] as num));
    register(name: 'isGte', factory: (args) => isGte<num>(args[0] as num));
    register(name: 'isLt', factory: (args) => isLt<num>(args[0] as num));
    register(name: 'isLte', factory: (args) => isLte<num>(args[0] as num));
    register(name: 'isInRange', factory: (args) => isInRange<num>(args[0] as num, args[1] as num));
    register(name: 'isOneOf', factory: (args) => isOneOf(args));

    // Boolean Logic
    register(name: 'isTrue', factory: (args) => isTrue());
    register(name: 'isFalse', factory: (args) => isFalse());

    // Iterable and Strings
    register(name: 'contains', factory: (args) => contains(args[0]));
    register(name: 'stringLength', factory: (args) => stringLength(args.cast<IValidator>()));
    register(name: 'stringIsOfLength', factory: (args) => stringIsOfLength(args[0] as int));
    register(name: 'stringContains', factory: (args) => stringContains(args[0] as String));
    register(name: 'stringMatchesPattern', factory: (args) => stringMatchesPattern(RegExp(args[0] as String)));
    register(name: 'isLowerCase', factory: (args) => isLowerCase());
    register(name: 'isUpperCase', factory: (args) => isUpperCase());
    register(name: 'isEmail', factory: (args) => isEmail());
    register(name: 'isStringEmpty', factory: (args) => isStringEmpty());
    register(name: 'isUrl', factory: (args) => isUrl(strict: args.isNotEmpty ? args[0] as bool : false));
    register(name: 'isStrictUrl', factory: (args) => isStrictUrl());
    register(name: 'isUuidV4', factory: (args) => isUuidV4());
    register(name: 'isIntString', factory: (args) => isIntString());
    register(name: 'isDoubleString', factory: (args) => isDoubleString());
    register(name: 'isNumString', factory: (args) => isNumString());
    register(name: 'isBoolString', factory: (args) => isBoolString());

    // Date
    register(name: 'isDate', factory: (args) => isDate());
    register(name: 'isDateBefore', factory: (args) {
      final dt = args[0] is String ? DateTime.parse(args[0] as String) : args[0] as DateTime;

      return isDateBefore(dt, inclusive: args.length > 1 ? args[1] as bool : false);
    });
    register(name: 'isDateAfter', factory: (args) {
      final dt = args[0] is String ? DateTime.parse(args[0] as String) : args[0] as DateTime;

      return isDateAfter(dt, inclusive: args.length > 1 ? args[1] as bool : false);
    });
    register(name: 'isDateBetween', factory: (args) {
      final start = args[0] is String ? DateTime.parse(args[0] as String) : args[0] as DateTime;
      final end = args[1] is String ? DateTime.parse(args[1] as String) : args[1] as DateTime;

      return isDateBetween(
        start,
        end,
        inclusiveStart: args.length > 2 ? args[2] as bool : true,
        inclusiveEnd: args.length > 3 ? args[3] as bool : true,
      );
    });
    register(name: 'isDateSameDay', factory: (args) {
      final dt = args[0] is String ? DateTime.parse(args[0] as String) : args[0] as DateTime;

      return isDateSameDay(dt);
    });
    register(name: 'isDateInPast', factory: (args) => isDateInPast(allowNow: args.isNotEmpty ? args[0] as bool : true));
    register(name: 'isDateInFuture', factory: (args) => isDateInFuture(allowNow: args.isNotEmpty ? args[0] as bool : true));

    // Json and Collections
    register(name: 'isJsonContainer', factory: (args) => isJsonContainer());
    register(name: 'isJsonObject', factory: (args) => isJsonObject());
    register(name: 'isJsonArray', factory: (args) => isJsonArray());
    register(name: 'jsonHasKeys', factory: (args) => jsonHasKeys(args.cast<String>()));
    register(name: 'jsonArrayLength', factory: (args) => jsonArrayLength(min: args[0] as int?, max: args[1] as int?));
    register(name: 'jsonArrayEvery', factory: (args) => jsonArrayEvery(args[0] as IValidator));
    
    register(name: 'containsKey', factory: (args) => containsKey(args[0] as String));
    register(name: 'containsKeys', factory: (args) => containsKeys(args.cast<String>()));
    register(name: 'containsValues', factory: (args) => containsValues(args));
    
    register(name: 'eskema', factory: (args) => eskema(args[0] as Map<String, IValidator>));
    register(name: 'eskemaStrict', factory: (args) => eskemaStrict(args[0] as Map<String, IValidator>));
    register(name: 'eskemaList', factory: (args) => eskemaList(args[0] as List<IValidator>));
    register(name: 'listEach', factory: (args) => listEach(args[0] as IValidator));

    // Dynamic 'type' handling (kept for backward compat with type(...) format)
    register(name: 'isType', factory: (args) {
      final typeName = args.isNotEmpty ? args[0].toString() : '';

      if (typeName == 'String') return isString();

      if (typeName == 'int') return isInt();

      if (typeName == 'double') return isDouble();

      if (typeName == 'num') return isNumber();

      if (typeName == 'bool') return isBool();

      if (typeName == 'List') return isList();

      if (typeName == 'Map') return isMap();

      return isType<dynamic>().copyWith(name: 'isType', args: [typeName]);
    });

    // Bare type names for simplified encoding (e.g. `int` instead of `type(int)`)
    register(name: 'String', factory: (args) => isString());
    register(name: 'int', factory: (args) => isInt());
    register(name: 'double', factory: (args) => isDouble());
    register(name: 'num', factory: (args) => isNumber());
    register(name: 'bool', factory: (args) => isBool());
    register(name: 'List', factory: (args) => isList());
    register(name: 'Map', factory: (args) => isMap());

  }
}
