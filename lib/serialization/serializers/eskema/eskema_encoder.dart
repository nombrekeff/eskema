import 'package:eskema/validator.dart';
import '../../default_registry.dart';
import '../../core/registry.dart';
import '../../core/encoder.dart';

/// A factory function that encodes arguments for a given `IValidator`.
typedef ArgumentEncoder = List<dynamic> Function(IValidator validator);

const defaultNameToSymbol = <String, String>{
  'all': '&',
  'any': '|',
  'none': '!|',
  'not': '!',
  'throwInstead': '!!',
  'withExpectation': '->',
  'when': 'when',
  'switchBy': 'switch',
  'isEq': '=',
  'isGt': '>',
  'isGte': '>=',
  'isLt': '<',
  'isLte': '<=',
  'isInRange': '<>',
  'isOneOf': 'in',
  'isTrue': 'T',
  'isFalse': 'F',
  'contains': '~',
  'stringLength': 'slen',
  'stringIsOfLength': 'slen=',
  'stringContains': 's~',
  'stringMatchesPattern': 's~/',
  'isLowerCase': 's_lc',
  'isUpperCase': 's_uc',
  'isEmail': 's_mail',
  'isStringEmpty': 's0',
  'isUrl': 's_url',
  'isStrictUrl': 's_url!',
  'isUuidV4': 's_uuid',
  'isIntString': 's_int',
  'isDoubleString': 's_dbl',
  'isNumString': 's_num',
  'isBoolString': 's_bool',
  'isDate': 's_date',
  'isDateBefore': 'd<',
  'isDateAfter': 'd>',
  'isDateBetween': 'd<>',
  'isDateSameDay': 'd=',
  'isDateInPast': 'd_past',
  'isDateInFuture': 'd_fut',
  'isJsonContainer': 'j_cont',
  'isJsonObject': 'j_obj',
  'isJsonArray': 'j_arr',
  'jsonHasKeys': 'j_keys',
  'jsonArrayLength': 'j_alen',
  'jsonArrayEvery': 'j_aevery',
  'containsKey': 'm_key',
  'containsKeys': 'm_keys',
  'containsValues': 'm_vals',
  'eskema': 'eskema',
  'eskemaStrict': 'eskema!',
  'eskemaList': 'eskema[]',
  'listEach': '[]each',
  'isType': 'type',
};

/// Encodes an Eskema IValidator into its compact string representation.
class EskemaEncoder extends DelegateValidatorEncoder<String> {
  final Map<String, String>? customSymbols;
  final Map<String, ArgumentEncoder>? customEncoders;

  const EskemaEncoder({this.customSymbols, this.customEncoders});

  String _getSymbol(String name) {
    if (customSymbols != null && customSymbols!.containsKey(name)) {
      return customSymbols![name]!;
    }

    return defaultNameToSymbol[name] ?? name;
  }

  bool _hasSymbolMap(String name) {
     return (customSymbols != null && customSymbols!.containsKey(name)) || defaultNameToSymbol.containsKey(name);
  }

  @override
  String encode(IValidator validator, {ValidatorRegistry? registry}) {
    final activeRegistry = registry ?? defaultRegistry;

    return encodeInternal(validator, activeRegistry);
  }

  @override
  String encodeInternal(IValidator validator, ValidatorRegistry? registry) {
    // We pass registry around in case nested calls need standard encode logic, 
    // but the symbols are handled internally here now.
    if (validator is Field || validator is MapValidator) {
      return encodeMap(validator as IdValidator, registry);
    }

    if (_hasSymbolMap(validator.name)) {
      final symbol = _getSymbol(validator.name);

      return encodeBuiltIn(symbol, validator, registry);
    }

    // fallback if no explicitly configured short symbol
    return encodeCustom(validator, registry);
  }

  @override
  String encodeMap(IdValidator field, ValidatorRegistry? registry) {
    if (field is MapValidator) {
      final buffer = StringBuffer('{');

      for (var i = 0; i < field.fields.length; i++) {
        final f = field.fields[i];
        buffer.write('${f.id}: ${encodeFieldModifiers(f, encodeMap(f, registry))}');

        if (i < field.fields.length - 1) buffer.write(', ');
      }

      buffer.write('}');

      return buffer.toString();
    }

    if (field is Field) {
      return field.validators.map((v) => encodeInternal(v, registry)).join(' & ');
    }

    return encodeInternal(field, registry);
  }

  @override
  String encodeFieldModifiers(IValidator validator, String encoded) {
    String mod = encoded;

    if (validator.isNullable) mod = '?$mod';
    if (validator.isOptional) mod = '*$mod';

    return mod;
  }

  @override
  String encodeBuiltIn(String symbol, IValidator validator, ValidatorRegistry? registry) {
    if (validator.arguments.isEmpty) {
      return symbol;
    }

    if (symbol == '&' || symbol == '|') {
      final subs = validator.arguments.cast<IValidator>();

      if (subs.isEmpty) return symbol;
      final joined = subs.map((v) => encodeInternal(v, registry)).join(' $symbol ');

      return '($joined)';
    }

    final customEncoder = customEncoders?[validator.name];
    final argsToEncode = customEncoder != null ? customEncoder(validator) : validator.arguments;

    final argsStr = argsToEncode.map((v) {
      if (symbol == 'type') return v.toString();

      return encodeValue(v, registry);
    }).join(', ');

    return '$symbol($argsStr)';
  }

  @override
  String encodeCustom(IValidator validator, ValidatorRegistry? registry) {
    final argsStr = validator.arguments.map((v) => encodeValue(v, registry)).join(', ');

    if (argsStr.isEmpty) return '@${validator.name}';

    return '@${validator.name}($argsStr)';
  }

  @override
  String encodeValue(dynamic value, ValidatorRegistry? registry) {
    if (value is String) return "'$value'";

    if (value is Iterable) {
      return '[${value.map((v) => encodeValue(v, registry)).join(', ')}]';
    }
    
    if (value is IValidator) return encodeInternal(value, registry);

    return value.toString();
  }
}
