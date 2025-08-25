/// Represents the result of a validation.
///
/// This class encapsulates the outcome of a validation process, including
/// whether the validation was successful, the value that was validated,
/// and any expectations that were not met.
library result;

import 'package:eskema/expectation.dart';
import 'package:eskema/src/util.dart';

/// Represents the result of a validation.
class Result<T> {
  Result({
    required this.isValid,
    required this.value,
    List<Expectation>? expectations,
    Expectation? expectation,
  })  : assert(
          isValid ||
              (!isValid && expectation != null ||
                  (expectations != null && expectations.isNotEmpty)),
          'invalid -> provide an expectation or non-empty expectations list',
        ),
        expectations = List.unmodifiable(
          expectations ?? (expectation == null ? const <Expectation>[] : [expectation]),
        );

  Result.valid(this.value)
      : isValid = true,
        expectations = const <Expectation>[];

  Result.invalid(this.value, {List<Expectation>? expectations, Expectation? expectation})
      : assert(
          (expectation != null || (expectations != null && expectations.isNotEmpty)),
          "If invalid, either 'expectation' or a non-empty 'expectations' list must be provided",
        ),
        isValid = false,
        expectations = (expectations != null
            ? List.unmodifiable(expectations)
            : List.unmodifiable([expectation!]));

  final bool isValid;

  /// The list of expectations for the validation result.
  /// It will contain expectations independent of the validation result.
  final List<Expectation> expectations;
  final T value;

  bool get hasExpectations => expectations.isNotEmpty;
  bool get isNotValid => !isValid;

  Expectation get firstExpectation => expectations.first;
  Expectation get lastExpectation => expectations.last;

  int get expectationCount => expectations.length;

  String get shortDescription {
    return isValid ? 'Valid' : expectations.map((e) => e.shortDescription).join(', ');
  }

  String get description {
    return isValid
        ? 'Valid: ${prettifyValue(value)}'
        : '$shortDescription (value: ${prettifyValue(value)})';
  }

  /// Creates a copy of the result with the given parameters.
  Result copyWith({
    bool? isValid,
    List<Expectation>? expectations,
    dynamic value,
  }) {
    return Result(
      isValid: isValid ?? this.isValid,
      expectations: expectations ?? this.expectations,
      value: value ?? this.value,
    );
  }

  @override
  String toString() {
    return description;
  }

  Map<String, Object?> toJson() => {
        'isValid': isValid,
        if (value != null) 'value': value,
        if (!isValid) 'errors': expectations.map((e) => e.toJson()).toList(growable: false),
      };
}
