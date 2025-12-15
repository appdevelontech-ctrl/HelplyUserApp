import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:shared_preferences/shared_preferences.dart';

class SocketController extends ChangeNotifier {
  static final SocketController _instance = SocketController._internal();
  factory SocketController() => _instance;
  SocketController._internal();

  IO.Socket? _socket;

  final String _baseUrl = "wss://backend-olxs.onrender.com";

  bool _isConnected = false;
  bool _isConnecting = false;
  bool _disposed = false;

  int _reconnectAttempts = 0;
  static const int _maxReconnectAttempts = 9999;

  // ============================================================
  // 🔔 CALLBACKS
  // ============================================================

  /// 🔔 Order create / status / assign events
  void Function(String orderId, Map<String, dynamic> orderInfo)?
  onOrderEvent;

  /// 📍 Live maid tracking
  void Function(String orderId, Map<String, dynamic> liveInfo)?
  onLiveTracking;

  bool get isConnected => _isConnected;

  // ============================================================
  // 🔌 CONNECT
  // ============================================================

  void connect() {
    if (_disposed || _isConnected || _isConnecting) return;

    _isConnecting = true;

    _socket = IO.io(
      _baseUrl,
      IO.OptionBuilder()
          .setTransports(['websocket'])
          .enableReconnection()
          .setReconnectionAttempts(10)
          .setReconnectionDelay(2000)
          .enableForceNew()
          .build(),
    );

    _socket!.onConnect((_) {
      _isConnected = true;
      _isConnecting = false;
      _reconnectAttempts = 0;
      debugPrint("🟢 SOCKET CONNECTED");
      notifyListeners();
    });

    // ============================================================
    // 📩 MAIN SOCKET LISTENER
    // ============================================================

    _socket!.on('chat message', (data) async {
      if (_disposed) return;

      if (data == null || data is! Map<String, dynamic>) {
        debugPrint("⛔ INVALID SOCKET PAYLOAD → $data");
        return;
      }

      final String? type = data['type']?.toString();

      debugPrint("📨 SOCKET MESSAGE RECEIVED → type=$type");
      debugPrint("📦 RAW DATA → $data");

      // ==========================================================
      // 📍 LIVE TRACKING (maid → user)
      // ==========================================================
      if (type == 'maid_live_location') {
        final orderId = data['orderId']?.toString();

        if (orderId == null || orderId.isEmpty) {
          debugPrint("⛔ LIVE TRACK WITHOUT ORDER ID");
          return;
        }

        final lat = _parseDouble(data['maidLat'] ?? data['lat']);
        final lng = _parseDouble(data['maidLng'] ?? data['lng']);

        if (lat == 0 || lng == 0) {
          debugPrint("⛔ INVALID MAID LOCATION → lat=$lat lng=$lng");
          return;
        }

        final liveInfo = {
          'orderId': orderId,
          'maidName': data['maidName'] ?? 'Maid',
          'maidPhone': data['maidPhone'] ?? '',
          'maidLat': lat,
          'maidLng': lng,
          'updatedAt': DateTime.now().toIso8601String(),
        };

        debugPrint(
            "📡 LIVE TRACK UPDATE → order=$orderId → ($lat,$lng)");

        // 💾 persist last location
        await _saveLiveTracking(orderId, liveInfo);

        // 🔔 notify UI
        if (onLiveTracking != null) {
          debugPrint("🚀 onLiveTracking CALLBACK FIRED");
          onLiveTracking!(orderId, liveInfo);
        } else {
          debugPrint("⚠️ onLiveTracking CALLBACK IS NULL");
        }

        return; // ⛔ IMPORTANT: stop here
      }

      // ==========================================================
      // 🔔 ORDER / NOTIFICATION EVENTS
      // ==========================================================
      final orderData =
      (data['order'] is Map<String, dynamic>)
          ? data['order'] as Map<String, dynamic>
          : <String, dynamic>{};

      final orderId = (data['orderId'] ??
          orderData['orderId'] ??
          orderData['_id'])
          ?.toString();

      if (orderId == null || orderId.isEmpty) {
        debugPrint("⛔ ORDER EVENT WITHOUT ORDER ID");
        return;
      }

      final orderInfo = {
        'orderId': orderId,
        'status': orderData['status'] ?? data['status'],
        'maidName': orderData['maidName'],
        'maidPhone': orderData['maidPhone'],
        'maidLat': _parseDouble(orderData['maidLat']),
        'maidLng': _parseDouble(orderData['maidLng']),
      };

      debugPrint("🔔 ORDER EVENT → order=$orderId");
      debugPrint("📦 ORDER INFO → $orderInfo");

      await _saveOrderInfo(orderId, orderInfo);

      if (onOrderEvent != null) {
        debugPrint("🚀 onOrderEvent CALLBACK FIRED");
        onOrderEvent!(orderId, orderInfo);
      } else {
        debugPrint("⚠️ onOrderEvent CALLBACK IS NULL");
      }
    });


    // ============================================================
    // 🔄 DISCONNECT & RECONNECT
    // ============================================================

    _socket!.onDisconnect((_) {
      _isConnected = false;
      _isConnecting = false;
      debugPrint("🔴 SOCKET DISCONNECTED");
      notifyListeners();
      _attemptReconnect();
    });

    _socket!.onConnectError((e) {
      _isConnected = false;
      _isConnecting = false;
      debugPrint("❌ SOCKET CONNECT ERROR: $e");
      _attemptReconnect();
    });

    _socket!.connect();
  }

