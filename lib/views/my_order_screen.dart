import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../controllers/order_controller.dart';
import '../models/order_model.dart';
import '../services/api_services.dart';
import '../services/payment_service.dart';
import 'package:shimmer/shimmer.dart';
import '../controllers/socket_controller.dart';
import 'live_tracking_page.dart';
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
    print('🚀 UserOrdersPage initialized');
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        try {
          context.read<OrderController>().fetchOrders();
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Failed to load orders: $e'),
                duration: const Duration(seconds: 3),
              ),
            );
          }
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return ScaffoldMessenger(
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
        body: RefreshIndicator(
          onRefresh: () async {
            try {
              await context.read<OrderController>().fetchOrders();
            } catch (e) {
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Failed to refresh orders: $e'),
                    duration: const Duration(seconds: 3),
                  ),
                );
              }
              return Future.error(e);
            }
          },
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
                final sortedOrders = List<Order>.from(controller.orders)
                  ..sort((a, b) => b.orderId.compareTo(a.orderId));
                return ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: sortedOrders.length,
                  itemBuilder: (context, index) {
                    final order = sortedOrders[index];
                    return _buildOrderCard(context, order, controller);
                  },
                );
              }
            },
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
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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

  Widget _buildOrderCard(
      BuildContext context, Order order, OrderController controller) {
    final paymentService = PaymentService(context, ApiServices());
    final socketController =
        Provider.of<SocketController>(context, listen: false);

    return GestureDetector(
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
      child: Card(
        margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: Colors.grey, width: 0.5),
        ),
        elevation: 4,
        shadowColor: Colors.black12,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
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
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
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
                        const SizedBox(height: 6),
                        Text(
                          "Payment: ${order.mode}",
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[700],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        if (order.otp != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            "OTP: ${order.otp}",
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[700],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
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
                  Icon(
                    Icons.arrow_forward_ios,
                    size: 16,
                    color: Colors.grey[600],
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (order.status == 7)
                Align(
                  alignment: Alignment.centerRight,
                  child: ElevatedButton(
                    onPressed: (order.payment == 1)
                        ? null
                        : () {
                            print(
                                '🚀 Pay clicked for order ID: ${order.orderId}, _id: ${order.id}');
                            paymentService.initiatePayment(order);
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          (order.payment == 1) ? Colors.grey : Colors.green,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      (order.payment == 1) ? "Paid" : "Pay Now",
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              if (order.status != 5 &&
                  (order.maidLat != null || order.maidLng != null))
                Align(
                  alignment: Alignment.centerRight,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      print(
                          '🚀 Live Track clicked for order ID: ${order.orderId}, _id: ${order.id}');
                      socketController.trackOrder(order.id);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              LiveTrackingPage(orderId: order.id),
                        ),
                      ).then((value) {
// Optional: Handle return from LiveTrackingPage if needed
                      });
                    },
                    icon: const Icon(Icons.location_on),
                    label: const Text("Live Track"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blueAccent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
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
          color: chipColor.computeLuminance() > 0.5
              ? Colors.black87
              : Colors.white,
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
