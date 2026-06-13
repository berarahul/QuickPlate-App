import 'package:flutter/material.dart';
import '../models/order_item.dart';
import '../../menu/model/menu_response.dart';

class CartProvider extends ChangeNotifier {
  final Map<String, CartItem> _items = {};

  Map<String, CartItem> get items => _items;

  int get itemCount => _items.length;

  double get totalAmount {
    var total = 0.0;
    _items.forEach((key, cartItem) {
      total += cartItem.price * cartItem.quantity;
    });
    return total;
  }

  void addItem(MenuItem menuItem) {
    if (menuItem.id == null) return;
    
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
          id: DateTime.now().toString(),
          name: menuItem.name ?? '',
          price: (menuItem.price ?? 0).toDouble(),
          quantity: 1,
          foodId: menuItem.id!,
        ),
      );
    }
    notifyListeners();
  }

  void removeItem(String foodId) {
    _items.remove(foodId);
    notifyListeners();
  }

  void removeSingleItem(String foodId) {
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
  }

  void incrementItem(String foodId) {
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
    }
  }

  void clearCart() {
    _items.clear();
    notifyListeners();
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
