import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shimmer/shimmer.dart';

import '../controllers/order_controller.dart';
import '../controllers/socket_controller.dart';
import '../models/order_model.dart';
import '../services/api_services.dart';
import '../services/payment_service.dart';
import 'live_tracking_page.dart';
import 'order_detail_page.dart';

class UserOrdersPage extends StatefulWidget {
  const UserOrdersPage({super.key});

  @override
  State<UserOrdersPage> createState() => _UserOrdersPageState();
}

class _UserOrdersPageState extends State<UserOrdersPage> {
  bool _isInitialized = false;
  Map<String, Map<String, dynamic>> _maidInfoMap = {};

  @override
  void initState() {
    super.initState();
    _initialize();
  }
  Future<void> _initialize() async {
    if (_isInitialized) return;
    _isInitialized = true;

    final orderController = context.read<OrderController>();
    final socketController = context.read<SocketController>();

    await _loadMaidInfo();
    await orderController.fetchOrders(forceRefresh: true);

    _mergeSavedMaidInfo(orderController.orders);

    socketController.attachOrderController(orderController);

    socketController.onMaidStartedOrder = (orderId, data) async {
      print("⚡ REAL-TIME UPDATE for $orderId");

      await _loadMaidInfo();                     // refresh saved local tracking
      _mergeSavedMaidInfo(orderController.orders);

      if (mounted) setState(() {});              // 🔥 UI refresh FIX
    };

    socketController.connect();

    if (mounted) setState(() {});
  }



  Future<void> _fetchOrdersAndMerge(OrderController orderController, {bool forceRefresh = false}) async {
    await EasyLoading.show(status: 'Loading orders...');
    await _loadMaidInfo();

    try {
      await orderController.fetchOrders(forceRefresh: forceRefresh); // force fetch
      _mergeSavedMaidInfo(orderController.orders);
      if (mounted) await EasyLoading.dismiss();
    } catch (e) {
      if (mounted) await EasyLoading.showError('Failed to load orders: $e');
    }
  }
  Future<void> _loadMaidInfo() async {
    final prefs = await SharedPreferences.getInstance();
    final uid = prefs.getString('userId') ?? "unknown_user";
    final key = "maid_info_$uid";

    final savedData = prefs.getString(key);
    print("📦 Loaded maid info for user: $uid → $savedData");

    if (savedData != null) {
      _maidInfoMap = (jsonDecode(savedData) as Map<String, dynamic>)
          .map((k, v) => MapEntry(k, Map<String, dynamic>.from(v)));
    }
  }
  void _mergeSavedMaidInfo(List<Order> orders) {
    debugPrint("🔄 Merging saved tracking with active orders...");

    final orderController = context.read<OrderController>();

    for (var order in orders) {
      final key = order.id.toString();

      if (!_maidInfoMap.containsKey(key)) {
        debugPrint("❌ No saved maid data for order → $key");
        continue;
      }

      final saved = _maidInfoMap[key]!;
      debugPrint("✅ Restoring → $key → $saved");

      final updatedOrder = order.copyWith(
        maidName: saved['maidName'],
        maidPhone: saved['maidPhone'],
        maidEmail: saved['maidEmail'],
        maidLat: (saved['maidLat'] as num?)?.toDouble(),
        maidLng: (saved['maidLng'] as num?)?.toDouble(),
      );

      /// 🔥 UI list update
      final index = orders.indexOf(order);
      orders[index] = updatedOrder;

      /// 🔥 IMPORTANT: Controller cache update
      orderController.updateMaidInfo(order.id, saved);
    }

    if (mounted) setState(() {});
  }

  Future<void> _onRefresh() async {
    final orderController = context.read<OrderController>();

    await _loadMaidInfo();  // 🔥 Step 1: Load saved tracking first
    await orderController.fetchOrders(forceRefresh: true); // 🔥 Step 2: Fetch updated orders
    _mergeSavedMaidInfo(orderController.orders); // 🔥 Step 3: Re-apply tracking to new data

    if (mounted) setState(() {}); // 🔥 Step 4: Refresh UI
  }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _onRefresh,
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
                    Text("No orders found", style: TextStyle(fontSize: 18, color: Colors.grey)),
                  ],
                ),
              );
            }

            final orders = [...controller.orders]..sort((a, b) => b.orderId.compareTo(a.orderId));

            return ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: orders.length,
              itemBuilder: (context, i) => OrderCard(order: orders[i]),
            );
          },
        ),
      ),
    );
  }

  Widget _buildShimmerLoader() => Shimmer.fromColors(
    baseColor: Colors.grey[300]!,
    highlightColor: Colors.grey[100]!,
    child: ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: 5,
      itemBuilder: (context, i) => Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Container(height: 100, color: Colors.grey),
      ),
    ),
  );
}

