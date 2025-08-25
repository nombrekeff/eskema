/// Type Validators
///
/// This file contains validators for checking the type of values.

library type_validators;
import 'package:eskema/eskema.dart';

/// Returns a [Validator] that checks if the given value is the correct type
IValidator isType<T>() => validator(
      (value) => value is T,
      (value) => Expectation(message: T.toString(), value: value, code: 'type.mismatch', data: {
        'expected': T.toString(),
        'found': value.runtimeType.toString(),
      }),
    );

/// Returns a [Validator] that checks if the given value is the correct type
IValidator isTypeOrNull<T>() => isType<T>() | isNull();

/// Returns a [IValidator] that checks if the given value is `null`
/// For better performance and readability, use the [$isNull] variable directly.
IValidator isNull() => isType<Null>();

/// Returns a [IValidator] that checks if the given value is a `String`
/// For better performance and readability, use the [$isString] variable directly.
IValidator isString() => isType<String>();

/// Returns a [IValidator] that checks if the given value is a `num`
/// For better performance and readability, use the [$isNumber] variable directly.
IValidator isNumber() => isType<num>();

/// Returns a [IValidator] that checks if the given value is a `int`
/// For better performance and readability, use the [$isInt] variable directly.
IValidator isInt() => isType<int>();

/// Returns a [IValidator] that checks if the given value is a `double`
/// For better performance and readability, use the [$isDouble] variable directly.
IValidator isDouble() => isType<double>();

/// Returns a [IValidator] that checks if the given value is a `bool`
/// For better performance and readability, use the [$isBool] variable directly.
IValidator isBool() => isType<bool>();

/// Returns a [IValidator] that checks if the given value is a `Function`
/// For better performance and readability, use the [$isFunction] variable directly.
IValidator isFunction() => isType<Function>();

/// Returns a [IValidator] that checks if the given value is a `List`
/// For better performance and readability, use the [$isList] variable directly.
IValidator isList<T>() => isType<List<T>>();

/// Returns a [IValidator] that checks if the given value is a `Map`
/// For better performance and readability, use the [$isMap] variable directly.
IValidator isMap<K, V>() => isType<Map<K, V>>();

/// Returns a [IValidator] that checks if the given value is a `Set`
/// For better performance and readability, use the [$isSet] variable directly.
IValidator isSet<T>() => isType<Set<T>>();

/// Returns a [IValidator] that checks if the given value is a `Record`
IValidator isRecord() => isType<Record>();

/// Returns a [IValidator] that checks if the given value is a `Symbol`
/// For better performance and readability, use the [$isSymbol] variable directly.
IValidator isSymbol() => isType<Symbol>();

/// Returns a [IValidator] that checks if the given value is a `Enum`
/// For better performance and readability, use the [$isEnum] variable directly.
IValidator isEnum() => isType<Enum>();

/// Returns a [IValidator] that checks if the given value is a `Future`
/// For better performance and readability, use the [$isFuture] variable directly.
IValidator isFuture<T>() => isType<Future<T>>();

/// Returns a [IValidator] that checks if the given value is a `Iterable`
/// For better performance and readability, use the [$isIterable] variable directly.
IValidator isIterable<T>() => isType<Iterable<T>>();

/// Returns a [IValidator] that checks if the given value is a `DateTime`
/// For better performance and readability, use the [$isDateTime] variable directly.
IValidator isDateTime() => isType<DateTime>();
