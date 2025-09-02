/// Type-specific builder classes for the fluent validation API.
///
/// This file contains all the concrete builder classes that provide
/// type-specific validation methods for different data types.
library builder.type_builders;

import '../validators.dart';
import 'core.dart';
import 'mixins.dart';

/// Builder for string validations with string-specific methods.
///
/// **Usage Examples:**
/// ```dart
/// // Basic string validation
/// final nameValidator = v().string().lengthMin(2).lengthMax(50).build();
///
/// // Email validation with custom message
/// final emailValidator = v().string().email().error("Invalid email format").build();
///
/// // Complex string validation
/// final passwordValidator = v().string()
///   .lengthMin(8)
///   .matches(r'[A-Z]', message: "Must contain uppercase letter")
///   .matches(r'[a-z]', message: "Must contain lowercase letter")
///   .matches(r'[0-9]', message: "Must contain number")
///   .build();
/// ```
class StringBuilder extends BaseBuilder<StringBuilder, String>
    with
        LengthMixin<StringBuilder, String>,
        EmptyMixin<StringBuilder, String>,
        ComparisonMixin<StringBuilder, String>,
        TransformerMixin<StringBuilder, String>,
        StringMixin<StringBuilder, String>,
        ContainsMixin<StringBuilder, String> {
  StringBuilder({super.negated, super.chain});
}

/// Builder for number validations with numeric comparison methods.
///
/// **Usage Examples:**
/// ```dart
/// // Age validation
/// final ageValidator = v().number().gte(0).lte(150).build();
///
/// // Price validation with coercion
/// final priceValidator = v().string().toDouble().gt(0).lte(10000).build();
///
/// // Percentage validation
/// final percentageValidator = v().number().gte(0).lte(100).build();
/// ```
class NumberBuilder extends BaseBuilder<NumberBuilder, num>
    with
        TransformerMixin<NumberBuilder, num>,
        NumberMixin<NumberBuilder, num>,
        ComparisonMixin<NumberBuilder, num> {
  NumberBuilder({super.chain});
}

/// Builder for integer validations, inherits from NumberBuilder.
///
/// **Usage Examples:**
/// ```dart
/// // Age validation
/// final ageValidator = v().int_().gte(0).lte(150).build();
///
/// // ID validation with strict parsing
/// final idValidator = v().string().toIntStrict().gt(0).build();
///
/// // Count validation
/// final countValidator = v().int_().gte(1).lte(100).build();
/// ```
class IntBuilder extends NumberBuilder {
  IntBuilder({super.chain});
}

/// Builder for double validations, inherits from NumberBuilder.
///
/// **Usage Examples:**
/// ```dart
/// // Price validation
/// final priceValidator = v().double_().gt(0).lte(10000).build();
///
/// // Rating validation
/// final ratingValidator = v().double_().gte(0).lte(5).build();
///
/// // Percentage with decimal places
/// final percentageValidator = v().double_().gte(0).lte(100).build();
/// ```
class DoubleBuilder extends NumberBuilder {
  DoubleBuilder({super.chain});
}

/// Builder for boolean validations with boolean-specific methods.
///
/// **Usage Examples:**
/// ```dart
/// // Simple boolean validation
/// final flagValidator = v().bool_().build();
///
/// // Must be true
/// final consentValidator = v().bool_().isTrue().build();
///
/// // String to boolean coercion
/// final stringBoolValidator = v().string().toBool().isTrue().build();
/// ```
class BoolBuilder extends BaseBuilder<BoolBuilder, bool>
    with TransformerMixin<BoolBuilder, bool>, BoolMixin<BoolBuilder, bool> {
  BoolBuilder({super.chain});
}

/// Builder for DateTime validations with date/time-specific methods.
///
/// **Usage Examples:**
/// ```dart
/// // Future date validation
/// final futureDateValidator = v().dateTime().inFuture().build();
///
/// // Past date validation
/// final pastDateValidator = v().dateTime().inPast().build();
///
/// // Date range validation
/// final eventDateValidator = v().dateTime()
///   .after(DateTime.now())
///   .before(DateTime.now().add(Duration(days: 365)))
///   .build();
///
/// // String to DateTime parsing
/// final stringDateValidator = v().string().toDateTime().inFuture().build();
/// ```
class DateTimeBuilder extends BaseBuilder<DateTimeBuilder, DateTime>
    with
        TransformerMixin<DateTimeBuilder, DateTime>,
        DateTimeMixin<DateTimeBuilder, DateTime>,
        ComparisonMixin<DateTimeBuilder, DateTime> {
  DateTimeBuilder({super.chain});
}

