/// Type Validators
///
/// This file contains validators for checking the type of values.

library validators.type;

import 'package:eskema/eskema.dart';

/// Returns a [Validator] that checks if the given value is the correct type
IValidator isType<T>({String? message}) {
  return validator(
    (value) => value is T,
    (value) => Expectation(
      message: message ?? T.toString(),
      value: value,
      code: 'type.mismatch',
      data: {
        'expected': T.toString(),
        'found': value.runtimeType.toString(),
      },
    ),
  );
}

/// Returns a [Validator] that checks if the given value is the correct type
IValidator isTypeOrNull<T>({String? message}) => isType<T>(message: message).nullable();

/// Returns a [IValidator] that checks if the given value is `null`
/// For better performance and readability, use the [$isNull] variable directly.
IValidator isNull({String? message}) => isType<Null>(message: message);

/// Returns a [IValidator] that checks if the given value is a `String`
/// For better performance and readability, use the [$isString] variable directly.
IValidator isString({String? message}) => isType<String>(message: message);

/// Returns a [IValidator] that checks if the given value is a `num`
/// For better performance and readability, use the [$isNumber] variable directly.
IValidator isNumber({String? message}) => isType<num>(message: message);

/// Returns a [IValidator] that checks if the given value is a `int`
/// For better performance and readability, use the [$isInt] variable directly.
IValidator isInt({String? message}) => isType<int>(message: message);

/// Returns a [IValidator] that checks if the given value is a `double`
/// For better performance and readability, use the [$isDouble] variable directly.
IValidator isDouble({String? message}) => isType<double>(message: message);

/// Returns a [IValidator] that checks if the given value is a `bool`
/// For better performance and readability, use the [$isBool] variable directly.
IValidator isBool({String? message}) => isType<bool>(message: message);

/// Returns a [IValidator] that checks if the given value is a `Function`
/// For better performance and readability, use the [$isFunction] variable directly.
IValidator isFunction({String? message}) => isType<Function>(message: message);

/// Returns a [IValidator] that checks if the given value is a `List`
/// For better performance and readability, use the [$isList] variable directly.
IValidator isList<T>({String? message}) => isType<List<T>>(message: message);

/// Returns a [IValidator] that checks if the given value is a `Map`
/// For better performance and readability, use the [$isMap] variable directly.
IValidator isMap<K, V>({String? message}) => isType<Map<K, V>>(message: message);

/// Returns a [IValidator] that checks if the given value is a `Set`
/// For better performance and readability, use the [$isSet] variable directly.
IValidator isSet<T>({String? message}) => isType<Set<T>>(message: message);

/// Returns a [IValidator] that checks if the given value is a `Record`
IValidator isRecord({String? message}) => isType<Record>(message: message);

/// Returns a [IValidator] that checks if the given value is a `Symbol`
/// For better performance and readability, use the [$isSymbol] variable directly.
IValidator isSymbol({String? message}) => isType<Symbol>(message: message);

/// Returns a [IValidator] that checks if the given value is a `Enum`
/// For better performance and readability, use the [$isEnum] variable directly.
IValidator isEnum({String? message}) => isType<Enum>(message: message);

/// Returns a [IValidator] that checks if the given value is a `Future`
/// For better performance and readability, use the [$isFuture] variable directly.
IValidator isFuture<T>({String? message}) => isType<Future<T>>(message: message);

/// Returns a [IValidator] that checks if the given value is a `Iterable`
/// For better performance and readability, use the [$isIterable] variable directly.
IValidator isIterable<T>({String? message}) => isType<Iterable<T>>(message: message);

/// Returns a [IValidator] that checks if the given value is a `DateTime`
/// For better performance and readability, use the [$isDateTime] variable directly.
IValidator isDateTime({String? message}) => isType<DateTime>(message: message);
