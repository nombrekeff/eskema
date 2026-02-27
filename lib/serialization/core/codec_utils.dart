import 'package:eskema/eskema.dart';

typedef SymbolMap = Map<String, String>;

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
