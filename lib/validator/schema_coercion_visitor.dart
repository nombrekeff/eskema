/// Visitor that inspects Eskema validator trees to coerce, transform, and normalize data.
library validator.coercion;

import 'package:eskema/result.dart';
import 'base_validator.dart';
import 'combinator_validators.dart';
import 'map_validators.dart';
import 'validator_visitor.dart';

/// Visitor that inspects Eskema validator trees to coerce, transform, and normalize data.
class SchemaCoercionVisitor
    implements IValidatorVisitor<Map<String, dynamic>?, dynamic> {
  /// Whether unknown keys should be stripped from map outputs.
  final bool stripUnknownKeys;

  /// Creates a [SchemaCoercionVisitor].
  const SchemaCoercionVisitor({this.stripUnknownKeys = false});

  /// Validates [data] against [schemaValidator] and applies type transformations and key stripping.
  Result validateAndCoerce(IValidator schemaValidator, dynamic data) {
    final baseResult = schemaValidator.validate(data);
    if (baseResult.isNotValid) {
      return baseResult;
    }

    if (data is Map) {
      final coerced = schemaValidator.accept(this, data);
      if (coerced != null) {
        return Result.valid(coerced);
      }
    }

    return baseResult;
  }

  @override
  Map<String, dynamic>? visitValidator(IValidator validator, dynamic data) {
    if (data is! Map) {
      return null;
    }

    if (validator.name == 'eskema' &&
        validator.args.isNotEmpty &&
        validator.args.first is Map<String, IValidator>) {
      final mapSchema = validator.args.first as Map<String, IValidator>;
      return _coerceWithMapSchema(mapSchema, data);
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
        return branch.accept(this, data);
      }
    }

    return null;
  }

  @override
  Map<String, dynamic>? visitMultiValidator(
      MultiValidatorBase validator, dynamic data) {
    if (data is! Map) {
      return null;
    }

    for (final child in validator.validators) {
      final result = child.accept(this, data);
      if (result != null) {
        return result;
      }
    }

    return null;
  }

  @override
  Map<String, dynamic>? visitMapValidator(
      MapValidator validator, dynamic data) {
    if (data is! Map) {
      return null;
    }

    final result = <String, dynamic>{};

    for (final field in validator.fields) {
      final id = field.id;
      if (id == null || id.isEmpty) {
        continue;
      }

      if (data.containsKey(id)) {
        final val = data[id];
        final fieldRes = field.validate(val, exists: true);
        if (fieldRes.isValid) {
          if (fieldRes.value is Map) {
            final nestedCoerced = field.accept(this, fieldRes.value);
            result[id] = nestedCoerced ?? fieldRes.value;
          } else {
            result[id] = fieldRes.value;
          }
        } else {
          result[id] = val;
        }
      }
    }

    _appendUnknownKeys(result, data);
    return result;
  }

  @override
  Map<String, dynamic>? visitField(Field validator, dynamic data) {
    if (data is! Map) {
      return null;
    }

    for (final child in validator.validators) {
      final result = child.accept(this, data);
      if (result != null) {
        return result;
      }
    }

    return null;
  }

  Map<String, dynamic> _coerceWithMapSchema(
    Map<String, IValidator> mapSchema,
    Map data,
  ) {
    final result = <String, dynamic>{};

    for (final entry in mapSchema.entries) {
      final key = entry.key;
      final validator = entry.value;

      if (data.containsKey(key)) {
        final val = data[key];
        final fieldRes = validator.validate(val, exists: true);
        if (fieldRes.isValid) {
          if (fieldRes.value is Map) {
            final nestedCoerced = validator.accept(this, fieldRes.value);
            result[key] = nestedCoerced ?? fieldRes.value;
          } else {
            result[key] = fieldRes.value;
          }
        } else {
          result[key] = val;
        }
      }
    }

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
}
