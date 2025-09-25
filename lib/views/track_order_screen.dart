import 'package:flutter/material.dart';

class TrackOrderScreen extends StatelessWidget {
  final Map<String, dynamic> order;
  const TrackOrderScreen({super.key, required this.order});

  @override
  Widget build(BuildContext context) {
    // Timeline steps based on status
    final steps = [
      {"title": "Order Placed", "subtitle": order["date"], "done": true},
      {"title": "Processing", "subtitle": "Preparing service",
        "done": order["status"] != "Cancelled"},
      {"title": "Out for Service", "subtitle": "Service partner on the way",
        "done": order["status"] == "Delivered"},
      {"title": "Delivered", "subtitle": "Completed at your address",
        "done": order["status"] == "Delivered"},
    ];

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        leading: IconButton(
          icon: Image.asset(
            'assets/icons/back.png',
            width: 24,
            height: 24,
          ),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: Text("Track ${order["id"]}"),
        backgroundColor: Colors.green,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ---- Order header card ----
            Card(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        order["thumbnail"] ??
                            "https://cdn-icons-png.flaticon.com/512/706/706164.png",
                        width: 70,
                        height: 70,
                        fit: BoxFit.cover,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(order["serviceName"] ?? "Service Name",
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(fontWeight: FontWeight.bold)),
                          const SizedBox(height: 4),
                          Text(order["category"] ?? "Category",
                              style: const TextStyle(
                                  fontSize: 13, color: Colors.grey)),
                          const SizedBox(height: 4),
                          Text("₹${order["price"]}  x${order["quantity"]}",
                              style: const TextStyle(
                                  fontSize: 13, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 4),
                          Text(order["status"],
                              style: TextStyle(
                                  color: _statusColor(order["status"]),
                                  fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // ---- Address & expected info ----
            Text("Service Address",
                style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 4),
            Text(order["address"] ?? "User address here",
                style: const TextStyle(fontSize: 14, color: Colors.black87)),
            const Divider(height: 32),

            // ---- Timeline steps ----
            Text("Order Status",
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            ListView.builder(
              itemCount: steps.length,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemBuilder: (context, index) {
                final step = steps[index];
                final isDone = step["done"] as bool;
                final isLast = index == steps.length - 1;

                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Column(
                      children: [
                        Icon(
                          isDone
                              ? Icons.check_circle
                              : Icons.radio_button_unchecked,
                          color: isDone ? Colors.green : Colors.grey,
                        ),
                        if (!isLast)
                          Container(
                            width: 2,
                            height: 40,
                            color: isDone ? Colors.green : Colors.grey[300],
                          ),
                      ],
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(step["title"],
                                style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    color: isDone
                                        ? Colors.black
                                        : Colors.grey)),
                            const SizedBox(height: 2),
                            Text(step["subtitle"] ?? "",
                                style: const TextStyle(
                                    fontSize: 12, color: Colors.grey)),
                          ],
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 20),

            // ---- Action buttons ----
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      // cancel / support action
                    },
                    icon: const Icon(Icons.help_outline),
                    label: const Text("Need Help"),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green),
                    onPressed: () {
                      // track live map or similar
                    },
                    icon: const Icon(Icons.location_on_outlined),
                    label: const Text("Track on Map"),
                  ),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }

  static Color _statusColor(String status) {
    switch (status) {
      case "Delivered":
        return Colors.green;
      case "In Progress":
        return Colors.orange;
      case "Cancelled":
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}
