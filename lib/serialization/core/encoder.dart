import 'package:eskema/validator.dart';
import 'registry.dart';

/// Defines an interface for encoding an `IValidator` into a target format `T`.
abstract interface class ValidatorEncoder<T> {
  /// Encodes the given [validator] into type `T`.
  /// Uses an optional [registry] for custom serialization logic.
  T encode(IValidator validator, {ValidatorRegistry? registry});
}

/// Abstract base class that provides common dispatch logic for encoding validators.
abstract class DelegateValidatorEncoder<T> implements ValidatorEncoder<T> {
  const DelegateValidatorEncoder();

  @override
  T encode(IValidator validator, {ValidatorRegistry? registry}) {
    // Abstract logic can be refined by subclasses.
    return encodeInternal(validator, registry);
  }

  /// Internal recursive encoding method. Subclasses MUST implement this.
  T encodeInternal(IValidator validator, ValidatorRegistry? registry);

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
