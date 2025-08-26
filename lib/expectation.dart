import 'package:eskema/eskema.dart';

/// Represents an expectation for a validation result.
class Expectation {
  /// The path to the value being validated. i.e. 'user.name'
  final String? path;
  final String message;
  final dynamic value;

  /// Optional machine‑readable code (e.g. 'type_mismatch', 'required_missing')
  ///
  /// Each expectation can include a `code` (namespaced, e.g. `type.mismatch`, `value.range_out_of_bounds`) and
  /// a structured `data` payload for machine processing (localization, analytics, conditional UI, etc.).
  ///
  /// See docs/expectation_codes.md for the authoritative mapping of built-in validators to codes & data shapes.
  final String? code;

  /// Optional structured metadata (e.g. {'expectedType': 'String', 'foundType': 'int'})
  final Map<String, Object?>? data;

  Expectation({
    this.path,
    required this.message,
    this.value,
    this.code,
    this.data,
  });

  /// Get a detailed description of the expectation.
  String get description {
    if (path != null && path!.isNotEmpty) {
      return '$path: $message';
    }

    return message;
  }

  Expectation copyWith({
    String? path,
    String? message,
    dynamic value,
    String? code,
    Map<String, Object?>? data,
  }) {
    return Expectation(
      path: path ?? this.path,
      message: message ?? this.message,
      value: value ?? this.value,
      code: code ?? this.code,
      data: data ?? this.data,
    );
  }

  /// Append [additionalPath] to the current path.
  Expectation addToPath(String additionalPath) {
    return copyWith(
      path: [path, additionalPath].join('.'),
    );
  }

  @override
  String toString() {
    return description;
  }

  Map<String, Object?> toJson() => {
        'message': message,
        if (code != null) 'code': code,
        if (path != null) 'path': path,
        if (value != null) 'value': value,
        if (data != null && data!.isNotEmpty) 'data': data,
      };

  /// Convenient method to convert the expectation to an invalid result.
  Result toInvalidResult() => Result.invalid(value, expectation: this);
}

/// Creates an expectation for a validation result.
Expectation expectation(String message, dynamic value,
        [String? path, String? code, Map<String, Object?>? data]) =>
    Expectation(path: path, message: message, value: value, code: code, data: data);
