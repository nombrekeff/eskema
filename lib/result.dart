import 'package:eskema/util.dart';

/// Represents the result of a validation
class EskResult {
  final bool isValid;
  final String? expected;
  final dynamic value;

  bool get isNotValid => !isValid;

  EskResult({required this.isValid, this.expected, this.value});

  EskResult.invalid(this.expected, this.value) : isValid = false;
  EskResult.valid(this.value)
      : isValid = true,
        expected = null;

  @override
  String toString() {
    return isValid
        ? 'Valid: ${pretifyValue(value)}'
        : 'Expected $expected, got ${pretifyValue(value)}';
  }
}
