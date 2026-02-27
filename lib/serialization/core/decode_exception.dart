/// The [DecodeExceptionType] enum.
enum DecodeExceptionType {
  /// Documentation for this public member.
  unexpectedEndOfInput,

  /// Documentation for this public member.
  missingClosingParenthesis,

  /// Documentation for this public member.
  missingClosingBrace,

  /// Documentation for this public member.
  missingColon,

  /// Documentation for this public member.
  missingIdentifier,

  /// Documentation for this public member.
  unknownValidator,

  /// Documentation for this public member.
  unknownCustomValidator,

  /// Documentation for this public member.
  unclosedString,

  /// Documentation for this public member.
  invalidType,
}

/// The [DecodeException] class.
class DecodeException extends FormatException {
  /// The [type] property.
  final DecodeExceptionType type;

  /// Executes the [DecodeException] operation.
  const DecodeException({
    required String message,
    required dynamic source,
    int? offset,
    required this.type,
  }) : super(message, source, offset);

  /// Executes the [unexpectedEndOfInput] operation.
  factory DecodeException.unexpectedEndOfInput(dynamic source, int? offset) =>
      DecodeException(
          message: 'Unexpected end of input',
          source: source,
          offset: offset,
          type: DecodeExceptionType.unexpectedEndOfInput);

  /// Executes the [missingClosingParenthesis] operation.
  factory DecodeException.missingClosingParenthesis(
          dynamic source, int? offset) =>
      DecodeException(
          message: 'Expected )',
          source: source,
          offset: offset,
          type: DecodeExceptionType.missingClosingParenthesis);

  /// Executes the [missingClosingBrace] operation.
  factory DecodeException.missingClosingBrace(dynamic source, int? offset) =>
      DecodeException(
          message: 'Expected }',
          source: source,
          offset: offset,
          type: DecodeExceptionType.missingClosingBrace);

  /// Executes the [missingColon] operation.
  factory DecodeException.missingColon(
          dynamic key, dynamic source, int? offset) =>
      DecodeException(
          message: 'Expected : after map key \$key',
          source: source,
          offset: offset,
          type: DecodeExceptionType.missingColon);

  /// Executes the [missingIdentifier] operation.
  factory DecodeException.missingIdentifier(dynamic source, int? offset) =>
      DecodeException(
          message: 'Expected identifier',
          source: source,
          offset: offset,
          type: DecodeExceptionType.missingIdentifier);

  /// Executes the [unknownCustomValidator] operation.
  factory DecodeException.unknownCustomValidator(
          String sym, dynamic source, int? offset) =>
      DecodeException(
          message: 'Unknown custom validator: @$sym',
          source: source,
          offset: offset,
          type: DecodeExceptionType.unknownCustomValidator);

  /// Executes the [unknownValidator] operation.
  factory DecodeException.unknownValidator(
          String sym, dynamic source, int? offset) =>
      DecodeException(
          message: 'Unknown validator symbol or name: $sym',
          source: source,
          offset: offset,
          type: DecodeExceptionType.unknownValidator);

  /// Executes the [unclosedString] operation.
  factory DecodeException.unclosedString(dynamic source, int? offset) =>
      DecodeException(
          message: 'Unclosed string',
          source: source,
          offset: offset,
          type: DecodeExceptionType.unclosedString);

  /// Executes the [invalidType] operation.
  factory DecodeException.invalidType(
          String expected, dynamic source, int? offset) =>
      DecodeException(
          message: 'Invalid type: expected \$expected',
          source: source,
          offset: offset,
          type: DecodeExceptionType.invalidType);
}
