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
    required super.errors,
    required super.value,
  });

  EskResult.valid(dynamic value) : super(isValid: true, errors: [], value: value);
  EskResult.invalid(List<EskError> errors, dynamic value)
      : super(isValid: false, errors: errors, value: value);

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

class EskError {
  final String? path;
  final String message;
  final dynamic value;

  EskError({
    this.path,
    required this.message,
    required this.value,
  });

  String get shortDescription {
    if (path != null && path!.isNotEmpty) {
      return '$path: $message';
    }

    return message;
  }

  String get description {
    final messageSuffix = '$message (value: ${pretifyValue(value)})';

    if (path != null && path!.isNotEmpty) {
      return '$path: $messageSuffix';
    }

    return messageSuffix;
  }

  EskError copyWith({
    String? path,
    String? message,
    dynamic value,
  }) {
    return EskError(
      path: path ?? this.path,
      message: message ?? this.message,
      value: value ?? this.value,
    );
  }

  @override
  String toString() {
    return description;
  }
}
