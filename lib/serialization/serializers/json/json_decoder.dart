import 'dart:convert' as convert;

import 'package:eskema/eskema.dart';

/// Decodes a JSON string into an IValidator.
///
/// The JSON format uses:
/// - `String` for no-argument validators (e.g. `"T"`, `"F"`, `"s_mail"`)
/// - `List` for parameterized validators (e.g. `[">", 18]`) or infix logical chains
///   (e.g. `[["type", "int"], "&", [">", 0]]`)
/// - `Map<String, dynamic>` for map/field validators
///
/// Example:
/// ```dart
/// final validator = const JsonDecoder().decode('{"name": "String", "age": [">", 0]}');
/// ```
class JsonDecoder extends DelegateValidatorDecoder<dynamic> {
  final Map<String, String>? customSymbols;

  const JsonDecoder({this.customSymbols});

  String? _getName(String symbol) {
    if (customSymbols != null && customSymbols!.containsKey(symbol)) {
      return customSymbols![symbol]!;
    }

    return defaultSymbolToName[symbol];
  }

  @override
  IValidator decode(
    dynamic input, {
    Map<String, Function>? customFactories,
    ValidatorRegistry? registry,
  }) {
    final activeRegistry = registry ?? defaultRegistry;
    final parsed = input is String ? convert.jsonDecode(input) : input;

    return _decodeNode(parsed, customFactories ?? {}, activeRegistry);
  }

  IValidator _decodeNode(
    dynamic node,
    Map<String, Function> customFactories,
    ValidatorRegistry registry,
  ) {
    if (node is String) {
      return _decodeString(node, customFactories, registry);
    }

    if (node is Map<String, dynamic>) {
      return _decodeMap(node, customFactories, registry);
    }

    if (node is List) {
      return _decodeList(node, customFactories, registry);
    }

    throw DecodeException.invalidType('String, List, or Map', node, null);
  }

  IValidator _decodeString(
    String str,
    Map<String, Function> customFactories,
    ValidatorRegistry registry,
  ) {
    // Handle modifier prefixes
    bool nullable = false;
    bool optional = false;
    int offset = 0;

    while (offset < str.length) {
      if (str[offset] == '?') {
        nullable = true;
        offset++;
      } else if (str[offset] == '*') {
        optional = true;
        offset++;
      } else {
        break;
      }
    }

    final symbol = str.substring(offset);

    // Handle custom validators
    if (symbol.startsWith('@')) {
      final name = symbol.substring(1);

      if (customFactories.containsKey(name)) {
        IValidator val = customFactories[name]!(<dynamic>[]) as IValidator;
        if (nullable) val = val.nullable();
        if (optional) val = val.optional();
        return val;
      }
      // Fall through to registry below
    }

    // Resolve symbol to name
    final String name = _getName(symbol) ?? symbol;

    try {
      IValidator val = registry.createValidator(name, []);

      if (nullable) val = val.nullable();

      if (optional) val = val.optional();

      return val;
    } catch (e) {
      // Fallback: wrap as a dynamic type validator
      IValidator val = isType<dynamic>().copyWith(name: name, args: []);

      if (nullable) val = val.nullable();

      if (optional) val = val.optional();

      return val;
    }
  }

  IValidator _decodeMap(
    Map<String, dynamic> map,
    Map<String, Function> customFactories,
    ValidatorRegistry registry,
  ) {
    final fields = <Field>[];

    for (final entry in map.entries) {
      final key = entry.key;
      final value = entry.value;

      // Check if the value IS a string with modifier prefixes
      bool nullable = false;
      bool optional = false;

      if (value is String) {
        int offset = 0;

        while (offset < value.length) {
          if (value[offset] == '?') {
            nullable = true;
            offset++;
          } else if (value[offset] == '*') {
            optional = true;
            offset++;
          } else {
            break;
          }
        }

        final cleanStr = value.substring(offset);
        final validator = _decodeString(cleanStr, customFactories, registry);
        fields.add(
            Field(id: key, validators: [validator], nullable: nullable, optional: optional));
      } else if (value is List) {
        // Check if the list starts with a modifier prefix string like ["?", ...] or ["*", ...]  or ["?*", ...]
        if (value.isNotEmpty &&
            value.first is String &&
            _isModifierPrefix(value.first as String)) {
          final prefix = value.first as String;

          if (prefix.contains('?')) nullable = true;

          if (prefix.contains('*')) optional = true;

          final innerNode = value.length == 2 ? value[1] : value.sublist(1);
          final validator = _decodeNode(innerNode, customFactories, registry);
          fields.add(
              Field(id: key, validators: [validator], nullable: nullable, optional: optional));
        } else {
          final validator = _decodeList(value, customFactories, registry);
          fields.add(Field(id: key, validators: [validator]));
        }
      } else {
        final validator = _decodeNode(value, customFactories, registry);
        fields.add(Field(id: key, validators: [validator]));
      }
    }

    return _DecodedMapValidator(fields, name: 'eskema');
  }

