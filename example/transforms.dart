import 'package:eskema/eskema.dart';

void main() {
  final age = toInt(isGte(0) & isLte(130));

  print(age.validate(' 42 ').isValid); // true
  print(age.validate('32').isValid);   // true
  print(age.validate(32).isValid);     // true

  print(age.validate('abc'));          // false (transform failed)
}
