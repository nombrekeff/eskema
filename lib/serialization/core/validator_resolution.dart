import 'package:eskema/eskema.dart';
import 'package:eskema/serialization/core/codec_utils.dart';

typedef CustomFactoryMap = Map<String, Function>;
typedef UnknownCustomFallbackPolicy = bool Function(String customName);

class DecoderResolutionContext {
  final ValidatorRegistry registry;
  final SymbolResolver symbolResolver;
  final CustomFactoryMap customFactories;
  final bool strictUnknownValidators;
  final UnknownCustomFallbackPolicy allowUnknownCustomFallback;

  const DecoderResolutionContext({
    required this.registry,
    required this.symbolResolver,
    required this.customFactories,
    required this.strictUnknownValidators,
    this.allowUnknownCustomFallback = _defaultUnknownCustomFallback,
  });
}

bool _defaultUnknownCustomFallback(String _) => true;

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
      if (!context.strictUnknownValidators && context.allowUnknownCustomFallback(token)) {
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
