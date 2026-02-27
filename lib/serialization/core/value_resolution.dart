import 'package:eskema/serialization/core/validator_resolution.dart';

/// The [DecodeNodeCallback] typedef.
typedef DecodeNodeCallback = dynamic Function(dynamic node);

/// The [ShouldDecodeListCallback] typedef.
typedef ShouldDecodeListCallback = bool Function(
    List value, DecoderResolutionContext context);

/// The [NestedValueResolutionOptions] class.
class NestedValueResolutionOptions {
  /// The [unwrapSingleQuotedStrings] property.
  final bool unwrapSingleQuotedStrings;

  /// The [tryDecodeMapsAsValidators] property.
  final bool tryDecodeMapsAsValidators;

  /// The [shouldDecodeListAsValidator] property.
  final ShouldDecodeListCallback? shouldDecodeListAsValidator;

  /// Executes the [NestedValueResolutionOptions] operation.
  const NestedValueResolutionOptions({
    this.unwrapSingleQuotedStrings = false,
    this.tryDecodeMapsAsValidators = true,
    this.shouldDecodeListAsValidator,
  });
}

/// Executes the [resolveNestedDecodedValue] operation.
dynamic resolveNestedDecodedValue({
  required dynamic value,
  required DecoderResolutionContext context,
  required DecodeNodeCallback decodeNode,
  NestedValueResolutionOptions options = const NestedValueResolutionOptions(),
}) {
  if (value is String) {
    if (options.unwrapSingleQuotedStrings &&
        value.startsWith("'") &&
        value.endsWith("'") &&
        value.length >= 2) {
      return value.substring(1, value.length - 1);
    }

    return value;
  }

  if (value is List) {
    final shouldDecode =
        options.shouldDecodeListAsValidator?.call(value, context) ?? false;
    if (shouldDecode) {
      return decodeNode(value);
    }

    return value
        .map((v) => resolveNestedDecodedValue(
              value: v,
              context: context,
              decodeNode: decodeNode,
              options: options,
            ))
        .toList();
  }

  if (value is Map<String, dynamic>) {
    if (options.tryDecodeMapsAsValidators) {
      try {
        return decodeNode(value);
      } catch (_) {}
    }

    return value.map(
      (k, v) => MapEntry(
        k,
        resolveNestedDecodedValue(
          value: v,
          context: context,
          decodeNode: decodeNode,
          options: options,
        ),
      ),
    );
  }

  return value;
}
