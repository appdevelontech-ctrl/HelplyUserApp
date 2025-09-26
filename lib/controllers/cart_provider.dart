import 'dart:convert';
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
    notifyListeners();
    await saveCartToPrefs();
  }

  Future<void> removeFromCart(Product product) async {
    _cartItems.removeWhere((p) => p.id == product.id);
    notifyListeners();
    await saveCartToPrefs();
  }

  Future<void> clearCart() async {
    _cartItems.clear();
    notifyListeners();
    await saveCartToPrefs();
  }

  Future<void> saveCartToPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = jsonEncode(_cartItems.map((e) => e.toJson()).toList());
    await prefs.setString('cart_items', jsonString);
  }

  Future<void> loadCartFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString('cart_items');
    if (jsonString != null) {
      final List<dynamic> jsonList = jsonDecode(jsonString);
      _cartItems = jsonList.map((e) => Product.fromJson(e)).toList();
      notifyListeners();
    }
  }
}
