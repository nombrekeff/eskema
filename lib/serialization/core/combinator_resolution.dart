import 'package:eskema/eskema.dart';

/// Executes the [resolveUniformInfixCombinatorOperator] operation.
String resolveUniformInfixCombinatorOperator(
  List list, {
  dynamic source,
  int? offset,
}) {
  String? operator;

  for (var i = 1; i < list.length; i += 2) {
    final token = list[i];
    if (token is! String || !combinatorSymbols.contains(token)) {
      throw DecodeException.invalidType(
          '"&" or "|" operator', source ?? list, offset);
    }

    if (operator == null) {
      operator = token;
      continue;
    }

    if (operator != token) {
      throw DecodeException(
        message: 'Cannot mix "&" and "|" operators in the same list',
        source: source ?? list,
        offset: offset,
        type: DecodeExceptionType.invalidType,
      );
    }
  }

  if (operator == null) {
    throw DecodeException.invalidType(
        '"&" or "|" operator', source ?? list, offset);
  }

  return operator;
}

/// Executes the [composeCombinatorValidator] operation.
IValidator composeCombinatorValidator({
  required String operator,
  required List<IValidator> operands,
  dynamic source,
  int? offset,
}) {
  if (operator == '&') {
    return all(operands);
  }

  if (operator == '|') {
    return any(operands);
  }

  throw DecodeException.invalidType(
      '"&" or "|" operator', source ?? operator, offset);
}
