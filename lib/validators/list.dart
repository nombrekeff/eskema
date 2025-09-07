/// List Validators
///
/// This file contains validators that are list specific

library validators.list;

import 'package:eskema/eskema.dart';
import 'package:eskema/src/util.dart';

/// Validates that it's a List and the length matches the validators
IValidator listLength<T>(List<IValidator> validators, {String? message}) {
  return isList<T>() & length(validators, message: message);
}

/// Validates that it's a list of `size` length
IValidator listIsOfLength(int size, {String? message}) {
  return listLength([isEq(size)], message: message);
}

/// Validates that the List contains [item]
///
/// This validator also validates that the value is a List first
/// So there's no need to add the [isList] validator when using this validator
IValidator listContains<T>(dynamic item, {String? message}) =>
    isList<T>() &
    (contains(item, message: message ?? 'List to contain ${prettifyValue(item)}'));

/// Validate that the list is empty
IValidator listEmpty<T>({String? message}) {
  return listLength<T>([isLte(0)], message: message ?? 'List to be empty');
}
