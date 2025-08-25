/// Cached Validators
///
/// This file contains cached instances of zero-argument validators for performance
/// and readability. Instead of calling `isString()` repeatedly, you can use the
/// constant `$isString`.

library cached_validators;

import 'package:eskema/validator.dart';
import 'package:eskema/validators/combinator.dart';
import 'package:eskema/validators/list.dart';
import 'package:eskema/validators/string.dart';
import 'package:eskema/validators/type.dart';

// Type validators
final IValidator $isNull = isNull();
final IValidator $isString = isString();
final IValidator $isNumber = isNumber();
final IValidator $isInt = isInt();
final IValidator $isDouble = isDouble();
final IValidator $isBool = isBool();
final IValidator $isFunction = isFunction();
final IValidator $isList = isList();
final IValidator $isMap = isMap();
final IValidator $isSet = isSet();
final IValidator $isRecord = isRecord();
final IValidator $isSymbol = isSymbol();
final IValidator $isEnum = isEnum();
final IValidator $isFuture = isFuture();
final IValidator $isIterable = isIterable();
final IValidator $isDateTime = isDateTime();

// String validators
final IValidator $stringEmpty = stringEmpty();
final IValidator $stringNotEmpty = not($stringEmpty);
final IValidator $isLowerCase = isLowerCase();
final IValidator $isUpperCase = isUpperCase();
final IValidator $isEmail = isEmail();
final IValidator $isUrl = isUrl();
final IValidator $isStrictUrl = isStrictUrl();
final IValidator $isUuidV4 = isUuidV4();
final IValidator $isIntString = isIntString();
final IValidator $isDoubleString = isDoubleString();
final IValidator $isNumString = isNumString();
final IValidator $isDate = isDate();

// List validators
final IValidator $listEmpty = listEmpty();
final IValidator $listNotEmpty = not($listEmpty);
