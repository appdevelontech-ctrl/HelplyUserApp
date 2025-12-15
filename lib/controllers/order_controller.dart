import 'package:flutter/foundation.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import '../models/order_model.dart';
import '../services/api_services.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class OrderController with ChangeNotifier {
  final ApiServices apiService;
  List<Order> _orders = [];
  Map<String, Order> _orderDetailsCache = {}; // Cache for order details
  bool _isOrdersLoading = false;
  bool _isOrderDetailsLoading = false;
  bool _isDisposed = false;

  OrderController({required this.apiService});

  List<Order> get orders => _orders;
  Order? getOrderDetails(String orderId) => _orderDetailsCache[orderId];
  bool get isOrdersLoading => _isOrdersLoading;
  bool get isOrderDetailsLoading => _isOrderDetailsLoading;

  /// Check if order details are cached and fresh
  bool hasFreshOrderDetails(String orderId, {Duration cacheDuration = const Duration(minutes: 5)}) {
    if (_orderDetailsCache.containsKey(orderId)) {
      final order = _orderDetailsCache[orderId];
      if (order != null && order.updatedAt != null) {
        final lastFetched = DateTime.tryParse(order.updatedAt!);
        if (lastFetched != null) {
          return DateTime.now().difference(lastFetched) < cacheDuration;
        }
      }
    }
    return false;
  }

  Future<void> fetchOrders({bool forceRefresh = false}) async {
    if (_isDisposed) return;
    if (_isOrdersLoading) return;

    _isOrdersLoading = true;
    notifyListeners();

    try {
      final newOrders = await apiService.fetchUserOrders();
      _orders = newOrders;
    } catch (e) {
      debugPrint('❌ fetchOrders error: $e');
    } finally {
      _isOrdersLoading = false;
      notifyListeners();
    }
  }


  /// Fetch details of a specific order
  Future<void> fetchOrderDetails(String orderId, {bool forceRefresh = false}) async {
    if (_isDisposed) return;
    if (!forceRefresh && hasFreshOrderDetails(orderId)) {
      debugPrint('📍 Using cached order details for orderId: $orderId');
      return;
    }
    if (_isOrderDetailsLoading) return; // Prevent concurrent fetches

    _isOrderDetailsLoading = true;
    notifyListeners();

    try {

      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('userId');
      if (userId == null) throw Exception('User ID not found');

      final order = await apiService.fetchOrderDetails(userId, orderId);
      _orderDetailsCache[orderId] = order.copyWith(updatedAt: DateTime.now().toIso8601String());
      await EasyLoading.dismiss();
    } catch (e) {
      _orderDetailsCache.remove(orderId); // Clear cache on error
      String errorMessage = 'Failed to load order details: $e';
      if (e.toString().contains('Status code: 404')) {
        errorMessage = 'Order not found. Please check the order ID or contact support.';
      }
      await EasyLoading.showError(errorMessage);
      debugPrint('❌ fetchOrderDetails error: $e');
    }

    _isOrderDetailsLoading = false;
    if (!_isDisposed) notifyListeners();
  }

  void updateOrderStatus(String orderId, int newStatus) {
    if (_isDisposed) return;

    final index = _orders.indexWhere((o) => o.orderId.toString() == orderId);
    if (index != -1) {
      _orders[index] = _orders[index].copyWith(status: newStatus);
    }

    final cachedOrder = _orderDetailsCache[orderId];
    if (cachedOrder != null && cachedOrder.orderId.toString() == orderId) {
      _orderDetailsCache[orderId] = cachedOrder.copyWith(status: newStatus);
    }

    if (!_isDisposed) notifyListeners();
  }


  /// Map status string to status code
  int _mapStatusToCode(String status) {
    switch (status.toLowerCase().trim()) {
      case 'started':
        return 5;
      case 'completed':
      case 'complete':
        return 7;
      case 'cancelled':
      case 'canceled':
        return 0;
      case 'accepted':
      case 'accept':
        return 2;
      case 'placed':
        return 1;
      default:
        debugPrint('⚠️ Unrecognized status: $status, defaulting to 1 (Placed)');
        return 1;
    }
  }

  /// Save maid info to SharedPreferences (per user)
  Future<void> _saveMaidInfoToPrefs(String orderId, Map<String, dynamic> maidInfo) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final uid = prefs.getString('userId') ?? 'unknown_user';
      final key = 'maid_info_$uid';

      final data = prefs.getString(key) ?? '{}';
      Map<String, dynamic> map;
      try {
        map = jsonDecode(data) as Map<String, dynamic>;
      } catch (e) {
        debugPrint('❌ Error parsing maid_info: $e');
        map = {};
      }

      map[orderId] = maidInfo;
      await prefs.setString(key, jsonEncode(map));

      debugPrint('💾 (USER: $uid) Maid info saved → $orderId → $maidInfo');
    } catch (e) {
      debugPrint('❌ Error saving maid info: $e');
    }
  }
  void clearOrders() {
    _orders.clear();
    _orderDetailsCache.clear();
    notifyListeners();
  }


  /// Clear outdated maid info from SharedPreferences
  Future<void> clearOutdatedMaidInfo({Duration maxAge = const Duration(days: 30)}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final data = prefs.getString('maid_info') ?? '{}';
      Map<String, dynamic> map;
      try {
        map = jsonDecode(data) as Map<String, dynamic>;
      } catch (e) {
        debugPrint('❌ Error parsing maid_info for cleanup: $e');
        return;
      }

      final now = DateTime.now();
      map.removeWhere((key, value) {
        final updatedAt = DateTime.tryParse(value['updatedAt'] ?? '');
        return updatedAt != null && now.difference(updatedAt) > maxAge;
      });

      await prefs.setString('maid_info', jsonEncode(map));
      debugPrint('🧹 Cleared outdated maid info');
    } catch (e) {
      debugPrint('❌ Error clearing outdated maid info: $e');
    }
  }

  @override
  void dispose() {
    _isDisposed = true;
    super.dispose();
  }
}