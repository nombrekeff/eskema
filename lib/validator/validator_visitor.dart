/// Validator visitor contract for tree traversal and operations.
library validator.visitor;

import 'base_validator.dart';
import 'combinator_validators.dart';
import 'map_validators.dart';

/// Visitor interface for inspecting, traversing, or transforming [IValidator] trees.
abstract class IValidatorVisitor<R, C> {
  /// Visits a generic [IValidator].
  R visitValidator(IValidator validator, C context);

  /// Visits a [MultiValidatorBase] combinator.
  R visitMultiValidator(MultiValidatorBase validator, C context) =>
      visitValidator(validator, context);

  /// Visits a [MapValidator] schema.
  R visitMapValidator(MapValidator validator, C context) =>
      visitValidator(validator, context);

  /// Visits a [Field] validator.
  R visitField(Field validator, C context) =>
      visitValidator(validator, context);
}
