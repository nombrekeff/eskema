import 'package:eskema/error_format.dart';
import 'package:eskema/result.dart';

/// Thrown when a synchronous validate() call encounters an async validator chain.
class AsyncValidatorException implements Exception {
  /// The [message] property.
  final String message =
      'Cannot call validate() on a validator chain that contains async operations. Use validateAsync() instead.';
  @override
  String toString() => message;
}

/// Thrown when a validation fails and validateOrThrow() is used.
class ValidatorFailedException implements Exception {
  /// The [result] property.
  final Result result;

  /// Executes the [timestamp] operation.
  final DateTime timestamp = DateTime.now();

  /// Executes the [ValidatorFailedException] operation.
  ValidatorFailedException(this.result) : assert(result.isNotValid);

  /// Primary human friendly message.
  String get message => buildValidationFailureMessage(result);

  /// Machine friendly summary (single line) for logs.
  String get summary =>
      'ValidatorFailed(errors=${result.expectationCount}, type=${result.value.runtimeType})';

  @override
  String toString() => message;
}
