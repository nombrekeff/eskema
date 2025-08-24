import 'package:eskema/error.dart';
import 'package:eskema/result.dart';
import 'package:eskema/validators.dart';

import 'validator.dart';

extension EskemaMapExtension on Map {
  EskResult validate(IEskValidator validator) {
    return validator.validate(this);
  }

  bool isValid(IEskValidator eskema) {
    return eskema.validate(this).isValid;
  }

  bool isNotValid(IEskValidator eskema) {
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
  EskResult validate(IEskValidator eskema) {
    return listEach(eskema).validate(this);
  }
}

extension EskemaEskValidatorOperations on IEskValidator {
  // IEskValidator operator +(IEskValidator other) {
  //   // TODO: Find a way of identifying validators like `all` and `any`,
  //   //  which contain a list of validators. If they are the same type,
  //   //  we can combine them into a single validator, instead of having
  //   //  excessive nested validators for the same field.
  // }

  /// Combines two validators with a logical AND, same as using [all]
  IEskValidator operator &(IEskValidator other) => all([this, other]);

  /// Combines two validators with a logical OR, same as using [any]
  IEskValidator operator |(IEskValidator other) => any([this, other]);

  /// Returns a new validator that will return the [error] message if the validation fails
  IEskValidator operator >(String error) => EskValidator(
        (value) => EskResult(
          isValid: validate(value).isValid,
          errors: [EskError(message: error, value: value)],
          value: value,
        ),
      );
}
