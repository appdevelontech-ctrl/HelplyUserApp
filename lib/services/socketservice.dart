import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;

/// 🔥 USER SIDE LIVE TRACKING SOCKET CONTROLLER (FINAL FIX)
class SocketLiveTrackingController extends ChangeNotifier {
  IO.Socket? _socket;

  final String _baseUrl = "wss://backend-olxs.onrender.com";

  bool _isConnected = false;
  bool _isConnecting = false;
  bool _disposed = false;

  int _reconnectAttempts = 0;
  static const int _maxReconnectAttempts = 9999;

  /// 🔴 CALLBACK → UI
  Function(String orderId, Map<String, dynamic> maidInfo)?
  onLiveTrackingUpdate;

  bool get isConnected => _isConnected;

  // ----------------------------------------------------------
  // 🔌 CONNECT (STRICT & SAFE)
  // ----------------------------------------------------------
  void connect() {
    if (_disposed || _isConnected || _isConnecting) return;

    _isConnecting = true;

    _socket = IO.io(
      _baseUrl,
      {
        'transports': ['websocket'],
        'autoConnect': false,
        'reconnection': true,
        'reconnectionAttempts': 10,
        'reconnectionDelay': 2000,
      },
    );

    /// 🔥 REMOVE OLD LISTENERS
    _socket!.off('chat message');

    _socket!.onConnect((_) {
      debugPrint("🟢 USER TRACKING SOCKET CONNECTED");
      _isConnected = true;
      _isConnecting = false;
      _reconnectAttempts = 0;
      notifyListeners();
    });

    // ----------------------------------------------------------
    // 📡 MAIN LISTENER (ONLY LIVE LOCATION)
    // ----------------------------------------------------------
    _socket!.on('chat message', (data) async {
      if (_disposed || data == null || data is! Map) return;

      /// ❌ IGNORE EVERYTHING ELSE
      if (data['type'] != 'maid_live_location') {
        debugPrint("⛔ Ignored non-live event");
        return;
      }

      final orderId = data['orderId']?.toString();
      if (orderId == null || orderId.isEmpty) {
        debugPrint("⛔ Ignored live event without orderId: $data");
        return;
      }

      /// 🔥 SUPPORT BOTH lat/lng & maidLat/maidLng
      final lat = (data['maidLat'] ?? data['lat']) as num?;
      final lng = (data['maidLng'] ?? data['lng']) as num?;

      if (lat == null || lng == null || lat == 0 || lng == 0) {
        debugPrint("⛔ Ignored invalid location: $data");
        return;
      }

      /// ✅ NORMALIZE PAYLOAD
      final cleanData = {
        "type": "maid_live_location",
        "orderId": orderId,
        "maidName": data['maidName'],
        "maidPhone": data['maidPhone'],
        "maidLat": lat,
        "maidLng": lng,
        "updatedAt": data['updatedAt'] ?? DateTime.now().toIso8601String(),
      };

      debugPrint("📡 LIVE TRACK UPDATE → $orderId → $cleanData");

      await _saveMaidTracking(orderId, cleanData);
      onLiveTrackingUpdate?.call(orderId, cleanData);
    });

    // ----------------------------------------------------------
    // 🔄 DISCONNECT / RECONNECT
    // ----------------------------------------------------------
    _socket!.onDisconnect((_) {
      debugPrint("🔴 USER TRACKING SOCKET DISCONNECTED");
      _isConnected = false;
      _isConnecting = false;
      _attemptReconnect();
    });

    _socket!.onConnectError((e) {
      debugPrint("❌ SOCKET CONNECT ERROR: $e");
      _isConnected = false;
      _isConnecting = false;
      _attemptReconnect();
    });

    _socket!.connect();
  }

  // ----------------------------------------------------------
  // 🔄 AUTO RECONNECT
  // ----------------------------------------------------------
  void _attemptReconnect() {
    if (_disposed || _isConnected || _isConnecting) return;
    if (_reconnectAttempts >= _maxReconnectAttempts) return;

    _reconnectAttempts++;

    Future.delayed(const Duration(seconds: 3), () {
      if (!_disposed && !_isConnected) {
        debugPrint("🔄 RECONNECT ATTEMPT $_reconnectAttempts");
        connect();
      }
    });
  }

  // ----------------------------------------------------------
  // 💾 SAVE TRACKING DATA
  // ----------------------------------------------------------
  Future<void> _saveMaidTracking(
      String orderId, Map<String, dynamic> data) async {
    final prefs = await SharedPreferences.getInstance();
    final uid = prefs.getString('userId') ?? 'guest_user';
    final key = "maid_info_$uid";

    Map<String, dynamic> saved = {};
    final raw = prefs.getString(key);
    if (raw != null) {
      saved = jsonDecode(raw);
    }

    saved[orderId] = data;
    await prefs.setString(key, jsonEncode(saved));
  }

  // ----------------------------------------------------------
  // 🛑 STOP TRACKING
  // ----------------------------------------------------------
  Future<void> stopTrackingForOrder(String orderId) async {
    final prefs = await SharedPreferences.getInstance();
    final uid = prefs.getString('userId') ?? 'guest_user';
    final key = "maid_info_$uid";

    final raw = prefs.getString(key);
    if (raw == null) return;

    final saved = jsonDecode(raw);
    saved.remove(orderId);

    await prefs.setString(key, jsonEncode(saved));
    debugPrint("🛑 TRACKING STOPPED → $orderId");
  }

  // ----------------------------------------------------------
  // ❌ DISPOSE
  // ----------------------------------------------------------
  @override
  void dispose() {
    _disposed = true;
    _socket?.off('chat message');
    _socket?.disconnect();
    _socket?.dispose();
    _socket = null;
    super.dispose();
  }
}
