import 'package:eskema/eskema.dart';

void main() {
  final validator = all([
    isGt(0),
    isLt(100),
    isType<int>(),
  ]);

  final encoded = const EskemaEncoder().encode(validator);
  final decodedValidator = const EskemaDecoder().decode(encoded);

  print(encoded); // (>(0) & <(100) & int)

  print(decodedValidator.validate(50).isValid);   // true
  print(decodedValidator.validate(100).isValid);  // false
  print(decodedValidator.validate(0).isValid);    // false
  print(decodedValidator.validate('50').isValid); // false
}