import 'package:eskema/expectation.dart';
import 'package:eskema/result.dart';
import 'package:eskema/validator.dart';
import 'package:eskema/validators.dart';

void main() {
  final isHelloWorld = all([
    $isString,
    Validator((value) => Result(
          isValid: value == 'Hello world',
          expectations: [Expectation(message: 'Expected Hello world', value: value)],
          value: value,
        )),
  ]);

  print(isHelloWorld.isValid('Hello world')); // true
  print(isHelloWorld.validate('hey')); // false - 'Expected Hello world (value: "hey")'

  IValidator isInRange(num min, num max) {
    return all([
      isType<num>(),
      Validator(
        (value) => Result(
          isValid: value >= min && value <= max,
          expectations: [Expectation(message: 'number to be between $min and $max', value: value)],
          value: value,
        ),
      ),
    ]);
  }

  print(isInRange(0, 5).isValid(2)); // true
  print(isInRange(0, 5)
      .validate(6)
      .description); // false - 'number to be between 0 and 5 (value: 6)'
}
