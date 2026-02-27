enum DecodeExceptionType {
  unexpectedEndOfInput,
  missingClosingParenthesis,
  missingClosingBrace,
  missingColon,
  missingIdentifier,
  unknownCustomValidator,
  unclosedString,
  invalidType,
}

class DecodeException extends FormatException {
  final DecodeExceptionType type;

  const DecodeException({
    required String message,
    required dynamic source,
    int? offset,
    required this.type,
  }) : super(message, source, offset);

  factory DecodeException.unexpectedEndOfInput(dynamic source, int? offset) =>
      DecodeException(message: 'Unexpected end of input', source: source, offset: offset, type: DecodeExceptionType.unexpectedEndOfInput);

  factory DecodeException.missingClosingParenthesis(dynamic source, int? offset) =>
      DecodeException(message: 'Expected )', source: source, offset: offset, type: DecodeExceptionType.missingClosingParenthesis);

  factory DecodeException.missingClosingBrace(dynamic source, int? offset) =>
      DecodeException(message: 'Expected }', source: source, offset: offset, type: DecodeExceptionType.missingClosingBrace);

  factory DecodeException.missingColon(dynamic key, dynamic source, int? offset) =>
      DecodeException(message: 'Expected : after map key \$key', source: source, offset: offset, type: DecodeExceptionType.missingColon);

  factory DecodeException.missingIdentifier(dynamic source, int? offset) =>
      DecodeException(message: 'Expected identifier', source: source, offset: offset, type: DecodeExceptionType.missingIdentifier);

  factory DecodeException.unknownCustomValidator(String sym, dynamic source, int? offset) =>
      DecodeException(message: 'Unknown custom validator: @\$sym', source: source, offset: offset, type: DecodeExceptionType.unknownCustomValidator);

  factory DecodeException.unclosedString(dynamic source, int? offset) =>
      DecodeException(message: 'Unclosed string', source: source, offset: offset, type: DecodeExceptionType.unclosedString);
      
  factory DecodeException.invalidType(String expected, dynamic source, int? offset) =>
      DecodeException(message: 'Invalid type: expected \$expected', source: source, offset: offset, type: DecodeExceptionType.invalidType);
}
