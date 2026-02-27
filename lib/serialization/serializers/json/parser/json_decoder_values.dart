part of '../json_decoder.dart';

dynamic _jsonResolveValue(
  JsonDecoder decoder,
  dynamic value,
  DecoderResolutionContext context,
) {
  if (value is String) {
    if (value.startsWith("'") && value.endsWith("'") && value.length >= 2) {
      return value.substring(1, value.length - 1);
    }

    return value;
  }

  if (value is List) {
    if (value.isNotEmpty && value.first is String) {
      final first = value.first as String;
      final name = context.symbolResolver.nameOfSymbol(first) ?? first;

      if (context.registry.factories.containsKey(name) || first.startsWith('@')) {
        return _jsonDecodeNode(decoder, value, context);
      }
    }

    return value.map((v) => _jsonResolveValue(decoder, v, context)).toList();
  }

  if (value is Map<String, dynamic>) {
    try {
      return _jsonDecodeNode(decoder, value, context);
    } catch (_) {
      return value.map((k, v) => MapEntry(k, _jsonResolveValue(decoder, v, context)));
    }
  }

  return value;
}
