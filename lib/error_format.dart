// ignore_for_file: unintended_html_in_doc_comment
/// Utilities for formatting validation / exception messages in a consistent, descriptive way.

library error_format;

import 'package:eskema/result.dart';

/// Build a standardized, human friendly message for a failed [Result].
///
/// Format (subject to small evolutionary changes, kept backwards friendly):
///
/// Validation failed (errors: <count>) for value (<Type>): <truncatedValue>
///  1) <expectation.description> [code=<code>] {data=<dataJson>}
///  2) ...
///  ... (remaining <n> not shown)
///
/// This provides:
/// * Count of errors (quick scanning / logging)
/// * Value type & representative sample (actionable debugging)
/// * Each expectation's description (already path-aware) plus code & optional data
/// * Compact truncation safeguards for very large values
String buildValidationFailureMessage(
  Result result, {
  int maxValueLength = 120,
  int maxErrorsToList = 20,
}) {
  assert(!result.isValid, 'Only call buildValidationFailureMessage on invalid results');

  final value = result.value;
  var valueRepr = _safeValueString(value);
  if (valueRepr.length > maxValueLength) {
    valueRepr = '${valueRepr.substring(0, maxValueLength)}…';
  }

  final buffer = StringBuffer();
  buffer.write('Validation failed (errors: ${result.expectationCount})');
  buffer.write(' for value (${value.runtimeType}): ');
  buffer.writeln(valueRepr);

  final toShow = result.expectations.take(maxErrorsToList).toList(growable: false);
  
  for (var i = 0; i < toShow.length; i++) {
    final e = toShow[i];
    buffer.write('  ${i + 1}) ');
    buffer.write(e.description);

    if (e.code != null) buffer.write(' [code=${e.code}]');
    if (e.data != null && e.data!.isNotEmpty) buffer.write(' {data=${e.data}}');
    buffer.writeln();
  }

  final remaining = result.expectationCount - toShow.length;
  if (remaining > 0) {
    buffer.writeln('  … ($remaining more not shown)');
  }

  return buffer.toString().trimRight();
}

String _safeValueString(dynamic value) {
  try {
    return value.toString();
  } catch (_) {
    return '<unprintable ${value.runtimeType}>';
  }
}

/// Build a standardized message for any validation [Result].
/// For valid results: `Valid (Type): <valueRepr>`
/// For invalid results: delegates to [buildValidationFailureMessage].
String buildValidationMessage(
  Result result, {
  int maxValueLength = 120,
  int maxErrorsToList = 20,
}) {
  if (result.isValid) {
    var valueRepr = _safeValueString(result.value);
    if (valueRepr.length > maxValueLength) {
      valueRepr = '${valueRepr.substring(0, maxValueLength)}…';
    }
    return 'Valid (${result.value.runtimeType}): $valueRepr';
  }
  return buildValidationFailureMessage(result,
      maxValueLength: maxValueLength, maxErrorsToList: maxErrorsToList);
}

/// Extension to access detailed formatting directly on [Result].
extension ResultFormatting on Result {
  String detailed({int maxValueLength = 120, int maxErrorsToList = 20}) =>
      buildValidationMessage(
        this,
        maxValueLength: maxValueLength,
        maxErrorsToList: maxErrorsToList,
      );
}
