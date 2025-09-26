import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../controllers/order_controller.dart';
import '../models/order_model.dart';
import '../services/api_services.dart';
import 'package:shimmer/shimmer.dart';

import 'order_detail_page.dart';

class UserOrdersPage extends StatefulWidget {
  const UserOrdersPage({super.key});

  @override
  State<UserOrdersPage> createState() => _UserOrdersPageState();
}

class _UserOrdersPageState extends State<UserOrdersPage> {
  @override
  void initState() {
    super.initState();
    debugPrint("🚀 UserOrdersPage initialized");
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => OrderController(apiService: ApiServices()),
      child: Scaffold(
        appBar: AppBar(
          title: const Text(
            "My Orders",
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 20,
              color: Colors.black87,
            ),
          ),
          backgroundColor: Colors.white,
          elevation: 0,
          centerTitle: true,
        ),
        body: Builder(
          builder: (BuildContext refreshContext) {
            return RefreshIndicator(
              onRefresh: () => Provider.of<OrderController>(refreshContext, listen: false).fetchOrders(),
              color: Colors.orangeAccent,
              child: Consumer<OrderController>(
                builder: (context, controller, child) {
                  if (controller.loading) {
                    return _buildShimmerLoader();
                  } else if (controller.orders.isEmpty) {
                    return const Center(
                      child: Text(
                        "No orders found.",
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.grey,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    );
                  } else {
                    return ListView.builder(
                      padding: const EdgeInsets.all(12),
                      itemCount: controller.orders.length,
                      itemBuilder: (context, index) {
                        final order = controller.orders[index];
                        return _buildOrderCard(context, order, controller);
                      },
                    );
                  }
                },
              ),
            );
          },
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
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: Colors.grey, width: 0.5),
      ),
      elevation: 4,
      shadowColor: Colors.black12,
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        leading: CircleAvatar(
          backgroundColor: Colors.orangeAccent,
          radius: 24,
          child: Text(
            order.orderId.toString(),
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ),
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              "₹${order.totalAmount.toStringAsFixed(2)}",
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
                color: Colors.black87,
              ),
            ),
            _buildStatusChip(order.status),
          ],
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Payment: ${order.mode}",
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[700],
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              if (order.otp != null)
                Text(
                  "OTP: ${order.otp}",
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[700],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              const SizedBox(height: 4),
              Text(
                "Date: ${DateFormat('dd MMM yyyy, hh:mm a').format(order.createdAt)}",
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
        ),
        trailing: Icon(
          Icons.arrow_forward_ios,
          size: 16,
          color: Colors.grey[600],
        ),
        onTap: () {
          debugPrint("Tapped on order ID: ${order.orderId}, _id: ${order.id}");
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => OrderDetailsPage(
                orderId: order.id,
                orderController: controller,
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatusChip(int status) {
    String statusText = _statusText(status);
    Color chipColor;
    switch (status) {
      case 0:
        chipColor = Colors.orange.shade100;
        break;
      case 1:
        chipColor = Colors.blue.shade100;
        break;
      case 2:
        chipColor = Colors.purple.shade100;
        break;
      case 5:
        chipColor = Colors.red.shade100;
        break;
      case 7:
        chipColor = Colors.green.shade100;
        break;
      default:
        chipColor = Colors.grey.shade100;
    }

    return Chip(
      label: Text(
        statusText,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: chipColor.computeLuminance() > 0.5 ? Colors.black87 : Colors.white,
        ),
      ),
      backgroundColor: chipColor,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
  }

  String _statusText(int status) {
    switch (status) {
      case 0:
        return "Pending";
      case 1:
        return "Confirmed";
      case 2:
        return "Processing";
      case 5:
        return "Cancelled";
      case 7:
        return "Delivered";
      default:
        return "Unknown";
    }
  }
}