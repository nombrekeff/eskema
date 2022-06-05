mixin IResult {
  bool get isValid;
  String? get expected;
  bool get isNotValid => !isValid;
}

typedef Validator = IResult Function(dynamic value);

mixin IValidatable {
  IResult validate(value);
}

class Result with IResult {
  static Result valid = Result(isValid: true);

  @override
  final bool isValid;

  @override
  final String? expected;

  Result({required this.isValid, this.expected});

  Result.invalid(this.expected) : isValid = false;
}
