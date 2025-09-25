import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/serviceCategoryDetail.dart';

class CartProvider with ChangeNotifier {
  List<Product> _cartItems = [];
  final String _cartKey = 'cart_items';

  CartProvider() {
    _loadCart();
  }

  List<Product> get cartItems => _cartItems;

  int get itemCount => _cartItems.length;

  double get totalPrice => _cartItems.fold(0, (sum, item) => sum + item.salePrice);

  void addToCart(Product product) {
    if (_cartItems.isEmpty || !_cartItems.any((item) => item.id == product.id)) {
      _cartItems.add(product);
      _saveCart();
      notifyListeners();
    }
  }

  void removeFromCart(Product product) {
    _cartItems.removeWhere((item) => item.id == product.id);
    _saveCart();
    notifyListeners();
  }

  void clearCart() {
    _cartItems.clear();
    _saveCart();
    notifyListeners();
  }

  Future<void> _loadCart() async {
    final prefs = await SharedPreferences.getInstance();
    final String? cartData = prefs.getString(_cartKey);
    if (cartData != null) {
      final List<dynamic> decodedData = jsonDecode(cartData);
      _cartItems = decodedData.map((item) => Product.fromJson(item)).toList();
      notifyListeners();
    }
  }

  Future<void> _saveCart() async {
    final prefs = await SharedPreferences.getInstance();
    final String encodedData = jsonEncode(_cartItems.map((item) => item.toJson()).toList());
    await prefs.setString(_cartKey, encodedData);
  }
}