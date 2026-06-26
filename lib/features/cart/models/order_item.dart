class OrderItem {
  final String foodId;
  final int quantity;

  OrderItem({required this.foodId, required this.quantity});

  Map<String, dynamic> toJson() {
    return {'foodId': foodId, 'quantity': quantity};
  }

  factory OrderItem.fromJson(Map<String, dynamic> json) {
    String id = '';
    if (json['foodId'] is Map) {
      id = json['foodId']['_id'] ?? '';
    } else {
      id = json['foodId']?.toString() ?? '';
    }

    return OrderItem(foodId: id, quantity: json['quantity'] ?? 0);
  }
}
