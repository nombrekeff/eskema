import 'package:eskema/result.dart';
import 'package:eskema/validators.dart';

import 'validator.dart';

extension EskemaMapExtension on Map {
  EskResult validate(IEskValidator validator) {
    return validator.validate(this);
  }

  isValid(IEskValidator eskema) {
    return eskema.validate(this).isValid;
  }

  isNotValid(IEskValidator eskema) {
    return !eskema.validate(this).isValid;
  }
}

extension EskemaListExtension on List {
  EskResult validate(List<IEskValidator> eskema) {
    return eskemaList(eskema).validate(this);
  }

  eachItemMatches(IEskValidator itemValidator) {
    return listEach(itemValidator).validate(this);
  }
}
