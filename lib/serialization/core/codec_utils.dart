import 'package:eskema/eskema.dart';

typedef SymbolMap = Map<String, String>;

class ParsedModifiers {
  final bool isNullable;
  final bool isOptional;
  final int offset;

  const ParsedModifiers({
    required this.isNullable,
    required this.isOptional,
    required this.offset,
  });

  String applyToString(String value) => value.substring(offset);
}

const Set<String> simpleTypeNames = {
  'int',
  'String',
  'double',
  'num',
  'bool',
  'List',
  'Map',
  'Set',
};

const noArgValidators = {
  'isTrue',
  'isFalse',
  'isLowerCase',
  'isUpperCase',
  'isEmail',
  'isStringEmpty',
  'isStrictUrl',
  'isUuidV4',
  'isIntString',
  'isDoubleString',
  'isNumString',
  'isBoolString',
  'isDate',
  'isDateInPast',
  'isDateInFuture',
  'isJsonContainer',
  'isJsonObject',
  'isJsonArray',
  'String',
  'int',
  'double',
  'num',
  'bool',
  'List',
  'Map',
};

const Set<String> combinatorSymbols = {'&', '|'};
const Set<String> comparisonSymbols = {'=', '>', '>=', '<', '<=', '<>', '~', 'in'};

class SymbolResolver {
  final SymbolMap customNameToSymbol;
  final SymbolMap customSymbolToName;

  const SymbolResolver({
    SymbolMap? customNameToSymbol,
    SymbolMap? customSymbolToName,
  })  : customNameToSymbol = customNameToSymbol ?? const {},
        customSymbolToName = customSymbolToName ?? const {};

  String symbolOfName(String name) {
    return customNameToSymbol[name] ?? defaultNameToSymbol[name] ?? name;
  }

  String? nameOfSymbol(String symbol) {
    return customSymbolToName[symbol] ?? defaultSymbolToName[symbol];
  }

  bool hasSymbolForName(String name) {
    return customNameToSymbol.containsKey(name) || defaultNameToSymbol.containsKey(name);
  }

  bool isKnownSymbol(String symbol) {
    return customSymbolToName.containsKey(symbol) || defaultSymbolToName.containsKey(symbol);
  }
}

bool isSimpleTypeValidator(IValidator validator) {
  if (validator.name != 'isType' || validator.args.isEmpty) {
    return false;
  }

  return simpleTypeNames.contains(validator.args.first.toString());
}

String? extractSimpleTypeName(IValidator validator) {
  if (!isSimpleTypeValidator(validator)) {
    return null;
  }

  return validator.args.first.toString();
}

String applyEskemaFieldModifiers({
  required bool isNullable,
  required bool isOptional,
  required String encoded,
}) {
  String mod = encoded;

  if (isNullable) {
    mod = '?$mod';
  }

  if (isOptional) {
    mod = '*$mod';
  }

  return mod;
}

dynamic applyJsonFieldModifiers({
  required bool isNullable,
  required bool isOptional,
  required dynamic encoded,
}) {
  final buffer = StringBuffer();

  if (isNullable) {
    buffer.write('?');
  }

  if (isOptional) {
    buffer.write('*');
  }

  final prefix = buffer.toString();
  if (prefix.isEmpty) {
    return encoded;
  }

  return [prefix, encoded];
}

bool isComparisonSymbol(String symbol) {
  return comparisonSymbols.contains(symbol);
}

bool isSimpleValue(dynamic value) {
  return value == null || value is num || value is bool || value is String;
}

dynamic tryParsePrimitiveLiteral(String token) {
  if (token == 'true') {
    return true;
  }

  if (token == 'false') {
    return false;
  }

  if (token == 'null') {
    return null;
  }

  return token;
}

ParsedModifiers parsePrefixModifiers(String source) {
  var offset = 0;
  var nullable = false;
  var optional = false;

  while (offset < source.length) {
    final ch = source[offset];
    if (ch == '?') {
      nullable = true;
      offset++;
      continue;
    }

    if (ch == '*') {
      optional = true;
      offset++;
      continue;
    }

    break;
  }

  return ParsedModifiers(
    isNullable: nullable,
    isOptional: optional,
    offset: offset,
  );
}

IValidator applyDecodedModifiers(IValidator validator, ParsedModifiers modifiers) {
  var result = validator;

  if (modifiers.isNullable) {
    result = result.nullable();
  }

  if (modifiers.isOptional) {
    result = result.optional();
  }

  return result;
}

bool isModifierPrefixToken(String token) {
  if (token.isEmpty) {
    return false;
  }

  for (var i = 0; i < token.length; i++) {
    final ch = token[i];
    if (ch != '?' && ch != '*') {
      return false;
    }
  }

  return true;
}
