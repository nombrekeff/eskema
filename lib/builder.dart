/// Builder library
///
/// High-level fluent API for assembling complex validation pipelines / schemas
/// in a readable, strongly-typed, incremental fashion. The builder pattern
/// helps you express intent (shape + constraints + transformations) without
/// manually wiring individual `Validator` instances or combinators.
///
/// # Goals
/// * Reduce boilerplate when composing many field validators.
/// * Provide progressive discovery via chained methods & IDE completion.
/// * Allow late binding of optional / conditional structure.
/// * Support both sync & async validators seamlessly.
/// * Make customization (messages, expectations, transformations) explicit.
///
/// # Core Concepts
/// * A concrete `SchemaBuilder` (see `core.dart`) accumulates field specs.
/// * Field specs wrap a validator chain plus metadata (name, optionality, etc.).
/// * Terminal build step produces an executable validator (or set of them)
///   that returns a structured `Result`.
/// * Mixins (in `mixins.dart`) add focused capability surfaces (numbers, lists, …).
/// * Type builders (in `type_builders.dart`) expose ergonomic helpers for common
///   primitive & composite types.
///
/// # Quick Start
/// ```dart
/// import 'package:eskema/eskema.dart';
///
/// final userSchema = schema((s) => s
///   .string('id').nonEmpty().withMessage('user id required')
///   .string('email').email()
///   .int('age').gte(18).withMessage('must be 18+')
///   .optional.string('nickname').maxLength(30)
///   .build()
/// );
///
/// final result = userSchema.validate({
///   'id': 'u_123',
///   'email': 'someone@example.com',
///   'age': 42,
/// });
///
/// if (result.isValid) {
///   print('Valid user');
/// } else {
///   print(result.detailed()); // Rich formatted failure output
/// }
/// ```
///
/// # Conditional Fields
/// Builders support conditionals by deferring evaluation:
/// ```dart
/// schema((s) => s
///   .string('type').oneOf(['A','B'])
///   .whenField('type', (value, branch) {
///      if (value == 'A') {
///        branch.int('aCount').gte(0);
///      } else {
///        branch.string('bCode').nonEmpty();
///      }
///   })
///   .build());
/// ```
///
/// # Custom Validation
/// Use `.custom(...)` or `.withValidator(...)` to plug bespoke logic, and
/// `.transform(...)` to normalize before further checks.
///
/// # Messages & Expectations
/// Each chain step can override the default message. The final aggregated
/// failure context merges individual `Expectation` objects for detailed
/// debugging & user feedback.
///
/// # Async
/// Async validators (e.g. uniqueness checks) can be inserted; the built schema
/// auto-upgrades to async mode when any async component exists.
///
/// # Performance Notes
/// * Builders aim to allocate minimally; chains flatten where possible.
/// * Cached common validators are reused (`cached.dart`).
/// * Only failed branches accumulate expectation lists.
///
/// # Extensibility Tips
/// * Create extension methods returning `IValidator` and expose them through
///   mixins to integrate seamlessly with the fluent surface.
/// * Prefer small, composable helpers over monolithic custom validators.
///
/// See individual exported files for the low-level implementations.
library builder;

export 'builder/core.dart';
export 'builder/mixins.dart';
export 'builder/type_builders.dart';
