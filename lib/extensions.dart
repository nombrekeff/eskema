import 'package:eskema/result.dart';
import 'package:eskema/validators.dart';

import 'validator.dart';

extension EskemaMapExtension on Map {
  /// Validates the map against the provided [validator].
  Result validate(IValidator validator) {
    return validator.validate(this);
  }

  /// Checks if the map is valid against the provided [validator].
  bool isValid(IValidator eskema) {
    return eskema.validate(this).isValid;
  }

  /// Checks if the map is not valid against the provided [validator].
  bool isNotValid(IValidator eskema) {
    return !eskema.validate(this).isValid;
  }
}

extension EskemaListExtension on List {
  /// Returns a Validator that checks a value against the eskema provided,
  /// the eskema defines a validator for each item in the list
  ///
  /// Example:
  /// ```dart
  /// final isValidList = eskemaList([isType<String>(), isType<int>()]);
  /// isValidList(["1", 2]).isValid;   // true
  /// isValidList(["1", "2"]).isValid; // false
  /// isValidList([1, "2"]).isValid;   // false
  /// ```
  ///
  /// `isValidList` will only be valid:
  /// * if the array is of length 2
  /// * the first item is a string
  /// * and the second item is an int
  ///
  /// This validator also checks that the value is a list
  Result validate(IValidator eskema) {
    return listEach(eskema).validate(this);
  }
}

extension EskemaEskValidatorOperations on IValidator {
  /// Combines two validators with a logical AND, same as using [all]
  ///
  /// This is **Sugar**, it allows for more concise validator composition.
  IValidator operator &(IValidator other) => all([this, other]);

  /// Combines two validators with a logical OR, same as using [any]
  /// 
  /// This is **Sugar**, it allows for more concise validator composition.
  IValidator operator |(IValidator other) => any([this, other]);

  /// Returns a new validator that will return the [error] message if the validation fails
  ///
  /// This is **Sugar**, it allows for more concise validator composition.
  IValidator operator >(String error) => withError(this, error);
}
