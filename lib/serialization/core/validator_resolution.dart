import 'package:eskema/eskema.dart';

/// The [CustomFactoryMap] typedef.
typedef CustomFactoryMap = Map<String, Function>;

/// The [UnknownCustomFallbackPolicy] typedef.
typedef UnknownCustomFallbackPolicy = bool Function(String customName);

/// The [DecoderResolutionContext] class.
class DecoderResolutionContext {
  /// The [registry] property.
  final ValidatorRegistry registry;

  /// The [symbolResolver] property.
  final SymbolResolver symbolResolver;

  /// The [customFactories] property.
  final CustomFactoryMap customFactories;

  /// The [strictUnknownValidators] property.
  final bool strictUnknownValidators;

  /// The [allowUnknownCustomFallback] property.
  final UnknownCustomFallbackPolicy allowUnknownCustomFallback;

  /// Executes the [DecoderResolutionContext] operation.
  const DecoderResolutionContext({
    required this.registry,
    required this.symbolResolver,
    required this.customFactories,
    required this.strictUnknownValidators,
    this.allowUnknownCustomFallback = _defaultUnknownCustomFallback,
  });
}

bool _defaultUnknownCustomFallback(String _) => true;

/// Executes the [resolveDecodedValidator] operation.
IValidator resolveDecodedValidator({
  required DecoderResolutionContext context,
  required String token,
  required List<dynamic> args,
  required bool isCustom,
  required dynamic source,
  required int? offset,
}) {
  if (isCustom) {
    final customFactory = context.customFactories[token];
    if (customFactory != null) {
      return customFactory(args) as IValidator;
    }

    try {
      return context.registry.createValidator(token, args);
    } catch (_) {
      if (!context.strictUnknownValidators &&
          context.allowUnknownCustomFallback(token)) {
        return isType<dynamic>().copyWith(name: token, args: args);
      }

      throw DecodeException.unknownCustomValidator(token, source, offset);
    }
  }

  final resolvedName = context.symbolResolver.nameOfSymbol(token) ?? token;
  try {
    return context.registry.createValidator(resolvedName, args);
  } catch (_) {
    if (!context.strictUnknownValidators) {
      return isType<dynamic>().copyWith(name: resolvedName, args: args);
    }

    throw DecodeException.unknownValidator(token, source, offset);
  }
}
