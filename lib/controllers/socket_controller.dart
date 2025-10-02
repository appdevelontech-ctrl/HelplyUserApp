
import 'package:flutter/foundation.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:provider/provider.dart';
import '../controllers/order_controller.dart';
import '../models/order_model.dart';
import 'package:flutter/material.dart';

class SocketController with ChangeNotifier {
static final SocketController _instance = SocketController._internal();
factory SocketController() => _instance;
SocketController._internal();

IO.Socket? socket;
bool _isConnected = false;
bool _isDisposed = false;
final List<Map<String, dynamic>> _pendingMessages = [];
int _reconnectionAttempts = 0;
static const int _maxReconnectionAttempts = 5;

bool get isConnected => _isConnected;

void connect({BuildContext? context}) {
if (_isDisposed) return;

if (socket != null && socket!.connected) {
print('🔌 Socket already connected at ${DateTime.now().toIso8601String()}');
return;
}

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

if (socket == null) {
print('⚠️ Socket initialization failed at ${DateTime.now().toIso8601String()}');
return;
}

socket!.onConnect((_) {
_isConnected = true;
_reconnectionAttempts = 0;
print('🔌 Socket connected ✅ at ${DateTime.now().toIso8601String()}');
notifyListeners();
if (_pendingMessages.isNotEmpty) {
for (var msg in _pendingMessages) {
socket!.emit('chat message', msg);
print('📤 Flushed queued message: $msg at ${DateTime.now().toIso8601String()}');
}
_pendingMessages.clear();
}
});

socket!.onDisconnect((_) {
_isConnected = false;
print('🔌 Socket disconnected ❌ at ${DateTime.now().toIso8601String()}');
notifyListeners();
_reconnect(context);
});

socket!.onConnectError((error) {
_isConnected = false;
print('❌ Socket connect error: $error at ${DateTime.now().toIso8601String()}');
notifyListeners();
_reconnect(context);
});

socket!.onError((error) {
print('❌ Socket error: $error at ${DateTime.now().toIso8601String()}');
});

socket!.on('maid_started_order', (data) {
if (socket == null || !socket!.connected) {
print('⚠️ Socket not connected, dropping maid_started_order at ${DateTime.now().toIso8601String()}');
return;
}
print('📩 Received maid_started_order raw data: $data at ${DateTime.now().toIso8601String()}');
if (data is Map) {
try {
final orderId = data['orderId']?.toString() ?? data['orderDetails']?['orderId']?.toString();
if (orderId == null) throw Exception('orderId not found in payload');
final orderDetails = data['orderDetails'] as Map? ?? {};
final maidInfo = {
'maidName': data['maidName'] as String? ?? 'Unknown Maid',
'maidPhone': data['maidPhone'] as String? ?? '',
'maidEmail': data['maidEmail'] as String? ?? '',
'maidLat': double.tryParse(data['maidLat'].toString()) ??
(orderDetails['latitude'] != null ? double.tryParse(orderDetails['latitude'].toString()) ?? 0.0 : 0.0) ??
(orderDetails['lat'] != null ? double.tryParse(orderDetails['lat'].toString()) ?? 0.0 : 0.0),
'maidLng': double.tryParse(data['maidLng'].toString()) ??
(orderDetails['longitude'] != null ? double.tryParse(orderDetails['longitude'].toString()) ?? 0.0 : 0.0) ??
(orderDetails['lng'] != null ? double.tryParse(orderDetails['lng'].toString()) ?? 0.0 : 0.0),
'status': data['status'] as String? ?? 'Started',
};
print('📦 Processed maid info for orderId: $orderId - $maidInfo at ${DateTime.now().toIso8601String()}');
_updateOrderWithMaidInfo(orderId, maidInfo, context);
} catch (e) {
print('❌ Error processing maid_started_order: $e - Raw data: $data at ${DateTime.now().toIso8601String()}');
}
} else {
print('⚠️ Invalid maid_started_order data format: $data at ${DateTime.now().toIso8601String()}');
}
});

socket!.on('chat message', (data) {
print('📩 Received chat message: $data at ${DateTime.now().toIso8601String()}');
});
}

void _reconnect(BuildContext? context) {
if (_reconnectionAttempts < _maxReconnectionAttempts) {
_reconnectionAttempts++;
print('🔄 Reconnecting attempt #$_reconnectionAttempts at ${DateTime.now().toIso8601String()}');
Future.delayed(const Duration(seconds: 2), () => connect(context: context));
} else {
print('⚠️ Max reconnection attempts reached at ${DateTime.now().toIso8601String()}');
}
}

void _updateOrderWithMaidInfo(String orderId, Map<String, dynamic> maidInfo, BuildContext? context) {
if (context != null) {
final orderController = Provider.of<OrderController>(context, listen: false);
orderController.updateMaidInfo(orderId, maidInfo);
print('✅ Updated OrderController with maid info for orderId: $orderId at ${DateTime.now().toIso8601String()}');
} else {
print('⚠️ Context is null, unable to update OrderController at ${DateTime.now().toIso8601String()}');
}
}

Future<void> sendOrderNotification(Map<String, dynamic> payload) async {
if (_isDisposed) return;

if (!_isConnected) {
print('⚠️ Socket not connected, saving to queue... at ${DateTime.now().toIso8601String()}');
_pendingMessages.add(payload);
return;
}

try {
print('📤 Sending order notification: $payload at ${DateTime.now().toIso8601String()}');
socket!.emit('chat message', payload);
print('✅ Order notification sent successfully at ${DateTime.now().toIso8601String()}');
} catch (e) {
print('❌ Error sending order notification: $e at ${DateTime.now().toIso8601String()}');
}
}

void trackOrder(String orderId) {
if (_isConnected && socket != null) {
socket!.emit('track_order', {'orderId': orderId});
print('📤 Tracking order: $orderId at ${DateTime.now().toIso8601String()}');
} else {
print('⚠️ Socket not connected or not initialized, cannot track order: $orderId at ${DateTime.now().toIso8601String()}');
}
}

@override
void dispose() {
_isDisposed = true;
if (socket != null && socket!.connected) {
socket!.disconnect();
}
super.dispose();
print('🗑️ SocketController disposed at ${DateTime.now().toIso8601String()}');
}
}
