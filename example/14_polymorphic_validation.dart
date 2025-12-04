import 'package:eskema/eskema.dart';

void main() {
  final schema = switchBy('type', {
    'business': eskema({
      'taxId': required(isString()) & stringLength([isGte(5)]),
    }),
    'person': eskema({
      'name': required(isString() & stringLength([isGte(5)])),
    }),
  });

  final result = schema.validate({'type': 'business', 'taxId': '123456789'});
  print(result);
}
