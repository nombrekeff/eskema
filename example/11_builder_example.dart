import 'package:eskema/eskema.dart';

Validator<Result> isValidName = Validator((value) async {
  return Result.valid(await Future.value(false));
});

void main() async {
  final nameValidator = $string().lengthRange(3, 10).not.empty().add(isValidName);
  final alla = all([nameValidator]);

  final nameRes = await nameValidator.validateAsync('123');
  print(nameRes.description);

  final ageValidator = $int().eq(0).nullable();

  final ageRes = ageValidator.validate(0);
  print(ageRes.description);
}
