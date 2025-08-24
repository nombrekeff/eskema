import 'package:eskema/error.dart';
import 'package:eskema/util.dart';

abstract class IEskResult {
  IEskResult({
    required this.isValid,
    required this.errors,
    required this.value,
  });

  final bool isValid;
  final List<EskError> errors;
  final dynamic value;

  bool get hasErrors => errors.isNotEmpty;
  bool get isNotValid => !isValid;

  String get shortDescription;
  String get description;

  IEskResult copyWith({
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

  IEskResult addErrors(List<EskError> newErrors) {
    return copyWith(
      isValid: false,
      errors: [...errors, ...newErrors],
    );
  }

  IEskResult negate() {
    return copyWith(
      isValid: !isValid,
    );
  }

  @override
  String toString() {
    return description;
  }
}

class EskResult extends IEskResult {
  EskResult({
    required super.isValid,
    required super.value,
    List<EskError>? errors,
    EskError? error,
  })  : assert(
          error != null || errors != null,
          "Either 'errors' list or 'error' must be provided",
        ),
        super(
          errors: errors ?? [error!],
        );

  EskResult.valid(dynamic value) : super(isValid: true, errors: [], value: value);

  EskResult.invalid(dynamic value, {List<EskError>? errors, EskError? error})
      : assert(
          error != null || errors != null,
          "Either 'errors' list or 'error' must be provided",
        ),
        super(isValid: false, errors: errors ?? [error!], value: value);

  @override
  String get shortDescription {
    if (isValid) {
      return 'Valid';
    } else {
      return errors.map((e) => e.shortDescription).join(', ');
    }
  }

  @override
  String get description {
    if (isValid) {
      return 'Valid: ${pretifyValue(value)}';
    } else {
      return '${errors.map((e) => e.shortDescription).join(', ')} (value: ${pretifyValue(value)})';
    }
  }
}
