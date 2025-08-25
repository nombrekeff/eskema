import 'package:eskema/validators.dart';
import 'package:eskema/extensions.dart';

void main() {
  final v1 = isString();
  final v2 = stringLength([isGt(0)]);

  // You can combine validators using the + operator
  // This creates a new validator that requires both conditions to be met
  // It's the same as doing:
  // final userVal all([v1, v2]);

  final userVal = v1 & v2;

  print(userVal.validate('')); // false - "length [greater than 0 (value: 0)]"
  print(userVal.validate('a')); // true
}
