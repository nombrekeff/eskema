import 'validators.dart';

extension EskemaMapExtension on Map {
  matchesEskema(Map<String, Validator> eskemaMap) {
    return eskema(eskemaMap).call(this);
  }
}

extension EskemaListExtension on List {
  matchesEskema(List<Validator> eskema) {
    return eskemaList(eskema).call(this);
  }

  eachItemMatches(Validator itemValidator) {
    return listEach(itemValidator).call(this);
  }
}
