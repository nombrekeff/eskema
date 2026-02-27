import 'package:eskema/eskema.dart';

/// Decodes an eskema string into a validator.
///
/// Head over to the [Encoding](https://github.com/nombrekeff/eskema/wiki/Encoding) section of the wiki for a comprehensive guide.
///
/// Example:
/// ```dart
/// final validator = const EskemaDecoder().decode('int & =(5)');
/// // same as
/// final validator = all([isInt, isEq(5)]);
/// ```
class EskemaDecoder extends DelegateValidatorDecoder<String> {
  /// Custom symbols to use for decoding.
  ///
  /// Example:
  /// ```dart
  /// final validator = const EskemaDecoder(customSymbols: {'&': 'all'}).decode('int & =(5)');
  /// // same as
  /// final validator = all([isInt, isEq(5)]);
  /// ```
  final Map<String, String>? customSymbols;
  final bool strictUnknownValidators;

  const EskemaDecoder({
    this.customSymbols,
    this.strictUnknownValidators = false,
  });

  /// Decodes an eskema string into a validator.
  ///
  /// Head over to the [Encoding](https://github.com/nombrekeff/eskema/wiki/Encoding) section of the wiki for a comprehensive guide.
  ///
  /// Example:
  /// ```dart
  /// final validator = const EskemaDecoder().decode('int & =(5)');
  /// // same as
  /// final validator = all([isInt, isEq(5)]);
  /// ```
  @override
  IValidator decode(
    String input, {
    Map<String, Function>? customFactories,
    ValidatorRegistry? registry,
  }) {
    final activeRegistry = registry ?? defaultRegistry;
    final parser = _DecoderParser(
      input,
      customFactories ?? {},
      activeRegistry,
      customSymbols,
      strictUnknownValidators,
    );

    return parser.parseTopLevel();
  }
}

class _DecoderParser {
  final String input;
  final Map<String, Function> customFactories;
  final ValidatorRegistry registry;
  final Map<String, String>? customSymbols;
  final bool strictUnknownValidators;

  SymbolResolver get _resolver => SymbolResolver(customSymbolToName: customSymbols);

  late final DecoderResolutionContext _resolutionContext = DecoderResolutionContext(
    registry: registry,
    symbolResolver: _resolver,
    customFactories: customFactories,
    strictUnknownValidators: strictUnknownValidators,
    allowUnknownCustomFallback: (name) => name == 'custom',
  );

  int pos = 0;

  _DecoderParser(
    this.input,
    this.customFactories,
    this.registry,
    this.customSymbols,
    this.strictUnknownValidators,
  );

  void skipWhitespace() {
    while (pos < input.length && input.codeUnitAt(pos) <= 32) {
      pos++;
    }
  }

  bool match(String str) {
    skipWhitespace();

    if (input.startsWith(str, pos)) {
      pos += str.length;

      return true;
    }

    return false;
  }

  bool peek(String str) {
    skipWhitespace();

    return input.startsWith(str, pos);
  }

  IValidator parseTopLevel() {
    return parseValidator();
  }

  IValidator parseValidator() {
    skipWhitespace();

    if (pos >= input.length) {
      throw DecodeException.unexpectedEndOfInput(input, pos);
    }

    final modifiers = _readStreamModifiers();

    var val = _parseComposedValidator();
    val = _parseImplicitCombinatorChain(val);

    return _applyStreamModifiers(val, modifiers);
  }

  IValidator _parseComposedValidator() {
    if (match('(')) {
      return _parseParenthesizedValidator();
    }

    if (match('{')) {
      return parseMap();
    }

    return parseCall();
  }

  IValidator _parseParenthesizedValidator() {
    final terms = <IValidator>[parseValidator()];
    final combinator = _readCombinatorToken();

    if (combinator != null) {
      terms.add(parseValidator());
      while (match(combinator)) {
        terms.add(parseValidator());
      }
    }

    if (!match(')')) {
      throw DecodeException.missingClosingParenthesis(input, pos);
    }

    if (combinator == '&') {
      return all(terms);
    }

    if (combinator == '|') {
      return any(terms);
    }

    return terms.first;
  }

  String? _readCombinatorToken() {
    skipWhitespace();
    if (match('&')) {
      return '&';
    }

    if (match('|')) {
      return '|';
    }

    return null;
  }

