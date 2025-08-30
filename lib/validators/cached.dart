/// Cached Validators
///
/// This file contains cached instances of zero-argument validators for performance
/// and readability. Instead of calling `isString()` repeatedly, you can use the
/// constant `$isString`.
///
/// These cached validators are pre-instantiated for better performance and provide
/// the same functionality as their function counterparts.

library validators.cached;

import 'package:eskema/validator.dart';
import 'package:eskema/validators/combinator.dart';
import 'package:eskema/validators/list.dart';
import 'package:eskema/validators/string.dart';
import 'package:eskema/validators/type.dart';

// Type validators

/// Cached instance of [isNull].
/// Validates that the value is null.
final IValidator $isNull = isNull();

/// Cached instance of [isString].
/// Validates that the value is a String.
final IValidator $isString = isString();

/// Cached instance of [isNumber].
/// Validates that the value is a num (int or double).
final IValidator $isNumber = isNumber();

/// Cached instance of [isInt].
/// Validates that the value is an int.
final IValidator $isInt = isInt();

/// Cached instance of [isDouble].
/// Validates that the value is a double.
final IValidator $isDouble = isDouble();

/// Cached instance of [isBool].
/// Validates that the value is a bool.
final IValidator $isBool = isBool();

/// Cached instance of [isFunction].
/// Validates that the value is a Function.
final IValidator $isFunction = isFunction();

/// Cached instance of [isList].
/// Validates that the value is a List.
final IValidator $isList = isList();

/// Cached instance of [isMap].
/// Validates that the value is a Map.
final IValidator $isMap = isMap();

/// Cached instance of [isSet].
/// Validates that the value is a Set.
final IValidator $isSet = isSet();

/// Cached instance of [isRecord].
/// Validates that the value is a Record.
final IValidator $isRecord = isRecord();

/// Cached instance of [isSymbol].
/// Validates that the value is a Symbol.
final IValidator $isSymbol = isSymbol();

/// Cached instance of [isEnum].
/// Validates that the value is an enum value.
final IValidator $isEnum = isEnum();

/// Cached instance of [isFuture].
/// Validates that the value is a Future.
final IValidator $isFuture = isFuture();

/// Cached instance of [isIterable].
/// Validates that the value is an Iterable.
final IValidator $isIterable = isIterable();

/// Cached instance of [isDateTime].
/// Validates that the value is a DateTime.
final IValidator $isDateTime = isDateTime();

// String validators

/// Cached instance of [isLowerCase].
/// Validates that the string contains only lowercase characters.
final IValidator $isLowerCase = isLowerCase();

/// Cached instance of [isUpperCase].
/// Validates that the string contains only uppercase characters.
final IValidator $isUpperCase = isUpperCase();

/// Cached instance of [isEmail].
/// Validates that the string is a valid email address.
final IValidator $isEmail = isEmail();

/// Cached instance of [isUrl].
/// Validates that the string is a valid URL.
final IValidator $isUrl = isUrl();

/// Cached instance of [isStrictUrl].
/// Validates that the string is a valid URL with strict requirements.
final IValidator $isStrictUrl = isStrictUrl();

/// Cached instance of [isUuidV4].
/// Validates that the string is a valid UUID v4.
final IValidator $isUuidV4 = isUuidV4();

/// Cached instance of [isIntString].
/// Validates that the string can be parsed as an integer.
final IValidator $isIntString = isIntString();

/// Cached instance of [isDoubleString].
/// Validates that the string can be parsed as a double.
final IValidator $isDoubleString = isDoubleString();

/// Cached instance of [isNumString].
/// Validates that the string can be parsed as a number.
final IValidator $isNumString = isNumString();

/// Cached instance of [isBoolString].
/// Validates that the string can be parsed as a boolean.
final IValidator $isBoolString = isBoolString();

/// Cached instance of [isDate].
/// Validates that the string is a valid DateTime format.
final IValidator $isDate = isDate();

/// Cached instance of [listEmpty].
/// Validates that the list is empty.
final IValidator $listEmpty = listEmpty();

/// Cached instance of [not] applied to [$listEmpty].
/// Validates that the list is not empty.
final IValidator $listNotEmpty = not($listEmpty);

/// Cached instance of [isStringEmpty].
/// Validates that the value is empty (string, list, map, etc.).
final IValidator $isStringEmpty = isStringEmpty();
