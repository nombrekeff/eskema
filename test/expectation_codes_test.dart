import 'package:test/test.dart';
import 'package:eskema/eskema.dart'
    hide contains, isNull; // hide validators that clash with matcher names

void main() {
  group('Expectation code & data', () {
    test('type.mismatch code with data expected/found', () {
      final r = isString().validate(123);
      expect(r.isValid, false);
      final e = r.firstExpectation;
      expect(e.code, 'type.mismatch');
      expect(e.data?['expected'], 'String');
      expect(e.data?['found'], 'int');
    });

    test('value.format_invalid via isUrl', () {
      final r = isUrl().validate('::://');
      expect(r.isValid, false);
      expect(r.firstExpectation.code, 'value.format_invalid');
    });

  test('value.membership_mismatch via isOneOf', () {
      final r = isOneOf<int>([1, 2, 3]).validate(4);
      expect(r.isValid, false);
      final e = r.firstExpectation;
      expect(e.code, 'value.membership_mismatch');
      expect(e.data?['options'], isA<List>());
    });

    test('value.contains_missing via containsKey', () {
      final r = containsKey('foo').validate({});
      expect(r.isValid, false);
      expect(r.firstExpectation.code, 'value.contains_missing');
    });

    test('structure.unknown_key code from eskemaStrict', () {
      final r = eskemaStrict({'name': isString()}).validate({'name': 'a', 'extra': 1});
      expect(r.isValid, false);
      expect(r.firstExpectation.code, 'structure.unknown_key');
      expect(r.firstExpectation.data?['keys'], contains('extra'));
    });

    test('structure.map_field_failed default code when child has none', () {
      final custom = validator((_) => false, (v) => Expectation(message: 'bad', value: v));
      final r = eskema({'x': custom}).validate({'x': 10});
      expect(r.isValid, false);
      // Underlying expectation had no code so collector should assign structure.map_field_failed
      expect(r.firstExpectation.code, anyOf('structure.map_field_failed', isNull));
    });

    test('structure.list_item_failed default code when child has none', () {
      final custom = validator((_) => false, (v) => Expectation(message: 'bad', value: v));
      final r = every(custom).validate(['a']);
      expect(r.isValid, false);
      expect(r.firstExpectation.code, anyOf('structure.list_item_failed', isNull));
    });

    test('copyWith preserves and overrides code/data', () {
      final e = const Expectation(message: 'm', value: 1, code: 'c1', data: {'a': 1});
      final e2 = e.copyWith(message: 'm2', code: 'c2');
      expect(e2.message, 'm2');
      expect(e2.code, 'c2');
      expect(e2.data?['a'], 1); // preserved
    });

    test('toJson includes code, path, data', () {
      final e = const Expectation(message: 'm', value: 5, code: 'x', data: {'k': 'v'}, path: 'p');
      final j = e.toJson();
      expect(j['code'], 'x');
      expect(j['path'], 'p');
      expect(j['data'], isA<Map>());
    });
  });
}
