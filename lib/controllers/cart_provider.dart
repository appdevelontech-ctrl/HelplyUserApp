import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/serviceCategoryDetail.dart';

class CartProvider extends ChangeNotifier {
  List<Product> _cartItems = [];
  List<Product> get cartItems => _cartItems;

  CartProvider() {
    loadCartFromPrefs();
  }

  double get totalPrice => _cartItems.fold(0, (sum, item) => sum + item.salePrice);

  // Add a service to cart (only 1 at a time)
  Future<void> addToCart(Product product) async {
    _cartItems = [product];
    debugPrint('Saving cart: ${jsonEncode(_cartItems.map((e) => e.toJson()).toList())}');
    notifyListeners();
    await saveCartToPrefs();
  }

  Future<void> removeFromCart(Product product) async {
    _cartItems.removeWhere((p) => p.id == product.id);
    debugPrint('Removing item from cart: ${product.id}');
    notifyListeners();
    await saveCartToPrefs();
  }

  Future<void> clearCart() async {
    _cartItems.clear();
    debugPrint('Clearing cart');
    notifyListeners();
    await saveCartToPrefs();
  }

  Future<void> saveCartToPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = jsonEncode(_cartItems.map((e) => e.toJson()).toList());
    await prefs.setString('cart_items', jsonString);
    debugPrint('Cart saved to SharedPreferences: $jsonString');
  }

  Future<void> loadCartFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString('cart_items');
    debugPrint('Loading cart from SharedPreferences: $jsonString');
    if (jsonString != null) {
      final List<dynamic> jsonList = jsonDecode(jsonString);
      _cartItems = jsonList.map((e) => Product.fromJson(e)).toList();
      debugPrint('Cart loaded: ${_cartItems.length} items');
      notifyListeners();
    }
  }
}