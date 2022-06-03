import 'package:json_scheme/json_scheme.dart';

Validator isType(Type type) {
  return (value) {
    final isValidType = value.runtimeType == type;

    return isValidType ? null : 'expected $type';
  };
}

Validator isTypeString() => isType(String);
Validator isTypeDouble() => isType(double);
Validator isTypeInt() => isType(int);
Validator isTypeNum() => isType(num);
Validator isTypeBool() => isType(bool);
Validator isTypeList<T>() {
  return (value) {
    return value is List<T> ? null : 'expected List';
  };
}
Validator isTypeMap() {
  return (value) {
    return value is Map ? null : 'expected Map';
  };
}

Validator isTypeSet() => isType(Set);
Validator isTypeFuture() => isType(Future);
Validator isTypeStream() => isType(Stream);

Validator isMin(num min) {
  return (value) {
    if (value is num && value < min) return 'value is under the min value of "$min"';

    return null;
  };
}

Validator isMax(num max) {
  return (value) {
    if (value is num && value > max) return 'value is over the max value of "$max"';

    return null;
  };
}

Validator isDate() {
  return (value) {
    try {
      DateTime.parse(value);
      return null;
    } catch (e) {
      return 'value is not a valid date';
    }
  };
}

// Utility validators

/// Passes the test if either of the [Validator]s are valid, and fails if both are invalid
Validator either(Validator validator1, Validator validator2) {
  return (value) {
    final res1 = validator1(value);
    final res2 = validator2(value);

    if (res1 != null && res2 != null) return '$res1 or $res2';

    return null;
  };
}
