import 'dart:async';
import 'package:test/test.dart';
// Hide eskema `contains` validator to avoid clash with matcher `contains`.
import 'package:eskema/eskema.dart' hide contains;

// Helper creating an async passing validator
IValidator asyncPass([String msg = 'ok']) => Validator((v) async {
      await Future.microtask(() {});
      return Result(
        isValid: true,
        value: v,
        expectation: Expectation(message: msg, value: v),
      );
    });

// Helper creating an async failing validator
IValidator asyncFail(String message) => Validator((v) async {
      await Future.microtask(() {});
      return Result.invalid(v, expectation: Expectation(message: message, value: v));
    });

class InnerMapValidator extends MapValidator<Map<String, dynamic>> {
  InnerMapValidator({String id = 'inner'}) : _id = id;
  final String _id;
  final Field idField = Field(id: 'id', validators: [isInt()]);
  @override
  List<IdValidator> get fields => [idField];
  @override
  String get id => _id;
}

class OuterMapValidator extends MapValidator<Map<String, dynamic>> {
  OuterMapValidator();
  final Field nameField = Field(id: 'name', validators: [isString()]);
  final InnerMapValidator inner = InnerMapValidator();
  @override
  List<IdValidator> get fields => [nameField, inner];
}

void main() {
  group('Expectation helpers', () {
    test('copyWith + addToPath + toInvalidResult', () {
      final e = const Expectation(path: 'user', message: 'is bad', value: 1);
      final e2 = e.copyWith(message: 'really bad');
      expect(e2.message, 'really bad');
      final e3 = e2.addToPath('name');
      expect(e3.path, 'user.name');
      final r = e3.toInvalidResult();
      expect(r.isValid, false);
      expect(r.firstExpectation.description.contains('user.name'), true);
    });
  });

  group('Result helpers', () {
    test('copyWith changes fields + multi expectation description join', () {
      final r = Result.invalid(10, expectations: [
        const Expectation(message: 'e1', value: 10),
        const Expectation(message: 'e2', value: 10),
      ]);
      final r2 = r.copyWith(isValid: true, value: 11);
      expect(r2.isValid, true);
      expect(r.description, contains('e1'));
      expect(r.description, contains('e2'));
      expect(r.description?.contains(', '), true);
      expect(r2.value, 11);
    });
  });

  group('Combinators rare paths', () {
    test('any aggregates all failures including async', () async {
      final v = any([
        asyncFail('a1'),
        validator((v) => false, (v) => Expectation(message: 'a2', value: v)),
      ]);
      final r = await v.validateAsync('x');
      expect(r.isValid, false);
      expect(r.expectationCount, 2);
    });

    test('none with passing validators becomes invalid collecting expectations (async + sync)',
        () async {
      final v = none([
        asyncPass('p1'),
        validator((v) => true, (v) => Expectation(message: 'p2', value: v)),
      ]);
      final r = await v.validateAsync('x');
      expect(r.isValid, false); // because original validators passed
      expect(r.expectationCount, 2);
    });

    test('withError wraps async child', () async {
      final v = withExpectation(asyncFail('inner'), const Expectation(message: 'outer'));
      final r = await v.validateAsync('z');
      expect(r.isValid, false);
      expect(r.firstExpectation.message, 'outer');
    });

    test('throwInstead async success + failure', () async {
      final pass = throwInstead(asyncPass());
      final ok = await pass.validateAsync(1);
      expect(ok.isValid, true);

      final fail = throwInstead(asyncFail('bad'));
      expect(
        () => fail.validateAsync(1),
        throwsA(isA<ValidatorFailedException>()),
      );
    });

    test('not async flips result', () async {
      final v = not(asyncFail('bad'));
      final r = await v.validateAsync('x');
      expect(r.isValid, true);
    });

    test('all validator collects expectations from all failing child validators', () async {
      // Use AllValidator with collecting=true for collecting all failures without value chaining
      final v = AllValidator([
        asyncFail('failure1'),
        validator((v) => false, (v) => Expectation(message: 'failure2', value: v)),
        asyncFail('failure3'),
      ], collecting: true);
      final r = await v.validateAsync('x');
      expect(r.isValid, false);
      // AllValidator with collecting=true should collect expectations from ALL failing validators
      expect(r.expectationCount, 3);
      expect(r.expectations.map((e) => e.message), containsAll(['failure1', 'failure2', 'failure3']));
    });
  });

  group('WhenValidator async condition + branches', () {
    test('outside eskema returns invalid usage error', () {
      final w = when(isString(), then: isInt(), otherwise: isBool());
      final r = w.validate('x');
      expect(r.isValid, false);
      expect(r.firstExpectation.message, contains('only be used'));
    });

    test('inside eskema async condition selects then', () async {
      final cond = Validator((map) async {
        await Future<void>.delayed(const Duration(milliseconds: 1));
        return Result.valid(map);
      });
      final v = eskema({
        'value': when(cond, then: asyncPass(), otherwise: asyncFail('nope')),
      });
      final r = await v.validateAsync({'value': 1});
      expect(r.isValid, true);
    });

    test('inside eskema async condition selects otherwise', () async {
      final cond = Validator((map) async {
        await Future<void>.delayed(const Duration(milliseconds: 1));
        return Result.invalid(map, expectation: Expectation(message: 'cond', value: map));
      });
      final v = eskema({
        'value': when(cond, then: asyncFail('should not run'), otherwise: asyncPass()),
      });
      final r = await v.validateAsync({'value': 1});
      expect(r.isValid, true); // otherwise asyncPass
    });
  });

  group('AsyncValidatorException toString', () {
    test('validate() on async chain throws with message', () {
      final v = asyncPass();
      try {
        v.validate(1); // should throw
        fail('Expected AsyncValidatorException');
      } catch (e) {
        expect(e.toString(), contains('validate()'));
      }
    });
  });

  group('MapValidator nested failure path formatting', () {
    test('nested validator error message contains nested key', () {
      final outer = OuterMapValidator();
      final r = outer.validate({
        'name': 'John',
        'inner': {'id': 'not-int'}
      });
      expect(r.isValid, false);
      expect(r.firstExpectation.message, contains('id'));
    });
  });

  group('cached validators unused types', () {
    test('record / symbol / enum / future / iterable / dateTime validators', () async {
      // Expect failures
      expect($isRecord.validate(1).isValid, false);
      expect($isSymbol.validate(1).isValid, false);
      expect($isEnum.validate(1).isValid, false);
      expect($isFuture.validate(1).isValid, false);
      expect($isIterable.validate(1).isValid, false);
      expect($isDateTime.validate(1).isValid, false);
      // And successes
      final rec = (1, 2);
      expect($isRecord.validate(rec).isValid, true);
      expect($isIterable.validate([1, 2]).isValid, true);
      expect($isFuture.validate(Future.value(1)).isValid, true);
      expect($isDateTime.validate(DateTime.now()).isValid, true);
    });
  });

  group('listEach nested path propagation', () {
    test('error path includes list index and nested key', () async {
      final listValidator = listEach(eskema({'a': isInt()}));
      final r = await listValidator.validateAsync([
        {'a': 'x'}
      ]);
      expect(r.isValid, false);
      // Path should be like [0].a
      expect(r.firstExpectation.path, contains('[0]'));
      expect(r.firstExpectation.path, contains('.a'));
    });
  });
}
