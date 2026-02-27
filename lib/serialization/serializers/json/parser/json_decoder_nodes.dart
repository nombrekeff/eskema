part of '../json_decoder.dart';

IValidator _jsonDecodeNode(
  JsonDecoder decoder,
  dynamic node,
  DecoderResolutionContext context,
) {
  return dispatchDecodedNode<IValidator>(
    node: node,
    onString: (value) => _jsonDecodeString(decoder, value, context),
    onList: (value) => _jsonDecodeList(decoder, value, context),
    onMap: (value) => _jsonDecodeMap(decoder, value, context),
    source: node,
  );
}

IValidator _jsonDecodeString(
  JsonDecoder decoder,
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

IValidator _jsonDecodeMap(
  JsonDecoder decoder,
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
      final validator = _jsonDecodeString(decoder, cleanStr, context);
      fields.add(createDecodedField(
        id: key,
        validator: validator,
        nullable: modifiers.isNullable,
        optional: modifiers.isOptional,
      ));
      continue;
    }

    if (value is List) {
      if (value.isNotEmpty && value.first is String) {
        final prefix = value.first as String;

        if (isModifierPrefixToken(prefix)) {
          final modifiers = parsePrefixModifiers(prefix);
          final innerNode = value.length == 2 ? value[1] : value.sublist(1);
          final validator = _jsonDecodeNode(decoder, innerNode, context);
          fields.add(createDecodedField(
            id: key,
            validator: validator,
            nullable: modifiers.isNullable,
            optional: modifiers.isOptional,
          ));
          continue;
        }
      }

      final validator = _jsonDecodeList(decoder, value, context);
      fields.add(createDecodedField(
        id: key,
        validator: validator,
        nullable: false,
        optional: false,
      ));
      continue;
    }

    final validator = _jsonDecodeNode(decoder, value, context);
    fields.add(createDecodedField(
      id: key,
      validator: validator,
      nullable: false,
      optional: false,
    ));
  }

  return DecodedMapValidator(fields, name: 'eskema');
}

IValidator _jsonDecodeList(
  JsonDecoder decoder,
  List list,
  DecoderResolutionContext context,
) {
  if (list.isEmpty) {
    throw DecodeException.unexpectedEndOfInput(list, null);
  }

  if (list.length >= 3 && _jsonHasInfixOperator(list)) {
    return _jsonDecodeInfix(decoder, list, context);
  }

  final first = list.first;
  if (first is! String) {
    throw DecodeException.invalidType(
        'String as first element of validator list', list, null);
  }

  final args = list
      .sublist(1)
      .map((a) => _jsonResolveValue(decoder, a, context))
      .toList();

  if (first.startsWith('@')) {
    return resolveDecodedValidator(
      context: context,
      token: first.substring(1),
      args: args,
      isCustom: true,
      source: list,
      offset: null,
    );
  }

  return resolveDecodedValidator(
    context: context,
    token: first,
    args: args,
    isCustom: false,
    source: list,
    offset: null,
  );
}

bool _jsonHasInfixOperator(List list) {
  for (var i = 1; i < list.length; i += 2) {
    if (list[i] is String && (list[i] == '&' || list[i] == '|')) {
      return true;
    }
  }

  return false;
}

IValidator _jsonDecodeInfix(
  JsonDecoder decoder,
  List list,
  DecoderResolutionContext context,
) {
  final operands = <IValidator>[];

  for (var i = 0; i < list.length; i++) {
    if (i.isEven) {
      operands.add(_jsonDecodeNode(decoder, list[i], context));
    }
  }

  final operator = resolveUniformInfixCombinatorOperator(list, source: list);
  return composeCombinatorValidator(
    operator: operator,
    operands: operands,
    source: list,
  );
}
