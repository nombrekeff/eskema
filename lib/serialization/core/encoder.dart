import 'package:eskema/eskema.dart';

/// Defines an interface for encoding an `IValidator` into a target format `T`.
abstract interface class ValidatorEncoder<T> {
  /// Encodes the given [validator] into type `T`.
  /// Uses an optional [registry] for custom serialization logic.
  T encode(IValidator validator, {ValidatorRegistry? registry});
}

/// Abstract base class that provides common dispatch logic for encoding validators.
abstract class DelegateValidatorEncoder<T> implements ValidatorEncoder<T> {
  final Map<String, String>? customSymbols;
  final Map<String, ArgumentEncoder>? customEncoders;

  const DelegateValidatorEncoder({this.customSymbols, this.customEncoders});

  SymbolResolver get resolver => SymbolResolver(customNameToSymbol: customSymbols);

  @override
  T encode(IValidator validator, {ValidatorRegistry? registry}) {
    final activeRegistry = registry ?? defaultRegistry;
    return encodeInternal(validator, activeRegistry);
  }

  /// Internal recursive encoding method.
  T encodeInternal(IValidator validator, ValidatorRegistry? registry) {
    if (validator is Field || validator is MapValidator) {
      return encodeMap(validator as IdValidator, registry);
    }

    final simpleTypeName = extractSimpleTypeName(validator);
    if (simpleTypeName != null) {
      // If our generic type T is String, this is easy, if not, usually subclasses handle it,
      // wait, `simpleTypeName` returns String. `JsonEncoder` returns dynamic (mostly strings).
      // We need to cast it to `T`.
      return simpleTypeName as T;
    }

    if (resolver.hasSymbolForName(validator.name)) {
      final symbol = resolver.symbolOfName(validator.name);
      return encodeBuiltIn(symbol, validator, registry);
    }

    return encodeCustom(validator, registry);
  }

  /// Helper to encode field modifiers (nullable/optional).
  /// Designed to be overridden if the target format represents these differently.
  T encodeFieldModifiers(IValidator validator, T encoded);

  /// Helper to encode Maps/Fields. 
  T encodeMap(IdValidator field, ValidatorRegistry? registry);

  /// Helper to encode built-in validators, optionally utilizing the registry.
  T encodeBuiltIn(String symbol, IValidator validator, ValidatorRegistry? registry);

  /// Helper to encode custom validators.
  T encodeCustom(IValidator validator, ValidatorRegistry? registry);

  /// Helper to encode a dynamically-typed value argument.
  T encodeValue(dynamic value, ValidatorRegistry? registry);
}
