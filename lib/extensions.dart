import 'package:eskema/eskema.dart';

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
  IValidator operator &(IValidator other) {
    if (this is AllValidator && other is AllValidator) {
      final mv1 = this as AllValidator;
      return mv1.copyWith(validators: {...mv1.validators, ...other.validators});
    }

    if (this is AllValidator) {
      final mv = this as AllValidator;
      return mv.copyWith(validators: {...mv.validators, other});
    }

    if (other is AllValidator) {
      return other.copyWith(validators: {...other.validators, this});
    }

    return all([this, other]);
  }

  /// Combines two validators with a logical OR, same as using [any]
  ///
  /// This is **Sugar**, it allows for more concise validator composition.
  IValidator operator |(IValidator other) {
    if (this is AnyValidator && other is AnyValidator) {
      final mv1 = this as AnyValidator;
      return mv1.copyWith(validators: {...mv1.validators, ...other.validators});
    }

    if (this is AnyValidator) {
      final mv = this as AnyValidator;
      return mv.copyWith(validators: {...mv.validators, other});
    }

    if (other is AnyValidator) {
      return other.copyWith(validators: {...other.validators, this});
    }

    return any([this, other]);
  }

  /// Returns a new validator that will return the [error] message if the validation fails
  ///
  /// This is **Sugar**, it allows for more concise validator composition.
  ///
  /// The underlying child's error `code` (and `data`) are preserved and propagated into the
  /// provided [error] (only the message is replaced). See docs/expectation_codes.md for the
  /// canonical list of built‑in codes.
  IValidator operator >(Expectation error) => withExpectation(this, error);
}
