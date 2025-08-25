import 'package:eskema/eskema.dart';
import 'package:eskema/util.dart';

/// Validates that it's a List and the length matches the validators
IValidator listLength<T>(List<IValidator> validators) => isList<T>() & length(validators);

/// Validates that it's a list of `size` length
IValidator listIsOfLength(int size) => listLength([isEq(size)]);

/// Validates that the List contains [item]
///
/// This validator also validates that the value is a List first
/// So there's no need to add the [isList] validator when using this validator
IValidator listContains<T>(dynamic item) =>
    isList<T>() & (contains(item) > "List to contain ${pretifyValue(item)}");

/// Validate that the list is empty
IValidator listEmpty<T>() => listLength<T>([isLte(0)]) > "List to be empty";
final $listEmpty = listEmpty();
