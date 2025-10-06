import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import '../controllers/order_controller.dart';
import '../controllers/socket_controller.dart';
import '../models/order_model.dart';
import '../services/api_services.dart';
import '../services/payment_service.dart';
import 'package:shimmer/shimmer.dart';
import 'live_tracking_page.dart';
import 'order_detail_page.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class UserOrdersPage extends StatefulWidget {
  const UserOrdersPage({super.key});

  @override
  State<UserOrdersPage> createState() => _UserOrdersPageState();
}

class _UserOrdersPageState extends State<UserOrdersPage> with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  Map<String, Map<String, dynamic>> _maidInfoMap = {};

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _animationController.forward();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeSocketAndFetchOrders();
    });
  }

  Future<void> _initializeSocketAndFetchOrders() async {
    final socketController = Provider.of<SocketController>(context, listen: false);
    final orderController = Provider.of<OrderController>(context, listen: false);
    socketController.attachOrderController(orderController);
    socketController.connect();
    await _fetchOrdersAndMerge();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _fetchOrdersAndMerge() async {
    await EasyLoading.show(status: 'Fetching orders...');
    await _loadMaidInfo();

    final orderController = context.read<OrderController>();
    try {
      await orderController.fetchOrders();
      _mergeSavedMaidInfo(orderController.orders);
      await EasyLoading.dismiss();
    } catch (e) {
      await EasyLoading.showError('Failed to load orders: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load orders: $e')),
        );
      }
    }
  }

  Future<void> _cancelOrderWithComment(String orderId, String comment) async {
    try {
      await EasyLoading.show(status: 'Cancelling order...');
      final response = await http.put(
        Uri.parse('https://backend-olxs.onrender.com/cancel-order/$orderId'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({"comment": comment}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          final prefs = await SharedPreferences.getInstance();
          final savedData = prefs.getString('maid_info') ?? '{}';
          final Map<String, dynamic> map = jsonDecode(savedData);
          map.remove(orderId);
          await prefs.setString('maid_info', jsonEncode(map));

          await _fetchOrdersAndMerge();
          await EasyLoading.showSuccess('Order cancelled successfully');
        } else {
          throw Exception('Failed to cancel order: ${data['message']}');
        }
      } else {
        throw Exception('Failed to cancel order: ${response.statusCode}');
      }
    } catch (e) {
      await EasyLoading.showError('Error cancelling order: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error cancelling order: $e')),
        );
      }
    }
  }

  void _mergeSavedMaidInfo(List<Order> orders) {
    for (var i = 0; i < orders.length; i++) {
      final orderIdStr = orders[i].id;
      Order updatedOrder = orders[i];

      if (_maidInfoMap.containsKey(orderIdStr)) {
        final info = _maidInfoMap[orderIdStr]!;
        final savedUpdatedAt = info['updatedAt'] as String?;
        final serverUpdatedAt = updatedOrder.updatedAt;
        bool shouldUpdateStatus = false;

        if (savedUpdatedAt != null && serverUpdatedAt != null) {
          final savedDate = DateTime.tryParse(savedUpdatedAt);
          final serverDate = DateTime.tryParse(serverUpdatedAt);
          if (savedDate != null && serverDate != null && savedDate.isAfter(serverDate)) {
            shouldUpdateStatus = true;
          }
        }

        updatedOrder = updatedOrder.copyWith(
          maidName: info['maidName'] ?? updatedOrder.maidName,
          maidPhone: info['maidPhone'] ?? updatedOrder.maidPhone,
          maidEmail: info['maidEmail'] ?? updatedOrder.maidEmail,
          status: shouldUpdateStatus ? _statusCodeFromServer(info['status']) : updatedOrder.status,
          maidLat: (info['maidLat'] as num?)?.toDouble() ?? updatedOrder.maidLat,
          maidLng: (info['maidLng'] as num?)?.toDouble() ?? updatedOrder.maidLng,
        );
        orders[i] = updatedOrder;
      }
    }

    if (mounted) setState(() {});
  }

  int _statusCodeFromServer(dynamic status) {
    if (status is int) {
      if ([0, 1, 2, 5, 7].contains(status)) return status;
      debugPrint('⚠️ Invalid integer status received: $status, defaulting to 1 (Placed)');
      return 1;
    }
    if (status is String) {
      switch (status.toLowerCase()) {
        case 'cancel': case 'cancelled': case 'canceled': return 0;
        case 'placed': return 1;
        case 'accept': case 'accepted': return 2;
        case 'started': return 5;
        case 'complete': case 'completed': return 7;
        default:
          debugPrint('⚠️ Unrecognized status string: $status, defaulting to 1 (Placed)');
          return 1;
      }
    }
    debugPrint('⚠️ Invalid status type: $status, defaulting to 1 (Placed)');
    return 1;
  }

  Future<void> _loadMaidInfo() async {
    final prefs = await SharedPreferences.getInstance();
    final savedData = prefs.getString('maid_info');
    if (savedData != null) {
      try {
        final decoded = jsonDecode(savedData) as Map<String, dynamic>;
        _maidInfoMap = decoded.map((key, value) => MapEntry(key, value));
        if (mounted) setState(() {});
      } catch (e) {
        debugPrint('❌ Error parsing maid_info: $e');
      }
    }
  }

  void _showCancelDialog(Order order) {
    final TextEditingController commentController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Cancel Order"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text("Please provide a reason for cancellation:"),
            const SizedBox(height: 12),
            TextField(
              controller: commentController,
              decoration: const InputDecoration(
                hintText: "Enter comment",
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () {
              final comment = commentController.text.trim();
              if (comment.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Comment cannot be empty")),
                );
                return;
              }
              Navigator.pop(context);
              _cancelOrderWithComment(order.id, comment);
            },
            child: const Text("Confirm"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ScaffoldMessenger(
      child: Scaffold(
        extendBodyBehindAppBar: true,
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Colors.white, Color(0xFFF8F9FA)],
            ),
          ),
          child: RefreshIndicator(
            onRefresh: _fetchOrdersAndMerge,
            color: Colors.orangeAccent,
            child: Consumer<OrderController>(
              builder: (context, controller, child) {
                if (controller.isOrdersLoading) return _buildShimmerLoader();
                if (controller.orders.isEmpty) {
                  return const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.shopping_bag_outlined, size: 80, color: Colors.grey),
                        SizedBox(height: 16),
                        Text(
                          "No orders found.",
                          style: TextStyle(fontSize: 18, color: Colors.grey, fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                  );
                }

                final sortedOrders = List<Order>.from(controller.orders)
                  ..sort((a, b) => b.orderId.compareTo(a.orderId));

                return CustomScrollView(
                  slivers: [
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: FadeTransition(
                          opacity: _fadeAnimation,
                          child: Column(
                            children: [
                              Text(
                                'Your Recent Orders',
                                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                              ),
                              const SizedBox(height: 16),
                            ],
                          ),
                        ),
                      ),
                    ),
                    SliverList(
                      delegate: SliverChildBuilderDelegate(
                            (context, index) {
                          Order order = sortedOrders[index];
                          return FadeTransition(
                            opacity: Tween<double>(begin: 0.0, end: 1.0).animate(
                              CurvedAnimation(
                                parent: _animationController,
                                curve: Interval(0.0, 1.0, curve: Curves.easeOut),
                              ),
                            ),
                            child: _buildOrderCard(context, order, controller),
                          );
                        },
                        childCount: sortedOrders.length,
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildShimmerLoader() {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: 5,
        itemBuilder: (context, index) => Card(
          margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          elevation: 4,
          child: ListTile(
            contentPadding: const EdgeInsets.all(16),
            leading: const CircleAvatar(backgroundColor: Colors.grey),
            title: Container(height: 20, color: Colors.grey),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 8),
                Container(height: 14, width: 100, color: Colors.grey),
                const SizedBox(height: 4),
                Container(height: 14, width: 80, color: Colors.grey),
                const SizedBox(height: 4),
                Container(height: 14, width: 120, color: Colors.grey),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildOrderCard(BuildContext context, Order order, OrderController controller) {
    final paymentService = PaymentService(context, ApiServices());
    final socketController = Provider.of<SocketController>(context, listen: false);

    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => OrderDetailsPage(
              orderId: order.id,
              orderController: controller,
            ),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
        child: Card(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: Colors.orangeAccent, width: 0.5),
          ),
          elevation: 8,
          shadowColor: Colors.orangeAccent.withOpacity(0.3),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: LinearGradient(
                colors: [Colors.white, Colors.grey[50]!],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildOrderHeader(order),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      if (order.status != 7 && order.status != 0)
                        Padding(
                          padding: const EdgeInsets.only(right: 8.0),
                          child: ElevatedButton.icon(
                            onPressed: () => _showCancelDialog(order),
                            icon: const Icon(Icons.cancel, color: Colors.white),
                            label: const Text("Cancel Order", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.redAccent,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            ),
                          ),
                        ),
                      if (order.status == 7)
                        _buildPayButton(order, paymentService),
                      if (order.status == 5 && order.maidLat != null && order.maidLng != null)
                        _buildLiveTrackButton(order, socketController),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildOrderHeader(Order order) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: Colors.orangeAccent,
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.shopping_bag,
            color: Colors.white,
            size: 24,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Order #${order.orderId}',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black87),
                      ),
                      Text(
                        "₹${order.totalAmount.toStringAsFixed(2)}",
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.orangeAccent),
                      ),
                    ],
                  ),
                  _buildStatusChip(order.status),
                ],
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  Icon(Icons.payment, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(
                    "Payment: ${order.mode}",
                    style: TextStyle(fontSize: 14, color: Colors.grey[700], fontWeight: FontWeight.w500),
                  ),
                ],
              ),
              if (order.otp != null) ...[
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.lock_outline, size: 16, color: Colors.grey[600]),
                    const SizedBox(width: 4),
                    Text(
                      "OTP: ${order.otp}",
                      style: TextStyle(fontSize: 14, color: Colors.grey[700], fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(Icons.access_time, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(
                    "Date: ${DateFormat('dd MMM yyyy, hh:mm a').format(order.createdAt)}",
                    style: TextStyle(fontSize: 14, color: Colors.grey[600], fontStyle: FontStyle.italic),
                  ),
                ],
              ),
            ],
          ),
        ),
        Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey[600]),
      ],
    );
  }

  Widget _buildPayButton(Order order, PaymentService paymentService) {
    return Align(
      alignment: Alignment.centerRight,
      child: ElevatedButton.icon(
        onPressed: (order.payment == 1) ? null : () async {
          await EasyLoading.show(status: 'Initiating payment...');
          try {
            await paymentService.initiatePayment(order);
            await EasyLoading.showSuccess('Payment initiated successfully');
          } catch (e) {
            await EasyLoading.showError('Failed to initiate payment: $e');
          }
        },
        icon: Icon((order.payment == 1) ? Icons.check : Icons.payment),
        label: Text((order.payment == 1) ? "Paid" : "Pay Now", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        style: ElevatedButton.styleFrom(
          backgroundColor: (order.payment == 1) ? Colors.green : Colors.orangeAccent,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        ),
      ),
    );
  }

  Widget _buildLiveTrackButton(Order order, SocketController socketController) {
    return Align(
      alignment: Alignment.centerRight,
      child: ElevatedButton.icon(
        onPressed: () => _onLiveTrackPressed(order, socketController),
        icon: const Icon(Icons.location_on, color: Colors.white),
        label: const Text("Live Track", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.blueAccent,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        ),
      ),
    );
  }

  void _onLiveTrackPressed(Order order, SocketController socketController) {
    final maidLat = order.maidLat ?? 0.0;
    final maidLng = order.maidLng ?? 0.0;
    if (maidLat == 0.0 && maidLng == 0.0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Maid location not yet available. Please wait.')),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => LiveTrackingPage(
          orderId: order.id,
          maidLat: maidLat,
          maidLng: maidLng,
          userLat: order.userLat ?? 0.0,
          userLng: order.userLng ?? 0.0,
          maidName: order.maidName ?? 'Unknown',
          maidPhone: order.maidPhone ?? '',
          maidEmail: order.maidEmail ?? '',
          orderStatus: order.status,
        ),
      ),
    );
  }

  Widget _buildStatusChip(int status) {
    String statusText = _statusText(status);
    IconData icon;
    Color chipColor;
    Color iconColor;

    switch (status) {
      case 0:
        chipColor = Colors.red.shade100;
        icon = Icons.cancel_outlined;
        iconColor = Colors.red.shade700;
        break;
      case 1:
        chipColor = Colors.orange.shade100;
        icon = Icons.pending_outlined;
        iconColor = Colors.orange.shade700;
        break;
      case 2:
        chipColor = Colors.purple.shade100;
        icon = Icons.check_circle_outline;
        iconColor = Colors.purple.shade700;
        break;
      case 5:
        chipColor = Colors.blue.shade100;
        icon = Icons.location_on_outlined;
        iconColor = Colors.blue.shade700;
        break;
      case 7:
        chipColor = Colors.green.shade100;
        icon = Icons.verified;
        iconColor = Colors.green.shade700;
        break;
      default:
        chipColor = Colors.grey.shade100;
        icon = Icons.help_outline;
        iconColor = Colors.grey.shade700;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: chipColor,
        borderRadius: BorderRadius.circular(20),
        border: status == 7 ? Border.all(color: Colors.green.shade700, width: 1.5) : null,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: status == 7 ? 18 : 16, color: iconColor),
          const SizedBox(width: 4),
          Text(
            statusText,
            style: TextStyle(
              fontSize: status == 7 ? 14 : 12,
              fontWeight: FontWeight.w700,
              color: iconColor,
            ),
          ),
        ],
      ),
    );
  }

  String _statusText(int status) {
    switch (status) {
      case 0: return "Cancelled";
      case 1: return "Placed";
      case 2: return "Accepted";
      case 5: return "Started";
      case 7: return "Completed";
      default: return "Unknown";
    }
  }
}