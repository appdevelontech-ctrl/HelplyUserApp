import 'package:socket_io_client/socket_io_client.dart' as IO;

class SocketService {
  static final SocketService _instance = SocketService._internal();
  factory SocketService() => _instance;
  SocketService._internal();

  IO.Socket? socket;

  void initSocket() {
    // Only connect once
    if (socket != null && socket!.connected) return;

    socket = IO.io(
      'https://backend-olxs.onrender.com',
      <String, dynamic>{
        'transports': ['websocket'],
        'autoConnect': true,
      },
    );

    socket?.onConnect((_) {
      print('✅ Connected to socket server');
    });

    socket?.onDisconnect((_) {
      print('⚠️ Disconnected from socket server');
    });

    // Listen for order status updates
    socket?.on('order_status_update', (data) {
      print('🔔 Order ${data['orderId']} updated status: ${data['status']}');
    });
  }

  void trackOrder(String orderId) {
    if (socket != null && socket!.connected) {
      socket!.emit('track_order', {'orderId': orderId});
      print('📡 Tracking order $orderId');
    }
  }
}
