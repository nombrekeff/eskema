import 'package:eskema/eskema.dart';

Validator<Result> isValidName = Validator((value) async {
  return Result.valid(await Future.value(false));
});

void simpleExample() async {
  final nameValidator = $string().lengthRange(3, 10).not.empty().add(isValidName);

  final nameRes = await nameValidator.validateAsync('123');
  print(nameRes.detailed());

  final ageValidator = $int().eq(0).nullable();

  final ageRes = ageValidator.validate(0);
  print(ageRes.detailed());
}

void complexExample() async {
  final userValidator = $map().schema({
    'name': $string().lengthRange(3, 10).not.empty().add(isValidName),
    'age': $int().eq(0).nullable(),
    'status': $string().oneOf(['active', 'inactive', 'banned']).error('Invalid status'),

    // If status is banned, banned_reason is required
    'banned_reason': resolve((parent) {
      if (parent['status'] == 'banned') {
        return required(
          $string().not.empty(),
          message: 'Banned reason is required if status is banned',
        );
      }
      return null;
    }),
  });

  final userRes = await userValidator.validateAsync({
    'name': '123',
    'age': 0,
    'status': 'banned',
    'banned_reason': '123',
  });

  print(userRes.detailed());
}

void main() async {
  simpleExample();
  complexExample();
}
