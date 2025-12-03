import 'package:eskema/eskema.dart';

void main() {
  IValidator dispatching(Map<String, IValidator> by, String key) {
    return $isMap &
        containsKeys([key], message: 'Missing key: "$key"') &
        Validator((value) {
          final type = value[key];
          final v = by[type];
          final r = v?.validate(value);

          if (r == null) {
            return Result.invalid(
              value,
              expectation: const Expectation(message: 'unknown type'),
            );
          }

          return r.isValid ? Result.valid(value) : r;
        });
  }

  final schema = dispatching({
    'business': eskema({
      'taxId': required(isString()) & stringLength([isGte(5)]),
    }),
    'person': eskema({
      'name': required(isString() & stringLength([isGte(5)])),
    }),
  }, 'type');

  final result = schema.validate({'type': 'business', 'taxId': '123456789'});
  print(result);
}
