import 'package:eskema/eskema.dart';
import 'package:eskema/util.dart';

/// Represents an expectation for a validation result.
class Expectation {
  /// The path to the value being validated. i.e. 'user.name'
  final String? path;
  final String message;
  final dynamic value;

  Expectation({
    this.path,
    required this.message,
    required this.value,
  });

  /// Get a short description of the expectation.
  String get shortDescription {
    if (path != null && path!.isNotEmpty) {
      return '$path: $message';
    }

    return message;
  }

  /// Get a detailed description of the expectation.
  String get description {
    final messageSuffix = '$message (value: ${pretifyValue(value)})';

    if (path != null && path!.isNotEmpty) {
      return '$path: $messageSuffix';
    }

    return messageSuffix;
  }

  Expectation copyWith({
    String? path,
    String? message,
    dynamic value,
  }) {
    return Expectation(
      path: path ?? this.path,
      message: message ?? this.message,
      value: value ?? this.value,
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

  /// Convenient method to convert the expectation to an invalid result.
  Result toInvalidResult() {
    return Result.invalid(value, expectation: this);
  }
}

/// Creates an expectation for a validation result.
Expectation expectation(String message, dynamic value, [String? path]) {
  return Expectation(
    path: path,
    message: message,
    value: value,
  );
}
