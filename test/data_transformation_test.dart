import 'package:eskema/eskema.dart';
import 'package:test/test.dart';

void main() {
  group('Data Transformation', () {
    test('eskema transforms values and preserves original', () {
      final validator = eskema({
        'name': trim(isString()),
        'age': toInt(isType<int>()),
      });

      final input = {
        'name': '  Bob  ',
        'age': '30',
        'extra': 'ignored',
      };

      final result = validator.validate(input);

      expect(result.isValid, isTrue);
      // Transformed values
      expect(result.value['name'], 'Bob');
      expect(result.value['age'], 30);
      expect(result.value['extra'], 'ignored'); // Preserves extra keys

      // Original values
      expect(result.originalValue['name'], '  Bob  ');
      expect(result.originalValue['age'], '30');
      expect(result.originalValue['extra'], 'ignored');
    });

    test('eskemaStrict transforms values and preserves original', () {
      final validator = eskemaStrict({
        'name': trim(isString()),
        'active': toBool(isType<bool>()),
      });

      final input = {
        'name': '  Alice  ',
        'active': 'true',
      };

      final result = validator.validate(input);

      expect(result.isValid, isTrue);
      expect(result.value['name'], 'Alice');
      expect(result.value['active'], true);

      expect(result.originalValue['name'], '  Alice  ');
      expect(result.originalValue['active'], 'true');
    });

    test('nested eskema transforms values deep in the structure', () {
      final validator = eskema({
        'user': eskema({
          'name': trim(isString()),
          'settings': eskema({
            'notifications': toBool(isType<bool>()),
          }),
        }),
      });

      final input = {
        'user': {
          'name': '  Charlie  ',
          'settings': {
            'notifications': 'false',
          },
        },
      };

      final result = validator.validate(input);

      expect(result.isValid, isTrue);
      final user = result.value['user'] as Map;
      expect(user['name'], 'Charlie');
      final settings = user['settings'] as Map;
      expect(settings['notifications'], false);

      final originalUser = result.originalValue['user'] as Map;
      expect(originalUser['name'], '  Charlie  ');
      final originalSettings = originalUser['settings'] as Map;
      expect(originalSettings['notifications'], 'false');
    });

    test('originalValue is available on failure', () {
      final validator = eskema({
        'age': toInt(isType<int>()),
      });

      final input = {
        'age': 'not-a-number',
      };

      final result = validator.validate(input);

      expect(result.isValid, isFalse);
      expect(result.originalValue['age'], 'not-a-number');
      // On failure, value might be the original map or partial transform depending on implementation details,
      // but we mostly care about originalValue being correct.
      // In current implementation, it returns the partially transformed map as value in invalid result too.
      expect(result.value, isA<Map>());
    });

    test('list transformation within eskema', () {
      final validator = eskema({
        'tags': listEach(trim(isString())),
      });

      // Note: listEach currently does NOT support transformation of elements in place
      // because it validates elements but doesn't reconstruct the list.
      // This test confirms current behavior (no transformation for list elements yet).
      // If we want to support list transformation, we'd need to update listEach/eskemaList.

      final input = {
        'tags': ['  a  ', '  b  '],
      };

      final result = validator.validate(input);

      expect(result.isValid, isTrue);
      // Current behavior: list elements are NOT transformed in the output map
      // because listEach just validates.
      // If we wanted them transformed, we'd need a transformer or update listEach.
      // For now, let's just assert they are valid.
      expect(result.value['tags'][0], '  a  ');
    });
  });
}
