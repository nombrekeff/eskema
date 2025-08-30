import 'package:benchmark_harness/benchmark_harness.dart';
import 'package:eskema/eskema.dart';

/// Benchmark for Eskema validation performance, focusing on successful validations
/// (no errors) to measure the impact of caching empty lists vs. allocating new ones.
///
/// Run with: dart run bin/benchmark.dart
class ValidationBenchmark extends BenchmarkBase {
  ValidationBenchmark() : super('Eskema Validation');

  // Simple validator chain for testing
  late final IValidator validator;
  
  @override
  void setup() {
    // Create a validator that should succeed frequently
    validator = isString() & stringLength([isInRange(1, 5000)]);
  }

  @override
  void run() {
    // Run many validations on valid data to stress the success path
    for (int i = 0; i < 10000; i++) {
      final result = validator.validate('valid_string_$i');
      if (!result.isValid) throw 'Unexpected failure';
    }
  }
}

void main() {
  ValidationBenchmark().report();
}