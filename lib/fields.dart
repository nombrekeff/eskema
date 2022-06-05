import 'common.dart';
import 'validators.dart';

/// Implementation of [IValidatable] for a single value
///
/// The field can be [nullable], and accepts a list of [Validator]s
///
/// This field is considered valid if:
/// * the value is null and the field is nullable
/// * all validators are valid or there are no validators
///
/// Example:
/// ```dart
/// final stringValidator = Field([isTypeString()]);
/// final result = stringValidator.validate('123');
/// ```
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

/// Implementation of [IValidatable] for a List of values
///
/// Like [Field] it also can be nullable,
/// it also receives a list of [Validator]s that check agains the List itself
/// You can pass [fieldValidator] in to validate each item in the List
///
/// Example:
/// ```dart
///  final listField = ListField(
///   fieldValidator: Field([isTypeInt()]),
///   validators: [listIsOfSize(2)],
///   nullable: true,
/// );
/// listField.validate(null).isValid;     // true
/// listField.validate([]).isValid;       // true
/// listField.validate([1, 2]).isValid;   // true
/// listField.validate([1, "2"]).isValid; // false
/// ```
class ListField extends Field {
  final IValidatable? fieldValidator;

  ListField({
    this.fieldValidator,
    bool nullable = false,
    List<Validator> validators = const [],
  }) : super([...validators, isTypeList()], nullable: nullable);

  ListField.nullable({
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

/// Implementation of [IValidatable] for a Map object
///
/// Like [Field] it also can be nullable,
/// it also receives a list of [Validator]s that check agains the List itself
/// You can pass [fieldValidator] in to validate each item in the List
///
/// Example:
/// ```dart
/// final field = MapField({
///   'address': MapField.nullable({
///     'city': Field([isTypeString()]),
///     'street': Field([isTypeString()]),
///     'number': Field([
///       isTypeInt(),
///       isMin(0),
///     ]),
///     'additional': MapField.nullable({
///       'doorbel_number': Field([isTypeInt()])
///     }),
///   })
/// });
/// ```
class MapField extends Field {
  /// Map holding the scheme for this MapField
  final Map<String, IValidatable> scheme;

  MapField(
    this.scheme, {
    bool nullable = false,
    List<Validator> validators = const [],
  }) : super([...validators, isTypeMap()], nullable: nullable);

  MapField.nullable(
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
