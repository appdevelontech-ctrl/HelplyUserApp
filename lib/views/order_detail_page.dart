import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import '../services/api_services.dart';
import '../models/order_model.dart';
import 'dart:io';
import 'dart:convert';
import 'package:open_filex/open_filex.dart';
import 'package:share_plus/share_plus.dart';
import 'package:file_saver/file_saver.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_filex/open_filex.dart';
import '../controllers/order_controller.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

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
    _fetchOrderDetails();
  }
  Future<void> _fetchOrderDetails() async {
    // Skip checking cached data to ensure fresh API call
    if (widget.orderController.isOrderDetailsLoading) return;

    try {
      await EasyLoading.show(status: 'Loading order details...');
      // Always fetch fresh data from the API
      await widget.orderController.fetchOrderDetails(widget.orderId);
      await EasyLoading.dismiss();
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        if (e.toString().contains('Status code: 404')) {
          _errorMessage = 'Order not found. Please check the order ID or contact support.';
        } else {
          _errorMessage = 'Failed to load order details: $_errorMessage';
        }
      });
      await EasyLoading.showError(_errorMessage!);
      await EasyLoading.dismiss();
    }
  }

  Future<void> _downloadInvoice(String invoiceId) async {
    try {
      await EasyLoading.show(status: 'Downloading...');

      final url = '${ApiServices.baseUrl}/download-invoice-order';
      print('🧾 Downloading invoice for ID: $invoiceId');
      print('➡️ Request URL: $url');

      final response = await http.post(
        Uri.parse(url),
        headers: {
          "Content-Type": "application/json",
          "Accept": "application/pdf",
        },
        body: json.encode({"invoiceId": invoiceId}),
      );

      print('📥 Status Code: ${response.statusCode}');

      if (response.statusCode == 200) {
        final directory = await getApplicationDocumentsDirectory();
        final filePath = '${directory.path}/invoice_$invoiceId.pdf';
        final file = File(filePath);

        await file.writeAsBytes(response.bodyBytes);
        print('✅ Invoice saved at: $filePath');

        if (!mounted) return;

        EasyLoading.dismiss();

        // Show action sheet with options
        showModalBottomSheet(
          context: context,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
          ),
          builder: (_) {
            return Padding(
              padding: const EdgeInsets.all(16.0),
              child: Wrap(
                runSpacing: 10,
                children: [
                  Center(
                    child: Text(
                      'Invoice Downloaded',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                  const Divider(),
                  ListTile(
                    leading: const Icon(Icons.print, color: Colors.blue),
                    title: const Text('Print Invoice'),
                    onTap: () async {
                      Navigator.pop(context);
                      await OpenFilex.open(filePath);
                    },
                  ),

                  ListTile(
                    leading: const Icon(Icons.share, color: Colors.deepPurple),
                    title: const Text('Share Invoice'),
                    onTap: () async {
                      Navigator.pop(context);
                      await Share.shareXFiles([XFile(filePath)], text: 'Invoice PDF');
                    },
                  ),
                ],
              ),
            );
          },
        );
      } else {
        EasyLoading.dismiss();
        print('❌ Failed: ${response.statusCode}');
        print('🧠 Response: ${response.body}');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to download invoice (${response.statusCode})')),
        );
      }
    } catch (e) {
      EasyLoading.dismiss();
      print('💥 Exception: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error downloading invoice: $e')),
      );
    }
  }

  Future<void> _downloadInvoiceForVendor(String invoiceId) async {
    try {
      await EasyLoading.show(status: 'Downloading...');

      final url = '${ApiServices.baseUrl}/download-invoice-order-vendor';
      print('🧾 Downloading invoice for ID: $invoiceId');
      print('➡️ Request URL: $url');

      final response = await http.post(
        Uri.parse(url),
        headers: {
          "Content-Type": "application/json",
          "Accept": "application/pdf",
        },
        body: json.encode({"invoiceId": invoiceId}),
      );

      print('📥 Status Code: ${response.statusCode}');

      if (response.statusCode == 200) {
        final directory = await getApplicationDocumentsDirectory();
        final filePath = '${directory.path}/invoice_$invoiceId.pdf';
        final file = File(filePath);

        await file.writeAsBytes(response.bodyBytes);
        print('✅ Invoice saved at: $filePath');

        if (!mounted) return;

        EasyLoading.dismiss();

        // Show action sheet with options
        showModalBottomSheet(
          context: context,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
          ),
          builder: (_) {
            return Padding(
              padding: const EdgeInsets.all(16.0),
              child: Wrap(
                runSpacing: 10,
                children: [
                  Center(
                    child: Text(
                      'Invoice Downloaded',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                  const Divider(),
                  ListTile(
                    leading: const Icon(Icons.print, color: Colors.blue),
                    title: const Text('Print Invoice'),
                    onTap: () async {
                      Navigator.pop(context);
                      await OpenFilex.open(filePath);
                    },
                  ),

                  ListTile(
                    leading: const Icon(Icons.share, color: Colors.deepPurple),
                    title: const Text('Share Invoice'),
                    onTap: () async {
                      Navigator.pop(context);
                      await Share.shareXFiles([XFile(filePath)], text: 'Invoice PDF');
                    },
                  ),
                ],
              ),
            );
          },
        );
      } else {
        EasyLoading.dismiss();
        print('❌ Failed: ${response.statusCode}');
        print('🧠 Response: ${response.body}');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to download invoice (${response.statusCode})')),
        );
      }
    } catch (e) {
      EasyLoading.dismiss();
      print('💥 Exception: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error downloading invoice: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: widget.orderController,
      child: Scaffold(
        appBar: _buildAppBar('Order Details'),
        body: Consumer<OrderController>(
          builder: (context, controller, child) {
            if (controller.isOrderDetailsLoading) {
              return const Center(
                child: CircularProgressIndicator(color: Colors.orangeAccent),
              );
            }

            if (_errorMessage != null) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline, size: 50, color: Colors.red),
                    const SizedBox(height: 16),
                    Text(
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
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _fetchOrderDetails,
                      child: const Text('Retry'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blueAccent,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ],
                ),
              );
            }

            final order = controller.getOrderDetails(widget.orderId);
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

            return RefreshIndicator(
              onRefresh: () => _fetchOrderDetails(),
              color: Colors.orangeAccent,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildOrderHeader(context, order),
                    const SizedBox(height: 16),
                    _buildUserDetails(context, order),
                    const SizedBox(height: 16),
                    _buildOrderDetails(context, order),
                    const SizedBox(height: 16),
                    if (order.items.isNotEmpty) _buildItemsList(context, order),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        ElevatedButton(
                          onPressed: () => _downloadInvoice(order.id),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blueAccent,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: const Text(
                            'Download Invoice',
                            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                          ),
                        ),
                        SizedBox(width: 10),
                        ElevatedButton(
                          onPressed: () => _downloadInvoiceForVendor(order.id),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: const Text(
                            'Download Vendor Invoice',
                            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    )
                  ],
                ),
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

  Widget _buildUserDetails(BuildContext context, Order order) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Customer Information",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 12),
            if (order.details.isNotEmpty)
              ...[
                _buildDetailRow("Name", order.details[0].username),
                _buildDetailRow("Phone", order.details[0].phone),
                _buildDetailRow("Email", order.details[0].email),
                _buildDetailRow("Address", order.details[0].address),
                _buildDetailRow("State", order.details[0].state),
                _buildDetailRow("Pincode", order.details[0].pincode),
              ]
            else
              const Text(
                "No customer information available.",
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                ),
              ),
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
                      errorBuilder: (context, error, stackTrace) =>
                      const Icon(Icons.error, size: 50),
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
          Flexible(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                color: Colors.black87,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.right,
              overflow: TextOverflow.ellipsis,
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
        chipColor = Colors.red.shade100;
        break;
      case 1:
        chipColor = Colors.orange.shade100;
        break;
      case 2:
        chipColor = Colors.purple.shade100;
        break;
      case 5:
        chipColor = Colors.blue.shade100;
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
        return "Cancelled";
      case 1:
        return "Placed";
      case 2:
        return "Accepted";
      case 5:
        return "Started";
      case 7:
        return "Completed";
      default:
        return "Unknown";
    }
  }

  AppBar _buildAppBar(String title) {
    return AppBar(
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: Colors.white),
        onPressed: () => Navigator.pop(context),
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
}