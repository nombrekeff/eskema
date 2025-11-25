import 'package:eskema/error_format.dart';
import 'package:eskema/result.dart';

/// Thrown when a synchronous validate() call encounters an async validator chain.
/// Thrown when a synchronous validate() call encounters an async validator chain.
class AsyncValidatorException implements Exception {
  final String? context;
  AsyncValidatorException([this.context]);

  String get message {
    final base =
        'Cannot call validate() on a validator chain that contains async operations. Use validateAsync() instead.';
    return context != null ? '$base (Context: $context)' : base;
  }

  @override
  String toString() => message;
}

/// Thrown when a validation fails and validateOrThrow() is used.
class ValidatorFailedException implements Exception {
  final Result result;
  final DateTime timestamp = DateTime.now();
  ValidatorFailedException(this.result) : assert(result.isNotValid);

  /// Primary human friendly message.
  String get message => buildValidationFailureMessage(result);

  /// Machine friendly summary (single line) for logs.
  String get summary =>
      'ValidatorFailed(errors=${result.expectationCount}, type=${result.value.runtimeType})';

  @override
  String toString() => message;
}
