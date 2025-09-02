/// Eskema Builder API
///
/// High-level fluent API for assembling complex validation pipelines and schemas
/// in a readable, strongly-typed, incremental fashion. The builder pattern lets you
/// express shape, normalization, and constraints in a left-to-right chain.
///
/// # Usage
///
/// - Entry point: `v()` returns a root builder. Choose a type: `.string()`, `.int_()`, `.map()`, `.list()`, etc.
/// - Chain transformers (e.g. `.trim()`, `.toIntStrict()`) and constraints (e.g. `.lengthMin(2)`, `.email()`, `.gt(0)`).
/// - For maps/lists, use `.schema({...})` and `.each(...)` to nest.
/// - Call `.build()` to get a reusable validator.
///
/// ## Example
/// ```dart
/// final userValidator = v().map().schema({
///   'id': v().string().trim().toIntStrict().gt(0).build(),
///   'email': v().string().trim().toLowerCase().email().build(),
///   'age': v().string().toIntStrict().gte(18).optional().build(),
/// }).build();
///
/// final result = userValidator.validate({
///   'id': '42',
///   'email': 'someone@example.com',
///   'age': '21',
/// });
/// if (result.isValid) {
///   print('Valid user');
/// } else {
///   print(result.detailed());
/// }
/// ```
///
/// # Features
/// - Type-specific builder classes: `StringBuilder`, `IntBuilder`, `MapBuilder`, etc.
/// - Transformers: `.trim()`, `.toIntStrict()`, `.toLowerCase()`, `.toDateTime()`, etc.
/// - Constraints: `.lengthMin()`, `.email()`, `.gt()`, `.oneOf([...])`, etc.
/// - Structure: `.map().schema({...})`, `.list().each(...)`, `.optional()`, `.nullable()`
/// - Custom: add your own via `.add(...)` or `.wrap(...)` or extension methods.
/// - Message override: `.error('msg')` or `> 'msg'` after build.
/// - Operator sugar: `&`, `|`, `>` for AND, OR, message override.
///
/// # Extensibility
/// - Add custom transformers or constraints via extension methods on builder classes.
/// - Compose with functional validators and combinators.
///
/// # Performance
/// - Validators are built once and reused.
/// - Zero-arg cached validators available as `$isString`, `$isEmail`, etc.
///
/// See exported files for low-level implementation details.
library builder;

import 'package:eskema/builder/type_builders.dart' show RootBuilder;

export 'builder/core.dart';
export 'builder/mixins.dart';
export 'builder/type_builders.dart';

/// Create a new builder instance. See [builder].
///
/// Aliases: [b], [builder] — pre-built: [$b], [$builder]
RootBuilder b() => RootBuilder();

/// Create a new builder instance. See [builder].
///
/// Aliases: [b], [builder] — pre-built: [$b], [$builder]
RootBuilder builder() => b();

/// Pre-built builder instance. See [builder].
///
/// Aliases: [b], [builder] — pre-built: [$b], [$builder]
RootBuilder $b = RootBuilder();

/// Pre-built builder instance. See [builder].
///
/// Aliases: [b], [builder] — pre-built: [$b], [$builder]
RootBuilder $builder = $b;
