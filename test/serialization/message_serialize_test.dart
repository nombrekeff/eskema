import 'package:test/test.dart';
import 'package:eskema/eskema.dart';

void main() {
  test('serialize message', () {
    final val1 = isString(message: "Must be a string");
    
    final eskemaEncoder = EskemaEncoder();
    final jsonEncoder = JsonEncoder();
    
    print("Eskema format: ${eskemaEncoder.encode(val1)}");
    print("JSON format: ${jsonEncoder.encode(val1)}");
  });
}
