import 'package:eskema/eskema.dart';

/// The [SymbolMap] typedef.
typedef SymbolMap = Map<String, String>;

/// The [ParsedModifiers] class.
class ParsedModifiers {
  /// The [isNullable] property.
  final bool isNullable;

  /// The [isOptional] property.
  final bool isOptional;

  /// The [offset] property.
  final int offset;

  /// Executes the [ParsedModifiers] operation.
  const ParsedModifiers({
    required this.isNullable,
    required this.isOptional,
    required this.offset,
  });

  /// Executes the [applyToString] operation.
  String applyToString(String value) => value.substring(offset);
}

/// The [SymbolResolver] class.
class SymbolResolver {
  /// The [customNameToSymbol] property.
  final SymbolMap customNameToSymbol;

  /// The [customSymbolToName] property.
  final SymbolMap customSymbolToName;

  /// Executes the [SymbolResolver] operation.
  const SymbolResolver({
    SymbolMap? customNameToSymbol,
    SymbolMap? customSymbolToName,
  })  : customNameToSymbol = customNameToSymbol ?? const {},
        customSymbolToName = customSymbolToName ?? const {};

  /// Executes the [symbolOfName] operation.
  String symbolOfName(String name) {
    return customNameToSymbol[name] ?? defaultNameToSymbol[name] ?? name;
  }

  /// Executes the [nameOfSymbol] operation.
  String? nameOfSymbol(String symbol) {
    return customSymbolToName[symbol] ?? defaultSymbolToName[symbol];
  }

  /// Executes the [hasSymbolForName] operation.
  bool hasSymbolForName(String name) {
    return customNameToSymbol.containsKey(name) ||
        defaultNameToSymbol.containsKey(name);
  }

  /// Executes the [isKnownSymbol] operation.
  bool isKnownSymbol(String symbol) {
    return customSymbolToName.containsKey(symbol) ||
        defaultSymbolToName.containsKey(symbol);
  }
}

/// Executes the [isSimpleTypeValidator] operation.
bool isSimpleTypeValidator(IValidator validator) {
  if (validator.name != 'isType' || validator.args.isEmpty) {
    return false;
  }

  return simpleTypeNames.contains(validator.args.first.toString());
}

/// Executes the [extractSimpleTypeName] operation.
String? extractSimpleTypeName(IValidator validator) {
  if (!isSimpleTypeValidator(validator)) {
    return null;
  }

  return validator.args.first.toString();
}

/// Executes the [applyEskemaFieldModifiers] operation.
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

/// Executes the [applyJsonFieldModifiers] operation.
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

/// Executes the [isComparisonSymbol] operation.
bool isComparisonSymbol(String symbol) {
  return comparisonSymbols.contains(symbol);
}

/// Executes the [isSimpleValue] operation.
bool isSimpleValue(dynamic value) {
  return value == null || value is num || value is bool || value is String;
}

/// Executes the [tryParsePrimitiveLiteral] operation.
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

/// Executes the [parsePrefixModifiers] operation.
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

/// Executes the [applyDecodedModifiers] operation.
IValidator applyDecodedModifiers(
    IValidator validator, ParsedModifiers modifiers) {
  var result = validator;

  if (modifiers.isNullable) {
    result = result.nullable();
  }

  if (modifiers.isOptional) {
    result = result.optional();
  }

  return result;
}

/// Executes the [isModifierPrefixToken] operation.
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
