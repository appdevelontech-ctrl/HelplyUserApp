import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_html/flutter_html.dart'; // Add this import
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';
import '../controllers/service_category_detail_controller.dart';
import '../widgets/product_card.dart';
import 'product_details_page.dart';

class ServiceCategoryDetailScreen extends StatelessWidget {
  final String slug;
  final String location;

  const ServiceCategoryDetailScreen({
    super.key,
    required this.slug,
    required this.location,
  });

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) =>
      ServiceCategoryDetailController()..fetchCategoryDetails(slug, location),
      child: Consumer<ServiceCategoryDetailController>(
        builder: (context, controller, child) {
          if (controller.isLoading) {
            return Scaffold(
              appBar: _buildAppBar("Loading..."),
              body: _buildShimmerGrid(context),
            );
          }

          if (controller.errorMessage != null || controller.mainCategory == null) {
            return Scaffold(
              appBar: _buildAppBar("Error"),
              body: Center(
                child: Text(
                  controller.errorMessage ?? 'Failed to load data',
                  style: const TextStyle(color: Colors.red),
                ),
              ),
            );
          }

          final mainCategory = controller.mainCategory!;
          final products = controller.products;

          return Scaffold(
            appBar: _buildAppBar(mainCategory.title),
            body: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  /// 🔹 Banner
                  ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      decoration: BoxDecoration(
                        boxShadow: [
                          BoxShadow(
                            color: Colors.blue.withOpacity(0.3),
                            spreadRadius: 2,
                            blurRadius: 12,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: CachedNetworkImage(
                        imageUrl: mainCategory.image,
                        width: double.infinity,
                        height: 220,
                        fit: BoxFit.cover,
                        placeholder: (context, url) => Shimmer.fromColors(
                          baseColor: Colors.blue.shade100,
                          highlightColor: Colors.blue.shade50,
                          child: Container(
                            width: double.infinity,
                            height: 220,
                            color: Colors.blue.shade100,
                          ),
                        ),
                        errorWidget: (context, url, error) => Image.asset(
                          'assets/images/fallback_image.webp',
                          width: double.infinity,
                          height: 220,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  /// 🔹 Title
                  Text(
                    mainCategory.title,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.blue[800],
                    ),
                  ),
                  const SizedBox(height: 6),

                  /// 🔹 Description
                  Html(
                    data: mainCategory.description,
                    style: {
                      "p": Style(
                        fontSize: FontSize(14),
                        color: Colors.grey[700],
                      ),
                      "h2": Style(
                        fontSize: FontSize(18),
                        fontWeight: FontWeight.bold,
                        color: Colors.blue[800],
                      ),
                      "strong": Style(
                        fontWeight: FontWeight.bold,
                      ),
                    },
                  ),
                  const SizedBox(height: 12),

                  /// 🔹 Rating
                  Row(
                    children: [
                      const Icon(
                        Icons.star,
                        color: Colors.orangeAccent,
                        size: 20,
                      ),
                      const SizedBox(width: 4),

                    ],
                  ),
                  const SizedBox(height: 12),

                  /// 🔹 Action Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {},
                      icon: const Icon(Icons.info_outline, color: Colors.white),
                      label: const Text(
                        'Cleaning Standards & Safety Guide',
                        style: TextStyle(color: Colors.white),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue[600],
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 3,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  /// 🔹 Products Title
                  Text(
                    'All ${mainCategory.title} Services',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.blue[900],
                    ),
                  ),
                  const SizedBox(height: 12),

                  /// 🔹 Products Grid
                  LayoutBuilder(
                    builder: (context, constraints) {
                      int crossAxisCount = (constraints.maxWidth / 180).floor();
                      if (crossAxisCount < 1) crossAxisCount = 1;
                      if (crossAxisCount > 2) crossAxisCount = 2;

                      return GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: products.length,
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: crossAxisCount,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                          childAspectRatio: 0.65,
                        ),
                        itemBuilder: (context, index) {
                          final product = products[index];
                          return ProductCard(
                            product: product,
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => ProductDetailsPage(
                                    slug: product.slug,
                                    name: product.title,
                                  ),
                                ),
                              );
                            },
                          );
                        },
                      );
                    },
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          );
        },
      ),
    );
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

  /// 🔹 Shimmer Loader (Blue)
  Widget _buildShimmerGrid(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Shimmer.fromColors(
            baseColor: Colors.blue.shade100,
            highlightColor: Colors.blue.shade50,
            child: Container(
              width: double.infinity,
              height: 220,
              decoration: BoxDecoration(
                color: Colors.blue.shade100,
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Shimmer.fromColors(
            baseColor: Colors.blue.shade100,
            highlightColor: Colors.blue.shade50,
            child: Container(
              width: 200,
              height: 28,
              color: Colors.blue.shade100,
            ),
          ),
          const SizedBox(height: 6),
          Shimmer.fromColors(
            baseColor: Colors.blue.shade100,
            highlightColor: Colors.blue.shade50,
            child: Container(
              width: 100,
              height: 20,
              color: Colors.blue.shade100,
            ),
          ),
          const SizedBox(height: 12),
          Shimmer.fromColors(
            baseColor: Colors.blue.shade100,
            highlightColor: Colors.blue.shade50,
            child: Container(
              width: double.infinity,
              height: 48,
              decoration: BoxDecoration(
                color: Colors.blue.shade100,
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          const SizedBox(height: 24),
          Shimmer.fromColors(
            baseColor: Colors.blue.shade100,
            highlightColor: Colors.blue.shade50,
            child: Container(
              width: 150,
              height: 28,
              color: Colors.blue.shade100,
            ),
          ),
          const SizedBox(height: 12),
          LayoutBuilder(
            builder: (context, constraints) {
              int crossAxisCount = (constraints.maxWidth / 180).floor();
              if (crossAxisCount < 1) crossAxisCount = 1;
              if (crossAxisCount > 2) crossAxisCount = 2;

              return GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: 4,
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: crossAxisCount,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 0.65,
                ),
                itemBuilder: (context, index) {
                  return Shimmer.fromColors(
                    baseColor: Colors.blue.shade100,
                    highlightColor: Colors.blue.shade50,
                    child: Card(
                      elevation: 3,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Expanded(
                            child: Container(color: Colors.blue.shade100),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  width: double.infinity,
                                  height: 16,
                                  color: Colors.blue.shade100,
                                ),
                                const SizedBox(height: 4),
                                Container(
                                  width: 60,
                                  height: 16,
                                  color: Colors.blue.shade100,
                                ),
                                const SizedBox(height: 2),
                                Container(
                                  width: 80,
                                  height: 14,
                                  color: Colors.blue.shade100,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}