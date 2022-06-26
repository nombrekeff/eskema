// ignore_for_file: avoid_print

import 'package:eskema/eskema.dart';
import 'package:eskema/util.dart';

void main() {
  final isEquals = throwInstead(isDeepEq<Set>({1, 2}));
  
  try {
    isEquals({1});
  } on ValidatorFailedException catch (e) {
    print(e.message);
    print(e.result.value);
  }
}
