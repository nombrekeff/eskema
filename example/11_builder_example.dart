import 'package:eskema/builder.dart';

void main() async {
  final nameValidator = v()
      .string()
      .lengthMin(3)
      .lengthMax(10)
      .notEmpty()
      .async((v) async => await Future.value(true), 'value.available')
      .build();

  final ageValidator = v().int_().gt(0).nullable().build();

  final nameRes = await nameValidator.validateAsync('123');
  print(nameRes.description);

  final ageRes = ageValidator.validate(3);
  print(ageRes.description);
}
