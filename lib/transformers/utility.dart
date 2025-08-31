/// Utility transformers.
///
/// This file contains general-purpose transformers that don't fit into
/// specific type categories.
library transformers.utility;

import 'package:eskema/eskema.dart';
import 'core.dart' as core;

/// Provides a default value if the input is `null`.
///
/// If the input value is `null`, it is replaced with [defaultValue]. Otherwise,
/// the original value is passed through.
/// Passes the resulting value to the [child] validator.
IValidator defaultTo(dynamic defaultValue, IValidator child, {String? message}) {
  final base = core.transform((v) => v ?? defaultValue, child);
  return core.handleReturnPreserveValue(base, message);
}