/// Builder for iterable validations with length and iteration methods.
///
/// **Usage Examples:**
/// ```dart
/// // Basic iterable validation
/// final iterableValidator = v().iterable().lengthMin(1).build();
///
/// // Each element validation
/// final stringListValidator = v().iterable()
///   .each(v().string().lengthMin(1).build())
///   .build();
///
/// // Number list validation
/// final numberListValidator = v().iterable()
///   .each(v().number().gt(0).build())
///   .lengthMax(10)
///   .build();
/// ```
class IterableBuilder extends BaseBuilder<IterableBuilder, Iterable>
    with
        LengthMixin<IterableBuilder, Iterable>,
        EmptyMixin<IterableBuilder, Iterable>,
        ComparisonMixin<IterableBuilder, Iterable>,
        IterableMixin<IterableBuilder, Iterable>,
        ContainsMixin<IterableBuilder, Iterable> {
  IterableBuilder({super.chain});
}

/// Builder for list validations, inherits from IterableBuilder.
///
/// **Usage Examples:**
/// ```dart
/// // Basic list validation
/// final listValidator = v().list().lengthMin(1).build();
///
/// // String list with constraints
/// final tagsValidator = v().list()
///   .each(v().string().lengthMin(1).lengthMax(50).build())
///   .lengthMax(10)
///   .build();
///
/// // Number list validation
/// final scoresValidator = v().list()
///   .each(v().number().gte(0).lte(100).build())
///   .lengthMin(1)
///   .build();
/// ```
class ListBuilder extends IterableBuilder {
  ListBuilder({super.chain});
}

/// Builder for set validations, inherits from IterableBuilder.
///
/// **Usage Examples:**
/// ```dart
/// // Basic set validation
/// final setValidator = v().set().lengthMin(1).build();
///
/// // Unique string set
/// final uniqueTagsValidator = v().set()
///   .each(v().string().lengthMin(1).build())
///   .lengthMax(20)
///   .build();
///
/// // Number set with range
/// final numbersValidator = v().set()
///   .each(v().number().gte(1).lte(100).build())
///   .build();
/// ```
class SetBuilder extends IterableBuilder {
  SetBuilder({super.chain});
}

/// Builder for map validations with map-specific methods.
///
/// **Usage Examples:**
/// ```dart
/// // Simple schema validation
/// final userValidator = v().map().schema({
///   'name': v().string().lengthMin(1).build(),
///   'age': v().int_().gte(0).build(),
/// }).build();
///
/// // Strict validation (no extra fields allowed)
/// final strictUserValidator = v().map().strict({
///   'id': v().string().lengthMin(1).build(),
///   'email': v().string().email().build(),
/// }).build();
///
/// // Nested object validation
/// final addressValidator = v().map().schema({
///   'street': v().string().lengthMin(5).build(),
///   'city': v().string().lengthMin(2).build(),
///   'zipCode': v().string().matches(r'^\d{5}$').build(),
/// }).build();
/// ```
class MapBuilder extends BaseBuilder<MapBuilder, Map>
    with
        TransformerMixin<MapBuilder, Map>,
        MapMixin<MapBuilder, Map>,
        EmptyMixin<MapBuilder, Map>,
        ComparisonMixin<MapBuilder, Map> {
  MapBuilder({super.chain});
}

/// Builder for JSON-decoded data with both map and iterable methods.
///
/// **Usage Examples:**
/// ```dart
/// // JSON string to object validation
/// final jsonValidator = v().string().toJson().jsonObject().build();
///
/// // JSON array validation
/// final jsonArrayValidator = v().string().toJson()
///   .jsonArray()
///   .jsonArrayEach(v().string().build())
///   .build();
///
/// // Complex JSON structure
/// final apiResponseValidator = v().string().toJson().schema({
///   'success': v().bool_().build(),
///   'data': v().map().jsonObject().build(),
///   'errors': v().list().jsonArray().optional().build(),
/// }).build();
/// ```
class JsonDecodedBuilder extends BaseBuilder<JsonDecodedBuilder, dynamic>
    with
        TransformerMixin<JsonDecodedBuilder, dynamic>,
        JsonMixin<JsonDecodedBuilder, dynamic>,
        ComparisonMixin<JsonDecodedBuilder, dynamic>,
        MapMixin<JsonDecodedBuilder, dynamic>,
        IterableMixin<JsonDecodedBuilder, dynamic> {
  JsonDecodedBuilder({super.chain});
}

