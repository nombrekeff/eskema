import 'package:eskema/eskema.dart';
import 'package:eskema/serialization/core/codec_utils.dart';

/// Encodes an Eskema IValidator into its compact string representation.
class EskemaEncoder extends DelegateValidatorEncoder<String> {
  final Map<String, String>? customSymbols;
  final Map<String, ArgumentEncoder>? customEncoders;

  // TODO: Allow passing a custom SymbolResolver directly for more flexibility?
  SymbolResolver get _resolver => SymbolResolver(customNameToSymbol: customSymbols);

  const EskemaEncoder({this.customSymbols, this.customEncoders});

  @override
  String encode(IValidator validator, {ValidatorRegistry? registry}) {
    final activeRegistry = registry ?? defaultRegistry;

    return encodeInternal(validator, activeRegistry);
  }

  @override
  String encodeInternal(IValidator validator, ValidatorRegistry? registry) {
    if (validator is Field || validator is MapValidator) {
      return encodeMap(validator as IdValidator, registry);
    }

    final simpleTypeName = extractSimpleTypeName(validator);
    if (simpleTypeName != null) {
      return simpleTypeName;
    }

    if (_resolver.hasSymbolForName(validator.name)) {
      final symbol = _resolver.symbolOfName(validator.name);

      return encodeBuiltIn(symbol, validator, registry);
    }

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
    return applyEskemaFieldModifiers(
      isNullable: validator.isNullable,
      isOptional: validator.isOptional,
      encoded: encoded,
    );
  }

  @override
  String encodeBuiltIn(String symbol, IValidator validator, ValidatorRegistry? registry) {
    if (validator.args.isEmpty) {
      return symbol;
    }

    if (symbol == '&' || symbol == '|') {
      final subs = validator.args.cast<IValidator>();

      if (subs.isEmpty) return symbol;
      final joined = subs.map((v) => encodeInternal(v, registry)).join(' $symbol ');

      return '($joined)';
    }

    final customEncoder = customEncoders?[validator.name];
    final argsToEncode = customEncoder != null ? customEncoder(validator) : validator.args;

    final argsStr = argsToEncode.map((v) {
      return encodeValue(v, registry);
    }).join(', ');

    if (argsToEncode.length == 1 &&
        isComparisonSymbol(symbol) &&
        isSimpleValue(argsToEncode[0])) {
      return '$symbol$argsStr';
    }

    return '$symbol($argsStr)';
  }

  @override
  String encodeCustom(IValidator validator, ValidatorRegistry? registry) {
    final argsStr = validator.args.map((v) => encodeValue(v, registry)).join(', ');

    if (argsStr.isEmpty) return '@${validator.name}';

    return '@${validator.name}($argsStr)';
  }

  @override
  String encodeValue(dynamic value, ValidatorRegistry? registry) {
    if (value is String) return "'$value'";
    if (value is RegExp) return "'${value.pattern}'";
    if (value is DateTime) return "'${value.toIso8601String()}'";

    if (value is Iterable) {
      return '[${value.map((v) => encodeValue(v, registry)).join(', ')}]';
    }

    if (value is Map) {
      final entries =
          value.entries.map((e) => '${e.key}: ${encodeValue(e.value, registry)}').join(', ');

      return '{$entries}';
    }

    if (value is IValidator) return encodeInternal(value, registry);

    return value.toString();
  }
}
