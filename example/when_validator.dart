import 'package:eskema/eskema.dart';

void main() {
  final addressValidator = eskema({
    'street': isString() & isNotEmpty(),
    'country': isOneOf(['USA', 'Canada']),
    'postal_code': when(
      // Condition (on parent map)
      getField('country', isEq('USA')),
      // `then` validator (on `postal_code` field)
      then: isString() & stringLength([isEq(5)]) > 'a 5-digit US zip code',
      // `otherwise` validator (on `postal_code` field)
      otherwise: isString() & stringLength([isEq(6)]) > 'a 6-character Canadian postal code',
    ),
  });

  // --- Success cases ---
  final validUsaAddress = {
    'street': '123 Main St',
    'country': 'USA',
    'postal_code': '90210',
  };
  print('USA Address: ${addressValidator.validate(validUsaAddress)}');
  // USA Address: Result(isValid: true, value: {street: 123 Main St, country: USA, postal_code: 90210})

  final validCanadaAddress = {
    'street': '456 Queen St',
    'country': 'Canada',
    'postal_code': 'M5H2N2',
  };
  print('Canada Address: ${addressValidator.validate(validCanadaAddress)}');
  // Canada Address: Result(isValid: true, value: {street: 456 Queen St, country: Canada, postal_code: M5H2N2})

  // --- Failure cases ---
  final invalidUsaAddress = {
    'street': '123 Main St',
    'country': 'USA',
    'postal_code': 'M5H2N2', // Canadian format
  };
  print('Invalid USA Address: ${addressValidator.validate(invalidUsaAddress)}');
  // Invalid USA Address: Result(isValid: false, value: {street: 123 Main St, country: USA, postal_code: M5H2N2}, expectations: [postal_code: must be a 5-digit US zip code])

  final invalidCanadaAddress = {
    'street': '456 Queen St',
    'country': 'Canada',
    'postal_code': '90210', // US format
  };
  print('Invalid Canada Address: ${addressValidator.validate(invalidCanadaAddress)}');
  // Invalid Canada Address: Result(isValid: false, value: {street: 456 Queen St, country: Canada, postal_code: 90210}, expectations: [postal_code: must be a 6-character Canadian postal code])
}
