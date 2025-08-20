import 'package:eskema/util.dart';

/// Represents the result of a validation
class EskResult {
  final bool isValid;
  final String? expected;
  final dynamic value;
  StackTrace? stackTrace;

  bool get isNotValid => !isValid;

  EskResult(
      {required this.isValid, this.expected, this.value, this.stackTrace});

  EskResult.invalid(this.expected, this.value, {this.stackTrace})
      : isValid = false;

  EskResult.valid(this.value, {this.stackTrace})
      : isValid = true,
        expected = null;

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
      return 'Expected $expected, got ${pretifyValue(value)}${verbose ? '\nStack trace: \n${getCleanStackTrace()}' : ''}';
    }
  }

  EskResult copyWith({
    bool? isValid,
    String? expected,
    dynamic value,
    StackTrace? stackTrace,
  }) {
    return EskResult(
      isValid: isValid ?? this.isValid,
      expected: expected ?? this.expected,
      value: value ?? this.value,
      stackTrace: stackTrace ?? this.stackTrace,
    );
  }

  @override
  String toString() {
    return describeResult();
  }
}
