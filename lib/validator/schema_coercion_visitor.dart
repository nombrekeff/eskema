/// Visitor that inspects Eskema validator trees to coerce, transform, and normalize data.
library validator.coercion;

import 'package:eskema/result.dart';
import 'base_validator.dart';
import 'combinator_validators.dart';
import 'map_validators.dart';
import 'validator_visitor.dart';

enum _TargetType {
  intType,
  doubleType,
  numType,
  boolType,
  dateTimeType,
  listType,
  mapType,
  none,
}

/// Visitor that inspects Eskema validator trees to coerce, transform, and normalize data.
class SchemaCoercionVisitor implements IValidatorVisitor<dynamic, dynamic> {
  /// Whether unknown keys should be stripped from map outputs.
  final bool stripUnknownKeys;

  /// Creates a [SchemaCoercionVisitor].
  const SchemaCoercionVisitor({this.stripUnknownKeys = false});

  /// Validates [data] against [schemaValidator], applying type coercions, field transformations, and key stripping.
  Result validateAndCoerce(IValidator schemaValidator, dynamic data) {
    if (data is Map) {
      final coerced = _coerceMap(schemaValidator, data);
      final finalRes = schemaValidator.validate(coerced);
      if (finalRes.isValid) {
        return Result.valid(coerced);
      }

      return finalRes;
    }

    final coerced = _coerceFieldValue(schemaValidator, data);
    final result = schemaValidator.validate(coerced);

    if (result.isValid) {
      return Result.valid(result.value ?? coerced);
    }

    return result;
  }

  /// Coerces a single field or scalar value against [validator].
  dynamic _coerceFieldValue(IValidator validator, dynamic val) {
    if (val == null) {
      return null;
    }

    final directRes = validator.validate(val);
    if (directRes.isValid) {
      final validatedVal = directRes.value ?? val;
      if (validatedVal is Map) {
        return _coerceMap(validator, validatedVal);
      }
      if (validatedVal is List) {
        final itemValidator = _extractListItemValidator(validator);
        if (itemValidator != null) {
          return validatedVal
              .map((e) => _coerceFieldValue(itemValidator, e))
              .toList();
        }
      }

      return validatedVal;
    }

    final coerced = coerceValue(validator, val);
    final coercedRes = validator.validate(coerced);

    if (coercedRes.isValid) {
      final validatedCoerced = coercedRes.value ?? coerced;
      if (validatedCoerced is Map) {
        return _coerceMap(validator, validatedCoerced);
      }
      if (validatedCoerced is List) {
        final itemValidator = _extractListItemValidator(validator);
        if (itemValidator != null) {
          return validatedCoerced
              .map((e) => _coerceFieldValue(itemValidator, e))
              .toList();
        }
      }

      return validatedCoerced;
    }

    if (coerced is Map) {
      return _coerceMap(validator, coerced);
    }

    return coerced;
  }

  /// Coerces a [value] to match the expected type of [validator].
  dynamic coerceValue(IValidator validator, dynamic value) {
    if (value == null) {
      return null;
    }

    final targetType = _detectType(validator);

    // 1. String to Primitive / Target Coercion
    if (value is String) {
      final trimmed = value.trim();

      switch (targetType) {
        case _TargetType.intType:
          final parsed = int.tryParse(trimmed);
          if (parsed != null) {
            return parsed;
          }
          break;

        case _TargetType.doubleType:
          final parsed = double.tryParse(trimmed);
          if (parsed != null) {
            return parsed;
          }
          break;

        case _TargetType.numType:
          final parsed = num.tryParse(trimmed);
          if (parsed != null) {
            return parsed;
          }
          break;

        case _TargetType.boolType:
          final lower = trimmed.toLowerCase();
          if (lower == 'true' || lower == '1') {
            return true;
          }
          if (lower == 'false' || lower == '0') {
            return false;
          }
          break;

        case _TargetType.dateTimeType:
          final parsed = DateTime.tryParse(trimmed);
          if (parsed != null) {
            return parsed;
          }
          break;

        case _TargetType.listType:
          final itemValidator = _extractListItemValidator(validator);
          final promoted = <dynamic>[
            if (itemValidator != null)
              _coerceFieldValue(itemValidator, trimmed)
            else
              trimmed,
          ];
          return promoted;

        default:
          break;
      }
    }

    // 2. Int to Double Coercion
    if (value is int && targetType == _TargetType.doubleType) {
      return value.toDouble();
    }

    // 3. List handling & Single-Element Promotion
    if (targetType == _TargetType.listType) {
      final itemValidator = _extractListItemValidator(validator);

      if (value is List) {
        if (itemValidator != null) {
          return value
              .map((item) => _coerceFieldValue(itemValidator, item))
              .toList();
        }

        return value;
      }

      final coercedItem = itemValidator != null
          ? _coerceFieldValue(itemValidator, value)
          : value;

      return <dynamic>[coercedItem];
    }

    // 4. Map Coercion
    if (value is Map) {
      return _coerceMap(validator, value);
    }

    return value;
  }

