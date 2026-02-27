const Set<String> defaultEskemaSymbolExtraChars = {
  '!',
  '=',
  '<',
  '>',
  '~',
  '&',
  '|',
  '[',
  ']',
  '/',
  '-',
};

bool isAsciiIdentifierCodeUnit(int codeUnit) {
  return (codeUnit >= 48 && codeUnit <= 57) ||
      (codeUnit >= 65 && codeUnit <= 90) ||
      (codeUnit >= 97 && codeUnit <= 122) ||
      codeUnit == 95;
}

bool isAsciiNumericOrDotCodeUnit(int codeUnit) {
  return (codeUnit >= 48 && codeUnit <= 57) || codeUnit == 46;
}

bool isEskemaValueStartCodeUnit(int codeUnit) {
  return (codeUnit >= 48 && codeUnit <= 57) ||
      codeUnit == 45 ||
      codeUnit == 46 ||
      codeUnit == 39 ||
      codeUnit == 34 ||
      codeUnit == 91 ||
      codeUnit == 123 ||
      codeUnit == 40 ||
      (codeUnit >= 65 && codeUnit <= 90) ||
      (codeUnit >= 97 && codeUnit <= 122);
}

({String token, int nextPos}) readEskemaSymbolToken({
  required String input,
  required int startPos,
  required bool Function(String) isKnownValidator,
  Set<String> symbolExtraChars = defaultEskemaSymbolExtraChars,
}) {
  var scanPos = startPos;
  var longestSymbolMatch = -1;

  while (scanPos < input.length) {
    final codeUnit = input.codeUnitAt(scanPos);
    final isIdentifier = isAsciiIdentifierCodeUnit(codeUnit);
    final asChar = String.fromCharCode(codeUnit);
    final isExtraSymbol = symbolExtraChars.contains(asChar);

    if (!isIdentifier && !isExtraSymbol) {
      break;
    }

    if (asChar == '(' || asChar == '{' || asChar == ' ') {
      break;
    }

    scanPos++;
    final current = input.substring(startPos, scanPos);
    if (isKnownValidator(current)) {
      longestSymbolMatch = scanPos;
    }
  }

  if (longestSymbolMatch != -1) {
    return (
      token: input.substring(startPos, longestSymbolMatch),
      nextPos: longestSymbolMatch,
    );
  }

  var identifierPos = startPos;
  while (identifierPos < input.length &&
      isAsciiIdentifierCodeUnit(input.codeUnitAt(identifierPos))) {
    identifierPos++;
  }

  return (
    token: input.substring(startPos, identifierPos),
    nextPos: identifierPos,
  );
}
