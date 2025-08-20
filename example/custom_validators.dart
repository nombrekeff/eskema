import 'package:eskema/result.dart';
import 'package:eskema/validator.dart';
import 'package:eskema/validators.dart';

void main() {
  final isHelloWorld = all([
    $isString,
    EskValidator((value) => EskResult(
          isValid: value == 'Hello world',
          expected: 'Hello world',
          value: value,
        )),
  ]);

  print(isHelloWorld.isValid('Hello world'));  // true
  print(isHelloWorld.validate('hey'));         // false - 'Expected Hello world, got "hey"'

  IEskValidator isInRange(num min, num max) {
    return all([
      isType<num>(),
      EskValidator((value) => EskResult(
            isValid: value >= min && value <= max,
            expected: 'number to be between $min and $max',
            value: value,
          )),
    ]);
  }

  print(isInRange(0, 5).isValid(2)); // true
  print(isInRange(0, 5)
      .validate(6).describeResult()); // false - 'Expected number to be between 0 and 5, got 6'
}
