import 'package:eskema/eskema.dart';

void main() {
  final validator = all([
    stringLength([isGt(0), isLt(100)], message: 'String length must be between 0 and 100'),
  ]);

  final encoded = const EskemaEncoder().encode(validator);
  final decodedValidator = const EskemaDecoder().decode(encoded);

  print(encoded); // (slen(>0, <100, "String length must be between 0 and 100"))

  print(decodedValidator.validate('50').isValid); // true
  print(decodedValidator.validate('').isValid); // false
}
