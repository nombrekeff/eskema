import 'package:eskema/validator.dart';
import 'registry.dart';

/// Defines an interface for decoding a source format `T` into an `IValidator`.
abstract interface class ValidatorDecoder<T> {
  /// Decodes the given [input] into an `IValidator`.
  /// Uses an optional [registry] for resolving aliases and customized deserialization.
  /// Also accepts optional [customFactories] for processing ad-hoc custom validations.
  IValidator decode(T input, {
    Map<String, Function>? customFactories,
    ValidatorRegistry? registry,
  });
}

/// Abstract base class that provides common lifecycle/management for decoding validators.
abstract class DelegateValidatorDecoder<T> implements ValidatorDecoder<T> {
  const DelegateValidatorDecoder();

  @override
  IValidator decode(
    T input, {
    Map<String, Function>? customFactories,
    ValidatorRegistry? registry,
  });
}
