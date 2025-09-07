import 'package:test/test.dart' hide isMap;
import 'package:eskema/eskema.dart';

// Helper identity validator to capture transformed value directly.
final _pass = Validator.valid;

void main() {
  group('pick transformer', () {
    final validator = pickKeys(['a', 'c'], _pass);

    test('picks subset', () {
      final res = validator.validate({'a': 1, 'b': 2, 'c': 3});
      expect(res.isValid, true);
      final m = res.value as Map;
      expect(m.containsKey('a'), true);
      expect(m.containsKey('c'), true);
      expect(m.containsKey('b'), false);
    });

    test('missing keys simply omitted', () {
      final res = validator.validate({'a': 1});
      expect(res.isValid, true);
      expect((res.value as Map).containsKey('c'), false);
    });
  });

  group('pluck transformer', () {
    final validator = pluckKey('name', isEq('Alice'));

    test('plucks existing key', () {
      expect(validator.validate({'name': 'Alice', 'age': 30}).isValid, true);
    });

    test('fails when key missing', () {
      expect(validator.validate({'age': 30}).isValid, false);
    });
  });

  group('flattenMapKeys transformer', () {
    final validator = flattenMapKeys('.', _pass);

    test('flattens nested maps', () {
      final res = validator.validate({
        'a': {
          'b': 1,
          'c': {'d': 2}
        },
        'e': 3
      });
      expect(res.isValid, true);
      final m = res.value as Map;
      expect(m['a.b'], 1);
      expect(m['a.c.d'], 2);
      expect(m['e'], 3);
    });

    test('leaves non-Map leaves untouched', () {
      final res = validator.validate({
        'a': {
          'b': [1, 2]
        }
      });
      expect(res.isValid, true);
      final m = res.value as Map;
      expect(m['a.b'], [1, 2]);
    });
  });

  group('builder wrappers', () {
    final validator = b().map().pick(['id', 'meta']).flattenKeys('_').build();

    test('builder pick + flatten', () {
      final res = validator.validate({
        'id': 1,
        'meta': {'inner': 2},
        'other': 3
      });
      expect(res.isValid, true);
      final m = res.value as Map;
      expect(m['id'], 1);
      expect(m['meta_inner'], 2);
    });

    test('builder pluck + numeric constraint', () {
      final validator2 = builder().map().pluckValue('id').toIntStrict().gte(1).build();
      final ok = validator2.validate({'id': 2, 'x': 3});
      expect(ok.value, 2);
      expect(ok.isValid, true);
      final zero = validator2.validate({'id': '0'});
      expect(zero.value, 0);
      expect(zero.isValid, false); // fails gte(1)
      final missing = validator2.validate({'x': 3});
      expect(missing.isValid, false);
    });
  });
}
