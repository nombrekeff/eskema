import 'common.dart';
import 'validators.dart';

class Field implements IValidatable {
  final bool nullable;

  final List<Validator> validators;

  Field(this.validators, {this.nullable = false});

  Field.nullable(this.validators) : nullable = true;

  @override
  IResult validate(value) {
    if (value == null && nullable) return Result.valid;

    if (validators.isNotEmpty) {
      for (final validator in validators) {
        final result = validator.call(value);
        if (result.isNotValid) return result;
      }
    }

    return Result.valid;
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
  IResult validate(value) {
    final superResult = super.validate(value);
    if (superResult.isNotValid) return superResult;

    if (fieldValidator != null) {
      for (int index = 0; index < value.length; index++) {
        final item = value[index];
        final result = fieldValidator!.validate(item);

        if (result.isNotValid) {
          return Result.invalid('[$index] -> ${result.expected}');
        }
      }
    }

    return Result.valid;
  }
}

class MapScheme extends Field {
  final Map<String, IValidatable> scheme;

  MapScheme(
    this.scheme, {
    bool nullable = false,
    List<Validator> validators = const [],
  }) : super([...validators, isTypeMap()], nullable: nullable);

  MapScheme.nullable(
    this.scheme, {
    List<Validator> validators = const [],
  }) : super([...validators, isTypeMap()], nullable: true);

  @override
  IResult validate(value) {
    final superResult = super.validate(value);
    if (superResult.isNotValid) return superResult;

    for (final key in scheme.keys) {
      final field = scheme[key] as Field;
      final result = field.validate(value[key]);

      if (result.isNotValid) {
        return Result.invalid('$key -> ${result.expected}');
      }
    }

    return Result.valid;
  }
}
