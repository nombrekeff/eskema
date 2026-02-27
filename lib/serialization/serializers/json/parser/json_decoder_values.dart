part of '../json_decoder.dart';

const _jsonNestedValueOptions = NestedValueResolutionOptions(
  unwrapSingleQuotedStrings: true,
  tryDecodeMapsAsValidators: true,
  shouldDecodeListAsValidator: _shouldDecodeJsonListAsValidator,
);

bool _shouldDecodeJsonListAsValidator(
    List value, DecoderResolutionContext context) {
  if (value.isEmpty || value.first is! String) {
    return false;
  }

  final first = value.first as String;
  final name = context.symbolResolver.nameOfSymbol(first) ?? first;
  return context.registry.factories.containsKey(name) || first.startsWith('@');
}

dynamic _jsonResolveValue(
  JsonDecoder decoder,
  dynamic value,
  DecoderResolutionContext context,
) {
  return resolveNestedDecodedValue(
    value: value,
    context: context,
    decodeNode: (node) => _jsonDecodeNode(decoder, node, context),
    options: _jsonNestedValueOptions,
  );
}
