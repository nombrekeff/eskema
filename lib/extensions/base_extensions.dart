import 'package:eskema/eskema.dart';
import 'package:eskema/validators/presence.dart' as prs;

extension BaseExtensions on Object {
  /// Validates [this] value using the provided [validator].
  Result validate(IValidator validator) {
    return validator.validate(this);
  }

  /// Validates [this] value using the provided [validator].
  bool isValid(IValidator validator) {
    return validator.isValid(this);
  }

  /// Validates [this] value using the provided [validator].
  bool isNotValid(IValidator validator) {
    return validator.isNotValid(this);
  }
}

extension BaseIterableExtensions on Iterable {
  /// Validates [this] value using the provided [validator] for each item in the list.
  Result validate(IValidator validator) {
    return listEach(validator).validate(this);
  }
}

extension ValidatorExtensions on IValidator {
  /// Combines this validator with another validator using the `and` operator.
  /// Similar to `&` and `all`, but with a more readable syntax.
  IValidator and(IValidator validator) {
    return validator & this;
  }

  /// Combines this validator with another validator using the `or` operator.
  /// Similar to `|` and `any`, but with a more readable syntax.
  IValidator or(IValidator validator) {
    return validator | this;
  }

  /// Returns a nullable version of this validator.
  IValidator get nullable => this.nullable();

  /// Returns an optional version of this validator.
  IValidator get optional => this.optional();

  IValidator get required => prs.required(this);
}

extension ResultExtensions on Result {
  /// Returns the value if valid, otherwise throws a [ValidationException].
  dynamic get orThrow {
    if (!isValid) throw ValidatorFailedException(this);
    return value;
  }

  /// Returns the value if valid, otherwise returns [defaultValue].
  dynamic valueOr(dynamic defaultValue) => isValid ? value : defaultValue;
}
