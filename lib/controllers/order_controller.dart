import 'package:flutter/foundation.dart';
import '../models/order_model.dart';
import '../services/api_services.dart';
import 'package:shared_preferences/shared_preferences.dart';

class OrderController with ChangeNotifier {
  final ApiServices apiService;
  List<Order> _orders = [];
  Order? _orderDetails;
  bool _loading = false;
  bool _isDisposed = false;

  OrderController({required this.apiService});

  List<Order> get orders => _orders;
  Order? get orderDetails => _orderDetails;
  bool get loading => _loading;

  Future<void> fetchOrders() async {
    if (_isDisposed) return;

    print('🚀 Starting fetchOrders in OrderController');
    _loading = true;
    if (!_isDisposed) notifyListeners();

    try {
      print('📡 Calling apiService.fetchUserOrders()');
      _orders = await apiService.fetchUserOrders();
      print('✅ Successfully fetched ${_orders.length} orders');
      print('📦 Orders: ${_orders.map((order) => 'Order ID: ${order.orderId}, _id: ${order.id}, Amount: ${order.totalAmount}, Status: ${order.status}').toList()}');
    } catch (e) {
      print('❌ Error in fetchOrders: $e');
      _orders = [];
    }

    _loading = false;
    print('🏁 fetchOrders completed, loading: $_loading');
    if (!_isDisposed) notifyListeners();
  }

  Future<void> fetchOrderDetails(String orderId) async {
    if (_isDisposed) return;

    print('🚀 Starting fetchOrderDetails for orderId: $orderId');
    _loading = true;
    if (!_isDisposed) notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('userId');
      if (userId == null) {
        throw Exception('User ID not found in SharedPreferences');
      }

      print('📡 Calling apiService.fetchOrderDetails() with userId: $userId');
      _orderDetails = await apiService.fetchOrderDetails(userId, orderId);
      print('✅ Successfully fetched order details for orderId: $orderId');
    } catch (e) {
      print('❌ Error in fetchOrderDetails: $e');
      _orderDetails = null;
    }

    _loading = false;
    print('🏁 fetchOrderDetails completed, loading: $_loading');
    if (!_isDisposed) notifyListeners();
  }

  @override
  void dispose() {
    _isDisposed = true;
    super.dispose();
    print('🗑️ OrderController disposed');
  }
}