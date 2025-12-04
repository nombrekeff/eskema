import 'package:eskema/config/expectations/eskema_expectations.dart';

typedef ExpectationsBuilder = EskemaExpectations Function();

/// Configuration hub for Eskema.
class EskemaConfig {
  // Default to the standard English implementation
  // ignore: prefer_function_declarations_over_variables
  static final ExpectationsBuilder _defaultBuilder = () => const EskemaExpectations();

  static ExpectationsBuilder _builder = _defaultBuilder;

  /// Accessor: This is called by validators.
  /// It executes the builder function to get the *current* correct instance.
  static EskemaExpectations get expectations => _builder();

  static RegExp emailRegex = RegExp(
    r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
  );
  static RegExp uuidRegex = RegExp(
    r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-4[0-9a-fA-F]{3}-[89abAB][0-9a-fA-F]{3}-[0-9a-fA-F]{12}$',
  );

  /// Simple Setup: Set a specific implementation of expectations to be used globally.
  /// Use this if you don't need to change languages at runtime.
  static void setExpectations(EskemaExpectations expectations) {
    _builder = () => expectations;
  }

  /// Advanced Setup: Set a dynamic resolver.
  /// Use this to hook into your app's state management or localization system
  /// to return different expectations based on the current context.
  static void setExpectationsBuilder(ExpectationsBuilder builder) {
    _builder = builder;
  }

  /// Internal helper to resolve a specific message override (if any).
  static String? resolveCode(String code, Map<String, dynamic> data) {
    // This is a hook if you want to support the "Option 1" static resolver
    // alongside the class-based approach, but usually not needed if using classes.
    return null;
  }
}
