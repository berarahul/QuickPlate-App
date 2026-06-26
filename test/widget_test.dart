import 'package:flutter_test/flutter_test.dart';
import 'package:quick_plate/features/cart/models/order_item.dart';

void main() {
  group('OrderItem Model Tests', () {
    test('should parse OrderItem from json correctly', () {
      final json = {'foodId': '123', 'quantity': 2};
      final orderItem = OrderItem.fromJson(json);

      expect(orderItem.foodId, '123');
      expect(orderItem.quantity, 2);
    });

    test('should convert OrderItem to json correctly', () {
      final orderItem = OrderItem(foodId: 'abc', quantity: 5);
      final json = orderItem.toJson();

      expect(json['foodId'], 'abc');
      expect(json['quantity'], 5);
    });
  });
}
