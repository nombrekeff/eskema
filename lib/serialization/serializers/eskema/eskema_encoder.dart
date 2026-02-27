import 'package:eskema/eskema.dart';

/// Encodes an Eskema IValidator into its compact string representation.
class EskemaEncoder extends DelegateValidatorEncoder<String> {
  final Map<String, String>? customSymbols;
  final Map<String, ArgumentEncoder>? customEncoders;

  const EskemaEncoder({this.customSymbols, this.customEncoders});

  String _getSymbol(String name) {
    if (customSymbols != null && customSymbols!.containsKey(name)) {
      return customSymbols![name]!;
    }

    return defaultNameToSymbol[name] ?? name;
  }

  bool _hasSymbolMap(String name) {
    return (customSymbols != null && customSymbols!.containsKey(name)) ||
        defaultNameToSymbol.containsKey(name);
  }

  @override
  String encode(IValidator validator, {ValidatorRegistry? registry}) {
    final activeRegistry = registry ?? defaultRegistry;

    return encodeInternal(validator, activeRegistry);
  }

  @override
  String encodeInternal(IValidator validator, ValidatorRegistry? registry) {
    // We pass registry around in case nested calls need standard encode logic,
    // but the symbols are handled internally here now.
    if (validator is Field || validator is MapValidator) {
      return encodeMap(validator as IdValidator, registry);
    }

    // isType validators encode as bare type names (e.g. int, String)
    if (validator.name == 'isType' && validator.args.isNotEmpty) {
      final typeName = validator.args[0].toString();
      const simpleTypes = {'int', 'String', 'double', 'num', 'bool', 'List', 'Map', 'Set'};
      
      if (simpleTypes.contains(typeName)) {
        return typeName;
      }
    }

    if (_hasSymbolMap(validator.name)) {
      final symbol = _getSymbol(validator.name);

      return encodeBuiltIn(symbol, validator, registry);
    }

    // fallback if no explicitly configured short symbol
    return encodeCustom(validator, registry);
  }

  @override
  String encodeMap(IdValidator field, ValidatorRegistry? registry) {
    if (field is MapValidator) {
      final buffer = StringBuffer('{');

      for (var i = 0; i < field.fields.length; i++) {
        final f = field.fields[i];
        buffer.write('${f.id}: ${encodeFieldModifiers(f, encodeMap(f, registry))}');

        if (i < field.fields.length - 1) buffer.write(', ');
      }

      buffer.write('}');

      return buffer.toString();
    }

    if (field is Field) {
      return field.validators.map((v) => encodeInternal(v, registry)).join(' & ');
    }

    return encodeInternal(field, registry);
  }

  @override
  String encodeFieldModifiers(IValidator validator, String encoded) {
    String mod = encoded;

    if (validator.isNullable) mod = '?$mod';
    if (validator.isOptional) mod = '*$mod';

    return mod;
  }

  @override
  String encodeBuiltIn(String symbol, IValidator validator, ValidatorRegistry? registry) {
    if (validator.args.isEmpty) {
      return symbol;
    }

    if (symbol == '&' || symbol == '|') {
      final subs = validator.args.cast<IValidator>();

      if (subs.isEmpty) return symbol;
      final joined = subs.map((v) => encodeInternal(v, registry)).join(' $symbol ');

      return '($joined)';
    }

    final customEncoder = customEncoders?[validator.name];
    final argsToEncode = customEncoder != null ? customEncoder(validator) : validator.args;

    final argsStr = argsToEncode.map((v) {
      return encodeValue(v, registry);
    }).join(', ');

    if (argsToEncode.length == 1 &&
        _isComparisonSymbol(symbol) &&
        _isSimpleValue(argsToEncode[0])) {
      return '$symbol$argsStr';
    }

    return '$symbol($argsStr)';
  }

  bool _isComparisonSymbol(String symbol) {
    return const {'=', '>', '>=', '<', '<=', '<>', '~', 'in'}.contains(symbol);
  }

  bool _isSimpleValue(dynamic value) {
    return value == null || value is num || value is bool || value is String;
  }

  @override
  String encodeCustom(IValidator validator, ValidatorRegistry? registry) {
    final argsStr = validator.args.map((v) => encodeValue(v, registry)).join(', ');

    if (argsStr.isEmpty) return '@${validator.name}';

    return '@${validator.name}($argsStr)';
  }

  @override
  String encodeValue(dynamic value, ValidatorRegistry? registry) {
    if (value is String) return "'$value'";
    if (value is RegExp) return "'${value.pattern}'";
    if (value is DateTime) return "'${value.toIso8601String()}'";

    if (value is Iterable) {
      return '[${value.map((v) => encodeValue(v, registry)).join(', ')}]';
    }

    if (value is Map) {
      final entries = value.entries
          .map((e) => '${e.key}: ${encodeValue(e.value, registry)}')
          .join(', ');

      return '{$entries}';
    }

    if (value is IValidator) return encodeInternal(value, registry);

    return value.toString();
  }
}
