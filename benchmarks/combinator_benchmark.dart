import 'package:benchmark_harness/benchmark_harness.dart';
import 'package:eskema/eskema.dart';

const iterations = 10000;

class CombinatorBenchmark extends BenchmarkBase {
  CombinatorBenchmark() : super('Combinator Performance');

  late IValidator validator;

  @override
  void setup() {
    // Create an 'all' validator with multiple rules
    validator = all([
      isString(),
      isNotEmpty(),
      isLowerCase(),
      not(isUpperCase()),
      // Add more for stress testing
    ]);
  }

  @override
  void run() {
    // Run many validations on valid data
    for (int i = 0; i < iterations; i++) {
      final result = validator.validate('test_string_$i');
      if (result.isNotValid) throw Exception('Validation failed: ${result.description}');
    }
  }
}

class CombinatorBenchmark2 extends BenchmarkBase {
  CombinatorBenchmark2() : super('Combinator Performance 2');

  late IValidator validator;

  @override
  void setup() {
    // Create an 'all' validator with multiple rules
    validator = all([
      $isString,
      $isNotEmpty,
      $isLowerCase,
      not($isUpperCase),
      // Add more for stress testing
    ]);
  }

  @override
  void run() {
    // Run many validations on valid data
    for (int i = 0; i < iterations; i++) {
      final result = validator.validate('test_string_$i');
      if (result.isNotValid) throw Exception('Validation failed: ${result.description}');
    }
  }
}

void reportBm(BenchmarkBase bm) {
  final time = bm.measure();
  print('${bm.name}: ${Duration(microseconds: time.round()).inMilliseconds} ms');
}

void main() {
  final bm = CombinatorBenchmark();
  // final bm2 = CombinatorBenchmark2();

  reportBm(bm);
  // reportBm(bm2);
}
