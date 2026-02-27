import 'package:eskema/eskema.dart';

DateTime _asDateTime(dynamic value) {
  if (value is DateTime) {
    return value;
  }

  if (value is String) {
    return DateTime.parse(value);
  }

  throw ArgumentError('Expected DateTime or ISO string, got: ${value.runtimeType}');
}

bool _boolArg(List<dynamic> args, int index, bool fallback) {
  if (args.length <= index) {
    return fallback;
  }

  return args[index] as bool;
}

final Map<String, IValidator Function()> _simpleTypeFactories = {
  'String': isString,
  'int': isInt,
  'double': isDouble,
  'num': isNumber,
  'bool': isBool,
  'List': isList,
  'Map': isMap,
};

IValidator _resolveTypeValidator(String typeName) {
  final directFactory = _simpleTypeFactories[typeName];
  if (directFactory != null) {
    return directFactory();
  }

  if (typeName.startsWith('List<')) {
    return isList();
  }

  if (typeName.startsWith('Map<')) {
    return isMap();
  }

  return isType<dynamic>().copyWith(name: 'isType', args: [typeName]);
}

void _registerMany(ValidatorRegistry registry, Map<String, ValidatorFactory> factories) {
  for (final entry in factories.entries) {
    registry.register(name: entry.key, factory: entry.value);
  }
}

/// The global registry containing all built-in eskema validators.
///
/// Custom registries can be built by instantiating new `ValidatorRegistry`
/// objects, or this standard default can be expanded via `defaultRegistry.merge(...)`.
final ValidatorRegistry defaultRegistry = ValidatorRegistry()..registerDefaults();

extension _ValidatorRegistryDefaults on ValidatorRegistry {
  /// Defines all standard symbols, names, and instantiation rules.
  void registerDefaults() {
    _registerMany(this, {
      'all': (args) => all(args.cast<IValidator>()),
      'any': (args) => any(args.cast<IValidator>()),
      'none': (args) => none(args.cast<IValidator>()),
      'not': (args) => not(args[0] as IValidator),
      'throwInstead': (args) => throwInstead(args[0] as IValidator),
      'withExpectation':
          (args) => withExpectation(args[0] as IValidator, args[1] as Expectation),
      'when': (args) => when(
            args[0] as IValidator,
            then: args[1] as IValidator,
            otherwise: args[2] as IValidator,
          ),
      'switchBy': (args) => switchBy(args[0] as String, args[1] as Map<String, IValidator>),
      'isEq': (args) => isEq(args[0]),
      'isDeepEq': (args) => isDeepEq(args[0]),
      'isGt': (args) => isGt<num>(args[0] as num),
      'isGte': (args) => isGte<num>(args[0] as num),
      'isLt': (args) => isLt<num>(args[0] as num),
      'isLte': (args) => isLte<num>(args[0] as num),
      'isInRange': (args) => isInRange<num>(args[0] as num, args[1] as num),
      'isOneOf': isOneOf,
      'contains': (args) => contains(args[0]),
      'stringLength': (args) => stringLength(args.cast<IValidator>()),
      'stringIsOfLength': (args) => stringIsOfLength(args[0] as int),
      'stringContains': (args) => stringContains(args[0] as String),
      'stringMatchesPattern': (args) => stringMatchesPattern(RegExp(args[0] as String)),
      'isUrl': (args) => isUrl(strict: _boolArg(args, 0, false)),
      'isDateBefore': (args) => isDateBefore(
            _asDateTime(args[0]),
            inclusive: _boolArg(args, 1, false),
          ),
      'isDateAfter': (args) => isDateAfter(
            _asDateTime(args[0]),
            inclusive: _boolArg(args, 1, false),
          ),
      'isDateBetween': (args) => isDateBetween(
            _asDateTime(args[0]),
            _asDateTime(args[1]),
            inclusiveStart: _boolArg(args, 2, true),
            inclusiveEnd: _boolArg(args, 3, true),
          ),
      'isDateSameDay': (args) => isDateSameDay(_asDateTime(args[0])),
      'isDateInPast': (args) => isDateInPast(allowNow: _boolArg(args, 0, true)),
      'isDateInFuture': (args) => isDateInFuture(allowNow: _boolArg(args, 0, true)),
      'jsonHasKeys': (args) => jsonHasKeys(args.cast<String>()),
      'jsonArrayLength':
          (args) => jsonArrayLength(min: args[0] as int?, max: args[1] as int?),
      'jsonArrayEvery': (args) => jsonArrayEvery(args[0] as IValidator),
      'containsKey': (args) => containsKey(args[0] as String),
      'containsKeys': (args) => containsKeys(args.cast<String>()),
      'containsValues': containsValues,
      'eskema': (args) => eskema(args[0] as Map<String, IValidator>),
      'eskemaStrict': (args) => eskemaStrict(args[0] as Map<String, IValidator>),
      'eskemaList': (args) => eskemaList(args[0] as List<IValidator>),
      'listEach': (args) => listEach(args[0] as IValidator),
      'isType': (args) => _resolveTypeValidator(args.isNotEmpty ? args[0].toString() : ''),
    });

    _registerMany(this, {
      'isTrue': (_) => isTrue(),
      'isFalse': (_) => isFalse(),
      'isLowerCase': (_) => isLowerCase(),
      'isUpperCase': (_) => isUpperCase(),
      'isEmail': (_) => isEmail(),
      'isStringEmpty': (_) => isStringEmpty(),
      'isStrictUrl': (_) => isStrictUrl(),
      'isUuidV4': (_) => isUuidV4(),
      'isIntString': (_) => isIntString(),
      'isDoubleString': (_) => isDoubleString(),
      'isNumString': (_) => isNumString(),
      'isBoolString': (_) => isBoolString(),
      'isDate': (_) => isDate(),
      'isJsonContainer': (_) => isJsonContainer(),
      'isJsonObject': (_) => isJsonObject(),
      'isJsonArray': (_) => isJsonArray(),
    });

    final typeFactories = _simpleTypeFactories.map<String, ValidatorFactory>(
      (name, factory) => MapEntry(name, (_) => factory()),
    );
    _registerMany(this, typeFactories);
  }
}
