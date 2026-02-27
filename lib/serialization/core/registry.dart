import 'package:eskema/validator.dart';

/// A factory function that instantiates an `IValidator` from deserialized arguments.
typedef ValidatorFactory = IValidator Function(List<dynamic> args);

/// A registry mapping validator names to factories.
/// It enables dynamic injection of standard and custom validation rules, separating parsing logic
/// from validation implementations.
class ValidatorRegistry {
  /// Stores factories capable of reconstructing validators from a list of dynamically parsed arguments.
  final Map<String, ValidatorFactory> factories = {};

  /// Registers a validator with the registry.
  ///
  /// * `name`: The logical name of the validator (e.g. `'isEmail'`). Often corresponds to `IValidator.name`.
  /// * `factory`: A callback which returns a concrete `IValidator` instance given parsed string arguments.
  void register({
    required String name,
    required ValidatorFactory factory,
  }) {
    if (factories.containsKey(name)) {
      throw StateError('Validator "$name" is already registered');
    }

    factories[name] = factory;
  }

  /// Copies all entries from another registry into this one, overwriting any duplicates.
  void merge(ValidatorRegistry other) {
    for (final entry in other.factories.entries) {
      if (factories.containsKey(entry.key)) {
        throw StateError('Validator "${entry.key}" is already registered');
      }

      factories[entry.key] = entry.value;
    }
  }

  /// Creates a validator instance by its logical name. Throws `ArgumentError` if unknown.
  IValidator createValidator(String name, List<dynamic> args) {
    final factoryStr = factories[name];

    if (factoryStr == null) {
      throw ArgumentError('No factory registered for validator: $name');
    }
    return factoryStr(args);
  }
}
