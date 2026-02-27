import 'package:eskema/eskema.dart';

void main() {
  final val1 = isString(message: 'Must be a string');
  
  final eskemaEncoder = EskemaEncoder();
  final jsonEncoder = JsonEncoder();
  
  try {
    print('Eskema format: ${eskemaEncoder.encode(val1)}');
  } catch (e) {
    print('EskemaEncoder Error: $e');
  }
  
  try {
    print('JSON format: ${jsonEncoder.encode(val1)}');
  } catch (e) {
    print('JsonEncoder Error: $e');
  }
}
