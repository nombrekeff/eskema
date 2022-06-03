library json_scheme;

mixin IValidatable {
  String? validate(value);
}

class ValidationResult {
  final dynamic value;
  final String expected;
  final String actual;

  ValidationResult({
    required this.value,
    required this.expected,
    required this.actual,
  });

  @override
  String toString() {
    return '';
  }
}

typedef Validator = String? Function(dynamic value);

class Field<T> implements IValidatable {
  Field(this.validators) : nullable = false;

  Field.nullable(this.validators) : nullable = true;

  final bool nullable;

  final List<Validator> validators;

  @override
  String? validate(value) {
    if (value == null && nullable) return null;
    if (value == null && !nullable) return "value can't be null";

    if (validators.isNotEmpty) {
      for (final validator in validators) {
        final result = validator.call(value);
        if (result != null) return result;
      }
    }

    return null;
  }
}

class Scheme implements IValidatable {
  static fromMap(Map<String, Object> testObject) {}

  Scheme(dynamic list);

  @override
  String? validate(object) {
    throw UnimplementedError();
  }
}
