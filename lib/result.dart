import 'package:eskema/error.dart';
import 'package:eskema/util.dart';

class EskResult {
  EskResult({
    required this.isValid,
    required this.value,
    List<EskError>? errors,
    EskError? error,
  })  : assert(
          error != null || errors != null,
          "Either 'errors' list or 'error' must be provided",
        ),
        errors = errors ?? [error!];

  EskResult.valid(this.value)
      : isValid = true,
        errors = [];

  EskResult.invalid(this.value, {List<EskError>? errors, EskError? error})
      : assert(
          error != null || errors != null,
          "Either 'errors' list or 'error' must be provided",
        ),
        isValid = false,
        errors = errors ?? [error!];

  final bool isValid;
  final List<EskError> errors;
  final dynamic value;

  bool get hasErrors => errors.isNotEmpty;
  bool get isNotValid => !isValid;

  String get shortDescription {
    if (isValid) {
      return 'Valid';
    } else {
      return errors.map((e) => e.shortDescription).join(', ');
    }
  }

  String get description {
    if (isValid) {
      return 'Valid: ${pretifyValue(value)}';
    } else {
      return '${errors.map((e) => e.shortDescription).join(', ')} (value: ${pretifyValue(value)})';
    }
  }

  EskResult copyWith({
    bool? isValid,
    List<EskError>? errors,
    dynamic value,
  }) {
    return EskResult(
      isValid: isValid ?? this.isValid,
      errors: errors ?? this.errors,
      value: value ?? this.value,
    );
  }

  EskResult addErrors(List<EskError> newErrors) {
    return copyWith(
      isValid: false,
      errors: [...errors, ...newErrors],
    );
  }

  EskResult negate() {
    return copyWith(
      isValid: !isValid,
    );
  }

  @override
  String toString() {
    return description;
  }
}
