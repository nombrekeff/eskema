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
  final bool strictUnknownValidators;
  SymbolResolver get _resolver => SymbolResolver(customSymbolToName: customSymbols);

  const JsonDecoder({
    this.customSymbols,
    this.strictUnknownValidators = false,
  });

  @override
  IValidator decode(
    dynamic input, {
    Map<String, Function>? customFactories,
    ValidatorRegistry? registry,
  }) {
    final activeRegistry = registry ?? defaultRegistry;
    final parsed = input is String ? convert.jsonDecode(input) : input;
    final context = DecoderResolutionContext(
      registry: activeRegistry,
      symbolResolver: _resolver,
      customFactories: customFactories ?? {},
      strictUnknownValidators: strictUnknownValidators,
    );

    return _decodeNode(parsed, context);
  }

  IValidator _decodeNode(dynamic node, DecoderResolutionContext context) {
    if (node is String) {
      return _decodeString(node, context);
    }

    if (node is Map<String, dynamic>) {
      return _decodeMap(node, context);
    }

    if (node is List) {
      return _decodeList(node, context);
    }

    throw DecodeException.invalidType('String, List, or Map', node, null);
  }

  IValidator _decodeString(
    String str,
    DecoderResolutionContext context,
  ) {
    final modifiers = parsePrefixModifiers(str);
    final symbol = modifiers.applyToString(str);

    if (symbol.startsWith('@')) {
      final val = resolveDecodedValidator(
        context: context,
        token: symbol.substring(1),
        args: const [],
        isCustom: true,
        source: str,
        offset: null,
      );

      return applyDecodedModifiers(val, modifiers);
    }

    final val = resolveDecodedValidator(
      context: context,
      token: symbol,
      args: const [],
      isCustom: false,
      source: str,
      offset: null,
    );

    return applyDecodedModifiers(val, modifiers);
  }

  IValidator _decodeMap(
    Map<String, dynamic> map,
    DecoderResolutionContext context,
  ) {
    final fields = <Field>[];

    for (final entry in map.entries) {
      final key = entry.key;
      final value = entry.value;

      if (value is String) {
        final modifiers = parsePrefixModifiers(value);
        final cleanStr = modifiers.applyToString(value);
        final validator = _decodeString(cleanStr, context);
        fields.add(createDecodedField(
          id: key,
          validator: validator,
          nullable: modifiers.isNullable,
          optional: modifiers.isOptional,
        ));
      } else if (value is List) {
        if (value.isNotEmpty && value.first is String) {
          final prefix = value.first as String;

          if (isModifierPrefixToken(prefix)) {
            final modifiers = parsePrefixModifiers(prefix);
            final innerNode = value.length == 2 ? value[1] : value.sublist(1);
            final validator = _decodeNode(innerNode, context);
            fields.add(createDecodedField(
              id: key,
              validator: validator,
              nullable: modifiers.isNullable,
              optional: modifiers.isOptional,
            ));
            continue;
          }
        }

        final validator = _decodeList(value, context);
        fields.add(createDecodedField(
          id: key,
          validator: validator,
          nullable: false,
          optional: false,
        ));
      } else {
        final validator = _decodeNode(value, context);
        fields.add(createDecodedField(
          id: key,
          validator: validator,
          nullable: false,
          optional: false,
        ));
      }
    }

    return DecodedMapValidator(fields, name: 'eskema');
  }

  IValidator _decodeList(
    List list,
    DecoderResolutionContext context,
  ) {
    if (list.isEmpty) {
      throw DecodeException.unexpectedEndOfInput(list, null);
    }

    // Check infix operators: scan for "&" or "|" at odd indices
    if (list.length >= 3 && _hasInfixOperator(list)) {
      return _decodeInfix(list, context);
    }

    // Standard parameterized validator: [symbol, arg1, arg2, ...]
    final first = list.first;

    if (first is! String) {
      throw DecodeException.invalidType(
          'String as first element of validator list', list, null);
    }

    // Handle custom validators
    if (first.startsWith('@')) {
      final args = list.sublist(1).map((a) => _resolveValue(a, context)).toList();

      return resolveDecodedValidator(
        context: context,
        token: first.substring(1),
        args: args,
        isCustom: true,
        source: list,
        offset: null,
      );
    }

    final args = list.sublist(1).map((a) => _resolveValue(a, context)).toList();

    return resolveDecodedValidator(
      context: context,
      token: first,
      args: args,
      isCustom: false,
      source: list,
      offset: null,
    );
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
    DecoderResolutionContext context,
  ) {
    // Collect operands (even indices) and verify operators (odd indices)
    final operands = <IValidator>[];
    String? operator;

    for (var i = 0; i < list.length; i++) {
      if (i.isEven) {
        operands.add(_decodeNode(list[i], context));
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
    DecoderResolutionContext context,
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
        final name = context.symbolResolver.nameOfSymbol(first) ?? first;

        if (context.registry.factories.containsKey(name) || first.startsWith('@')) {
          return _decodeNode(value, context);
        }
      }

      // Otherwise treat as a plain list of values
      return value.map((v) => _resolveValue(v, context)).toList();
    }

    if (value is Map<String, dynamic>) {
      try {
        return _decodeNode(value, context);
      } catch (e) {
        return value.map((k, v) => MapEntry(k, _resolveValue(v, context)));
      }
    }

    // primitives: int, double, bool, null
    return value;
  }
}
