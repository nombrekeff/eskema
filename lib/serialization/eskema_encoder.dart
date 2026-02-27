import 'package:eskema/validator.dart';
import 'default_registry.dart';
import 'core/registry.dart';
import 'core/encoder.dart';

/// Encodes an Eskema IValidator into its compact string representation.
class EskemaEncoder extends DelegateValidatorEncoder<String> {
  const EskemaEncoder();

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

    final activeRegistry = registry ?? defaultRegistry;
    final symbol = activeRegistry.getSymbolByName(validator.name);
    if (symbol != null) {
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
      final innerSer = field.validators.map((v) => encodeInternal(v, registry)).join(' & ');
      return innerSer;
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

    final activeRegistry = registry ?? defaultRegistry;
    final customEncoder = activeRegistry.encoders[validator.name];
    final argsToEncode =
        customEncoder != null ? customEncoder(validator) : validator.arguments;

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
