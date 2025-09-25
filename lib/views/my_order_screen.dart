import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import 'package:user_app/views/track_order_screen.dart';

class MyOrdersScreen extends StatefulWidget {
  const MyOrdersScreen({super.key});

  @override
  State<MyOrdersScreen> createState() => _MyOrdersPageState();
}

class _MyOrdersPageState extends State<MyOrdersScreen> {
  bool isLoading = true;
  List<Map<String, dynamic>> orders = [];

  @override
  void initState() {
    super.initState();
    _loadOrders();
  }

  Future<void> _loadOrders() async {
    await Future.delayed(const Duration(seconds: 2));
    if (mounted) {
      setState(() {
        isLoading = false;
        orders = [
          {
            "id": "ORD-1001",
            "date": "25 Sep 2025",
            "status": "Delivered",
            "serviceName": "Deep House Cleaning",
            "category": "Cleaning",
            "price": 499,
            "quantity": 1,
            "address": "123, MG Road, Delhi",
            "thumbnail":
            "https://cdn-icons-png.flaticon.com/512/706/706164.png"
          },
          {
            "id": "ORD-1002",
            "date": "20 Sep 2025",
            "status": "In Progress",
            "serviceName": "AC Repair Service",
            "category": "Maintenance",
            "price": 799,
            "quantity": 2,
            "address": "Flat 4B, Green Park, Delhi",
            "thumbnail":
            "https://cdn-icons-png.flaticon.com/512/3534/3534066.png"
          },
          {
            "id": "ORD-1003",
            "date": "10 Sep 2025",
            "status": "Cancelled",
            "serviceName": "Pest Control",
            "category": "Home Care",
            "price": 249,
            "quantity": 1,
            "address": "House 7, Model Town",
            "thumbnail":
            "https://cdn-icons-png.flaticon.com/512/490/490091.png"
          },
        ];
      });
    }
  }

  Future<void> _refreshOrders() async {
    setState(() => isLoading = true);
    await _loadOrders();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],

      body: RefreshIndicator(
        onRefresh: _refreshOrders,
        child: isLoading
            ? ListView.builder(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          itemCount: 3,
          itemBuilder: (context, index) => _shimmerOrderCard(context),
        )
            : ListView.builder(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          itemCount: orders.length,
          itemBuilder: (context, index) =>
              _orderCard(context, orders[index]),
        ),
      ),
    );
  }

  Widget _orderCard(BuildContext context, Map<String, dynamic> order) {
    Color statusColor;
    switch (order["status"]) {
      case "Delivered":
        statusColor = Colors.green;
        break;
      case "In Progress":
        statusColor = Colors.orange;
        break;
      case "Cancelled":
        statusColor = Colors.red;
        break;
      default:
        statusColor = Colors.grey;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // top row
            Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    order["thumbnail"],
                    width: 60,
                    height: 60,
                    fit: BoxFit.cover,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  Text(order["serviceName"] ?? '',
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(fontWeight: FontWeight.w600)),
                      Text(order["category"],
                          style: const TextStyle(fontSize: 13, color: Colors.grey)),
                      Text("Qty: ${order["quantity"]}",
                          style: const TextStyle(fontSize: 13, color: Colors.grey)),
                    ],
                  ),
                ),
                Text("₹${order["price"]}",
                    style: const TextStyle(
                        fontSize: 15, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 8),
            // order id & date
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(order["id"],
                    style: const TextStyle(
                        fontSize: 13, fontWeight: FontWeight.w500)),
                Text(order["date"],
                    style: const TextStyle(fontSize: 13, color: Colors.grey)),
              ],
            ),
            const SizedBox(height: 4),
            // status
            Text(order["status"],
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: statusColor)),
            const SizedBox(height: 4),
            // address
            Text("Address: ${order["address"]}",
                style: const TextStyle(fontSize: 13, color: Colors.black54)),
            const SizedBox(height: 8),
            // track button
            Align(
              alignment: Alignment.centerRight,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => TrackOrderScreen(order: order)),
                  );
                },
                icon: const Icon(Icons.location_on, size: 18),
                label: const Text("Track Order"),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _shimmerOrderCard(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: Colors.grey.shade300,
      highlightColor: Colors.grey.shade100,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
        height: 140,
      ),
    );
  }
}
