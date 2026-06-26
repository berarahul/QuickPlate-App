import 'package:flutter/material.dart';
import '../models/order_item.dart';
import '../../menu/model/menu_response.dart';
import '../repository/cart_repository.dart';

class CartProvider extends ChangeNotifier {
  final CartRepository _cartRepository;
  final Map<String, CartItem> _items = {};
  bool _isLoading = false;

  CartProvider(this._cartRepository);

  Map<String, CartItem> get items => _items;
  int get itemCount => _items.length;
  bool get isLoading => _isLoading;

  double get totalAmount {
    var total = 0.0;
    _items.forEach((key, cartItem) {
      total += cartItem.price * cartItem.quantity;
    });
    return total;
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  Future<void> fetchCart() async {
    _setLoading(true);
    try {
      final backendItems = await _cartRepository.getCart();
      _items.clear();
      _items.addAll(backendItems);
    } catch (e) {
      debugPrint("Error fetching cart from backend: $e");
    } finally {
      _setLoading(false);
    }
  }

  Future<void> addItem(MenuItem menuItem) async {
    if (menuItem.id == null) return;

    // Optimistic UI update
    final tempId = DateTime.now().toString();
    if (_items.containsKey(menuItem.id)) {
      _items.update(
        menuItem.id!,
        (existingCartItem) => CartItem(
          id: existingCartItem.id,
          name: existingCartItem.name,
          price: existingCartItem.price,
          quantity: existingCartItem.quantity + 1,
          foodId: existingCartItem.foodId,
        ),
      );
    } else {
      _items.putIfAbsent(
        menuItem.id!,
        () => CartItem(
          id: tempId,
          name: menuItem.name ?? '',
          price: (menuItem.price ?? 0).toDouble(),
          quantity: 1,
          foodId: menuItem.id!,
        ),
      );
    }
    notifyListeners();

    try {
      final backendItems = await _cartRepository.addToCart(menuItem.id!);
      _items.clear();
      _items.addAll(backendItems);
      notifyListeners();
    } catch (e) {
      debugPrint("Error adding to backend cart: $e");
      await fetchCart();
    }
  }

  void removeItem(String foodId) {
    _items.remove(foodId);
    notifyListeners();
  }

  Future<void> removeSingleItem(String foodId) async {
    if (!_items.containsKey(foodId)) {
      return;
    }
    if (_items[foodId]!.quantity > 1) {
      _items.update(
        foodId,
        (existingCartItem) => CartItem(
          id: existingCartItem.id,
          name: existingCartItem.name,
          price: existingCartItem.price,
          quantity: existingCartItem.quantity - 1,
          foodId: existingCartItem.foodId,
        ),
      );
    } else {
      _items.remove(foodId);
    }
    notifyListeners();

    try {
      final backendItems = await _cartRepository.removeFromCart(foodId);
      _items.clear();
      _items.addAll(backendItems);
      notifyListeners();
    } catch (e) {
      debugPrint("Error removing from backend cart: $e");
      await fetchCart();
    }
  }

  Future<void> incrementItem(String foodId) async {
    if (_items.containsKey(foodId)) {
      _items.update(
        foodId,
        (existingCartItem) => CartItem(
          id: existingCartItem.id,
          name: existingCartItem.name,
          price: existingCartItem.price,
          quantity: existingCartItem.quantity + 1,
          foodId: existingCartItem.foodId,
        ),
      );
      notifyListeners();

      try {
        final backendItems = await _cartRepository.addToCart(foodId);
        _items.clear();
        _items.addAll(backendItems);
        notifyListeners();
      } catch (e) {
        debugPrint("Error incrementing backend cart: $e");
        await fetchCart();
      }
    }
  }

  Future<void> clearCart() async {
    _items.clear();
    notifyListeners();

    try {
      final backendItems = await _cartRepository.clearCart();
      _items.clear();
      _items.addAll(backendItems);
      notifyListeners();
    } catch (e) {
      debugPrint("Error clearing backend cart: $e");
      await fetchCart();
    }
  }

  List<OrderItem> get orderItems {
    return _items.values
        .map((item) => OrderItem(foodId: item.foodId, quantity: item.quantity))
        .toList();
  }
}

class CartItem {
  final String id;
  final String name;
  final double price;
  final int quantity;
  final String foodId;

  CartItem({
    required this.id,
    required this.name,
    required this.price,
    required this.quantity,
    required this.foodId,
  });
}
