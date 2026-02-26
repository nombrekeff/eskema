import 'package:eskema/validator.dart';
import 'default_registry.dart';
import 'registry.dart';

/// Serializes an Eskema IValidator into its compact string representation.
class EskemaSerializer {
  /// Converts a validator instance to a string representation.
  /// Uses [defaultRegistry] if [registry] is not provided.
  static String serialize(IValidator validator, {ValidatorRegistry? registry}) {
    final activeRegistry = registry ?? defaultRegistry;
    return _serializeInternal(validator, activeRegistry);
  }

  static String _serializeInternal(IValidator validator, ValidatorRegistry registry) {
    if (validator is Field || validator is MapValidator) {
      return _serializeMap(validator as IdValidator, registry);
    }

    final symbol = registry.getSymbolByName(validator.name);
    if (symbol != null) {
      return _serializeBuiltIn(symbol, validator, registry);
    }

    return _serializeCustom(validator, registry);
  }

  static String _serializeMap(IdValidator field, ValidatorRegistry registry) {
    if (field is MapValidator) {
      final buffer = StringBuffer('{');
      for (var i = 0; i < field.fields.length; i++) {
        final f = field.fields[i];
        buffer.write('${f.id}: ${_serializeFieldModifiers(f, _serializeMap(f, registry))}');
        if (i < field.fields.length - 1) buffer.write(', ');
      }
      buffer.write('}');
      return buffer.toString();
    }

    if (field is Field) {
      final innerSer = field.validators.map((v) => _serializeInternal(v, registry)).join(' & ');
      return innerSer;
    }

    return _serializeInternal(field, registry);
  }

  static String _serializeFieldModifiers(IValidator validator, String serialized) {
    String mod = serialized;
    if (validator.isNullable) mod = '?$mod';
    if (validator.isOptional) mod = '*$mod';
    return mod;
  }

  static String _serializeBuiltIn(
      String symbol, IValidator validator, ValidatorRegistry registry) {
    if (validator.arguments.isEmpty) {
      return symbol;
    }

    if (symbol == '&' || symbol == '|') {
      final subs = validator.arguments.cast<IValidator>();
      if (subs.isEmpty) return symbol;
      final joined = subs.map((v) => _serializeInternal(v, registry)).join(' $symbol ');
      return '($joined)';
    }

    final customSerializer = registry.serializers[validator.name];
    final argsToSerialize =
        customSerializer != null ? customSerializer(validator) : validator.arguments;

    final argsStr = argsToSerialize.map((v) {
      if (symbol == 'type') return v.toString();
      return _serializeValue(v, registry);
    }).join(', ');
    return '$symbol($argsStr)';
  }

  static String _serializeCustom(IValidator validator, ValidatorRegistry registry) {
    final argsStr = validator.arguments.map((v) => _serializeValue(v, registry)).join(', ');
    if (argsStr.isEmpty) return '@${validator.name}';
    return '@${validator.name}($argsStr)';
  }

  static String _serializeValue(dynamic value, ValidatorRegistry registry) {
    if (value is String) return "'$value'";
    if (value is Iterable) {
      return '[${value.map((v) => _serializeValue(v, registry)).join(', ')}]';
    }
    if (value is IValidator) return _serializeInternal(value, registry);
    return value.toString();
  }
}
