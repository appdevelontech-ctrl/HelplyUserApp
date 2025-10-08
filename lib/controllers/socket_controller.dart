import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:shared_preferences/shared_preferences.dart';
import '../controllers/order_controller.dart';

class SocketController with ChangeNotifier {
  static final SocketController _instance = SocketController._internal();
  factory SocketController() => _instance;
  SocketController._internal();

  IO.Socket? socket;
  bool _isConnected = false;
  bool _isDisposed = false;
  final List<Map<String, dynamic>> _pendingMessages = [];
  int _reconnectionAttempts = 0;
  static const int _maxReconnectionAttempts = 9999;

  final Set<String> _liveOrders = {};
  OrderController? orderController;


  /// Global callback for maid_started_order
  void Function(String orderId, Map<String, dynamic> maidInfo)? onMaidStartedOrder;

  /// Attach OrderController to update orders automatically
  void attachOrderController(OrderController controller) {
    orderController = controller;
  }

  bool get isConnected => _isConnected;
  bool isOrderLive(String orderId) => _liveOrders.contains(orderId);

  /// Connect to socket
  void connect() {
    if (_isDisposed) return;
    if (socket != null && socket!.connected) return;

    socket = IO.io(
      'wss://backend-olxs.onrender.com',
      IO.OptionBuilder()
          .setTransports(['websocket'])
          .enableReconnection()
          .setReconnectionDelay(2000)
          .setReconnectionAttempts(_maxReconnectionAttempts)
          .enableForceNew()
          .enableAutoConnect()
          .setTimeout(20000)
          .build(),
    );

    socket?.onConnect((_) async {
      _isConnected = true;
      _reconnectionAttempts = 0;
      notifyListeners();

      for (var msg in _pendingMessages) socket!.emit('chat message', msg);
      _pendingMessages.clear();
      print('🔌 Socket connected ✅');

      // Load persisted maid info on reconnect
      await _loadPersistedMaidInfo();
    });

    socket?.onDisconnect((_) {
      _isConnected = false;
      notifyListeners();
      print('🔌 Socket disconnected ❌');
      _reconnect();
    });

    socket?.onConnectError((error) {
      _isConnected = false;
      notifyListeners();
      print('❌ Socket connect error: $error');
      _reconnect();
    });

    socket?.onError((error) {
      print('❌ Socket error: $error');
    });

    socket?.on('chat message', (data) async {
      if (data is! Map<String, dynamic>) return;

      final orderData = data['order'] as Map<String, dynamic>? ?? {};
      final orderDetails = orderData['orderDetails'] as Map<String, dynamic>? ?? {};
      final orderId = orderData['orderId']?.toString() ??
          orderDetails['orderId']?.toString();
      if (orderId == null) return;

      final maidLat = _parseDouble(orderData['maidLat']);
      final maidLng = _parseDouble(orderData['maidLng']);

      final maidInfo = <String, dynamic>{
        'maidName': orderData['maidName'] ?? 'Unknown Maid',
        'maidPhone': orderData['maidPhone'] ?? '',
        'maidEmail': orderData['maidEmail'] ?? '',
        'maidLat': maidLat,
        'maidLng': maidLng,
        'status': orderData['status'] ?? 'Started',
      };

      print('📡 Received from socket: $maidInfo');

      // Update live orders
      updateOrderLiveStatus(orderId, true);

      // Call global callback
      if (onMaidStartedOrder != null) {
        onMaidStartedOrder!(orderId, maidInfo);
      }

      // Update OrderController with full maid info
      if (orderController != null) {
        orderController!.updateOrderStatusFromSocket(
          orderId,
          maidInfo['status'].toString(),
          maidLat,
          maidLng,
          maidName: maidInfo['maidName'],
          maidPhone: maidInfo['maidPhone'],
          maidEmail: maidInfo['maidEmail'],
        );
      }

      // Persist maid info globally
      await _persistMaidInfo(orderId, maidInfo);
    });
  }

  double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }

  void _reconnect() {
    if (_reconnectionAttempts < _maxReconnectionAttempts) {
      _reconnectionAttempts++;
      Future.delayed(const Duration(seconds: 2), () => connect());
    } else {
      print('⚠️ Max reconnection attempts reached');
    }
  }

  Future<void> sendOrderNotification(Map<String, dynamic> payload) async {
    if (!_isConnected) {
      _pendingMessages.add(payload);
      return;
    }
    socket?.emit('chat message', payload);
  }

  void updateOrderLiveStatus(String orderId, bool isLive) {
    if (isLive) {
      _liveOrders.add(orderId);
    } else {
      _liveOrders.remove(orderId);
    }
    notifyListeners();
  }

  void trackOrder(String orderId) => updateOrderLiveStatus(orderId, true);
  void stopTracking(String orderId) => updateOrderLiveStatus(orderId, false);

  /// Persist maid info for each order using SharedPreferences
  Future<void> _persistMaidInfo(String orderId, Map<String, dynamic> maidInfo) async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString('maid_info') ?? '{}';
    final Map<String, dynamic> map = jsonDecode(data);
    map[orderId] = maidInfo;
    await prefs.setString('maid_info', jsonEncode(map));
    debugPrint('💾 Maid info saved for order $orderId: $maidInfo');
  }

  /// Load persisted maid info and update OrderController
  Future<void> _loadPersistedMaidInfo() async {
    if (orderController == null) return;
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString('maid_info') ?? '{}';
    final Map<String, dynamic> map = jsonDecode(data);

    map.forEach((orderId, maidInfo) {
      final lat = maidInfo['maidLat'] ?? 0.0;
      final lng = maidInfo['maidLng'] ?? 0.0;
      orderController!.updateOrderStatusFromSocket(
        orderId,
        maidInfo['status'].toString(),
        lat,
        lng,
        maidName: maidInfo['maidName'],
        maidPhone: maidInfo['maidPhone'],
        maidEmail: maidInfo['maidEmail'],
      );
    });

    debugPrint('📌 Restored maid info from SharedPreferences: $map');
  }

  @override
  void dispose() {
    _isDisposed = true;
    socket?.disconnect();
    super.dispose();
  }
}
