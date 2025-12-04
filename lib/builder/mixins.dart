/// Builder mixins providing type-specific validation methods.
///
/// This file contains all the mixin classes that provide specialized validation
/// methods for different data types in the fluent builder pattern.
library builder.mixins;

import 'package:eskema/validators/json.dart';

import '../validators.dart';
import '../validator.dart';
import '../transformers.dart' as tr;
import '../validators.dart' as esk;
import 'core.dart';
import 'type_builders.dart';

/// Mixin providing type transformation methods for builders.
mixin TransformerMixin<B extends BaseBuilder<B, T>, T> on BaseBuilder<B, T> {
  /// Transform the value to an integer using standard parsing.
  IntBuilder toInt({String? message}) {
    if (chain.coercedToInt) return IntBuilder(chain: chain);
    chain.setTransform(CoercionKind.int_, (child) => tr.toInt(child));
    return IntBuilder(chain: chain);
  }

  /// Transform the value to an integer using strict parsing (no fallback to 0).
  IntBuilder toIntStrict({String? message}) {
    if (chain.coercedToInt) return IntBuilder(chain: chain);
    chain.setTransform(CoercionKind.int_, (child) => tr.toIntStrict(child));
    return IntBuilder(chain: chain);
  }

  /// Transform the value to an integer using safe parsing (returns null on failure).
  IntBuilder toIntSafe({String? message}) {
    if (chain.coercedToInt) return IntBuilder(chain: chain);
    chain.setTransform(CoercionKind.int_, (child) => tr.toIntSafe(child));
    return IntBuilder(chain: chain);
  }

  /// Transform the value to a double using standard parsing.
  DoubleBuilder toDouble({String? message}) {
    if (chain.coercedToDouble) return DoubleBuilder(chain: chain);
    chain.setTransform(CoercionKind.double_, (child) => tr.toDouble(child));
    return DoubleBuilder(chain: chain);
  }

  /// Transform the value to a boolean using standard parsing.
  BoolBuilder toBool({String? message}) {
    if (chain.coercedToBool) return BoolBuilder(chain: chain);
    chain.setTransform(CoercionKind.bool_, (child) => tr.toBool(child));
    return BoolBuilder(chain: chain);
  }

  /// Transform the value to a boolean using strict parsing.
  BoolBuilder toBoolStrict({String? message}) {
    if (chain.coercedToBool) return BoolBuilder(chain: chain);
    chain.setTransform(CoercionKind.bool_, (child) => tr.toBoolStrict(child));
    return BoolBuilder(chain: chain);
  }

  /// Transform the value to a boolean using lenient parsing.
  BoolBuilder toBoolLenient({String? message}) {
    if (chain.coercedToBool) return BoolBuilder(chain: chain);
    chain.setTransform(CoercionKind.bool_, (child) => tr.toBoolLenient(child));
    return BoolBuilder(chain: chain);
  }

  /// Transform the value to a string.
  StringBuilder toString_({String? message}) {
    // Use the toString() transformer from transformers.dart (imported unprefixed)
    // but qualify via a helper variable to avoid confusion with Object.toString.
    if (chain.coercedToString) return StringBuilder(chain: chain);
    chain.setTransform(CoercionKind.string_, (child) => tr.toString(child));
    return StringBuilder(chain: chain);
  }

  /// Transform the value to a number (int or double).
  NumberBuilder toNum() {
    if (chain.coercedToDouble || chain.coercedToInt) return NumberBuilder(chain: chain);
    chain.setTransform(CoercionKind.double_, (child) => tr.toNum(child));
    return NumberBuilder(chain: chain);
  }

  /// Transform the value to a BigInt.
  NumberBuilder toBigInt() {
    // Represent BigInt coercion using double_ slot to avoid new enum value (keeps simplicity)
    if (chain.coercedToDouble) return NumberBuilder(chain: chain);
    chain.setTransform(CoercionKind.double_, (child) => tr.toBigInt(child));
    return NumberBuilder(chain: chain);
  }

  /// Transform JSON string to decoded object (Map/List).
  JsonDecodedBuilder toJson() {
    if (chain.coercedToJson) return JsonDecodedBuilder(chain: chain);
    chain.setTransform(CoercionKind.json_, (child) => tr.toJsonDecoded(child));
    return JsonDecodedBuilder(chain: chain);
  }

  /// Transform string to DateTime using standard parsing.
  DateTimeBuilder toDateTime() {
    if (chain.coercedToDateTime) return DateTimeBuilder(chain: chain);
    chain.setTransform(CoercionKind.datetime_, (child) => tr.toDateTime(child));
    return DateTimeBuilder(chain: chain);
  }

  /// Apply a custom transformation using the provided pivot.
  GenericBuilder<dynamic> use(CustomPivot pivot) {
    chain.setTransform(CoercionKind.custom, pivot.transformer, dropPre: pivot.dropPre);
    return GenericBuilder<dynamic>(chain: chain);
  }
}

