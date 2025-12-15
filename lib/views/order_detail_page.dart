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
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import '../controllers/order_controller.dart';
import 'live_tracking_page.dart';

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

class _OrderDetailsPageState extends State<OrderDetailsPage>
    with SingleTickerProviderStateMixin {

  String? _errorMessage;
  late AnimationController _liveBtnController;
  late Animation<double> _pulseAnim;


  @override
  void initState() {
    super.initState();
    _fetchOrderDetails();
    _liveBtnController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat(reverse: true);

    _pulseAnim = Tween<double>(begin: 0.9, end: 1.05).animate(
      CurvedAnimation(parent: _liveBtnController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _liveBtnController.dispose();
    super.dispose();
  }


  Future<void> _fetchOrderDetails() async {
    try {
      await EasyLoading.show(status: 'Loading order details...');
      // Force refresh is good for details page
      await widget.orderController.fetchOrderDetails(widget.orderId, forceRefresh: true);
      await EasyLoading.dismiss();
    } catch (e) {
      setState(() {
        if (e.toString().contains('404')) {
          _errorMessage = 'Order not found. Please check the order ID.';
        } else {
          _errorMessage = 'Failed to load order details.';
        }
      });
      // Show error briefly without dismissing immediately to give user time to read
      EasyLoading.showError(_errorMessage!, duration: const Duration(seconds: 3));
    }

  }

  Future<void> _downloadInvoice(String invoiceId) async {
    try {
      await EasyLoading.show(status: 'Downloading...');

      final url = '${ApiServices.baseUrl}/download-invoice-order';

      final response = await http.post(
        Uri.parse(url),
        headers: {"Content-Type": "application/json", "Accept": "application/pdf"},
        body: json.encode({"invoiceId": invoiceId}),
      );

      if (response.statusCode == 200) {
        final directory = await getApplicationDocumentsDirectory();
        final filePath = '${directory.path}/invoice_$invoiceId.pdf';
        final file = File(filePath);

        await file.writeAsBytes(response.bodyBytes);

        EasyLoading.dismiss();

        // 🚀 Better Bottom Sheet for Post-Download Actions
        showModalBottomSheet(
          context: context,
          backgroundColor: Colors.white,
          shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.vertical(top: Radius.circular(25))),
          builder: (_) {
            return Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Invoice Downloaded Successfully!',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.green),
                  ),
                  const Divider(height: 20, thickness: 1.5),
                  ListTile(
                    leading: const Icon(Icons.picture_as_pdf, color: Colors.blue),
                    title: const Text('View / Print Invoice'),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                    onTap: () async {
                      Navigator.pop(context);
                      await OpenFilex.open(filePath);
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.share, color: Colors.purple),
                    title: const Text('Share Invoice'),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                    onTap: () async {
                      Navigator.pop(context);
                      await Share.shareXFiles([XFile(filePath)], text: 'Order Invoice PDF');
                    },
                  ),
                  const SizedBox(height: 10),
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Close', style: TextStyle(color: Colors.red)),
                  )
                ],
              ),
            );
          },
        );
      } else {
        EasyLoading.dismiss();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to download invoice. Server responded with an error.')),
        );
      }
    } catch (e) {
      EasyLoading.dismiss();
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  Widget _liveTrackPill(Order order) {
    if (order.status != 5 || order.agent == null) return const SizedBox();

    return AnimatedBuilder(
      animation: _pulseAnim,
      builder: (_, __) {
        return Transform.scale(
          scale: _pulseAnim.value,
          child: InkWell(
            borderRadius: BorderRadius.circular(30),
            onTap: () {
              final agent = order.agent!;

              if (agent.latitude == null ||
                  agent.longitude == null ||
                  order.orderLat == null ||
                  order.orderLng == null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("📍 Location not available yet")),
                );
                return;
              }

              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => LiveTrackingPage(
                    // 🔹 REAL DB ID (socket + tracking ke liye)
                    orderId: order.id.toString(),

                    // 🔹 USER KO DIKHANE WALA ORDER NUMBER
                    orderidNameForShow: order.orderId,

                    // 🔹 MAID LOCATION
                    maidLat: agent.latitude ?? 0.0,
                    maidLng: agent.longitude ?? 0.0,

                    // 🔹 ORDER LOCATION (FIXED ✅)
                    orderLat: order.orderLat ?? 0.0,
                    orderLng: order.orderLng ?? 0.0,

                    // 🔹 MAID DETAILS (UI me dikhane ke liye)
                    maidName: agent.username ?? "Maid",
                    maidPhone: agent.phone ?? "N/A",


                    // 🔹 ORDER STATUS
                    orderStatus: order.status,
                  ),
                ),
              );

            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(30),
                border: Border.all(color: Colors.blue.shade300),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // 🔴 Blinking Dot
                  Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  const Icon(Icons.location_on, size: 16, color: Colors.blue),
                  const SizedBox(width: 6),
                  const Text(
                    "LIVE TRACK",
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: Colors.blue,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }


  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: widget.orderController,
      child: Scaffold(
        appBar: _buildAppBar("Order Details"),
        backgroundColor: const Color(0xfff6f6f6), // Light background for contrast
        body: Consumer<OrderController>(
          builder: (context, controller, child) {
            if (controller.isOrderDetailsLoading) {
              return Center(child: CircularProgressIndicator(color: Theme.of(context).primaryColor)); // Use theme color
            }

            if (_errorMessage != null) {
              return Center(
                  child: Text(_errorMessage!,
                      style: const TextStyle(color: Colors.red, fontSize: 16, fontWeight: FontWeight.w500)));
            }

            final order = controller.getOrderDetails(widget.orderId);

            if (order == null) {
              return const Center(child: Text("Order not found.", style: TextStyle(fontSize: 16)));
            }

            return RefreshIndicator(
              onRefresh: _fetchOrderDetails,
              color: Theme.of(context).primaryColor, // Refresh indicator color
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    _styledCard(child: _buildOrderHeader(order)),
                    const SizedBox(height: 16),
                    _styledCard(child: _buildOrderInfo(order)),
                    const SizedBox(height: 16),
                    _styledCard(child: _buildUserDetails(order)),
                    const SizedBox(height: 16),
                    if (order.items.isNotEmpty)
                      _styledCard(child: _buildItemList(order)),
                    const SizedBox(height: 20),


                    const SizedBox(height: 20),

                    // Download Button styled
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () => _downloadInvoice(order.id),
                        icon: const Icon(Icons.picture_as_pdf, color: Colors.white),
                        label: const Text(
                          "Download Invoice",
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blueAccent, // Use a vibrant blue
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          elevation: 5, // Add some elevation
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  // 🎨 Zepto Style Card Wrapper
  Widget _styledCard({required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15), // Slightly smaller radius for a modern look
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.08), // Softer shadow
              blurRadius: 15,
              offset: const Offset(0, 5)),
        ],
      ),
      child: child,
    );
  }

  // 🎨 HEADER UI
  Widget _buildOrderHeader(Order order) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Order #${order.orderId}",
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Colors.black87)),
                const SizedBox(height: 4),
                Text("Date: ${DateFormat('dd MMM yyyy • hh:mm a').format(order.createdAt)}",
                    style: TextStyle(color: Colors.grey[600], fontSize: 13)),
              ]),
        ),
        const SizedBox(width: 10),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            _buildStatusChip(order.status),
            const SizedBox(height: 6),
            _liveTrackPill(order),
          ],
        ),

      ],
    );
  }

  // 🎨 CUSTOMER DETAILS UI
  Widget _buildUserDetails(Order order) {
    final d = order.details[0];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _title("Customer Information"),
        const Divider(height: 15, thickness: 1),
        _row("Name", d.username, icon: Icons.person_outline),
        _row("Phone", d.phone, icon: Icons.phone_outlined),
        _row("Email", d.email, icon: Icons.mail_outline),
        _row("Address", d.address, icon: Icons.location_on_outlined, isAddress: true),
        _row("State", d.state, icon: Icons.area_chart),
        _row("Pincode", d.pincode, icon: Icons.numbers),
      ],
    );
  }
  Widget _buildOrderInfo(Order order) {
    final isPaid = order.payment == 1;
    final paymentStatus = isPaid ? "Paid" : "Pending";
    final paymentColor = isPaid ? Colors.green.shade700 : Colors.red.shade700;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _title("Payment & Order Summary"),
        const Divider(height: 15, thickness: 1),

        _row(
          "Payment Status",
          paymentStatus,
          icon: Icons.credit_card_outlined,
          valueStyle: TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 15,
            color: paymentColor,
            backgroundColor: paymentColor.withOpacity(0.1),
          ),
        ),

        _row("Mode", order.mode, icon: Icons.payment_outlined),

        if (order.otp != null)
          _row("OTP", order.otp.toString(), icon: Icons.security_outlined),

        // ✅ SAFE AGENT CHECK
        if (order.agent != null)
          _row(
            "Agent ID",
            order.agent!.id.toString(),
            icon: Icons.support_agent_outlined,
          ),

        const Divider(height: 20, thickness: 1.5),

        _row("Shipping/Delivery Fee", "₹${order.shipping}",
            icon: Icons.local_shipping_outlined),

        _row("Discount Applied", "₹${order.discount}",
            icon: Icons.discount_outlined),

        _highlightedRow(
          "Total Amount",
          "₹${order.totalAmount.toStringAsFixed(2)}",
          icon: Icons.monetization_on_outlined,
        ),
      ],
    );
  }


  // 🎨 ITEM LIST UI
  Widget _buildItemList(Order order) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _title("Items (${order.items.length})"),
        const Divider(height: 15, thickness: 1),

        ...order.items.map((i) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 15),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 🖼️ Rounded Image
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Image.network(
                    i.image,
                    width: 70,
                    height: 70,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) =>
                        Container(width: 70, height: 70, color: Colors.grey.shade200, child: const Icon(Icons.image_not_supported, size: 30, color: Colors.grey)),
                  ),
                ),
                const SizedBox(width: 15),

                // 📝 Item Details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        i.title,
                        style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 16,
                            color: Colors.black87),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "Qty: ${i.quantity} x ₹${i.price}",
                        style: TextStyle(color: Colors.grey[700], fontSize: 14),
                      ),
                      const SizedBox(height: 4),
                      // Total price for item
                      Text(
                        "Total: ₹${(i.quantity * i.price).toStringAsFixed(2)}",
                        style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        })
      ],
    );
  }


  // 🖋️ Helper Widget for Titles
  Widget _title(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 5),
      child: Text(
          text,
          style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: Color(0xFF1E1E1E))), // Darker title color
    );
  }

  // ℹ️ Helper Widget for Info Rows
  Widget _row(String label, String value, {IconData? icon, bool isAddress = false, TextStyle? valueStyle}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: isAddress ? CrossAxisAlignment.start : CrossAxisAlignment.center,
        children: [
          Icon(icon ?? Icons.info_outline, size: 20, color: Colors.grey.shade600),
          const SizedBox(width: 10),
          Expanded(
            flex: 2,
            child: Text(label, style: TextStyle(color: Colors.grey[700], fontSize: 15)),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: valueStyle ?? const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
            ),
          )
        ],
      ),
    );
  }

  // 💰 Helper Widget for Highlighted Row (e.g., Total Amount)
  Widget _highlightedRow(String label, String value, {IconData? icon}) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
      margin: const EdgeInsets.only(top: 8),
      decoration: BoxDecoration(
        color: Colors.lightGreen.shade50,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.lightGreen.shade100),
      ),
      child: Row(
        children: [
          Icon(icon ?? Icons.star, size: 22, color: Colors.green.shade700),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                color: Colors.green.shade800,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Text(
            value,
            textAlign: TextAlign.right,
            style: const TextStyle(
              fontWeight: FontWeight.w900,
              fontSize: 18,
              color: Colors.black,
            ),
          ),
        ],
      ),
    );
  }

