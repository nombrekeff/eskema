import 'package:eskema/validator.dart';
import 'package:eskema/serialization/core/decoder.dart';
import 'package:eskema/serialization/serializers/eskema/eskema_decoder.dart';

/// Decodes an encoded validator string/format inline for composability.
///
/// If no [decoder] is provided, it defaults to [EskemaDecoder] which expects a `String`.
///
/// Head over to the [Encoding](https://github.com/nombrekeff/eskema/wiki/Encoding) section of the wiki for a comprehensive guide.
///
/// Example:
/// ```dart
/// all([
///   $isInt,
///   decode('[{"validator":"isEq","value": 5}]', decoder: myJsonDecoder)
/// ])
/// ```
IValidator decode<T>(T encoded, {ValidatorDecoder<T>? decoder}) {
  if (decoder != null) {
    return decoder.decode(encoded);
  }

  if (encoded is String) {
    return const EskemaDecoder().decode(encoded);
  }

  throw ArgumentError(
      'A ValidatorDecoder<T> must be explicitly provided when not decoding a String.');
}