  // ============================================================
  // 🔄 AUTO RECONNECT
  // ============================================================

  void _attemptReconnect() {
    if (_disposed || _isConnected || _isConnecting) return;
    if (_reconnectAttempts >= _maxReconnectAttempts) return;

    _reconnectAttempts++;
    Future.delayed(const Duration(seconds: 3), connect);
  }

  // ============================================================
  // 📤 EMIT ORDER NOTIFICATION (USER → SERVER)
  // ============================================================

  void sendOrderNotification(Map<String, dynamic> payload) {
    if (!_isConnected) return;
    _socket?.emit('chat message', payload);
    debugPrint("📤 ORDER NOTIFICATION SENT → $payload");
  }

  // ============================================================
  // 💾 STORAGE
  // ============================================================

  Future<void> _saveLiveTracking(
      String orderId, Map<String, dynamic> data) async {
    final prefs = await SharedPreferences.getInstance();
    final uid = prefs.getString('userId') ?? 'guest_user';
    final key = 'maid_info_$uid';

    final raw = prefs.getString(key) ?? '{}';
    final map = jsonDecode(raw) as Map<String, dynamic>;
    map[orderId] = data;

    await prefs.setString(key, jsonEncode(map));
  }

  Future<void> _saveOrderInfo(
      String orderId, Map<String, dynamic> data) async {
    final prefs = await SharedPreferences.getInstance();
    final uid = prefs.getString('userId') ?? 'guest_user';
    final key = 'order_info_$uid';

    final raw = prefs.getString(key) ?? '{}';
    final map = jsonDecode(raw) as Map<String, dynamic>;
    map[orderId] = data;

    await prefs.setString(key, jsonEncode(map));
  }

  // ============================================================
  // 🧠 HELPERS
  // ============================================================

  double _parseDouble(dynamic v) {
    if (v == null) return 0;
    if (v is double) return v;
    if (v is int) return v.toDouble();
    if (v is String) return double.tryParse(v) ?? 0;
    return 0;
  }

  // ============================================================
  // ❌ DISPOSE
  // ============================================================

  @override
  void dispose() {
    _disposed = true;
    _socket?.disconnect();
    _socket?.dispose();
    _socket = null;
    super.dispose();
  }
}