  bool _isModifierPrefix(String str) {
    return RegExp(r'^[?*]+$').hasMatch(str);
  }

  IValidator _decodeList(
    List list,
    Map<String, Function> customFactories,
    ValidatorRegistry registry,
  ) {
    if (list.isEmpty) {
      throw DecodeException.unexpectedEndOfInput(list, null);
    }

    // Check infix operators: scan for "&" or "|" at odd indices
    if (list.length >= 3 && _hasInfixOperator(list)) {
      return _decodeInfix(list, customFactories, registry);
    }

    // Standard parameterized validator: [symbol, arg1, arg2, ...]
    final first = list.first;

    if (first is! String) {
      throw DecodeException.invalidType(
          'String as first element of validator list', list, null);
    }

    // Handle custom validators
    if (first.startsWith('@')) {
      final name = first.substring(1);

      if (customFactories.containsKey(name)) {
        final args =
            list.sublist(1).map((a) => _resolveValue(a, customFactories, registry)).toList();
        return customFactories[name]!(args) as IValidator;
      }
      // Fall through to registry below
    }

    final String name = _getName(first) ?? first;
    final args =
        list.sublist(1).map((a) => _resolveValue(a, customFactories, registry)).toList();

    try {
      return registry.createValidator(name, args);
    } catch (e) {
      return isType<dynamic>().copyWith(name: name, args: args);
    }
  }

  bool _hasInfixOperator(List list) {
    for (var i = 1; i < list.length; i += 2) {
      if (list[i] is String && (list[i] == '&' || list[i] == '|')) {
        return true;
      }
    }

    return false;
  }

  IValidator _decodeInfix(
    List list,
    Map<String, Function> customFactories,
    ValidatorRegistry registry,
  ) {
    // Collect operands (even indices) and verify operators (odd indices)
    final operands = <IValidator>[];
    String? operator;

    for (var i = 0; i < list.length; i++) {
      if (i.isEven) {
        operands.add(_decodeNode(list[i], customFactories, registry));
      } else {
        final op = list[i];

        if (op is! String || (op != '&' && op != '|')) {
          throw DecodeException.invalidType('"&" or "|" operator', list, null);
        }

        if (operator == null) {
          operator = op;
        } else if (operator != op) {
          throw DecodeException(
            message: 'Cannot mix "&" and "|" operators in the same list',
            source: list,
            type: DecodeExceptionType.invalidType,
          );
        }
      }
    }

    if (operator == '&') {
      return all(operands);
    }

    return any(operands);
  }

  /// Resolve a value from JSON. Strings wrapped in single quotes are literal strings,
  /// otherwise they may be validator symbols.
  dynamic _resolveValue(
    dynamic value,
    Map<String, Function> customFactories,
    ValidatorRegistry registry,
  ) {
    if (value is String) {
      // If wrapped in single quotes, it's a literal string value
      if (value.startsWith("'") && value.endsWith("'") && value.length >= 2) {
        return value.substring(1, value.length - 1);
      }

      // Otherwise, it's a bare value (could be an enum-like identifier)
      return value;
    }

    if (value is List) {
      // Could be a nested validator or a list of values
      // If first element is a string that looks like a validator symbol, decode as validator
      if (value.isNotEmpty && value.first is String) {
        final first = value.first as String;
        final name = _getName(first) ?? first;

        if (registry.factories.containsKey(name) || first.startsWith('@')) {
          return _decodeNode(value, customFactories, registry);
        }
      }

      // Otherwise treat as a plain list of values
      return value.map((v) => _resolveValue(v, customFactories, registry)).toList();
    }

    if (value is Map<String, dynamic>) {
      try {
        return _decodeNode(value, customFactories, registry);
      } catch (e) {
        return value.map((k, v) => MapEntry(k, _resolveValue(v, customFactories, registry)));
      }
    }

    // primitives: int, double, bool, null
    return value;
  }
}

class _DecodedMapValidator extends MapValidator {
  final List<IdValidator> _fields;

  _DecodedMapValidator(this._fields, {super.name = 'eskema'}) : super(id: '');

  @override
  List<IdValidator> get fields => _fields;
}
