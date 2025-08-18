import 'package:eskema/result.dart';
import 'package:eskema/validators.dart';

/// Returns a [EskValidator] that checks if the given value is a String
EskValidator isString() {
  return isType<String>();
}

EskValidator isNumber() {
  return isType<num>();
}

EskValidator isInteger() {
  return isType<int>();
}

EskValidator isDouble() {
  return isType<double>();
}

EskValidator isBoolean() {
  return isType<bool>();
}

EskValidator isFunction() {
  return isType<Function>();
}

EskValidator isList() {
  return isType<List>();
}

EskValidator isMap() {
  return isType<Map>();
}

EskValidator isSet() {
  return isType<Set>();
}

EskValidator isRecord() {
  return isType<Record>();
}

EskValidator isSymbol() {
  return isType<Symbol>();
}

EskValidator isObject() {
  return isType<Object>();
}

EskValidator isEnum() {
  return isType<Enum>();
}

EskValidator isFuture() {
  return isType<Future>();
}

EskValidator isIterable() {
  return isType<Iterable>();
}

EskValidator isDynamic() {
  return isType<dynamic>();
}

EskValidator isVoid() {
  return isType<void>();
}
