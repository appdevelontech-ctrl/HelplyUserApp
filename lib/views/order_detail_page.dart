import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/order_model.dart';
import '../controllers/order_controller.dart';

class OrderDetailsPage extends StatefulWidget {
  final String orderId;
  final OrderController orderController;

  const OrderDetailsPage({
    super.key,
    required this.orderId,
    required this.orderController,
  });

  @override
  State<OrderDetailsPage> createState() => _OrderDetailsPageState();
}

class _OrderDetailsPageState extends State<OrderDetailsPage> {
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    if (widget.orderController.orderDetails == null ||
        widget.orderController.orderDetails!.id != widget.orderId) {
      widget.orderController.fetchOrderDetails(widget.orderId).catchError((e) {
        setState(() {
          _errorMessage = e.toString();
          if (e.toString().contains('Status code: 404')) {
            _errorMessage = 'Order not found. Please check the order ID or contact support.';
          }
        });
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: widget.orderController,
      child: Scaffold(
        appBar:  _buildAppBar('Order Details'),
        body: Consumer<OrderController>(
          builder: (context, controller, child) {
            if (controller.loading) {
              return const Center(child: CircularProgressIndicator(color: Colors.orangeAccent));
            }

            if (_errorMessage != null) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      "Failed to load order details.",
                      style: TextStyle(
                        fontSize: 18,
                        color: Colors.red,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _errorMessage!,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[700],
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              );
            }

            final order = controller.orderDetails;
            if (order == null) {
              return const Center(
                child: Text(
                  "Order not found.",
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.grey,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              );
            }

            return SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildOrderHeader(context, order),
                  const SizedBox(height: 16),
                  _buildOrderDetails(context, order),
                  const SizedBox(height: 16),
                  if (order.items.isNotEmpty) _buildItemsList(context, order),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildOrderHeader(BuildContext context, Order order) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Order #${order.orderId}",
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 8),
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
            _buildStatusChip(order.status),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderDetails(BuildContext context, Order order) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Order Information",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 12),
            _buildDetailRow("Total Amount", "₹${order.totalAmount.toStringAsFixed(2)}"),
            _buildDetailRow("Payment Mode", order.mode),
            if (order.otp != null) _buildDetailRow("OTP", order.otp.toString()),
            _buildDetailRow("Payment Status", order.payment == 1 ? "Paid" : "Pending"),
            _buildDetailRow("Discount", "₹${order.discount}"),
            _buildDetailRow("Shipping", "₹${order.shipping}"),
            _buildDetailRow("Lead Status", order.leadStatus.toString()),
            _buildDetailRow("Agent ID", order.agentId),
          ],
        ),
      ),
    );
  }

  Widget _buildItemsList(BuildContext context, Order order) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Items",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 12),
            ...order.items.map((item) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      item.image,
                      width: 50,
                      height: 50,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => const Icon(Icons.error, size: 50),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.title,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: Colors.black87,
                          ),
                        ),
                        Text(
                          "Qty: ${item.quantity} | Price: ₹${item.price}",
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[700],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            )),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[700],
              fontWeight: FontWeight.w500,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              color: Colors.black87,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
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


/// 🔹 AppBar (Blue)
AppBar _buildAppBar(String title) {
  return AppBar(
    leading: Builder(
      builder: (context) => IconButton(
        icon: Image.asset(
          'assets/icons/back.png',
          width: 24,
          height: 24,
          color: Colors.white,
        ),
        onPressed: () => Navigator.pop(context),
      ),
    ),
    title: Text(
      title,
      style: const TextStyle(
        fontWeight: FontWeight.bold,
        color: Colors.white,
        fontSize: 20,
      ),
    ),
    backgroundColor: Colors.blue[700],
    elevation: 3,
  );
}