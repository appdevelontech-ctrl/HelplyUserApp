import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';
import 'package:provider/provider.dart';
import 'package:user_app/main_screen.dart';
import '../controllers/service_detail_controller.dart';
import '../models/Service.dart';
import '../controllers/cart_provider.dart';

class ServiceDetailPage extends StatelessWidget {
  final Service service;
  final ServiceDetailController controller;

  ServiceDetailPage({super.key, required this.service})
      : controller = ServiceDetailController(service);

  @override
  Widget build(BuildContext context) {
    final detail = controller.serviceDetail;

    return Scaffold(
      appBar: AppBar(
        title: Text(service.name),
        backgroundColor: Colors.green[700],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: CachedNetworkImage(
                imageUrl: service.imageUrl,
                height: 200,
                width: double.infinity,
                fit: BoxFit.cover,
                placeholder: (context, url) => Shimmer.fromColors(
                  baseColor: Colors.grey[300]!,
                  highlightColor: Colors.grey[100]!,
                  child: Container(height: 200, color: Colors.grey[300]),
                ),
                errorWidget: (context, url, error) => Image.asset(
                  'assets/images/fallback_image.webp',
                  height: 200,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Title + Price
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    service.name,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Text(
                  '₹${service.price}',
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Duration: ${service.duration}',
              style: TextStyle(color: Colors.grey[600]),
            ),

            const SizedBox(height: 20),

            // Buttons (Moved before Key Features)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  onPressed: () {

                    showDialog(
                      context: context,
                      builder: (BuildContext context) {
                        return Dialog(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          insetPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 24,
                          ),
                          child: LayoutBuilder(
                            builder: (context, constraints) {
                              final screenHeight = MediaQuery.of(
                                context,
                              ).size.height;
                              final screenWidth = MediaQuery.of(
                                context,
                              ).size.width;

                              return ConstrainedBox(
                                constraints: BoxConstraints(
                                  maxHeight:
                                  screenHeight * 0.85, // Responsive height
                                  maxWidth:
                                  screenWidth * 0.95, // Responsive width
                                ),
                                child: SingleChildScrollView(
                                  padding: const EdgeInsets.all(16.0),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'Choose Date & Time',
                                        style: TextStyle(
                                          fontSize: 20,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 16),
                                      const Text(
                                        'When should the professional arrive?',
                                        style: TextStyle(fontSize: 16),
                                      ),
                                      const SizedBox(height: 8),

                                      // Date Selection
                                      Wrap(
                                        spacing: 8.0,
                                        runSpacing: 8.0,
                                        children: [
                                          for (var date in [
                                            'Wed, 24 Sept',
                                            'Thu, 25 Sept',
                                            'Fri, 26 Sept',
                                            'Sat, 27 Sept',
                                            'Sun, 28 Sept',
                                            'Mon, 29 Sept',
                                            'Tue, 30 Sept',
                                          ])
                                            ChoiceChip(
                                              label: Text(
                                                date,
                                                style: const TextStyle(
                                                  fontSize: 14,
                                                ),
                                              ),
                                              selected: false,
                                              onSelected: (bool selected) {},
                                            ),
                                        ],
                                      ),

                                      const SizedBox(height: 16),
                                      const Text(
                                        'Select start time of service',
                                        style: TextStyle(fontSize: 16),
                                      ),
                                      const SizedBox(height: 8),

                                      // Time Selection
                                      Wrap(
                                        spacing: 8.0,
                                        runSpacing: 8.0,
                                        children: [
                                          for (var time in [
                                            '5:08 PM',
                                            '5:38 PM',
                                            '6:08 PM',
                                            '6:38 PM',
                                            '7:08 PM',
                                            '7:38 PM',
                                            '8:08 PM',
                                            '8:38 PM',
                                            '9:08 PM',
                                            '9:38 PM',
                                            '10:08 PM',
                                            '10:38 PM',
                                            '11:08 PM',
                                            '11:38 PM',
                                          ])
                                            ChoiceChip(
                                              label: Text(
                                                time,
                                                style: const TextStyle(
                                                  fontSize: 14,
                                                ),
                                              ),
                                              selected: false,
                                              onSelected: (bool selected) {},
                                            ),
                                        ],
                                      ),

                                      const SizedBox(height: 16),
                                      const Text(
                                        'Select service hour',
                                        style: TextStyle(fontSize: 16),
                                      ),
                                      const SizedBox(height: 8),

                                      // Hour Selection
                                      Wrap(
                                        spacing: 8.0,
                                        runSpacing: 8.0,
                                        children: [
                                          for (var hour in [
                                            '30min',
                                            '1Hr',
                                            '2Hr',
                                            '3Hr',
                                            '4Hr',
                                            '5Hr',
                                            '6Hr',
                                          ])
                                            ChoiceChip(
                                              label: Text(
                                                hour,
                                                style: const TextStyle(
                                                  fontSize: 14,
                                                ),
                                              ),
                                              selected: false,
                                              onSelected: (bool selected) {},
                                            ),
                                        ],
                                      ),
                                      const Text(
                                        'Approx Price: ₹201',
                                        style: TextStyle(
                                          fontSize: 16,
                                          color: Colors.red,
                                        ),
                                      ),

                                      const SizedBox(height: 16),
                                      Padding(
                                        padding: const EdgeInsets.all(18.0),
                                        child: Row(
                                          mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                          children: [
                                            Row(
                                              children: [
                                                ElevatedButton(
                                                  onPressed: () {
                                                    final cartProvider = Provider.of<CartProvider>(context, listen: false);
                                                    cartProvider.addItem();

                                                    ScaffoldMessenger.of(context).showSnackBar(
                                                      const SnackBar(
                                                        content: Text('Added to Cart'),
                                                        duration: Duration(seconds: 2),
                                                      ),
                                                    );
                                                    Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (context)=>MainScreen()), (Route<dynamic> route)=>false);
                                                  },
                                                  style: ElevatedButton.styleFrom(
                                                    backgroundColor: Colors.blue,
                                                    foregroundColor: Colors.white,
                                                    minimumSize: const Size(100, 36),
                                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                                    shape: RoundedRectangleBorder(
                                                      borderRadius: BorderRadius.circular(8),
                                                    ),
                                                  ),
                                                  child: const Text(
                                                    'Add to Cart',
                                                    style: TextStyle(fontSize: 14),
                                                  ),
                                                ),
                                                const SizedBox(width: 8),
                                                ElevatedButton(
                                                  onPressed: () => Navigator.pop(context),
                                                  style: ElevatedButton.styleFrom(
                                                    backgroundColor: Colors.black,
                                                    foregroundColor: Colors.white,
                                                    minimumSize: const Size(100, 36),
                                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                                    shape: RoundedRectangleBorder(
                                                      borderRadius: BorderRadius.circular(8),
                                                    ),
                                                  ),
                                                  child: const Text(
                                                    'Book Now',
                                                    style: TextStyle(fontSize: 14),
                                                  ),
                                                ),
                                              ],
                                            )
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        );
                      },
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange[700],
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 14,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 5,
                    shadowColor: Colors.orange[300],
                    textStyle: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      Icon(Icons.add_shopping_cart, size: 20),
                      SizedBox(width: 8),
                      Text("Add to Cart"),
                    ],
                  ),
                ),
                ElevatedButton(
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green[700],
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 14,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 5,
                    shadowColor: Colors.green[300],
                    textStyle: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      Icon(Icons.book_online, size: 20),
                      SizedBox(width: 8),
                      Text("Book Now"),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Key Features
            const Text(
              "Key Features",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            ...detail.features.map(
                  (f) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 4.0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.check_circle,
                      color: Colors.green,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(f, style: const TextStyle(fontSize: 16)),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // What’s Included
            const Text(
              "What’s Included",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            ...detail.whatIsIncluded.map(
                  (f) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 4.0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.check_circle,
                      color: Colors.green,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(f, style: const TextStyle(fontSize: 16)),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // What’s Excluded
            const Text(
              "What’s Excluded",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            ...detail.whatIsExcluded.map(
                  (f) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 4.0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.cancel, color: Colors.red, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(f, style: const TextStyle(fontSize: 16)),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // FAQs
            const Text(
              "FAQs",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            ...detail.specifications
                .expand((spec) => spec['labels']!)
                .map(
                  (faq) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      faq['label']!,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      faq['value'] ?? '',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}