/// Generic builder that supports all validation methods.
///
/// Use this builder when you need to apply validations that don't fit into
/// the specialized builders, or when working with dynamic types.
///
/// **Usage Examples:**
/// ```dart
/// // Dynamic type validation
/// final dynamicValidator = v().type<dynamic>()
///   .lengthMin(1)
///   .matches(r'some_pattern')
///   .build();
///
/// // Custom type validation
/// final customValidator = v().type<MyClass>()
///   .add(myCustomValidator)
///   .build();
///
/// // Advanced chaining with type coercion
/// final complexValidator = v().type()
///   .toString_()
///   .lengthMin(5)
///   .email()
///   .build();
/// ```
class GenericBuilder<T> extends BaseBuilder<GenericBuilder<T>, T>
    with
        NumberMixin<GenericBuilder<T>, T>,
        LengthMixin<GenericBuilder<T>, T>,
        EmptyMixin<GenericBuilder<T>, T>,
        ComparisonMixin<GenericBuilder<T>, T>,
        TransformerMixin<GenericBuilder<T>, T>,
        StringMixin<GenericBuilder<T>, T>,
        MapMixin<GenericBuilder<T>, T>,
        DateTimeMixin<GenericBuilder<T>, T>,
        JsonMixin<GenericBuilder<T>, T> {
  GenericBuilder({super.chain});
}

/// Root builder that provides entry points for different data types.
///
/// **Usage Examples:**
/// ```dart
/// // String validation
/// final nameValidator = v().string().lengthMin(2).lengthMax(100).build();
///
/// // Number validation with coercion
/// final ageValidator = v().string().toInt().gte(0).lte(150).build();
///
/// // Complex object validation
/// final userValidator = v().map().schema({
///   'name': v().string().lengthMin(1).build(),
///   'email': v().string().email().build(),
///   'age': v().int_().gte(18).build(),
/// }).build();
///
/// // List validation
/// final tagsValidator = v().list().each(v().string().lengthMin(1).build()).build();
/// ```
class RootBuilder {
  /// Expect a String; returns a StringBuilder with string‑specific methods.
  StringBuilder string({String? message}) {
    return StringBuilder()..add($isString, message: message);
  }

  /// Expect an int; returns an IntBuilder with integer-specific methods.
  IntBuilder int_({String? message}) {
    return IntBuilder()..add($isInt, message: message);
  }

  /// Expect a double; returns a DoubleBuilder with double-specific methods.
  DoubleBuilder double_({String? message}) {
    return DoubleBuilder()..add($isDouble, message: message);
  }

  /// Expect a number (int or double); returns a NumberBuilder with numeric methods.
  NumberBuilder number({String? message}) {
    return NumberBuilder()..add($isNumber, message: message);
  }

  /// Expect a bool; returns a BoolBuilder with boolean-specific methods.
  BoolBuilder bool({String? message}) {
    return BoolBuilder()..add($isBool, message: message);
  }

  /// Expect an Iterable; returns an IterableBuilder with collection methods.
  IterableBuilder iterable({String? message}) {
    return IterableBuilder()..add($isIterable, message: message);
  }

  /// Expect a List; returns a ListBuilder with list-specific methods.
  ListBuilder list({String? message}) {
    return ListBuilder()..add($isList, message: message);
  }

  /// Expect a Map; returns a MapBuilder with map-specific methods.
  MapBuilder map({String? message}) {
    return MapBuilder()..add($isMap, message: message);
  }

  /// Expect a DateTime; returns a DateTimeBuilder with date/time methods.
  DateTimeBuilder dateTime({String? message}) {
    return DateTimeBuilder()..add(isType<DateTime>(), message: message);
  }

  /// Generic type guard (rarely needed; concrete helpers preferred).
  GenericBuilder type<T>({String? message}) {
    return GenericBuilder<T>()..add(isType<T>(), message: message);
  }
}
