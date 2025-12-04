import 'package:eskema/eskema.dart';

///
/// This example demonstrates a more complex usage of the Builder API.
///
/// It showcases:
/// - Nested map validation.
/// - List validation within a map.
/// - Custom error messages.
///
void main() {
  print('--- Complex Builder Example ---');

  // 1. Define Schema
  final orderSchema = $map().schema({
    'orderId': $string().not.empty().build(),
    
    // Nested object: 'customer'
    'customer': $map().schema({
      'name': $string().not.empty().build(),
      'vip': $bool().optional().build(),
    }).build(),

    // List of objects: 'items'
    'items': $list().each(
      $map().schema({
        'productId': $string().not.empty().build(),
        'quantity': $int().gt(0).build(),
        'price': $number().gt(0).build(),
      }).build()
    ).build(),

    // Optional status with specific allowed values
    'status': $string()
        .oneOf(['pending', 'shipped', 'delivered'])
        .error('Status must be pending, shipped, or delivered')
        .optional()
        .build(),
  }).build();

  // 2. Define Data
  final orderData = {
    'orderId': 'ORD-2023-001',
    'customer': {
      'name': 'Alice Smith',
      'vip': true,
    },
    'items': [
      {'productId': 'P1', 'quantity': 2, 'price': 19.99},
      {'productId': 'P2', 'quantity': 1, 'price': 5.50},
    ],
    'status': 'shipped',
  };

  // 3. Validate
  print('\n--- Validating Order ---');
  final result = orderSchema.validate(orderData);

  if (result.isValid) {
    print('Order is valid!');
    print('Value: ${result.value}');
  } else {
    print('Order is invalid:');
    print(result.detailed());
  }

  print('-' * 20);
}