// 🎨 PREMIUM TYPED STATUS CHIP (NO ERRORS)
  Widget _buildStatusChip(int status) {
    final Map<int, Map<String, dynamic>> map = {
      0: {
        "label": "Cancelled",
        "icon": Icons.cancel,
        "bg": Colors.red.shade50,
        "color": Colors.red.shade700
      },
      1: {
        "label": "Order Placed",
        "icon": Icons.access_time,
        "bg": Colors.amber.shade50,
        "color": Colors.amber.shade700
      },
      2: {
        "label": "Accepted",
        "icon": Icons.check_circle_outline,
        "bg": Colors.purple.shade50,
        "color": Colors.purple.shade700
      },
      5: {
        "label": "Out for Delivery",
        "icon": Icons.two_wheeler_outlined,
        "bg": Colors.blue.shade50,
        "color": Colors.blue.shade700
      },
      7: {
        "label": "Delivered",
        "icon": Icons.task_alt,
        "bg": Colors.green.shade50,
        "color": Colors.green.shade700
      },
    };

    final data = map[status] ??
        {
          "label": "Unknown Status",
          "icon": Icons.help_outline,
          "bg": Colors.grey.shade100,
          "color": Colors.grey.shade700
        };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: data["bg"],
        borderRadius: BorderRadius.circular(25),
        border: Border.all(color: data["color"].withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            data["icon"],
            size: 16,
            color: data["color"],
          ),
          const SizedBox(width: 6),
          Text(
            data["label"],
            style: TextStyle(
              color: data["color"],
              fontWeight: FontWeight.w700,
              fontSize: 13,
            ),
          )
        ],
      ),
    );
  }

  // ⚙️ Premium AppBar
  AppBar _buildAppBar(String title) {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0, // Flat app bar looks modern
      scrolledUnderElevation: 4, // Add shadow on scroll
      title: Text(
        title,
        style: const TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w800,
          color: Colors.black,
        ),
      ),
      centerTitle: true,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black, size: 20),
        onPressed: () => Navigator.pop(context),
      ),
    );
  }
}