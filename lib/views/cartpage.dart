import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import 'package:user_app/views/addressdetailScreen.dart';

class MyCartPage extends StatefulWidget {
  const MyCartPage({super.key});

  @override
  State<MyCartPage> createState() => _MyCartPageState();
}

class _MyCartPageState extends State<MyCartPage> {
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    // simulate API call
    await Future.delayed(const Duration(seconds: 2));
    if (mounted) {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _refreshData() async {
    setState(() => isLoading = true);
    await _loadData();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: LayoutBuilder(
        builder: (context, constraints) {
          final maxWidth = constraints.maxWidth;
          final horizontalPadding = maxWidth > 600 ? 40.0 : 16.0;

          return RefreshIndicator(
            onRefresh: _refreshData,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 12),
                  // Tabs Row
                  Row(
                    children: [
                      _tabButton("Instant", true),
                      _tabButton("Scheduled", false),
                      _tabButton("Recurring", false),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Text(
                    "Review booking",
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 12),

                  // Service Card or shimmer
                  if (isLoading) ..._shimmerList(maxWidth)
                  else ...[
                    Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16)),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Row(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.network(
                                'https://cdn-icons-png.flaticon.com/512/3063/3063186.png',
                                width: maxWidth * 0.18,
                                height: maxWidth * 0.18,
                                fit: BoxFit.cover,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text("Sweeping",
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleMedium
                                          ?.copyWith(
                                          fontWeight: FontWeight.w600)),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: const [
                                      Text("₹60",
                                          style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold)),
                                      SizedBox(width: 6),
                                      Text("₹780",
                                          style: TextStyle(
                                              fontSize: 13,
                                              color: Colors.grey,
                                              decoration: TextDecoration
                                                  .lineThrough)),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            _quantitySelector(),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),

                    // Add more services link
                    Row(
                      children: [
                        Text("Missed something?",
                            style: TextStyle(color: Colors.grey.shade700)),
                        const SizedBox(width: 4),
                        TextButton(
                            onPressed: () {},
                            child: const Text("Add more services")),
                      ],
                    ),
                    const Divider(thickness: 0.5),

                    // Coupons
                    ListTile(
                      dense: true,
                      title: const Text("View all coupons"),
                      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                      onTap: () {},
                    ),
                    const Divider(thickness: 0.5),

                    // Booking Details
                    Text("Booking details",
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium
                            ?.copyWith(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 8),
                    Card(
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      child: Column(
                        children: [
                          ListTile(
                            leading: const Icon(Icons.location_on_outlined),
                            title: const Text("Location"),
                            subtitle: const Text("Add address",
                                style: TextStyle(color: Colors.green)),
                            onTap: () {
                              Navigator.push(
                                  context,
                                    MaterialPageRoute(
                                      builder: (context) => AddAddressPage()));
                            },
                          ),
                          const Divider(height: 0),
                          ListTile(
                            leading: const Icon(Icons.person_outline),
                            title: const Text("Your name"),
                            subtitle: const Text("+91 8802377021"),
                            onTap: () {},
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Bill details
                    Text("Bill details",
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium
                            ?.copyWith(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 8),
                    Card(
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          children: [
                            _billRow("Sub total", "₹60"),
                            _billRow("Discount", "₹0",
                                valueColor: Colors.green),
                            _billRow("GST total", "₹10.8"),
                            const Divider(),
                            _billRow("To Pay", "₹70.8", bold: true),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Bottom Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: () {

                        },
                        child: const Text("Add address to proceed",
                            style: TextStyle(fontSize: 16)),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ]
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  /// shimmer skeletons
  List<Widget> _shimmerList(double maxWidth) {
    return List.generate(
      3,
          (index) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: Shimmer.fromColors(
          baseColor: Colors.grey.shade300,
          highlightColor: Colors.grey.shade100,
          child: Container(
            width: double.infinity,
            height: maxWidth * 0.25,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ),
    );
  }

  Widget _tabButton(String text, bool selected) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: selected ? Colors.green : Colors.white,
            foregroundColor: selected ? Colors.white : Colors.black,
            elevation: selected ? 1 : 0,
            padding: const EdgeInsets.symmetric(vertical: 10),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
                side: BorderSide(
                    color: selected ? Colors.green : Colors.grey.shade300)),
          ),
          onPressed: () {},
          child: Text(text),
        ),
      ),
    );
  }

  Widget _quantitySelector() {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade400),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          IconButton(
              onPressed: () {}, icon: const Icon(Icons.remove, size: 18)),
          const Text("1"),
          IconButton(onPressed: () {}, icon: const Icon(Icons.add, size: 18)),
        ],
      ),
    );
  }

  Widget _billRow(String title, String value,
      {Color? valueColor, bool bold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title,
              style: TextStyle(
                  fontSize: 14, fontWeight: bold ? FontWeight.bold : null)),
          Text(value,
              style: TextStyle(
                  color: valueColor ?? Colors.black,
                  fontSize: 14,
                  fontWeight: bold ? FontWeight.bold : null)),
        ],
      ),
    );
  }
}
