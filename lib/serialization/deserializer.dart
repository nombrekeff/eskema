import 'package:eskema/eskema.dart';
import 'package:eskema/serialization/symbols.dart';

class EskemaDeserializer {
  static IValidator deserialize(String input, {Map<String, Function>? customFactories}) {
    final parser = _DeserializerParser(input, customFactories ?? {});
    return parser.parseTopLevel();
  }
}

class _DeserializerParser {
  final String input;
  final Map<String, Function> customFactories;
  int pos = 0;

  _DeserializerParser(this.input, this.customFactories);

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
      throw const FormatException('Unexpected end of input');
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
        throw FormatException('Expected ) at $pos');
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
    // Serializer generates `type('String') & >(0)` for fields. Wait, inside map literal `name: type('String') & >(0)`
    // So there might be `&` without parenthesis.
    skipWhitespace();
    if (pos < input.length && peek('&') && !peek('&&')) { // wait, no && in grammar
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
      if (pos >= input.length) throw FormatException('Expected }');
      final key = parseIdentifier();
      if (!match(':')) throw FormatException('Expected : after map key $key at $pos');
      
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
      
      final field = Field(id: key, validators: fieldValidators, optional: optional, nullable: nullable);
      fields.add(field);

      match(','); // optional trailing comma
    }
    // We just return an Eskema map. But what map class?
    // Eskema has `MapValidator` as abstract... Wait.
    // Eskema doesn't have a concrete map validator? You usually create a class extending MapValidator, or use `IdValidator`?
    // Oh wait, `isMap` / `MapValidator` ? We can just use `EskemaMapValidator` or a custom class here.
    // Let's look at `MapValidator` definition later. For now, we can use `MapValidator` if it has a default constructor, or something.
    return _DeserializedMapValidator(fields);
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
        return parseString() as String;
      }
      throw FormatException('Expected identifier at $pos');
    }
    return input.substring(start, pos);
  }

  IValidator parseCall() {
    skipWhitespace();
    bool isCustom = match('@');
    final start = pos;

    while (pos < input.length && RegExp(r'[a-zA-Z0-9_!=\<\>~&\|]').hasMatch(input[pos])) {
      pos++;
    }
    final sym = input.substring(start, pos);

    final args = <dynamic>[];
    if (match('(')) {
      while (!match(')')) {
        if (pos >= input.length) throw FormatException('Expected )');
        args.add(parseValue());
        match(',');
      }
    }

    if (isCustom) {
      if (!customFactories.containsKey(sym)) {
        throw FormatException('Unknown custom validator: @$sym');
      }
      return customFactories[sym]!(args) as IValidator;
    }

    final String name = reverseValidatorSymbols[sym] ?? sym;

    switch (name) {
      case 'isEq': return isEq(args[0]);
      case 'isGt': return isGt<num>(args[0] as num);
      case 'isGte': return isGte<num>(args[0] as num);
      case 'isLt': return isLt<num>(args[0] as num);
      case 'isLte': return isLte<num>(args[0] as num);
      case 'isInRange': return isInRange<num>(args[0] as num, args[1] as num);
      case 'contains': return contains(args[0]);
      case 'all': return all(args.cast<IValidator>());
      case 'any': return any(args.cast<IValidator>());
      case 'none': return none(args.cast<IValidator>());
      case 'not': return not(args[0] as IValidator);
      case 'throwInstead': return throwInstead(args[0] as IValidator);
      case 'withExpectation': return withExpectation(args[0] as IValidator, args[1] as Expectation); // Not strictly valid syntax for deserialization but provided for completeness
      case 'isOneOf': return isOneOf(args);
      case 'isTrue': return isTrue();
      case 'isFalse': return isFalse();
      case 'isType': 
        final typeName = args.isNotEmpty ? args[0].toString() : '';
        if (typeName == 'String') return isString();
        if (typeName == 'int') return isInt();
        if (typeName == 'double') return isDouble();
        if (typeName == 'num') return isNumber();
        if (typeName == 'bool') return isBool();
        if (typeName == 'List') return isList();
        if (typeName == 'Map') return isMap();
        return isType<dynamic>().copyWith(name: 'isType', arguments: [typeName]);
      case 'stringLength': return stringLength(args.cast<IValidator>());
      case 'stringIsOfLength': return stringIsOfLength(args[0] as int);
      case 'stringContains': return stringContains(args[0] as String);
      case 'stringMatchesPattern': return stringMatchesPattern(RegExp(args[0] as String));
      case 'isLowerCase': return isLowerCase();
      case 'isUpperCase': return isUpperCase();
      case 'isEmail': return isEmail();
      case 'isStringEmpty': return isStringEmpty();
      case 'isUrl': return isUrl(strict: args.isNotEmpty ? args[0] as bool : false);
      case 'isStrictUrl': return isStrictUrl();
      case 'isUuidV4': return isUuidV4();
      case 'isIntString': return isIntString();
      case 'isDoubleString': return isDoubleString();
      case 'isNumString': return isNumString();
      case 'isBoolString': return isBoolString();
      case 'isDate': return isDate();
      case 'isJsonContainer': return isJsonContainer();
      case 'isJsonObject': return isJsonObject();
      case 'isJsonArray': return isJsonArray();
      case 'jsonHasKeys': return jsonHasKeys(args.cast<String>());
      case 'jsonArrayLength': return jsonArrayLength(min: args[0] as int?, max: args[1] as int?);
      case 'jsonArrayEvery': return jsonArrayEvery(args[0] as IValidator);
      case 'containsKey': return containsKey(args[0] as String);
      case 'containsKeys': return containsKeys(args.cast<String>());
      case 'containsValues': return containsValues(args);
      case 'eskema': return eskema(args[0] as Map<String, IValidator>);
      case 'eskemaStrict': return eskemaStrict(args[0] as Map<String, IValidator>);
      case 'eskemaList': return eskemaList(args[0] as List<IValidator>);
      case 'listEach': return listEach(args[0] as IValidator);
      case 'isDateBefore': return isDateBefore(args[0] as DateTime, inclusive: args[1] as bool);
      case 'isDateAfter': return isDateAfter(args[0] as DateTime, inclusive: args[1] as bool);
      case 'isDateBetween': return isDateBetween(args[0] as DateTime, args[1] as DateTime, inclusiveStart: args[2] as bool, inclusiveEnd: args[3] as bool);
      case 'isDateSameDay': return isDateSameDay(args[0] as DateTime);
      case 'isDateInPast': return isDateInPast(allowNow: args[0] as bool);
      case 'isDateInFuture': return isDateInFuture(allowNow: args[0] as bool);
      case 'when': return when(args[0] as IValidator, then: args[1] as IValidator, otherwise: args[2] as IValidator);
      case 'switchBy': return switchBy(args[0] as String, args[1] as Map<String, IValidator>);
      default:
        // By default, assume a dynamic validator wrapper
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
    if (input[pos] == '-') {pos++; isNum=true;}
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
      
      // If the identifier is immediately followed by a paren, it might be a validator (e.g., String(...) if custom, but usually they start with @)
      // Wait, validators could be words like 'T', 'F', 'contains'. But built-in validators with no args shouldn't be parsed inside `parseValue` unless it's a nested validator.
      // If it's a nested validator like `=(T)`, `T` is a validator.
      // Let's check if the symbol is a known validator symbol.
      final mapped = reverseValidatorSymbols[id];
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
      if (input[pos] == '\\') pos++; // skip escaped
      pos++;
    }
    final str = input.substring(start, pos);
    pos++; // skip closing quote
    return str.replaceAll("\\'", "'").replaceAll('\\"', '"');
  }
}

class _DeserializedMapValidator extends MapValidator {
  final List<IdValidator> _fields;
  _DeserializedMapValidator(this._fields) : super(id: '');

  @override
  List<IdValidator> get fields => _fields;
}
