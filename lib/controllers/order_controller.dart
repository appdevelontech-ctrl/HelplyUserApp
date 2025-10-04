import 'package:flutter/foundation.dart';
import '../models/order_model.dart';
import '../services/api_services.dart';
import 'dart:convert';
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

  /// Fetch all user orders
  Future<void> fetchOrders() async {
    if (_isDisposed) return;
    _loading = true;
    notifyListeners();

    try {
      _orders = await apiService.fetchUserOrders();
    } catch (e) {
      _orders = [];
      debugPrint('❌ fetchOrders error: $e');
    }

    _loading = false;
    notifyListeners();
  }

  /// Fetch details of a specific order
  Future<void> fetchOrderDetails(String orderId) async {
    if (_isDisposed) return;
    _loading = true;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('userId');
      if (userId == null) throw Exception('User ID not found');

      _orderDetails = await apiService.fetchOrderDetails(userId, orderId);
    } catch (e) {
      _orderDetails = null;
      debugPrint('❌ fetchOrderDetails error: $e');
    }

    _loading = false;
    notifyListeners();
  }

  /// Update maid info for an order manually
  void updateMaidInfo(String orderId, Map<String, dynamic> maidInfo) {
    final index = _orders.indexWhere((o) => o.orderId.toString() == orderId);
    if (index != -1) {
      _orders[index] = _orders[index].copyWith(
        maidName: maidInfo['maidName'],
        maidPhone: maidInfo['maidPhone'],
        maidEmail: maidInfo['maidEmail'],
        maidLat: maidInfo['maidLat'] is String
            ? double.tryParse(maidInfo['maidLat'])
            : maidInfo['maidLat'] ?? 0.0,
        maidLng: maidInfo['maidLng'] is String
            ? double.tryParse(maidInfo['maidLng'])
            : maidInfo['maidLng'] ?? 0.0,
      );
      notifyListeners();
    }

    if (_orderDetails?.orderId.toString() == orderId) {
      _orderDetails = _orderDetails?.copyWith(
        maidName: maidInfo['maidName'],
        maidPhone: maidInfo['maidPhone'],
        maidEmail: maidInfo['maidEmail'],
        maidLat: maidInfo['maidLat'] is String
            ? double.tryParse(maidInfo['maidLat'])
            : maidInfo['maidLat'] ?? 0.0,
        maidLng: maidInfo['maidLng'] is String
            ? double.tryParse(maidInfo['maidLng'])
            : maidInfo['maidLng'] ?? 0.0,
      );
      notifyListeners();
    }
  }

  /// Update order status manually
  void updateOrderStatus(String orderId, int newStatus) {
    final index = _orders.indexWhere((o) => o.orderId.toString() == orderId);
    if (index != -1) {
      _orders[index] = _orders[index].copyWith(status: newStatus);
      notifyListeners();
    }

    if (_orderDetails?.orderId.toString() == orderId) {
      _orderDetails = _orderDetails?.copyWith(status: newStatus);
      notifyListeners();
    }
  }

  /// Update order status and maid info from socket
  Future<void> updateOrderStatusFromSocket(
      String orderId,
      String status,
      double lat,
      double lng, {
        required String maidName,
        required String maidPhone,
        required String maidEmail,
      }) async {
    int statusCode;
    switch (status.toLowerCase()) {
      case 'started':
        statusCode = 5;
        break;
      case 'completed':
        statusCode = 7;
        break;
      case 'cancelled':
        statusCode = 0;
        break;
      case 'accepted':
        statusCode = 2;
        break;
      default:
        statusCode = 1;
    }

    debugPrint(
        '📡 Socket Update -> orderId: $orderId, status: $status ($statusCode), lat: $lat, lng: $lng, maid: $maidName');

    final index = _orders.indexWhere((o) => o.orderId.toString() == orderId);
    if (index != -1) {
      _orders[index] = _orders[index].copyWith(
        status: statusCode,
        maidLat: lat,
        maidLng: lng,
        maidName: maidName,
        maidPhone: maidPhone,
        maidEmail: maidEmail,
      );
      notifyListeners();
    }

    if (_orderDetails?.orderId.toString() == orderId) {
      _orderDetails = _orderDetails?.copyWith(
        status: statusCode,
        maidLat: lat,
        maidLng: lng,
        maidName: maidName,
        maidPhone: maidPhone,
        maidEmail: maidEmail,
      );
      notifyListeners();
    }

    // Save full maid info to SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString('maid_info') ?? '{}';
    final Map<String, dynamic> map = jsonDecode(data);
    map[orderId] = {
      'maidName': maidName,
      'maidPhone': maidPhone,
      'maidEmail': maidEmail,
      'maidLat': lat,
      'maidLng': lng,
      'status': status,
    };
    await prefs.setString('maid_info', jsonEncode(map));

    debugPrint('💾 Maid info saved for order $orderId');
  }

  @override
  void dispose() {
    _isDisposed = true;
    super.dispose();
  }
}
