/// List Validators
///
/// This file contains validators that are list specific

library list_validators;
import 'package:eskema/eskema.dart';
import 'package:eskema/src/util.dart';

/// Validates that it's a List and the length matches the validators
IValidator listLength<T>(List<IValidator> validators) => isList<T>() & length(validators);

/// Validates that it's a list of `size` length
IValidator listIsOfLength(int size) => listLength([isEq(size)]);

/// Validates that the List contains [item]
///
/// This validator also validates that the value is a List first
/// So there's no need to add the [isList] validator when using this validator
IValidator listContains<T>(dynamic item) => isList<T>() &
    (contains(item) > Expectation(message: 'List to contain ${prettifyValue(item)}', code: 'value.contains_missing', data: {'needle': prettifyValue(item)}));

/// Validate that the list is empty
IValidator listEmpty<T>() => listLength<T>([isLte(0)]) >
    Expectation(message: 'List to be empty', code: 'value.length_out_of_range', data: {'expected': 0});
