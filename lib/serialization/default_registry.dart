import 'package:eskema/eskema.dart';
import 'package:eskema/serialization/registry.dart';

/// The global registry containing all built-in eskema validators.
/// 
/// Custom registries can be built by instantiating new `ValidatorRegistry`
/// objects, or this standard default can be expanded via `defaultRegistry.merge(...)`.
final ValidatorRegistry defaultRegistry = ValidatorRegistry()..registerDefaults();

extension _ValidatorRegistryDefaults on ValidatorRegistry {
  /// Defines all standard symbols, names, and instantiation rules.
  void registerDefaults() {
    // Basic Combinators (Note: serializer has hardcoded handling for & and | syntax,
    // but they can still be mapped here for deserialization lookup)
    register(name: 'all', symbol: '&', factory: (args) => all(args.cast<IValidator>()));
    register(name: 'any', symbol: '|', factory: (args) => any(args.cast<IValidator>()));
    register(name: 'none', symbol: '!|', factory: (args) => none(args.cast<IValidator>()));
    register(name: 'not', symbol: '!', factory: (args) => not(args[0] as IValidator));

    // Structural and Expectation
    register(name: 'throwInstead', symbol: '!!', factory: (args) => throwInstead(args[0] as IValidator));
    register(name: 'withExpectation', symbol: '->', factory: (args) => withExpectation(args[0] as IValidator, args[1] as Expectation));
    register(name: 'when', symbol: 'when', factory: (args) => when(args[0] as IValidator, then: args[1] as IValidator, otherwise: args[2] as IValidator));
    register(name: 'switchBy', symbol: 'switch', factory: (args) => switchBy(args[0] as String, args[1] as Map<String, IValidator>));

    // Comparison and Math
    register(name: 'isEq', symbol: '=', factory: (args) => isEq(args[0]));
    register(name: 'isGt', symbol: '>', factory: (args) => isGt<num>(args[0] as num));
    register(name: 'isGte', symbol: '>=', factory: (args) => isGte<num>(args[0] as num));
    register(name: 'isLt', symbol: '<', factory: (args) => isLt<num>(args[0] as num));
    register(name: 'isLte', symbol: '<=', factory: (args) => isLte<num>(args[0] as num));
    register(name: 'isInRange', symbol: '<>', factory: (args) => isInRange<num>(args[0] as num, args[1] as num));
    register(name: 'isOneOf', symbol: 'in', factory: (args) => isOneOf(args));

    // Boolean Logic
    register(name: 'isTrue', symbol: 'T', factory: (args) => isTrue());
    register(name: 'isFalse', symbol: 'F', factory: (args) => isFalse());

    // Iterable and Strings
    register(name: 'contains', symbol: '~', factory: (args) => contains(args[0]));
    register(name: 'stringLength', symbol: 'slen', factory: (args) => stringLength(args.cast<IValidator>()));
    register(name: 'stringIsOfLength', symbol: 'slen=', factory: (args) => stringIsOfLength(args[0] as int));
    register(name: 'stringContains', symbol: 's~', factory: (args) => stringContains(args[0] as String));
    register(name: 'stringMatchesPattern', symbol: 's~/', factory: (args) => stringMatchesPattern(RegExp(args[0] as String)));
    register(name: 'isLowerCase', symbol: 's_lc', factory: (args) => isLowerCase());
    register(name: 'isUpperCase', symbol: 's_uc', factory: (args) => isUpperCase());
    register(name: 'isEmail', symbol: 's_mail', factory: (args) => isEmail());
    register(name: 'isStringEmpty', symbol: 's0', factory: (args) => isStringEmpty());
    register(name: 'isUrl', symbol: 's_url', factory: (args) => isUrl(strict: args.isNotEmpty ? args[0] as bool : false));
    register(name: 'isStrictUrl', symbol: 's_url!', factory: (args) => isStrictUrl());
    register(name: 'isUuidV4', symbol: 's_uuid', factory: (args) => isUuidV4());
    register(name: 'isIntString', symbol: 's_int', factory: (args) => isIntString());
    register(name: 'isDoubleString', symbol: 's_dbl', factory: (args) => isDoubleString());
    register(name: 'isNumString', symbol: 's_num', factory: (args) => isNumString());
    register(name: 'isBoolString', symbol: 's_bool', factory: (args) => isBoolString());

    // Date
    register(name: 'isDate', symbol: 's_date', factory: (args) => isDate());
    register(name: 'isDateBefore', symbol: 'd<', factory: (args) => isDateBefore(args[0] as DateTime, inclusive: args[1] as bool));
    register(name: 'isDateAfter', symbol: 'd>', factory: (args) => isDateAfter(args[0] as DateTime, inclusive: args[1] as bool));
    register(name: 'isDateBetween', symbol: 'd<>', factory: (args) => isDateBetween(args[0] as DateTime, args[1] as DateTime, inclusiveStart: args[2] as bool, inclusiveEnd: args[3] as bool));
    register(name: 'isDateSameDay', symbol: 'd=', factory: (args) => isDateSameDay(args[0] as DateTime));
    register(name: 'isDateInPast', symbol: 'd_past', factory: (args) => isDateInPast(allowNow: args[0] as bool));
    register(name: 'isDateInFuture', symbol: 'd_fut', factory: (args) => isDateInFuture(allowNow: args[0] as bool));

    // Json and Collections
    register(name: 'isJsonContainer', symbol: 'j_cont', factory: (args) => isJsonContainer());
    register(name: 'isJsonObject', symbol: 'j_obj', factory: (args) => isJsonObject());
    register(name: 'isJsonArray', symbol: 'j_arr', factory: (args) => isJsonArray());
    register(name: 'jsonHasKeys', symbol: 'j_keys', factory: (args) => jsonHasKeys(args.cast<String>()));
    register(name: 'jsonArrayLength', symbol: 'j_alen', factory: (args) => jsonArrayLength(min: args[0] as int?, max: args[1] as int?));
    register(name: 'jsonArrayEvery', symbol: 'j_aevery', factory: (args) => jsonArrayEvery(args[0] as IValidator));
    
    register(name: 'containsKey', symbol: 'm_key', factory: (args) => containsKey(args[0] as String));
    register(name: 'containsKeys', symbol: 'm_keys', factory: (args) => containsKeys(args.cast<String>()));
    register(name: 'containsValues', symbol: 'm_vals', factory: (args) => containsValues(args));
    
    register(name: 'eskema', symbol: 'eskema', factory: (args) => eskema(args[0] as Map<String, IValidator>));
    register(name: 'eskemaStrict', symbol: 'eskema!', factory: (args) => eskemaStrict(args[0] as Map<String, IValidator>));
    register(name: 'eskemaList', symbol: 'eskema[]', factory: (args) => eskemaList(args[0] as List<IValidator>));
    register(name: 'listEach', symbol: '[]each', factory: (args) => listEach(args[0] as IValidator));

    // Dynamic 'type' handling
    register(name: 'isType', symbol: 'type', factory: (args) {
      final typeName = args.isNotEmpty ? args[0].toString() : '';
      if (typeName == 'String') return isString();
      if (typeName == 'int') return isInt();
      if (typeName == 'double') return isDouble();
      if (typeName == 'num') return isNumber();
      if (typeName == 'bool') return isBool();
      if (typeName == 'List') return isList();
      if (typeName == 'Map') return isMap();
      return isType<dynamic>().copyWith(name: 'isType', arguments: [typeName]);
    });
  }
}