class OrderCard extends StatelessWidget {
  final Order order;
  const OrderCard({super.key, required this.order});

  @override
  Widget build(BuildContext context) {
    final paymentService = PaymentService(context, ApiServices());
    final socketController = context.read<SocketController>();
    final theme = Theme.of(context);
    final isSmallScreen = MediaQuery.of(context).size.width < 600;

    return InkWell(
      onTap: () {
        final orderController = context.read<OrderController>();
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => OrderDetailsPage(
              orderId: order.id,
              orderController: orderController,
            ),
          ),
        );
      },
      child: Card(
        margin: EdgeInsets.symmetric(
          vertical: 8,
          horizontal: isSmallScreen ? 8 : 16,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        elevation: 6,
        shadowColor: theme.colorScheme.shadow.withOpacity(0.3),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(context, order, isSmallScreen),
              const SizedBox(height: 12),
              _buildActionButtons(
                context,
                order,
                paymentService,
                socketController,
                isSmallScreen,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, Order order, bool isSmallScreen) {
    final theme = Theme.of(context);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Icon Container
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [theme.colorScheme.primary, theme.colorScheme.primaryContainer],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Icon(
            Icons.shopping_bag_outlined,
            color: theme.colorScheme.onPrimary,
            size: isSmallScreen ? 24 : 32,
          ),
        ),
        const SizedBox(width: 12),

        // Order Info
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Order ID
              Text(
                'Order #${order.orderId}',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  fontSize: isSmallScreen ? 16 : 18,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),

              // Amount
              Text(
                "₹${order.totalAmount.toStringAsFixed(2)}",
                style: theme.textTheme.titleSmall?.copyWith(
                  color: theme.colorScheme.secondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 6),

              // OTP
              if (order.otp != null)
                _buildInfoRow(
                  'OTP:',
                  order.otp!.toString(),
                  theme.colorScheme.primary,
                  isSmallScreen,
                ),

              // Payment Mode
              if (order.mode != null)
                _buildInfoRow(
                  'Mode:',
                  order.mode!,
                  _getModeColor(order.mode),
                  isSmallScreen,
                ),
            ],
          ),
        ),

