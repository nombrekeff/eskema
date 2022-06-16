/// Represents the result of a validation
mixin IResult {
  /// Tells us if  this result is valid
  bool get isValid;
  
  /// Optional message for the expected result
  String? get expected;

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

  Result({required this.isValid, this.expected});

  Result.invalid(this.expected) : isValid = false;

  @override
  String toString() {
    return isValid ? 'Valid' : 'Expected $expected';
  }
}