/// Mixin providing length validation methods.
mixin LengthMixin<B extends BaseBuilder<B, T>, T> on BaseBuilder<B, T> {
  /// Validate that the length matches all the provided validators.
  B length(List<IValidator> lengthValidators, {String? message}) {
    return add(esk.length(lengthValidators), message: message);
  }

  /// Validate that the length is at least the specified minimum.
  B lengthMin(int min, {String? message}) => length([isGte(min)], message: message);

  /// Validate that the length is at most the specified maximum.
  B lengthMax(int max, {String? message}) => length([isLte(max)], message: message);

  /// Validate that the length is within the specified range.
  B lengthRange(int min, int max, {String? message}) {
    return length([isInRange(min, max)], message: message);
  }
}

/// Mixin providing empty validation methods.
mixin EmptyMixin<B extends BaseBuilder<B, T>, T> on BaseBuilder<B, T> {
  /// Validate that the value is empty.
  B empty({String? message}) => add(isStringEmpty(), message: message);
}

/// Mixin providing comparison validation methods.
mixin ComparisonMixin<B extends BaseBuilder<B, T>, T> on BaseBuilder<B, T> {}

/// Mixin providing contains validation methods.
mixin ContainsMixin<B extends BaseBuilder<B, T>, T> on BaseBuilder<B, T> {
  /// Validate that the value contains the specified element.
  B contains(value, {String? message}) {
    return add(esk.contains(value), message: message ?? 'A value that contains value: $value');
  }
}

/// Mixin providing boolean-specific validation methods.
mixin BoolMixin<B extends BaseBuilder<B, T>, T> on BaseBuilder<B, T> {
  /// Validate that the boolean value is true.
  B isTrue({String message = 'true'}) => add(isEq(true), message: message);
}

/// Mixin providing number-specific validation methods.
mixin NumberMixin<B extends BaseBuilder<B, T>, T> on BaseBuilder<B, T> {
  /// Validate that the number is less than the specified value.
  B lt(num n, {String? message}) => add(isLt(n), message: message);

  /// Validate that the number is less than or equal to the specified value.
  B lte(num n, {String? message}) => add(isLte(n), message: message);

  /// Validate that the number is greater than the specified value.
  B gt(num n, {String? message}) => add(isGt(n), message: message);

  /// Validate that the number is greater than or equal to the specified value.
  B gte(num n, {String? message}) => add(isGte(n), message: message);

  /// Validate that the number is within the specified range.
  B between(num min, num max, {String? message}) => add(isInRange(min, max), message: message);
}

/// Mixin providing string-specific validation methods.
mixin StringMixin<B extends BaseBuilder<B, T>, T> on BaseBuilder<B, T> {
  /// Validate that the string matches the provided regular expression pattern.
  B matches(RegExp pattern, {String? message}) {
    return add(stringMatchesPattern(pattern), message: message);
  }

  /// Validate that the string is a valid email address.
  B email({String? message}) => add($isEmail, message: message);

  /// Validate that the string contains only lowercase characters.
  B lowerCase({String? message}) => add(isLowerCase(), message: message);

  /// Validate that the string contains only uppercase characters.
  B upperCase({String? message}) => add(isUpperCase(), message: message);

  /// Validate that the string is a valid URL.
  B url({String? message, bool strict = false}) => add(isUrl(strict: strict), message: message);

  /// Validate that the string is a valid URL with strict requirements.
  B strictUrl({String? message}) => url(message: message, strict: true);

  /// Validate that the string can be parsed as an integer.
  B intString({String? message}) => add($isIntString, message: message);

  /// Validate that the string can be parsed as a double.
  B doubleString({String? message}) => add($isDoubleString, message: message);

  /// Validate that the string can be parsed as a number.
  B numString({String? message}) => add($isNumString, message: message);

  /// Validate that the string can be parsed as a boolean.
  B boolString({String? message}) => add($isBoolString, message: message);

  /// Validate that the string is a valid DateTime format.
  B isDate({String? message}) => add($isDate, message: message);

  /// Normalize the string by trimming whitespace from both ends.
  B trim() => wrap((c) => tr.trimString(c));

  /// Normalize the string by collapsing multiple whitespace characters into single spaces.
  B collapseWhitespace() => wrap((c) => tr.collapseWhitespace(c));

  /// Convert the string to lowercase.
  B toLowerCase() => wrap((c) => tr.toLowerCaseString(c));

  /// Convert the string to uppercase.
  B toUpperCase() => wrap((c) => tr.toUpperCaseString(c));
}

