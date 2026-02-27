part of '../eskema_decoder.dart';

const _eskemaNestedValueOptions = NestedValueResolutionOptions(
  unwrapSingleQuotedStrings: false,
  tryDecodeMapsAsValidators: false,
);

extension _DecoderParserValueMethods on _DecoderParser {
  dynamic parseValue() {
    skipWhitespace();

    if (peek("'") || peek('"')) {
      return parseString();
    }

    if (peek('[')) {
      match('[');

      final list = <dynamic>[];

      while (!match(']')) {
        list.add(parseValue());
        match(',');
      }

      return resolveNestedDecodedValue(
        value: list,
        context: _resolutionContext,
        decodeNode: (node) => parseValidatorCore(),
        options: _eskemaNestedValueOptions,
      );
    }

    final numeric = _tryReadNumericValue();
    if (numeric != null) {
      return numeric;
    }

    final literalOrIdentifier = _tryReadLiteralIdentifier();
    if (literalOrIdentifier case final value?) {
      return value;
    }

    final primitive = _matchPrimitiveKeyword();
    if (primitive case final value?) {
      return value;
    }

    return parseValidatorCore();
  }

  String parseString() {
    final quote = input[pos];

    pos++;

    final start = pos;

    while (pos < input.length && input[pos] != quote) {
      if (input[pos] == '\\') {
        pos++;

        if (pos >= input.length) break;
      }

      pos++;
    }

    if (pos >= input.length) {
      throw DecodeException.unclosedString(input, start);
    }

    final str = input.substring(start, pos);
    pos++;

    return str.replaceAll("\\'", "'").replaceAll('\\"', '"');
  }

  num? _tryReadNumericValue() {
    final start = pos;
    var isNum = false;

    if (input[pos] == '-') {
      pos++;
      isNum = true;
    }

    while (pos < input.length && isAsciiNumericOrDotCodeUnit(input.codeUnitAt(pos))) {
      pos++;
      isNum = true;
    }

    if (isNum && pos > start && start != pos - (input[start] == '-' ? 1 : 0)) {
      final strNode = input.substring(start, pos);
      if (strNode.contains('.')) {
        return double.parse(strNode);
      }

      return int.parse(strNode);
    }

    pos = start;
    return null;
  }

  dynamic _tryReadLiteralIdentifier() {
    final startId = pos;

    while (pos < input.length && isAsciiIdentifierCodeUnit(input.codeUnitAt(pos))) {
      pos++;
    }

    if (pos == startId) {
      return null;
    }

    final id = input.substring(startId, pos);
    final literal = tryParsePrimitiveLiteral(id);
    if (literal is! String) {
      return literal;
    }

    final mapped = _resolutionContext.symbolResolver.nameOfSymbol(id);
    if (mapped == null) {
      return id;
    }

    pos = startId;
    return null;
  }

  dynamic _matchPrimitiveKeyword() {
    if (match('true')) {
      return true;
    }

    if (match('false')) {
      return false;
    }

    if (match('null')) {
      return null;
    }

    return null;
  }
}
