import 'package:eskema/validator.dart';
import 'package:eskema/validator/combinator_validators.dart';
import 'symbols.dart';

/// Serializes an Eskema IValidator into its compact string representation.
class EskemaSerializer {
  /// Converts a validator instance to a string representation.
  static String serialize(IValidator validator) {
    if (validator is Field || validator is MapValidator) {
      return _serializeMap(validator as IdValidator);
    }

    if (standardValidatorSymbols.containsKey(validator.name)) {
      final symbol = standardValidatorSymbols[validator.name]!;
      return _serializeBuiltIn(symbol, validator);
    }

    return _serializeCustom(validator);
  }

  static String _serializeMap(IdValidator field) {
    if (field is MapValidator) {
      final buffer = StringBuffer('{');
      for (var i = 0; i < field.fields.length; i++) {
        final f = field.fields[i];
        buffer.write('${f.id}: ${_serializeFieldModifiers(f, _serializeMap(f))}');
        if (i < field.fields.length - 1) buffer.write(', ');
      }
      buffer.write('}');
      return buffer.toString();
    }

    if (field is Field) {
      final innerSer = field.validators.map(serialize).join(' & ');
      return innerSer;
    }

    return serialize(field);
  }

  static String _serializeFieldModifiers(IValidator validator, String serialized) {
    String mod = serialized;
    if (validator.isNullable) mod = '?$mod';
    if (validator.isOptional) mod = '*$mod';
    return mod;
  }

  static String _serializeBuiltIn(String symbol, IValidator validator) {
    if (validator.arguments.isEmpty) {
      return symbol;
    }

    if (symbol == '&' || symbol == '|') {
      final subs = validator.arguments.cast<IValidator>();
      if (subs.isEmpty) return symbol;
      final joined = subs.map(serialize).join(' $symbol ');
      return '($joined)';
    }

    final argsStr = validator.arguments.map((v) {
      if (symbol == 'type') return v.toString();
      return _serializeValue(v);
    }).join(', ');
    return '$symbol($argsStr)';
  }

  static String _serializeCustom(IValidator validator) {
    final argsStr = validator.arguments.map(_serializeValue).join(', ');
    if (argsStr.isEmpty) return '@${validator.name}';
    return '@${validator.name}($argsStr)';
  }

  static String _serializeValue(dynamic value) {
    if (value is String) return "'$value'";
    if (value is Iterable) {
      return '[${value.map(_serializeValue).join(', ')}]';
    }
    if (value is IValidator) return serialize(value);
    return value.toString();
  }
}
