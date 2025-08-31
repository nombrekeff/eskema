import 'package:eskema/eskema.dart';

void main() {
  final userEskema = v().map().schema({
    'id': v().string().not.empty().build(),
    'email': v().string().email().build(),
    'age': v().int_().gte(18).optional().build(),
    'nickname': v().string().lengthMax(30).optional().build(),
  }).build();

  final input = {
    'id': 'u_123',
    'email': 'someone@example.com',
    'age': 42,
  };

  final result = userEskema.validate(input);
  if (result.isValid) {
    print('OK');
  } else {
    print(result.detailed());
  }
}