        // Status Chip
        const SizedBox(width: 8),
        _buildStatusChip(order.status, theme),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value, Color valueColor, bool isSmallScreen) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: RichText(
        text: TextSpan(
          text: label,
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: isSmallScreen ? 12 : 14,
          ),
          children: [
            TextSpan(
              text: value,
              style: TextStyle(
                color: valueColor,
                fontWeight: FontWeight.w600,
                fontSize: isSmallScreen ? 12 : 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getModeColor(String? mode) {
    switch (mode?.toLowerCase()) {
      case 'paytm':
        return Colors.blueAccent;
      case 'cash':
        return Colors.greenAccent.shade700;
      case 'card':
        return Colors.purpleAccent;
      default:
        return Colors.grey.shade600;
    }
  }

  Widget _buildStatusChip(int status, ThemeData theme) {
    String text;
    Color color;

    switch (status) {
      case 0:
        text = "Cancelled";
        color = theme.colorScheme.error;
        break;
      case 1:
        text = "Placed";
        color = Colors.orangeAccent;
        break;
      case 2:
        text = "Accepted";
        color = Colors.purpleAccent;
        break;
      case 5:
        text = "Started";
        color = theme.colorScheme.primary;
        break;
      case 7:
        text = "Completed";
        color = Colors.greenAccent.shade700;
        break;
      default:
        text = "Unknown";
        color = Colors.grey.shade600;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
      ),
    );
  }
  Widget _buildActionButtons(
      BuildContext context,
      Order order,
      PaymentService paymentService,
      SocketController socketController,
      bool isSmallScreen,
      ) {

    // 🧪 Debug prints
    debugPrint("============== DEBUG ORDER ==============");
    debugPrint("Order ID: ${order.id}");
    debugPrint("Status: ${order.status}");
    debugPrint("Maid Name: ${order.maidName}");
    debugPrint("Maid Phone: ${order.maidPhone}");
    debugPrint("Lat: ${order.maidLat}");
    debugPrint("Lng: ${order.maidLng}");
    debugPrint("==========================================");

    // Updated Logic Check
    final bool isTrackingAllowed =
        order.status == 5 &&
            order.maidLat != null &&
            order.maidLng != null;

    debugPrint("🔍 isTrackingAllowed: $isTrackingAllowed");

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      alignment: WrapAlignment.end,
      children: [
        if (order.status != 7 && order.status != 0)
          _buildActionButton(
            context: context,
            icon: Icons.cancel_outlined,
            label: "Cancel",
            color: Colors.redAccent,
            onPressed: () => _showCancelDialog(context, order),
            isSmallScreen: isSmallScreen,
          ),

        if (order.status == 7)
          _buildActionButton(
            context: context,
            icon: order.payment == 1 ? Icons.check_circle : Icons.payment,
            label: order.payment == 1 ? "Paid" : "Pay Now",
            color: order.payment == 1 ? Colors.greenAccent.shade700 : Colors.orangeAccent,
            onPressed: order.payment == 1
                ? null
                : () async {
              await EasyLoading.show(status: 'Processing payment...');
              try {
                await paymentService.initiatePayment(order);
                if (context.mounted) await EasyLoading.showSuccess('Payment successful');
              } catch (e) {
                if (context.mounted) await EasyLoading.showError('Payment failed: $e');
              }
            },
            isSmallScreen: isSmallScreen,
          ),

        /// Live Tracking Debug
        if (isTrackingAllowed)
          _buildActionButton(
            context: context,
            icon: Icons.location_on_outlined,
            label: "Live Track",
            color: Colors.blueAccent,
            onPressed: () {
              debugPrint("📍 LIVE TRACK BUTTON CLICKED FOR ORDER: ${order.id}");

              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => LiveTrackingPage(
                    orderId: order.id,
                    maidLat: order.maidLat ?? 0,
                    maidLng: order.maidLng ?? 0,
                    userLat: order.userLat ?? 0,
                    userLng: order.userLng ?? 0,
                    maidName: order.maidName ?? 'Unknown',
                    maidPhone: order.maidPhone ?? '',
                    maidEmail: order.maidEmail ?? '',
                    orderStatus: order.status,
                  ),
                ),
              );
            },
            isSmallScreen: isSmallScreen,
          ),
      ],
    );
  }


  Widget _buildActionButton({
    required BuildContext context,
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback? onPressed,
    required bool isSmallScreen,
  }) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: isSmallScreen ? 18 : 20),
      label: Text(
        label,
        style: TextStyle(fontSize: isSmallScreen ? 12 : 14),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        padding: EdgeInsets.symmetric(
          horizontal: isSmallScreen ? 12 : 16,
          vertical: isSmallScreen ? 8 : 10,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        elevation: 2,
      ),
    );
  }

  void _showCancelDialog(BuildContext context, Order order) {
    final TextEditingController comment = TextEditingController();
    final theme = Theme.of(context);

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          "Cancel Order",
          style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        content: TextField(
          controller: comment,
          decoration: InputDecoration(
            hintText: "Reason for cancellation",
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            filled: true,
            fillColor: theme.colorScheme.surfaceContainerLowest,
          ),
          maxLines: 3,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text("Close", style: TextStyle(color: theme.colorScheme.secondary)),
          ),
          ElevatedButton(
            onPressed: () async {
              if (comment.text.trim().isEmpty) return;
              Navigator.of(dialogContext).pop();
              await _cancelOrder(context, order.id, comment.text);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.colorScheme.error,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text("Confirm"),
          ),
        ],
      ),
    );
  }

  Future<void> _cancelOrder(BuildContext context, String orderId, String comment) async {
    final orderController = context.read<OrderController>();
    try {
      await EasyLoading.show(status: 'Cancelling...');
      final response = await http.put(
        Uri.parse('https://backend-olxs.onrender.com/cancel-order/$orderId'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({"comment": comment}),
      );

      if (response.statusCode == 200) {
        if (context.mounted) await EasyLoading.showSuccess('Order cancelled');
        await orderController.fetchOrders();
      } else {
        throw Exception('Failed: ${response.body}');
      }
    } catch (e) {
      if (context.mounted) await EasyLoading.showError('Error: $e');
    }
  }
}
