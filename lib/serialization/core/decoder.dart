import 'package:eskema/eskema.dart';

/// Defines an interface for decoding a source format `T` into an `IValidator`.
abstract interface class ValidatorDecoder<T> {
  /// Decodes the given [input] into an `IValidator`.
  /// Uses an optional [registry] for resolving aliases and customized deserialization.
  /// Also accepts optional [customFactories] for processing ad-hoc custom validations.
  IValidator decode(
    T input, {
    Map<String, Function>? customFactories,
    ValidatorRegistry? registry,
  });
}

/// Abstract base class that provides common lifecycle/management for decoding validators.
abstract class DelegateValidatorDecoder<T> implements ValidatorDecoder<T> {
  /// The [Map] property.
  final Map<String, String>? customSymbols;

  /// The [strictUnknownValidators] property.
  final bool strictUnknownValidators;

  /// Executes the [DelegateValidatorDecoder] operation.
  const DelegateValidatorDecoder({
    this.customSymbols,
    this.strictUnknownValidators = false,
  });

  /// The [resolver] property.
  SymbolResolver get resolver =>
      SymbolResolver(customSymbolToName: customSymbols);

  /// Executes the [createResolutionContext] operation.
  DecoderResolutionContext createResolutionContext(
    ValidatorRegistry registry,
    Map<String, Function>? customFactories, {
    bool Function(String customName)? allowUnknownCustomFallback,
  }) {
    if (allowUnknownCustomFallback != null) {
      return DecoderResolutionContext(
        registry: registry,
        symbolResolver: resolver,
        customFactories: customFactories ?? {},
        strictUnknownValidators: strictUnknownValidators,
        allowUnknownCustomFallback: allowUnknownCustomFallback,
      );
    }
    return DecoderResolutionContext(
      registry: registry,
      symbolResolver: resolver,
      customFactories: customFactories ?? {},
      strictUnknownValidators: strictUnknownValidators,
    );
  }

  @override
  IValidator decode(
    T input, {
    Map<String, Function>? customFactories,
    ValidatorRegistry? registry,
  });
}
