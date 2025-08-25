import 'package:eskema/eskema.dart';

/// Returns a [Validator] that checks if the given value is the correct type
IValidator isType<T>() => validator(
      (value) => value is T,
      (value) => Expectation(message: T.toString(), value: value),
    );

/// Returns a [Validator] that checks if the given value is the correct type
IValidator isTypeOrNull<T>() => isType<T>() | isNull();

/// Returns a [IValidator] that checks if the given value is `null`
/// For better performance and readability, use the [$isNull] variable directly.
IValidator isNull() => isType<Null>();
final $isNull = isNull();

/// Returns a [IValidator] that checks if the given value is a `String`
/// For better performance and readability, use the [$isString] variable directly.
IValidator isString() => isType<String>();
final $isString = isString();

/// Returns a [IValidator] that checks if the given value is a `num`
/// For better performance and readability, use the [$isNumber] variable directly.
IValidator isNumber() => isType<num>();
final $isNumber = isNumber();

/// Returns a [IValidator] that checks if the given value is a `int`
/// For better performance and readability, use the [$isInt] variable directly.
IValidator isInt() => isType<int>();
final $isInt = isInt();

/// Returns a [IValidator] that checks if the given value is a `double`
/// For better performance and readability, use the [$isDouble] variable directly.
IValidator isDouble() => isType<double>();
final $isDouble = isDouble();

/// Returns a [IValidator] that checks if the given value is a `bool`
/// For better performance and readability, use the [$isBool] variable directly.
IValidator isBool() => isType<bool>();
final $isBool = isBool();

/// Returns a [IValidator] that checks if the given value is a `Function`
/// For better performance and readability, use the [$isFunction] variable directly.
IValidator isFunction() => isType<Function>();
final $isFunction = isFunction();

/// Returns a [IValidator] that checks if the given value is a `List`
/// For better performance and readability, use the [$isList] variable directly.
IValidator isList<T>() => isType<List<T>>();
final $isList = isList();

/// Returns a [IValidator] that checks if the given value is a `Map`
/// For better performance and readability, use the [$isMap] variable directly.
IValidator isMap<K, V>() => isType<Map<K, V>>();
final $isMap = isMap();

/// Returns a [IValidator] that checks if the given value is a `Set`
/// For better performance and readability, use the [$isSet] variable directly.
IValidator isSet<T>() => isType<Set<T>>();
final $isSet = isSet();

/// Returns a [IValidator] that checks if the given value is a `Record`
IValidator isRecord() => isType<Record>();
final $isRecord = isRecord();

/// Returns a [IValidator] that checks if the given value is a `Symbol`
/// For better performance and readability, use the [$isSymbol] variable directly.
IValidator isSymbol() => isType<Symbol>();
final $isSymbol = isSymbol();

/// Returns a [IValidator] that checks if the given value is a `Enum`
/// For better performance and readability, use the [$isEnum] variable directly.
IValidator isEnum() => isType<Enum>();
final $isEnum = isEnum();

/// Returns a [IValidator] that checks if the given value is a `Future`
/// For better performance and readability, use the [$isFuture] variable directly.
IValidator isFuture<T>() => isType<Future<T>>();
final $isFuture = isFuture();

/// Returns a [IValidator] that checks if the given value is a `Iterable`
/// For better performance and readability, use the [$isIterable] variable directly.
IValidator isIterable<T>() => isType<Iterable<T>>();
final $isIterable = isIterable();

/// Returns a [IValidator] that checks if the given value is a `DateTime`
/// For better performance and readability, use the [$isDateTime] variable directly.
IValidator isDateTime() => isType<DateTime>();
final $isDateTime = isDateTime();
