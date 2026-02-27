import 'package:eskema/eskema.dart';
import 'package:eskema/serialization/default_registry.dart';
import 'package:eskema/serialization/core/registry.dart';
import 'package:eskema/serialization/serializers/eskema/eskema_decode_exception.dart';
import '../../core/decoder.dart';
import 'eskema_encoder.dart' show defaultNameToSymbol;

final _defaultSymbolToName = defaultNameToSymbol.map((k, v) => MapEntry(v, k));

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

  const EskemaDecoder({this.customSymbols});

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
    final parser = _DecoderParser(input, customFactories ?? {}, activeRegistry, customSymbols);

    return parser.parseTopLevel();
  }
}

class _DecoderParser {
  final String input;
  final Map<String, Function> customFactories;
  final ValidatorRegistry registry;
  final Map<String, String>? customSymbols;
  int pos = 0;

  _DecoderParser(this.input, this.customFactories, this.registry, this.customSymbols);

  String? _getName(String symbol) {
    if (customSymbols != null && customSymbols!.containsKey(symbol)) {
      return customSymbols![symbol]!;
    }

    return _defaultSymbolToName[symbol];
  }

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
      throw EskemaDecodeException.unexpectedEndOfInput(input, pos);
    }

    bool optional = false;
    bool nullable = false;

    if (match('*')) optional = true;

    if (match('?')) nullable = true;

    IValidator val;

    if (match('(')) {
      final terms = <IValidator>[];
      terms.add(parseValidator());

      // we assume it"s something like (A & B) or (A | B)
      skipWhitespace();
      String combinator = '';

      if (match('&')) {
        combinator = '&';
      } else if (match('|')) {
        combinator = '|';
      }

      if (combinator.isNotEmpty) {
        terms.add(parseValidator());

        while (match(combinator)) {
          terms.add(parseValidator());
        }
      }

      if (!match(')')) {
        throw EskemaDecodeException.missingClosingParenthesis(input, pos);
      }

      if (combinator == '&') {
        val = all(terms);
      } else if (combinator == '|') {
        val = any(terms);
      } else {
        val = terms[0];
      }
    } else if (match('{')) {
      val = parseMap();
    } else {
      val = parseCall();
    }

    // handle implicit & without parens if applicable or chaining?
    skipWhitespace();

    if (pos < input.length && peek('&') && !peek('&&')) {
      // We read `&` here and chain it
      final terms = <IValidator>[val];

      while (match('&')) {
        terms.add(parseValidatorCore());
      }

      val = all(terms);
    } else if (pos < input.length && peek('|') && !peek('||')) {
      final terms = <IValidator>[val];

      while (match('|')) {
        terms.add(parseValidatorCore());
      }

      val = any(terms);
    }

    if (nullable) val = val.nullable();

    if (optional) val = val.optional();

    return val;
  }

  IValidator parseValidatorCore() {
    skipWhitespace();

    if (match('(')) {
      final v = parseValidator();
      match(')');

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
      if (pos >= input.length) throw EskemaDecodeException.missingClosingBrace(input, pos);

      final key = parseIdentifier();

      if (!match(':')) {
        throw EskemaDecodeException.missingColon(key, input, pos);
      }

      bool optional = false;
      bool nullable = false;

      if (match('*')) optional = true;

      if (match('?')) nullable = true;

      // field value could be a chain of & operators without parens
      final valStart = pos;
      final val = parseValidator(); // parseValidator handles implicit &

      List<IValidator> fieldValidators = [val];
      final parsedStr = input.substring(valStart, pos).trim();

      if (val.name == 'all' && !parsedStr.startsWith('(')) {
        fieldValidators = val.arguments.cast<IValidator>().toList();
      }

      final field = Field(
        id: key,
        validators: fieldValidators,
        optional: optional,
        nullable: nullable,
      );
      fields.add(field);

      match(','); // optional trailing comma
    }
    return _DecodedMapValidator(fields);
  }

  String parseIdentifier() {
    skipWhitespace();
    final start = pos;
    // can be simple words
    while (pos < input.length && RegExp(r'[a-zA-Z0-9_]').hasMatch(input[pos])) {
      pos++;
    }
    if (start == pos) {
      // maybe quote?
      if (peek("'") || peek('"')) {
        return parseString();
      }
      throw EskemaDecodeException.missingIdentifier(input, pos);
    }
    return input.substring(start, pos);
  }

  IValidator parseCall() {
    skipWhitespace();

    final start = pos;
    final isCustom = match('@');
    final nameStart = pos;

    while (pos < input.length && RegExp(r'[a-zA-Z0-9_!=\<\>~&\|\[\]]').hasMatch(input[pos])) {
      pos++;
    }

    final sym = input.substring(nameStart, pos);

    final args = <dynamic>[];

    if (match('(')) {
      while (!match(')')) {
        if (pos >= input.length) {
          throw EskemaDecodeException.missingClosingParenthesis(input, pos);
        }

        args.add(parseValue());
        match(',');
      }
    }

    if (isCustom) {
      if (!customFactories.containsKey(sym)) {
        throw EskemaDecodeException.unknownCustomValidator(sym, input, start);
      }

      return customFactories[sym]!(args) as IValidator;
    }

    final String name = _getName(sym) ?? sym;

    try {
      return registry.createValidator(name, args);
    } catch (e) {
      // By default, if it's not registered, assume a dynamic validator wrapper
      return isType<dynamic>().copyWith(name: name, arguments: args);
    }
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

    // Check if it's a number
    final start = pos;
    bool isNum = false;

    if (input[pos] == '-') {
      pos++;
      isNum = true;
    }

    while (pos < input.length && RegExp(r'[0-9\.]').hasMatch(input[pos])) {
      pos++;
      isNum = true;
    }

    // Wait, if it didn't match any digits
    if (isNum && pos > start && start != pos - (input[start] == '-' ? 1 : 0)) {
      final strNode = input.substring(start, pos);
      
      if (strNode.contains('.')) return double.parse(strNode);

      return int.parse(strNode);
    }

    // reset pos if not num
    pos = start;

    final startId = pos;

    while (pos < input.length && RegExp(r'[a-zA-Z0-9_]').hasMatch(input[pos])) {
      pos++;
    }

    if (pos > startId) {
      final id = input.substring(startId, pos);

      if (id == 'true') return true;

      if (id == 'false') return false;

      if (id == 'null') return null;

      final mapped = _getName(id);

      if (mapped == null) {
        // It's not a known validator symbol, treat as bare string argument
        return id;
      }

      // If it IS a known validator symbol, reset and fall through
      pos = startId;
    }

    // Check built-in boolean or null again just in case (we handled them above)
    if (match('true')) return true;

    if (match('false')) return false;

    if (match('null')) return null;

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
      throw EskemaDecodeException.unclosedString(input, start);
    }
    
    final str = input.substring(start, pos);
    pos++; // skip closing quote
    
    return str.replaceAll("\\'", "'").replaceAll('\\"', '"');
  }
}

class _DecodedMapValidator extends MapValidator {
  final List<IdValidator> _fields;
  
  _DecodedMapValidator(this._fields) : super(id: '');

  @override
  List<IdValidator> get fields => _fields;
}
