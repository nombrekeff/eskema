import 'result.dart';

typedef EskValidatorFn = IResult Function(dynamic value);

abstract class IEskValidator {
  IResult validate(dynamic value);
  bool isValid(dynamic value) => validate(value).isValid;
  bool isNotValid(dynamic value) => !validate(value).isValid;

  bool _nullable;

  IEskValidator({bool nullable = false}) : _nullable = nullable;

  bool get isNullable => _nullable;

  IEskValidator copyWith({bool? nullable});

  IEskValidator orNullable<T>() {
    return copyWith(nullable: true);
  }
}

abstract class EskIdValidator extends IEskValidator {
  final String id;

  EskIdValidator({required this.id, super.nullable});
}

class EskValidator extends IEskValidator {
  final EskValidatorFn _validator;
  EskValidator(this._validator, {super.nullable});

  @override
  IResult validate(dynamic value) {
    final result = _validator.call(value);
    if (value == null && isNullable) return Result.valid;
    return result;
  }

  @override
  IEskValidator copyWith({bool? nullable}) {
    return EskValidator(_validator, nullable: nullable ?? isNullable);
  }

  @override
  String toString() => 'Validator';
}

class EskField extends EskIdValidator {
  final List<EskValidator> validators;

  EskField({required this.validators, required super.id, super.nullable});

  @override
  IResult validate(dynamic value) {
    if ((value == null && isNullable)) {
      return Result.valid;
    }

    if ((value == null && !isNullable)) {
      return Result.invalid('not null', value);
    }

    for (var validator in validators) {
      final result = validator.validate(value);
      if (result.isNotValid) {
        return result;
      }
    }
    return Result.valid;
  }

  @override
  IEskValidator copyWith({bool? nullable}) {
    return EskField(
      validators: List<EskValidator>.from(
          validators.map((v) => v.copyWith(nullable: nullable))),
      id: id,
      nullable: nullable ?? isNullable,
    );
  }
}

abstract class EskMap<T extends Map> extends EskIdValidator {
  List<IEskValidator> get fields;
  EskMap({super.id = 'class_validator', super.nullable});

  @override
  IResult validate(dynamic map) {
    if (map == null && isNullable) {
      return Result.valid..value = map;
    }

    if ((map == null && !isNullable) || map is! Map) {
      return Result.invalid('Expected a ${T.runtimeType}', map);
    }

    if (map.isEmpty && !isNullable) {
      return Result.invalid('No data provided for validation', map);
    }

    for (final field in fields) {
      if (field is EskIdValidator) {
        final mapValue = map[field.id];
        // If the field is nullable, we can skip validation if the value is null
        if (mapValue == null && field.isNullable) continue;

        print(
          "Validating field: ${field.id}, value: $mapValue, with field: ${field}",
        );

        final result = field.validate(mapValue);
        if (result.isValid) continue;

        String expected = '';

        if (field is EskMap) {
          expected += '${field.id}.${result.expected}';
        } else {
          expected += '${field.id} to be ${result.expected}';
        }

        return Result(
          isValid: result.isValid,
          expected: expected,
          value: mapValue,
        );
      }
    }

    return Result.valid..value = map;
  }

  @override
  IEskValidator copyWith({bool? nullable}) {
    throw Exception(
        'copyWith not implemented for ${runtimeType}, as it defines properties that cannot be copied automaticaly.\n' +
            'Please create a new instance manually. Or override the "copyWith" method.');
  }
}
