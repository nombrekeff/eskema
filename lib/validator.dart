import 'package:eskema/util.dart';
import 'package:eskema/validators.dart';

import 'result.dart';

typedef EskValidatorFn = EskResult Function(dynamic value);

abstract class IEskValidator {
  EskResult validator(dynamic value);

  EskResult validate(dynamic value) {
    if (value == null && isNullable) {
      return EskResult.valid(value);
    }

    final result = validator(value);

    try {
      throw Exception('Validation failed');
    } catch (e, trace) {
      result.stackTrace = trace;
    }

    return result;
  }

  EskResult validateOrThrow(dynamic value) {
    final result = validate(value);
    if (result.isNotValid) throw ValidatorFailedException(result);
    return result;
  }

  bool isValid(dynamic value) => validate(value).isValid;

  bool isNotValid(dynamic value) => !validate(value).isValid;

  bool _nullable;

  IEskValidator({bool nullable = false}) : _nullable = nullable;

  bool get isNullable => _nullable;

  IEskValidator copyWith({bool? nullable});

  IEskValidator nullable<T>() {
    return copyWith(nullable: true);
  }
}

class EskValidator extends IEskValidator {
  final EskValidatorFn _validator;
  EskValidator(this._validator, {super.nullable});

  @override
  EskResult validator(dynamic value) {
    return _validator.call(value);
  }

  @override
  IEskValidator copyWith({bool? nullable}) {
    return EskValidator(_validator, nullable: nullable ?? isNullable);
  }

  @override
  String toString() => 'Validator';
}

abstract class EskIdValidator extends EskValidator {
  final String id;

  EskIdValidator({
    required EskValidatorFn validator,
    required this.id,
    super.nullable,
  }) : super(validator);
}

class EskField extends EskIdValidator {
  final List<IEskValidator> validators;

  EskField({required this.validators, required super.id, super.nullable})
      : super(validator: EskResult.valid);

  @override
  EskResult validator(dynamic value) {
    final superRes = super.validator(value);
    if (superRes.isNotValid) return superRes;

    for (var validator in validators) {
      final result = validator.validate(value);
      if (result.isNotValid) {
        return result;
      }
    }

    return EskResult.valid(value);
  }

  @override
  IEskValidator copyWith({bool? nullable}) {
    return EskField(
      validators: List<IEskValidator>.from(
        validators.map((v) => v.copyWith(nullable: nullable)),
      ),
      id: id,
      nullable: nullable ?? isNullable,
    );
  }
}

abstract class EskMap<T extends Map> extends EskIdValidator {
  List<IEskValidator> get fields;
  EskMap({super.id = 'class_validator', super.nullable})
      : super(validator: isMap().validate);

  @override
  EskResult validator(dynamic value) {
    final superRes = super.validator(value);
    if (superRes.isNotValid) return superRes;

    for (final field in fields) {
      if (field is EskIdValidator) {
        final mapValue = value[field.id];
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

        return EskResult(
          isValid: result.isValid,
          expected: expected,
          value: mapValue,
        );
      }
    }

    return EskResult.valid(value);
  }

  @override
  IEskValidator copyWith({bool? nullable}) {
    throw Exception(
        'copyWith not implemented for ${runtimeType}, as it defines properties that cannot be copied automaticaly.\n' +
            'Please create a new instance manually. Or override the "copyWith" method.');
  }
}
