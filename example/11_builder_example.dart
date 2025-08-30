import 'package:eskema/eskema.dart';

Validator<Result> isValidName = Validator((value) async {
  return Result.valid(await Future.value(false));
});

void main() async {
  final nameValidator = v().string().lengthRange(3, 10).not.empty().add(isValidName).build();

  final nameRes = await nameValidator.validateAsync('123');
  print(nameRes.description);

  final ageValidator = v().int_().eq(0).nullable().build();

  final ageRes = ageValidator.validate(0);
  print(ageRes.description);
}