  IValidator _parseImplicitCombinatorChain(IValidator first) {
    skipWhitespace();

    if (pos < input.length && peek('&') && !peek('&&')) {
      return _readImplicitChain(first, '&');
    }

    if (pos < input.length && peek('|') && !peek('||')) {
      return _readImplicitChain(first, '|');
    }

    return first;
  }

  IValidator _readImplicitChain(IValidator first, String op) {
    final terms = <IValidator>[first];
    while (match(op)) {
      terms.add(parseValidatorCore());
    }

    return op == '&' ? all(terms) : any(terms);
  }

  IValidator _applyStreamModifiers(
    IValidator validator,
    ({bool isOptional, bool isNullable}) modifiers,
  ) {
    var result = validator;

    if (modifiers.isNullable) {
      result = result.nullable();
    }

    if (modifiers.isOptional) {
      result = result.optional();
    }

    return result;
  }

  IValidator parseValidatorCore() {
    skipWhitespace();

    if (match('(')) {
      final v = parseValidator();

      if (!match(')')) {
        throw DecodeException.missingClosingParenthesis(input, pos);
      }

      return v;
    } else if (match('{')) {
      return parseMap();
    } else {
      return parseCall();
    }
  }

  IValidator parseMap() {
    final fields = <Field>[];

    while (!match('}')) {
      if (pos >= input.length) throw DecodeException.missingClosingBrace(input, pos);

      final key = parseIdentifier();

      if (!match(':')) {
        throw DecodeException.missingColon(key, input, pos);
      }

      final modifiers = _readStreamModifiers();

      // field value could be a chain of & operators without parens
      final valStart = pos;
      final val = parseValidator(); // parseValidator handles implicit &

      List<IValidator> fieldValidators = [val];
      final parsedStr = input.substring(valStart, pos).trim();

      if (val.name == 'all' && !parsedStr.startsWith('(')) {
        fieldValidators = val.args.cast<IValidator>().toList();
      }

      final field = Field(
        id: key,
        validators: fieldValidators,
        optional: modifiers.isOptional,
        nullable: modifiers.isNullable,
      );
      fields.add(field);

      match(','); // optional trailing comma
    }
    return DecodedMapValidator(fields, name: 'eskema');
  }

  String parseIdentifier() {
    skipWhitespace();
    final start = pos;
    while (pos < input.length && isAsciiIdentifierCodeUnit(input.codeUnitAt(pos))) {
      pos++;
    }
    if (start == pos) {
      // maybe quote?
      if (peek("'") || peek('"')) {
        return parseString();
      }
      throw DecodeException.missingIdentifier(input, pos);
    }
    return input.substring(start, pos);
  }

  IValidator parseCall() {
    skipWhitespace();

    final start = pos;
    final isCustom = match('@');
    final sym = _readSymbolToken(isCustom: isCustom);
    final args = _readCallArgs(isCustom: isCustom, symbol: sym);

    if (isCustom) {
      return resolveDecodedValidator(
        context: _resolutionContext,
        token: sym,
        args: args,
        isCustom: true,
        source: input,
        offset: start,
      );
    }

    return resolveDecodedValidator(
      context: _resolutionContext,
      token: sym,
      args: args,
      isCustom: false,
      source: input,
      offset: start,
    );
  }

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

      return list;
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

    // Could be an inner validator?
    return parseValidatorCore();
  }

  String parseString() {
    final quote = input[pos];

    pos++;

    final start = pos;

    while (pos < input.length && input[pos] != quote) {
      if (input[pos] == '\\') {
        pos++; // skip escaped

        if (pos >= input.length) break;
      }

      pos++;
    }

    if (pos >= input.length) {
      throw DecodeException.unclosedString(input, start);
    }

    final str = input.substring(start, pos);
    pos++; // skip closing quote

    return str.replaceAll("\\'", "'").replaceAll('\\"', '"');
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

    final mapped = _resolver.nameOfSymbol(id);
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

  bool _isKnownValidator(String sym) {
    if (customSymbols?.containsKey(sym) ?? false) return true;
    if (defaultSymbolToName.containsKey(sym)) return true;
    if (registry.factories.containsKey(sym)) return true;
    return false;
  }

  bool _isNoArgSymbol(String sym) {
    final name = _resolver.nameOfSymbol(sym) ?? sym;
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
