import 'package:eskema/result.dart';
import 'package:eskema/validators.dart';

import 'validator.dart';

extension EskemaMapExtension on Map {
  IResult validate(EskValidator validator) {
    return validator.validate(this);
  }

  isValid(EskValidator eskema) {
    return eskema.validate(this).isValid;
  }

  isNotValid(EskValidator eskema) {
    return !eskema.validate(this).isValid;
  }
}

extension EskemaListExtension on List {
  IResult validate(List<EskValidator> eskema) {
    return eskemaList(eskema).validate(this);
  }

  eachItemMatches(EskValidator itemValidator) {
    return listEach(itemValidator).validate(this);
  }
}
