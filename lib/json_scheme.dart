library json_scheme;

import 'package:json_scheme/validators.dart';

mixin IValidatable {
  Result validate(value);
}

class Result {
  final bool isValid;
  final dynamic value;
  final String? expected;
  final String? actual;

  Result({
    required this.isValid,
    this.value,
    this.expected,
    this.actual,
  });

  bool get isNotValid => !isValid;

  Result.valid({
    required this.value,
  })  : isValid = true,
        expected = null,
        actual = null;

  Result.invalid({
    required this.value,
    required this.expected,
    required this.actual,
  }) : isValid = false;
}

typedef Validator = Result Function(dynamic value);

class Field implements IValidatable {
  Field(this.validators, {this.nullable = false});

  Field.nullable(this.validators) : nullable = true;

  final bool nullable;

  final List<Validator> validators;

  @override
  Result validate(value) {
    if (value == null && nullable) return Result.valid(value: value);

    if (validators.isNotEmpty) {
      for (final validator in validators) {
        final result = validator.call(value);
        if (result.isNotValid) return result;
      }
    }

    return Result.valid(value: value);
  }
}

class MapScheme extends Field {
  final Map<String, IValidatable> scheme;

  MapScheme(
    this.scheme, {
    bool nullable = false,
    List<Validator> validators = const [],
  }) : super(validators, nullable: nullable);

  MapScheme.nullable(
    this.scheme, {
    List<Validator> validators = const [],
  }) : super(validators, nullable: true);

  @override
  Result validate(value) {
    final superResult = super.validate(value);
    if (superResult.isNotValid) return superResult;
    if (nullable && value == null) return Result.valid(value: value);

    if (value is! Map) {
      return Result.invalid(
        value: value,
        expected: 'Map',
        actual: value.runtimeType.toString(),
      );
    }

    for (final key in scheme.keys) {
      final field = scheme[key] as Field;
      final result = field.validate(value[key]);

      if (result.isNotValid) {
        // Absolute hack here folks
        String expected = '$key to be ${result.expected}';
        if (field is MapScheme) {
          expected = '$key.${result.expected}';
        }

        return Result.invalid(
          value: value,
          expected: expected,
          actual: value.runtimeType.toString(),
        );
      }
    }

    return Result.valid(value: value);
  }
}

class ListScheme extends Field {
  final IValidatable? fieldValidator;

  ListScheme({
    this.fieldValidator,
    bool nullable = false,
    List<Validator> validators = const [],
  }) : super([...validators, isTypeList()], nullable: nullable);

  ListScheme.nullable({
    this.fieldValidator,
    List<Validator> validators = const [],
  }) : super([...validators, isTypeList()], nullable: true);

  @override
  Result validate(value) {
    final superResult = super.validate(value);
    if (superResult.isNotValid) return superResult;
    if (nullable && value == null) return Result.valid(value: value);

    if (value is! List) {
      return Result.invalid(
        value: value,
        expected: 'List',
        actual: value.runtimeType.toString(),
      );
    }

    if (fieldValidator != null) {
      for (int index = 0; index < value.length; index++) {
        final item = value[index];
        final result = fieldValidator!.validate(item);

        if (result.isNotValid) {
          String expected = '[$index] to be ${result.expected}';
          if (fieldValidator is MapScheme) {
            expected = '[$index].${result.expected}';
          }
          if (fieldValidator is ListScheme) {
            expected = '[$index]${result.expected}';
          }

          return Result.invalid(
            value: value,
            expected: expected,
            actual: value.runtimeType.toString(),
          );
        }
      }
    }

    return Result.valid(value: value);
  }
}
