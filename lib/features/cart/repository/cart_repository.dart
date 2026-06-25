import '../../../core/network/api_client.dart';
import '../../../core/network/api_endpoints.dart';
import '../provider/cart_provider.dart';

class CartRepository {
  final ApiClient _apiClient;

  CartRepository(this._apiClient);

  Future<Map<String, CartItem>> getCart() async {
    final response = await _apiClient.get(ApiEndpoints.cart);
    return _parseCart(response.data);
  }

  Future<Map<String, CartItem>> addToCart(String foodId, {int quantity = 1}) async {
    final response = await _apiClient.post(
      ApiEndpoints.cartAdd,
      data: {'foodId': foodId, 'quantity': quantity},
    );
    return _parseCart(response.data);
  }

  Future<Map<String, CartItem>> removeFromCart(String foodId) async {
    final response = await _apiClient.post(
      ApiEndpoints.cartRemove,
      data: {'foodId': foodId},
    );
    return _parseCart(response.data);
  }

  Future<Map<String, CartItem>> clearCart() async {
    final response = await _apiClient.post(ApiEndpoints.cartClear, data: {});
    return _parseCart(response.data);
  }

  Map<String, CartItem> _parseCart(dynamic responseData) {
    final Map<String, CartItem> parsedItems = {};
    if (responseData == null) return parsedItems;

    final data = responseData['data'];
    if (data == null) return parsedItems;

    final items = data['items'] as List?;
    if (items == null) return parsedItems;

    for (var item in items) {
      final food = item['food'];
      if (food == null) continue;

      final foodId = food['_id'] as String;
      final quantity = item['quantity'] as int? ?? 1;

      parsedItems[foodId] = CartItem(
        id: item['_id'] ?? foodId,
        name: food['name'] ?? '',
        price: (food['price'] ?? 0).toDouble(),
        quantity: quantity,
        foodId: foodId,
      );
    }
    return parsedItems;
  }
}
