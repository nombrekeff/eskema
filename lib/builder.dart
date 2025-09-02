/// Eskema Builder API
///
/// High-level fluent API for assembling complex validation pipelines and schemas
/// in a readable, strongly-typed, incremental fashion. The builder pattern lets you
/// express shape, normalization, and constraints in a left-to-right chain.
///
/// # Entrypoints
///
/// - `b()` or `builder()` — create a new root builder (see [RootBuilder]).
/// - `$b`, `$builder` — pre-built root builder singletons (stateless, safe to reuse).
/// - Type-specific helpers: `$string()`, `$int()`, `$double()`, `$number()`, `$bool()`, `$map()`, `$list()` — shortcut for `$b.string()`, etc.
///
/// # Usage
///
/// - Choose a type: `.string()`, `.int_()`, `.map()`, `.list()`, etc.
/// - Chain transformers (e.g. `.trim()`, `.toIntStrict()`) and constraints (e.g. `.lengthMin(2)`, `.email()`, `.gt(0)`).
/// - For maps/lists, use `.schema({...})` and `.each(...)` to nest.
/// - Call `.build()` to get a reusable validator.
///
/// ## Example
/// ```dart
/// final userValidator = $map().schema({
///   'id': $string().trim().toIntStrict().gt(0).build(),
///   'email': $string().trim().toLowerCase().email().build(),
///   'age': $string().toIntStrict().gte(18).optional().build(),
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

import 'package:eskema/eskema.dart';

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
RootBuilder $b = b();

/// Pre-built builder instance. See [builder].
///
/// Aliases: [b], [builder] — pre-built: [$b], [$builder]
RootBuilder $builder = $b;

/// Type specific builders
StringBuilder $string({String? message}) => $b.string(message: message);
IntBuilder $int({String? message}) => $b.int_(message: message);
DoubleBuilder $double({String? message}) => $b.double_(message: message);
NumberBuilder $number({String? message}) => $b.number(message: message);
BoolBuilder $bool({String? message}) => $b.bool(message: message);

MapBuilder<K, V> $map<K, V>({String? message}) => $b.map<K, V>(message: message);
IterableBuilder<T> $iterable<T>({String? message}) => $b.iterable<T>(message: message);
ListBuilder<T> $list<T>({String? message}) => $b.list<T>(message: message);
SetBuilder<T> $set<T>({String? message}) => $b.set<T>(message: message);
