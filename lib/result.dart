/// Represents the result of a validation.
///
/// This class encapsulates the outcome of a validation process, including
/// whether the validation was successful, the value that was validated,
/// and any expectations that were not met.
library result;

import 'package:eskema/expectation.dart';

const _emptyExpectations = <Expectation>[];
const _defaultExpectation = Expectation(message: 'Validation failed');

/// Represents the result of a validation.
class Result {
  Result({
    required this.isValid,
    required this.value,
    Iterable<Expectation>? expectations,
    Expectation? expectation,
  }) : expectations =
            expectations ?? (expectation == null ? _emptyExpectations : [expectation]);

  Result.valid(this.value)
      : isValid = true,
        expectations = _emptyExpectations;

  Result.invalid(this.value, {Iterable<Expectation>? expectations, Expectation? expectation})
      : isValid = false,
        expectations =
            expectations ?? (expectation == null ? [_defaultExpectation] : [expectation]);

  final bool isValid;

  /// The list of expectations for the validation result.
  /// It will contain expectations independent of the validation result.
  final Iterable<Expectation> expectations;
  final dynamic value;

  bool get hasExpectations => expectations.isNotEmpty;
  bool get isNotValid => !isValid;

  Expectation get firstExpectation => expectations.first;
  Expectation get lastExpectation => expectations.last;

  int get expectationCount => expectations.length;

  String? get description {
    return isValid ? null : expectations.map((e) => e.description).join(', ');
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
    // Keep valid results concise; invalid use joined expectation descriptions (legacy behavior).
    // Callers needing structured formatting should use error_format.dart helpers.
    return description ?? 'Valid';
  }

  Map<String, Object?> toJson() => {
    'isValid': isValid,
    if (value != null) 'value': value,
    if (!isValid) 'errors': expectations.map((e) => e.toJson()).toList(growable: false),
  };
}
