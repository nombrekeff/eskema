/// Eskema is a small, composable runtime validation library for Dart. It helps you validate dynamic values (JSON, Maps, Lists, primitives) with readable validators and clear error messages.
/// 
/// **Use cases**:
/// 
/// Here are some common usecases for Eskema:
/// 
/// * Validate untyped API JSON before mapping to models (catch missing/invalid fields early).
/// * Guard inbound request payloads (HTTP handlers, jobs) with clear, fail-fast errors.
/// * Validate runtime config and feature flags from files or remote sources.

library eskema;

export 'validators.dart';
export 'validator.dart';
export 'result.dart';
export 'extensions.dart';
