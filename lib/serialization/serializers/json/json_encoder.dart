import 'package:eskema/eskema.dart';

/// Encodes an Eskema IValidator into a standard Dart representation (Maps, Lists, Strings)
/// that can be directly passed to `jsonEncode()`.
class JsonEncoder extends DelegateValidatorEncoder<dynamic> {
  final Map<String, String>? customSymbols;
  final Map<String, ArgumentEncoder>? customEncoders;

  const JsonEncoder({this.customSymbols, this.customEncoders});

  String _getSymbol(String name) {
    if (customSymbols != null && customSymbols!.containsKey(name)) {
      return customSymbols![name]!;
    }
    return defaultNameToSymbol[name] ?? name;
  }

  bool _hasSymbolMap(String name) {
     return (customSymbols != null && customSymbols!.containsKey(name)) || defaultNameToSymbol.containsKey(name);
  }

  @override
  dynamic encode(IValidator validator, {ValidatorRegistry? registry}) {
    final activeRegistry = registry ?? defaultRegistry;
    return encodeInternal(validator, activeRegistry);
  }

  @override
  dynamic encodeInternal(IValidator validator, ValidatorRegistry? registry) {
    if (validator is Field || validator is MapValidator) {
      return encodeMap(validator as IdValidator, registry);
    }

    // isType validators encode as bare type name strings (e.g. 'int', 'String')
    if (validator.name == 'isType' && validator.arguments.isNotEmpty) {
      return validator.arguments[0].toString();
    }

    if (_hasSymbolMap(validator.name)) {
      final symbol = _getSymbol(validator.name);
      return encodeBuiltIn(symbol, validator, registry);
    }

    // fallback if no explicitly configured short symbol
    return encodeCustom(validator, registry);
  }

  @override
  dynamic encodeMap(IdValidator field, ValidatorRegistry? registry) {
    if (field is MapValidator) {
      final map = <String, dynamic>{};
      for (var i = 0; i < field.fields.length; i++) {
        final f = field.fields[i];
        map[f.id!] = encodeFieldModifiers(f, encodeMap(f, registry));
      }
      return map;
    }

    if (field is Field) {
      if (field.validators.isEmpty) {
        return null;
      }
      if (field.validators.length == 1) {
        return encodeInternal(field.validators.first, registry);
      }
      // Wrap in 'all' operator for JSON parity
      final symbol = _getSymbol('all');
      return encodeBuiltIn(symbol, all(field.validators), registry);
    }

    return encodeInternal(field, registry);
  }

  @override
  dynamic encodeFieldModifiers(IValidator validator, dynamic encoded) {
    String prefix = '';
    
    if (validator.isNullable) prefix += '?';
    if (validator.isOptional) prefix += '*';

    if (prefix.isEmpty) return encoded;

    // Wrap: ["?", ["T"]] or ["?*", [">", 0]]
    return [prefix, encoded];
  }

  @override
  dynamic encodeBuiltIn(String symbol, IValidator validator, ValidatorRegistry? registry) {
    if (validator.arguments.isEmpty) {
      return [symbol];
    }

    if (symbol == '&' || symbol == '|') {
      final subs = validator.arguments.cast<IValidator>();

      if (subs.isEmpty) return symbol;
      if (subs.length == 1) return encodeInternal(subs.first, registry);

      final list = <dynamic>[];
      // Push infix operators at odd indices for cleaner parsing: ["int", "&", [">", 18], "&", ["<", 65]]
      for (var i = 0; i < subs.length; i++) {
        list.add(encodeInternal(subs[i], registry));
        if (i < subs.length - 1) {
          list.add(symbol);
        }
      }

      return list;
    }

    final customEncoder = customEncoders?[validator.name];
    final argsToEncode = customEncoder != null ? customEncoder(validator) : validator.arguments;

    final list = <dynamic>[symbol];
    for (final v in argsToEncode) {
      list.add(encodeValue(v, registry));
    }

    return list;
  }

  @override
  dynamic encodeCustom(IValidator validator, ValidatorRegistry? registry) {
    final list = <dynamic>['@${validator.name}'];
    for (final v in validator.arguments) {
      list.add(encodeValue(v, registry));
    }

    return list;
  }

  @override
  dynamic encodeValue(dynamic value, ValidatorRegistry? registry) {
    // Strings get escaped in Eskema string syntax, keep parity for literal tracking
    // Without this, the json-string "int" would map to the numeric integer validator implicitly.
    if (value is String) return "'$value'";

    if (value is Iterable) {
      return value.map((v) => encodeValue(v, registry)).toList();
    }
    
    if (value is IValidator) return encodeInternal(value, registry);

    return value;
  }
}
