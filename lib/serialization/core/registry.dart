import 'package:eskema/validator.dart';

/// A factory function that instantiates an `IValidator` from deserialized arguments.
typedef ValidatorFactory = IValidator Function(List<dynamic> args);

/// A factory function that encodes arguments for a given `IValidator`.
typedef ArgumentEncoder = List<dynamic> Function(IValidator validator);

/// A registry mapping validator names to string symbols, factories, and optional serializers.
/// It enables dynamic injection of standard and custom validation rules, separating parsing logic
/// from validation implementations.
class ValidatorRegistry {
  /// Maps the validator's name (e.g. `'isEq'`) to a shortened symbol (e.g. `'='`).
  final Map<String, String> nameToSymbol = {};

  /// Maps a shortened symbol back to the validator's name.
  final Map<String, String> symbolToName = {};

  /// Stores factories capable of reconstructing validators from a list of dynamically parsed arguments.
  final Map<String, ValidatorFactory> factories = {};

  /// Optional specialized encodings for validators where default object strings are insufficient.
  /// If null for a validator, `EskemaEncoder` will attempt standard iteration over `validator.arguments`.
  final Map<String, ArgumentEncoder> encoders = {};

  /// Registers a validator with the registry.
  ///
  /// * `name`: The logical name of the validator (e.g. `'isEmail'`). Often corresponds to `IValidator.name`.
  /// * `symbol`: A compact string used to represent this validator during encoding (e.g. `'s_mail'`).
  /// * `factory`: A callback which returns a concrete `IValidator` instance given parsed string arguments.
  /// * `encoder`: Optional callback to generate the list of arguments from the instance during encoding.
  void register({
    required String name,
    required String symbol,
    required ValidatorFactory factory,
    ArgumentEncoder? encoder,
  }) {
    nameToSymbol[name] = symbol;
    symbolToName[symbol] = name;
    factories[name] = factory;
    if (encoder != null) {
      encoders[name] = encoder;
    }
  }

  /// Copies all entries from another registry into this one, overwriting any duplicates.
  void merge(ValidatorRegistry other) {
    nameToSymbol.addAll(other.nameToSymbol);
    symbolToName.addAll(other.symbolToName);
    factories.addAll(other.factories);
    encoders.addAll(other.encoders);
  }

  /// Looks up a validator name by its encoding symbol. Returns `null` if unknown.
  String? getNameBySymbol(String symbol) => symbolToName[symbol];

  /// Looks up an encoding symbol by its validator name. Returns `null` if unknown.
  String? getSymbolByName(String name) => nameToSymbol[name];

  /// Creates a validator instance by its logical name. Throws `ArgumentError` if unknown.
  IValidator createValidator(String name, List<dynamic> args) {
    final factoryStr = factories[name];
    if (factoryStr == null) {
      throw ArgumentError('No factory registered for validator: $name');
    }
    return factoryStr(args);
  }
}
