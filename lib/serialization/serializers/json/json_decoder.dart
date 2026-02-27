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
  final Map<String, String>? customSymbols;
  final bool strictUnknownValidators;
  SymbolResolver get _resolver => SymbolResolver(customSymbolToName: customSymbols);

  const JsonDecoder({
    this.customSymbols,
    this.strictUnknownValidators = false,
  });

  @override
  IValidator decode(
    dynamic input, {
    Map<String, Function>? customFactories,
    ValidatorRegistry? registry,
  }) {
    final activeRegistry = registry ?? defaultRegistry;
    final parsed = input is String ? convert.jsonDecode(input) : input;
    final context = DecoderResolutionContext(
      registry: activeRegistry,
      symbolResolver: _resolver,
      customFactories: customFactories ?? {},
      strictUnknownValidators: strictUnknownValidators,
    );

    return _decodeNode(parsed, context);
  }

  IValidator _decodeNode(dynamic node, DecoderResolutionContext context) {
    return _jsonDecodeNode(this, node, context);
  }
}
