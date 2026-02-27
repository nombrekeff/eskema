import 'dart:convert' as convert;

import 'package:eskema/eskema.dart';

part 'parser/json_decoder_nodes.dart';
part 'parser/json_decoder_values.dart';

/// Decodes a JSON string into an IValidator.
///
/// The JSON format uses:
/// - `String` for no-argument validators (e.g. `"T"`, `"F"`, `"s_mail"`)
/// - `List` for parameterized validators (e.g. `[">", 18]`) or infix logical chains
///   (e.g. `[["type", "int"], "&", [">", 0]]`)
/// - `Map<String, dynamic>` for map/field validators
///
/// Example:
/// ```dart
/// final validator = const JsonDecoder().decode('{"name": "String", "age": [">", 0]}');
/// ```
class JsonDecoder extends DelegateValidatorDecoder<dynamic> {
  const JsonDecoder({
    super.customSymbols,
    super.strictUnknownValidators = false,
  });

  @override
  IValidator decode(
    dynamic input, {
    Map<String, Function>? customFactories,
    ValidatorRegistry? registry,
  }) {
    final activeRegistry = registry ?? defaultRegistry;
    final parsed = input is String ? convert.jsonDecode(input) : input;
    final context = createResolutionContext(activeRegistry, customFactories);

    return _decodeNode(parsed, context);
  }

  IValidator _decodeNode(dynamic node, DecoderResolutionContext context) {
    return _jsonDecodeNode(this, node, context);
  }
}
