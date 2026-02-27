import 'dart:convert' as convert;

import 'package:eskema/eskema.dart';

/// Encodes an Eskema IValidator into a JSON string representation.
class JsonEncoder extends DelegateValidatorEncoder<dynamic> {
  final Map<String, String>? customSymbols;
  final Map<String, ArgumentEncoder>? customEncoders;
  SymbolResolver get _resolver => SymbolResolver(customNameToSymbol: customSymbols);

  const JsonEncoder({this.customSymbols, this.customEncoders});

  @override
  String encode(IValidator validator, {ValidatorRegistry? registry}) {
    final activeRegistry = registry ?? defaultRegistry;
    return convert.jsonEncode(encodeInternal(validator, activeRegistry));
  }

  @override
  dynamic encodeInternal(IValidator validator, ValidatorRegistry? registry) {
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
  dynamic encodeMap(IdValidator field, ValidatorRegistry? registry) {
    if (field is MapValidator) {
      final map = <String, dynamic>{};
      for (var i = 0; i < field.fields.length; i++) {
        final f = field.fields[i];
        map[f.id!] = encodeFieldModifiers(f, encodeMap(f, registry));
      }
      return map;
    }

    if (field is Field) {
      if (field.validators.isEmpty) {
        return null;
      }
      if (field.validators.length == 1) {
        return encodeInternal(field.validators.first, registry);
      }
      final symbol = _resolver.symbolOfName('all');
      return encodeBuiltIn(symbol, all(field.validators), registry);
    }

    return encodeInternal(field, registry);
  }

  @override
  dynamic encodeFieldModifiers(IValidator validator, dynamic encoded) {
    return applyJsonFieldModifiers(
      isNullable: validator.isNullable,
      isOptional: validator.isOptional,
      encoded: encoded,
    );
  }

  @override
  dynamic encodeBuiltIn(String symbol, IValidator validator, ValidatorRegistry? registry) {
    if (validator.args.isEmpty) {
      return [symbol];
    }

    if (symbol == '&' || symbol == '|') {
      final subs = validator.args.cast<IValidator>();

      if (subs.isEmpty) return symbol;
      if (subs.length == 1) return encodeInternal(subs.first, registry);

      final list = <dynamic>[];
      // Push infix operators at odd indices for cleaner parsing: ["int", "&", [">", 18], "&", ["<", 65]]
      for (var i = 0; i < subs.length; i++) {
        list.add(encodeInternal(subs[i], registry));
        if (i < subs.length - 1) {
          list.add(symbol);
        }
      }

      return list;
    }

    final customEncoder = customEncoders?[validator.name];
    final argsToEncode = customEncoder != null ? customEncoder(validator) : validator.args;

    final list = <dynamic>[symbol];
    for (final v in argsToEncode) {
      list.add(encodeValue(v, registry));
    }

    return list;
  }

  @override
  dynamic encodeCustom(IValidator validator, ValidatorRegistry? registry) {
    final list = <dynamic>['@${validator.name}'];
    for (final v in validator.args) {
      list.add(encodeValue(v, registry));
    }

    return list;
  }

  @override
  dynamic encodeValue(dynamic value, ValidatorRegistry? registry) {
    // Strings get escaped in Eskema string syntax, keep parity for literal tracking
    // Without this, the json-string "int" would map to the numeric integer validator implicitly.
    if (value is String) return "'$value'";

    if (value is RegExp) return "'${value.pattern}'";

    if (value is Map) {
      return value.map((k, v) => MapEntry(k, encodeValue(v, registry)));
    }

    if (value is Iterable) {
      return value.map((v) => encodeValue(v, registry)).toList();
    }

    if (value is IValidator) return encodeInternal(value, registry);

    // JSON-safe primitives pass through directly
    if (value is num || value is bool || value == null) return value;

    // Anything else (RegExp, DateTime, Type, etc.) → quoted string
    return "'$value'";
  }
}
