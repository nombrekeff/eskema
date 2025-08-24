import 'package:eskema/util.dart';

class EskError {
  final String? path;
  final String message;
  final dynamic value;

  EskError({
    this.path,
    required this.message,
    required this.value,
  });

  String get shortDescription {
    if (path != null && path!.isNotEmpty) {
      return '$path: $message';
    }

    return message;
  }

  String get description {
    final messageSuffix = '$message (value: ${pretifyValue(value)})';

    if (path != null && path!.isNotEmpty) {
      return '$path: $messageSuffix';
    }

    return messageSuffix;
  }

  EskError copyWith({
    String? path,
    String? message,
    dynamic value,
  }) {
    return EskError(
      path: path ?? this.path,
      message: message ?? this.message,
      value: value ?? this.value,
    );
  }

  @override
  String toString() {
    return description;
  }
}

EskError error(String message, dynamic value, [String? path]) {
  return EskError(
    path: path,
    message: message,
    value: value,
  );
}
