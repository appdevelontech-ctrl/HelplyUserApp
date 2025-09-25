import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';
import '../controllers/product_detail_controller.dart';
import '../controllers/cart_provider.dart';

import '../main_screen.dart';

class ProductDetailsPage extends StatelessWidget {
  final String slug;
  final String name;

  const ProductDetailsPage({
    super.key,
    required this.slug,
    required this.name,
  });

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ProductDetailController()..fetchProductDetails(slug),
      child: Consumer<ProductDetailController>(
        builder: (context, controller, child) {
          if (controller.isLoading) {
            return Scaffold(
              appBar: AppBar(
                title: Text(name),
                backgroundColor: Colors.green[300],
                elevation: 2,
              ),
              body: _buildShimmer(context),
            );
          }

          if (controller.errorMessage != null || controller.productDetail == null) {
            return Scaffold(
              appBar: AppBar(
                title: Text(name),
                backgroundColor: Colors.green[300],
                elevation: 2,
              ),
              body: Center(child: Text(controller.errorMessage ?? 'Failed to load product details')),
            );
          }

          final product = controller.productDetail!;

          return Scaffold(
            appBar: AppBar(
              title: Text(product.title),
              backgroundColor: Colors.green[300],
              elevation: 2,
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
                      imageUrl: product.pImage,
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
                          product.title,
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            '₹${product.salePrice.toStringAsFixed(0)}',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Colors.green[800],
                            ),
                          ),
                          if (product.regularPrice > product.salePrice)
                            Text(
                              '₹${product.regularPrice.toStringAsFixed(0)}',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey[600],
                                decoration: TextDecoration.lineThrough,
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    product.metaDescription,
                    style: TextStyle(color: Colors.grey[600], fontSize: 14),
                  ),
                  const SizedBox(height: 20),
                  // Buttons
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
                                    final screenHeight = MediaQuery.of(context).size.height;
                                    final screenWidth = MediaQuery.of(context).size.width;

                                    return ConstrainedBox(
                                      constraints: BoxConstraints(
                                        maxHeight: screenHeight * 0.85,
                                        maxWidth: screenWidth * 0.95,
                                      ),
                                      child: SingleChildScrollView(
                                        padding: const EdgeInsets.all(16.0),
                                        child: Column(
                                          mainAxisSize: MainAxisSize.min,
                                          crossAxisAlignment: CrossAxisAlignment.start,
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
                                                      style: const TextStyle(fontSize: 14),
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
                                                      style: const TextStyle(fontSize: 14),
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
                                                      style: const TextStyle(fontSize: 14),
                                                    ),
                                                    selected: false,
                                                    onSelected: (bool selected) {},
                                                  ),
                                              ],
                                            ),
                                            const SizedBox(height: 16),
                                            Text(
                                              'Approx Price: ₹${product.salePrice.toStringAsFixed(0)}',
                                              style: const TextStyle(
                                                fontSize: 16,
                                                color: Colors.red,
                                              ),
                                            ),
                                            const SizedBox(height: 16),
                                            Padding(
                                              padding: const EdgeInsets.all(18.0),
                                              child: Row(
                                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                children: [
                                                  Row(
                                                    children: [
                                                      ElevatedButton(
                                                        onPressed: () {
                                                        //   final cartProvider = Provider.of<CartProvider>(context, listen: false);
                                                        //   cartProvider.addItem(product.title, product.salePrice);
                                                        //   ScaffoldMessenger.of(context).showSnackBar(
                                                        //     const SnackBar(
                                                        //       content: Text('Added to Cart'),
                                                        //       duration: Duration(seconds: 2),
                                                        //     ),
                                                        //   );
                                                        //   Navigator.pushAndRemoveUntil(
                                                        //     context,
                                                        //     MaterialPageRoute(builder: (context) => const MainScreen()),
                                                        //         (Route<dynamic> route) => false,
                                                        //   );
                                                        //
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
                                                  ),
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
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
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
                        onPressed: () {
                          // Placeholder for Book Now action
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Book Now clicked'),
                              duration: Duration(seconds: 2),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green[700],
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
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
                  // Description
                  const Text(
                    "Description",
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  Html(
                    data: product.description,
                    style: {
                      "body": Style(
                        fontSize: FontSize(16),
                        color: Colors.grey[800],
                      ),
                      "h3": Style(
                        fontSize: FontSize(18),
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                      "p": Style(
                        fontSize: FontSize(14),
                        color: Colors.grey[700],
                      ),
                      "ul": Style(
                        fontSize: FontSize(14),
                        color: Colors.grey[700],
                      ),
                      "li": Style(
                        fontSize: FontSize(14),
                        color: Colors.grey[700],
                      ),
                    },
                  ),
                  const SizedBox(height: 20),
                  // Key Features
                  const Text(
                    "Key Features",
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  ...product.features.map(
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
                            child: Text(
                              f,
                              style: const TextStyle(fontSize: 16),
                            ),
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
                  ...product.whatIsIncluded.map(
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
                            child: Text(
                              f,
                              style: const TextStyle(fontSize: 16),
                            ),
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
                  ...product.whatIsExcluded.map(
                        (f) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4.0),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(
                            Icons.cancel,
                            color: Colors.red,
                            size: 18,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              f,
                              style: const TextStyle(fontSize: 16),
                            ),
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
                  ...product.specifications.expand((spec) => spec.labels).map(
                        (faq) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            faq.label,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            faq.value,
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
        },
      ),
    );
  }

  Widget _buildShimmer(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Shimmer.fromColors(
            baseColor: Colors.grey[300]!,
            highlightColor: Colors.grey[100]!,
            child: Container(
              height: 200,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Shimmer.fromColors(
            baseColor: Colors.grey[300]!,
            highlightColor: Colors.grey[100]!,
            child: Container(
              height: 24,
              width: 200,
              color: Colors.grey[300],
            ),
          ),
          const SizedBox(height: 8),
          Shimmer.fromColors(
            baseColor: Colors.grey[300]!,
            highlightColor: Colors.grey[100]!,
            child: Container(
              height: 14,
              width: 100,
              color: Colors.grey[300],
            ),
          ),
          const SizedBox(height: 20),
          Shimmer.fromColors(
            baseColor: Colors.grey[300]!,
            highlightColor: Colors.grey[100]!,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Container(
                  height: 48,
                  width: 150,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                Container(
                  height: 48,
                  width: 150,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Shimmer.fromColors(
            baseColor: Colors.grey[300]!,
            highlightColor: Colors.grey[100]!,
            child: Container(
              height: 20,
              width: 150,
              color: Colors.grey[300],
            ),
          ),
          const SizedBox(height: 10),
          ...List.generate(
            3,
                (_) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 4.0),
              child: Shimmer.fromColors(
                baseColor: Colors.grey[300]!,
                highlightColor: Colors.grey[100]!,
                child: Container(
                  height: 16,
                  width: double.infinity,
                  color: Colors.grey[300],
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Shimmer.fromColors(
            baseColor: Colors.grey[300]!,
            highlightColor: Colors.grey[100]!,
            child: Container(
              height: 20,
              width: 150,
              color: Colors.grey[300],
            ),
          ),
          const SizedBox(height: 10),
          ...List.generate(
            3,
                (_) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 4.0),
              child: Shimmer.fromColors(
                baseColor: Colors.grey[300]!,
                highlightColor: Colors.grey[100]!,
                child: Container(
                  height: 16,
                  width: double.infinity,
                  color: Colors.grey[300],
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Shimmer.fromColors(
            baseColor: Colors.grey[300]!,
            highlightColor: Colors.grey[100]!,
            child: Container(
              height: 20,
              width: 150,
              color: Colors.grey[300],
            ),
          ),
          const SizedBox(height: 10),
          ...List.generate(
            3,
                (_) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 4.0),
              child: Shimmer.fromColors(
                baseColor: Colors.grey[300]!,
                highlightColor: Colors.grey[100]!,
                child: Container(
                  height: 16,
                  width: double.infinity,
                  color: Colors.grey[300],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}