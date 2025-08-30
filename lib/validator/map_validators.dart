/// Map-oriented validators (schema / object validation helpers).
library validator.map;

import 'dart:async';
import 'package:eskema/expectation.dart';
import 'package:eskema/result.dart';
import 'package:eskema/validators.dart';
import 'base_validator.dart';

/// Abstract class for schema-like map validators composed of Field/IdValidator instances.
abstract class MapValidator<T extends Map> extends IdValidator {
  MapValidator({super.id = '', super.nullable}) : super(validator: isMap().validate);

  List<IdValidator> get fields;

  @override
  FutureOr<Result> validator(dynamic value) {
    final base = super.validator(value);
    if (base is Future<Result>) return base.then((r) => _mapContinue(r, value));
    return _mapContinue(base, value);
  }

  Result _mapContinue(Result base, dynamic value) {
    if (base.isNotValid) return base;
    for (final field in fields) {
      final mapValue = value[field.id];
      if (mapValue == null && field.isNullable) continue;
      final result = field.validate(mapValue);
      if (result.isValid) continue;
      final error = field is MapValidator
          ? '${field.id}.${result.description}'
          : '${field.id} to be ${result.description}';
      return Result(
        isValid: result.isValid,
        expectations: [Expectation(message: error, value: mapValue)],
        value: mapValue,
      );
    }
    return Result.valid(value);
  }

  @override
  IValidator copyWith({bool? nullable, bool? optional}) => throw Exception(
      'copyWith not implemented for $runtimeType. Create a new instance or override copyWith.');
}
