part of '../eskema_decoder.dart';

extension _DecoderParserTokenMethods on _DecoderParser {
  String parseIdentifier() {
    skipWhitespace();
    final start = pos;
    while (pos < input.length && isAsciiIdentifierCodeUnit(input.codeUnitAt(pos))) {
      pos++;
    }
    if (start == pos) {
      if (peek("'") || peek('"')) {
        return parseString();
      }
      throw DecodeException.missingIdentifier(input, pos);
    }
    return input.substring(start, pos);
  }

  String _readSymbolToken({required bool isCustom}) {
    final startPosBeforeId = pos;
    final tokenResult = readEskemaSymbolToken(
      input: input,
      startPos: pos,
      isKnownValidator: _isKnownValidator,
    );
    pos = tokenResult.nextPos;
    final sym = tokenResult.token;

    if (pos == startPosBeforeId && !isCustom && sym.isEmpty && pos < input.length) {
      throw DecodeException.missingIdentifier(input, pos);
    }

    return sym;
  }

  List<dynamic> _readCallArgs({required bool isCustom, required String symbol}) {
    final args = <dynamic>[];

    if (match('(')) {
      while (!match(')')) {
        if (pos >= input.length) {
          throw DecodeException.missingClosingParenthesis(input, pos);
        }

        args.add(parseValue());
        match(',');
      }

      return args;
    }

    if (!isCustom && symbol.isNotEmpty && !_isNoArgSymbol(symbol)) {
      skipWhitespace();
      if (pos < input.length && isEskemaValueStartCodeUnit(input.codeUnitAt(pos))) {
        args.add(parseValue());
      }
    }

    return args;
  }

  bool _isKnownValidator(String sym) {
    if (_resolutionContext.symbolResolver.nameOfSymbol(sym) != null) return true;
    if (_resolutionContext.registry.factories.containsKey(sym)) return true;
    return false;
  }

  bool _isNoArgSymbol(String sym) {
    final name = _resolutionContext.symbolResolver.nameOfSymbol(sym) ?? sym;
    return noArgValidators.contains(name);
  }

  ({bool isOptional, bool isNullable}) _readStreamModifiers() {
    var optional = false;
    var nullable = false;

    if (match('*')) {
      optional = true;
    }

    if (match('?')) {
      nullable = true;
    }

    return (isOptional: optional, isNullable: nullable);
  }
}