/// Mixin providing map-specific validation methods.
mixin MapMixin<B extends BaseBuilder<B, T>, T> on BaseBuilder<B, T> {
  /// Validate the map against a strict schema where all keys must be present and match the validators.
  B strict(Map<String, IValidator> schema) => add(eskemaStrict(schema));

  /// Validate the map against a schema where keys are optional unless specified.
  B schema(Map<String, IValidator> schema) => add(eskema(schema));

  /// Validate that the map contains the specified key.
  B containsKey(key, {String? message}) {
    return add(esk.containsKey(key), message: message ?? 'A value that contains key: $key');
  }

  /// Extract only the specified keys from the map.
  B pick(Iterable<String> keys) => wrap((c) => tr.pickKeys(keys, c));

  /// Extract a single key from the map, keeping the map structure.
  /// @return The builder for chaining
  B pluck(String key) {
    // Keep backward type (MapBuilder) to allow chaining map operations; provide
    // a separate pluckValue() that returns a GenericBuilder for further numeric/string ops.
    chain.wrap((child) => tr.pluckKey(key, child));
    return self;
  }

  /// Extract a single value from the map, returning a GenericBuilder for further operations.
  /// @return A GenericBuilder for the extracted value
  GenericBuilder<dynamic> pluckValue(String key) {
    // Pivot value early so subsequent coercions (e.g., toIntStrict) see the plucked scalar.
    // Also add a containsKey guard in pre-validators for clearer error when missing.
    add(esk.containsKey(key));
    chain.addPrefix((child) => tr.pluckKey(key, child));
    return GenericBuilder<dynamic>(chain: chain);
  }

  /// Flatten nested map keys using the specified delimiter.
  B flattenKeys([String delimiter = '.']) => wrap((c) => tr.flattenMapKeys(delimiter, c));
}

/// Mixin providing DateTime-specific validation methods.
mixin DateTimeMixin<B extends BaseBuilder<B, T>, T> on BaseBuilder<B, T> {
  /// Validate that the DateTime is before the specified date.
  B before(DateTime dt, {bool inclusive = false, String? message}) {
    return add(isDateBefore(dt, inclusive: inclusive), message: message);
  }

  /// Validate that the DateTime is after the specified date.
  B after(DateTime dt, {bool inclusive = false, String? message}) {
    return add(isDateAfter(dt, inclusive: inclusive), message: message);
  }

  /// Validate that the DateTime is within the specified date range.
  /// @return The builder for chaining
  B betweenDates(
    DateTime start,
    DateTime end, {
    bool inclusiveStart = true,
    bool inclusiveEnd = true,
    String? message,
  }) {
    assert(!end.isBefore(start), 'end must be >= start');
    return add(
      isDateBetween(start, end, inclusiveStart: inclusiveStart, inclusiveEnd: inclusiveEnd),
      message: message,
    );
  }

  /// Validate that the DateTime is on the same day as the specified date.
  B sameDay(DateTime dt, {String? message}) => add(isDateSameDay(dt), message: message);

  /// Validate that the DateTime is in the past.
  B inPast({bool allowNow = true, String? message}) {
    return add(isDateInPast(allowNow: allowNow), message: message);
  }

  /// Validate that the DateTime is in the future.
  B inFuture({bool allowNow = true, String? message}) {
    return add(isDateInFuture(allowNow: allowNow), message: message);
  }
}

/// Mixin providing JSON-specific validation methods.
mixin JsonMixin<B extends BaseBuilder<B, T>, T> on BaseBuilder<B, T> {
  /// Validate that the value is a valid JSON container (object or array).
  B jsonContainer({String? message}) => add(isJsonContainer(), message: message);

  /// Validate that the value is a valid JSON object.
  B jsonObject({String? message}) => add(isJsonObject(), message: message);

  /// Validate that the value is a valid JSON array.
  B jsonArray({String? message}) => add(isJsonArray(), message: message);

  /// Validate that the JSON object contains all required keys.
  B jsonRequiresKeys(Iterable<String> keys, {String? message}) {
    return add(jsonHasKeys(keys), message: message);
  }

  /// Validate the length of a JSON array.
  B jsonArrayLen({int? min, int? max, String? message}) {
    return add(
      jsonArrayLength(min: min, max: max),
      message: message,
    );
  }

  /// Validate that each element in a JSON array satisfies the provided validator.
  B jsonArrayEach(IValidator elementValidator, {String? message}) {
    return add(
      jsonArrayEvery(elementValidator),
      message: message,
    );
  }
}

/// Mixin providing iterable-specific validation methods.
mixin IterableMixin<B extends BaseBuilder<B, T>, T> on BaseBuilder<B, T> {
  /// Validate that each element in the iterable satisfies the provided validator.
  B each(IValidator elementValidator) => add(every(elementValidator));
}
