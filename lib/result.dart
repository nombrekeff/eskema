import 'package:eskema/util.dart';

/// Represents the result of a validation
class EskResult {
  final bool isValid;
  final String? error;
  final dynamic value;
  StackTrace? stackTrace;

  bool get isNotValid => !isValid;

  EskResult({
    required this.isValid,
    this.error,
    this.value,
    this.stackTrace,
  });

  EskResult.invalid(this.error, this.value, {this.stackTrace})
      : isValid = false;

  EskResult.valid(this.value, {this.stackTrace})
      : isValid = true,
        error = null;

  String getCleanStackTrace() {
    return stackTrace
            ?.toString()
            .split('\n')
            .where((line) => !line.contains('(dart:'))
            .join('\n') ??
        '';
  }

  String describeResult({bool verbose = false}) {
    if (isValid) {
      return 'Valid: ${pretifyValue(value)}';
    } else {
      return 'Expected $error, got ${pretifyValue(value)}${verbose ? '\nStack trace: \n${getCleanStackTrace()}' : ''}';
    }
  }

  EskResult copyWith({
    bool? isValid,
    String? error,
    dynamic value,
    StackTrace? stackTrace,
  }) {
    return EskResult(
      isValid: isValid ?? this.isValid,
      error: error ?? this.error,
      value: value ?? this.value,
      stackTrace: stackTrace ?? this.stackTrace,
    );
  }

  @override
  String toString() {
    return describeResult();
  }
}
