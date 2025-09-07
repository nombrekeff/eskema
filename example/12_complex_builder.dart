import 'package:eskema/eskema.dart';

void main() {
  final userEskema = builder().map().schema({
    'id': $string().not.empty().build(),
    'email': $string().email().build(),
    'age': $int().gte(18).optional().build(),
    'nickname': $string().lengthMax(30).optional().build(),
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
