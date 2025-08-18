import 'package:eskema/util.dart';

/// Represents the result of a validation
mixin IResult {
  /// Tells us if this result is valid
  bool get isValid;

  /// Optional message for the expected result
  String? get expected;

  dynamic value;

  /// Handy getter to check if this result is not valid
  bool get isNotValid => !isValid;
}

/// Basic implementation of [IResult]
class Result with IResult {
  /// Valid result, use this instead if creating a new instance
  static final Result valid = Result(isValid: true);

  @override
  final bool isValid;

  @override
  final String? expected;

  @override
  dynamic value;

  Result({required this.isValid, this.expected, this.value});

  Result.invalid(this.expected, this.value) : isValid = false;

  @override
  String toString() {
    return isValid ? 'Valid: ${pretifyValue(value)}' : 'Expected $expected, got ${pretifyValue(value)}';
  }
}
