import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shimmer/shimmer.dart';

import '../controllers/order_controller.dart';
import '../models/order_model.dart';
import '../services/api_services.dart';
import '../services/payment_service.dart';
import 'order_detail_page.dart';

class UserOrdersPage extends StatefulWidget {
  const UserOrdersPage({super.key});

  @override
  State<UserOrdersPage> createState() => _UserOrdersPageState();
}

class _UserOrdersPageState extends State<UserOrdersPage> {
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    if (_isInitialized) return;
    _isInitialized = true;

    final orderController = context.read<OrderController>();
    await orderController.fetchOrders(forceRefresh: true);

    if (mounted) setState(() {});
  }

  Future<void> _onRefresh() async {
    await context.read<OrderController>().fetchOrders(forceRefresh: true);
    if (mounted) setState(() {});
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

            final orders = [...controller.orders]
              ..sort((a, b) => b.orderId.compareTo(a.orderId));

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
      itemBuilder: (_, __) => Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Container(height: 100, color: Colors.grey),
      ),
    ),
  );
}

/* ======================= ORDER CARD ======================= */

class OrderCard extends StatelessWidget {
  final Order order;
  const OrderCard({super.key, required this.order});

  @override
  Widget build(BuildContext context) {
    final paymentService = PaymentService(context, ApiServices());
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        elevation: 6,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(context, theme, isSmallScreen),
              const SizedBox(height: 12),
              _buildActionButtons(context, paymentService, isSmallScreen),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, ThemeData theme, bool isSmall) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [theme.colorScheme.primary, theme.colorScheme.primaryContainer],
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Icon(Icons.shopping_bag_outlined,
              color: theme.colorScheme.onPrimary, size: isSmall ? 24 : 32),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(
              'Order #${order.orderId}',
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              "₹${order.totalAmount.toStringAsFixed(2)}",
              style: theme.textTheme.titleSmall?.copyWith(
                color: theme.colorScheme.secondary,
                fontWeight: FontWeight.w600,
              ),
            ),
            if (order.otp != null)
              Text("OTP: ${order.otp}", style: const TextStyle(fontSize: 12)),
            Text("Mode: ${order.mode}", style: const TextStyle(fontSize: 12)),
          ]),
        ),
        _buildStatusChip(order.status, theme),
      ],
    );
  }

  Widget _buildStatusChip(int status, ThemeData theme) {
    final map = {
      0: ["Cancelled", Colors.red],
      1: ["Placed", Colors.orange],
      2: ["Accepted", Colors.purple],
      5: ["Started", theme.colorScheme.primary],
      7: ["Completed", Colors.green],
    };

    final data = map[status] ?? ["Unknown", Colors.grey];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: (data[1] as Color).withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        data[0] as String,
        style: TextStyle(color: data[1] as Color, fontSize: 12),
      ),
    );
  }

  Widget _buildActionButtons(
      BuildContext context,
      PaymentService paymentService,
      bool isSmallScreen,
      ) {
    return Wrap(
      spacing: 8,
      alignment: WrapAlignment.end,
      children: [
        if (order.status != 7 && order.status != 0)
          _button(
            icon: Icons.cancel_outlined,
            label: "Cancel",
            color: Colors.redAccent,
            onPressed: () => _showCancelDialog(context),
            small: isSmallScreen,
          ),
        if (order.status == 7)
          _button(
            icon: order.payment == 1 ? Icons.check_circle : Icons.payment,
            label: order.payment == 1 ? "Paid" : "Pay Now",
            color: order.payment == 1 ? Colors.green : Colors.orange,
            onPressed: order.payment == 1
                ? null
                : () async {
              await EasyLoading.show(status: 'Processing...');
              await paymentService.initiatePayment(order);
              await EasyLoading.dismiss();
            },
            small: isSmallScreen,
          ),
      ],
    );
  }

  Widget _button({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback? onPressed,
    required bool small,
  }) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: small ? 18 : 20),
      label: Text(label, style: TextStyle(fontSize: small ? 12 : 14)),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  void _showCancelDialog(BuildContext context) {
    final TextEditingController comment = TextEditingController();

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Cancel Order"),
        content: TextField(
          controller: comment,
          decoration: const InputDecoration(hintText: "Reason"),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Close")),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await _cancelOrder(context, comment.text);
            },
            child: const Text("Confirm"),
          )
        ],
      ),
    );
  }

  Future<void> _cancelOrder(BuildContext context, String comment) async {
    await EasyLoading.show(status: 'Cancelling...');
    await http.put(
      Uri.parse('https://backend-olxs.onrender.com/cancel-order/${order.id}'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({"comment": comment}),
    );
    await context.read<OrderController>().fetchOrders(forceRefresh: true);
    await EasyLoading.dismiss();
  }
}