  Map<String, dynamic> _coerceMap(IValidator validator, Map data) {
    if (validator is MapValidator) {
      final result = <String, dynamic>{};

      for (final field in validator.fields) {
        final id = field.id;
        if (id == null || id.isEmpty) {
          continue;
        }

        if (data.containsKey(id)) {
          final val = data[id];
          result[id] = _coerceFieldValue(field, val);
        }
      }

      _appendUnknownKeys(result, data);
      return result;
    }

    if (validator.name == 'eskema' &&
        validator.args.isNotEmpty &&
        validator.args.first is Map<String, IValidator>) {
      final mapSchema = validator.args.first as Map<String, IValidator>;
      final result = <String, dynamic>{};

      for (final entry in mapSchema.entries) {
        final key = entry.key;
        final childValidator = entry.value;

        if (data.containsKey(key)) {
          final val = data[key];
          result[key] = _coerceFieldValue(childValidator, val);
        }
      }

      _appendUnknownKeys(result, data);
      return result;
    }

    if (validator.name == 'switchBy' &&
        validator.args.length >= 2 &&
        validator.args[0] is String &&
        validator.args[1] is Map<String, IValidator>) {
      final key = validator.args[0] as String;
      final by = validator.args[1] as Map<String, IValidator>;
      final type = data[key];
      final branch = by[type];
      if (branch != null) {
        return _coerceMap(branch, data);
      }
    }

    if (validator is MultiValidatorBase) {
      for (final child in validator.validators) {
        if (child is MapValidator ||
            child.name == 'eskema' ||
            child.name == 'switchBy' ||
            child is MultiValidatorBase) {
          final coerced = _coerceMap(child, data);
          if (coerced.isNotEmpty) {
            return coerced;
          }
        }
      }
    }

    if (validator is Field) {
      for (final child in validator.validators) {
        if (child is MapValidator ||
            child.name == 'eskema' ||
            child.name == 'switchBy' ||
            child is MultiValidatorBase) {
          final coerced = _coerceMap(child, data);
          if (coerced.isNotEmpty) {
            return coerced;
          }
        }
      }
    }

    final result = <String, dynamic>{};
    _appendUnknownKeys(result, data);
    return result;
  }

  void _appendUnknownKeys(Map<String, dynamic> target, Map source) {
    if (!stripUnknownKeys) {
      for (final entry in source.entries) {
        final keyStr = entry.key.toString();
        if (!target.containsKey(keyStr)) {
          target[keyStr] = entry.value;
        }
      }
    }
  }

  _TargetType _detectType(IValidator validator) {
    if (validator is MapValidator || validator.name == 'eskema') {
      return _TargetType.mapType;
    }

    if (validator.name == 'isType' && validator.args.isNotEmpty) {
      final typeName = validator.args.first.toString();
      if (typeName == 'int') {
        return _TargetType.intType;
      }
      if (typeName == 'double') {
        return _TargetType.doubleType;
      }
      if (typeName == 'num') {
        return _TargetType.numType;
      }
      if (typeName == 'bool') {
        return _TargetType.boolType;
      }
      if (typeName == 'DateTime') {
        return _TargetType.dateTimeType;
      }
      if (typeName.startsWith('List')) {
        return _TargetType.listType;
      }
      if (typeName.startsWith('Map')) {
        return _TargetType.mapType;
      }
    }

    final name = validator.name;
    if (name == 'int' || name == 'isIntString') {
      return _TargetType.intType;
    }
    if (name == 'double' || name == 'isDoubleString') {
      return _TargetType.doubleType;
    }
    if (name == 'num' || name == 'isNumString' || name == 'isNumber') {
      return _TargetType.numType;
    }
    if (name == 'bool' ||
        name == 'isBoolString' ||
        name == 'isTrue' ||
        name == 'isFalse') {
      return _TargetType.boolType;
    }
    if (name == 'DateTime' ||
        name == 'isDate' ||
        name == 'isDateInPast' ||
        name == 'isDateInFuture' ||
        name == 'isDateBefore' ||
        name == 'isDateAfter' ||
        name == 'isDateBetween' ||
        name == 'isDateSameDay') {
      return _TargetType.dateTimeType;
    }
    if (name == 'List' || name == 'eskemaList' || name == 'listEach') {
      return _TargetType.listType;
    }

    if (validator is MultiValidatorBase) {
      for (final child in validator.validators) {
        final t = _detectType(child);
        if (t != _TargetType.none) {
          return t;
        }
      }
    }

    if (validator is Field) {
      for (final child in validator.validators) {
        final t = _detectType(child);
        if (t != _TargetType.none) {
          return t;
        }
      }
    }

    return _TargetType.none;
  }

  IValidator? _extractListItemValidator(IValidator validator) {
    if (validator.name == 'listEach' &&
        validator.args.isNotEmpty &&
        validator.args.first is IValidator) {
      return validator.args.first as IValidator;
    }

    if (validator.name == 'eskemaList' &&
        validator.args.isNotEmpty &&
        validator.args.first is IValidator) {
      return validator.args.first as IValidator;
    }

    if (validator is MultiValidatorBase) {
      for (final child in validator.validators) {
        final itemV = _extractListItemValidator(child);
        if (itemV != null) {
          return itemV;
        }
      }
    }

    if (validator is Field) {
      for (final child in validator.validators) {
        final itemV = _extractListItemValidator(child);
        if (itemV != null) {
          return itemV;
        }
      }
    }

    return null;
  }

  @override
  dynamic visitValidator(IValidator validator, dynamic data) {
    return _coerceFieldValue(validator, data);
  }

  @override
  dynamic visitMultiValidator(MultiValidatorBase validator, dynamic data) {
    return _coerceFieldValue(validator, data);
  }

  @override
  dynamic visitMapValidator(MapValidator validator, dynamic data) {
    return _coerceFieldValue(validator, data);
  }

  @override
  dynamic visitField(Field validator, dynamic data) {
    return _coerceFieldValue(validator, data);
  }
}
