import 'package:test/test.dart';
import 'package:eskema/eskema.dart';
import 'dart:async';

class WithExpectationValidator extends Validator<Result> {
  WithExpectationValidator(IValidator child, Expectation error, {String? message})
      : super((value) {
          final result = child.validator(value);
          Expectation build(Result r) => _applyOverride(
                error,
                message,
                value,
                code: r.isValid ? null : r.firstExpectation.code,
              );
          if (result is Future<Result>) {
            return result.then((r) => Result(isValid: r.isValid, expectation: build(r), value: value));
          }
          return Result(isValid: result.isValid, expectation: build(result), value: value);
        }, name: 'withExpectation', args: [child, error]);
}

Expectation _applyOverride(Expectation base, String? message, dynamic value, {String? code}) {
  if (message == null) return base.copyWith(value: value, code: code ?? base.code);
  return base.copyWith(message: message, value: value, code: code ?? base.code);
}

void main() {
  test('serialize message', () {
    final val1 = WithExpectationValidator(isString(), Expectation(message: "Must be a string"));
    final eskemaEncoder = EskemaEncoder();
    final jsonEncoder = JsonEncoder();
    
    print("Eskema format: ${eskemaEncoder.encode(val1)}");
    print("JSON format: ${jsonEncoder.encode(val1)}");
  });
}
