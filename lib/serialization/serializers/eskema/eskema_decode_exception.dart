enum EskemaDecodeExceptionType {
  unexpectedEndOfInput,
  missingClosingParenthesis,
  missingClosingBrace,
  missingColon,
  missingIdentifier,
  unknownCustomValidator,
  unclosedString,
}

class EskemaDecodeException extends FormatException {
  final EskemaDecodeExceptionType type;

  const EskemaDecodeException({
    required String message,
    required String source,
    required int offset,
    required this.type,
  }) : super(message, source, offset);

  factory EskemaDecodeException.unexpectedEndOfInput(String source, int offset) =>
      EskemaDecodeException(message: 'Unexpected end of input', source: source, offset: offset, type: EskemaDecodeExceptionType.unexpectedEndOfInput);

  factory EskemaDecodeException.missingClosingParenthesis(String source, int offset) =>
      EskemaDecodeException(message: 'Expected )', source: source, offset: offset, type: EskemaDecodeExceptionType.missingClosingParenthesis);

  factory EskemaDecodeException.missingClosingBrace(String source, int offset) =>
      EskemaDecodeException(message: 'Expected }', source: source, offset: offset, type: EskemaDecodeExceptionType.missingClosingBrace);

  factory EskemaDecodeException.missingColon(String key, String source, int offset) =>
      EskemaDecodeException(message: 'Expected : after map key \$key', source: source, offset: offset, type: EskemaDecodeExceptionType.missingColon);

  factory EskemaDecodeException.missingIdentifier(String source, int offset) =>
      EskemaDecodeException(message: 'Expected identifier', source: source, offset: offset, type: EskemaDecodeExceptionType.missingIdentifier);

  factory EskemaDecodeException.unknownCustomValidator(String sym, String source, int offset) =>
      EskemaDecodeException(message: 'Unknown custom validator: @\$sym', source: source, offset: offset, type: EskemaDecodeExceptionType.unknownCustomValidator);

  factory EskemaDecodeException.unclosedString(String source, int offset) =>
      EskemaDecodeException(message: 'Unclosed string', source: source, offset: offset, type: EskemaDecodeExceptionType.unclosedString);
}
