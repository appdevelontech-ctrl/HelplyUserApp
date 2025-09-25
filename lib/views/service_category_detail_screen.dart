import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';
import 'package:provider/provider.dart';
import 'package:user_app/views/product_details_page.dart';

import '../controllers/service_category_detail_controller.dart';

import '../controllers/service_category_controller.dart';
import '../models/serviceCategoryDetail.dart';
import '../widgets/product_card.dart';

class ServiceCategoryDetailScreen extends StatelessWidget {
  final String title;
  final String imageUrl;

  const ServiceCategoryDetailScreen({super.key, required this.title, required this.imageUrl});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ServiceCategoryController(title: title, imageUrl: imageUrl)),
        ChangeNotifierProvider(create: (_) => ServiceCategoryDetailController()),
      ],
      child: Consumer2<ServiceCategoryController, ServiceCategoryDetailController>(
        builder: (context, serviceCategoryController, serviceController, child) {
          // Check loading state
          if (serviceController.isLoading || serviceController.isLoading) {
            return Scaffold(
              appBar: AppBar(
                title: Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 20),
                ),
                backgroundColor: Colors.green[300],
                elevation: 2,
              ),
              body: _buildShimmerGrid(context),
            );
          }

          final service = serviceCategoryController.servicecategory;
          final products = serviceController.servicecategorydetail.map((product) {
            return Servicecategorydetail(
              name: '${service.title} - ${product.name}',
              description: product.description,
              price: product.price,
              duration: product.duration,
              imageUrl: service.imageUrl ?? product.imageUrl,
              regularPrice: double.tryParse(product.price.replaceAll('₹', '')) ?? 0.0,
              salePrice: (double.tryParse(product.price.replaceAll('₹', '')) ?? 0.0) * 0.7,
            );
          }).toList();

          if (products.isEmpty) {
            return const Scaffold(
              body: Center(child: Text('No services available')),
            );
          }

          return Scaffold(
            appBar: AppBar(
              title: Text(
                service.title,
                style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 20),
              ),
              backgroundColor: Colors.green[300],
              elevation: 2,
            ),
            body: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 🔹 Top Image Banner with Shadow
                  ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      decoration: BoxDecoration(
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black26,
                            spreadRadius: 2,
                            blurRadius: 12,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: CachedNetworkImage(
                        imageUrl: service.imageUrl,
                        width: double.infinity,
                        height: 220,
                        fit: BoxFit.cover,
                        placeholder: (context, url) => Shimmer.fromColors(
                          baseColor: Colors.grey[300]!,
                          highlightColor: Colors.grey[100]!,
                          child: Container(
                            width: double.infinity,
                            height: 220,
                            color: Colors.grey[300],
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

                  // 🔹 Service Title & Rating
                  Text(
                    service.title,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.green[700],
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(Icons.star, color: Colors.orange, size: 20),
                      const SizedBox(width: 4),
                      Text(
                        '4.8 (89% bookings)',
                        style: TextStyle(color: Colors.grey[700], fontSize: 14),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // 🔹 Action Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {},
                      icon: const Icon(Icons.info_outline),
                      label: const Text('Cleaning Standards & Safety Guide',style: TextStyle(color: Colors.white),),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green[500],
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // 🔹 All Services Grid Title
                  Text(
                    'All ${service.title}',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.green[800],
                    ),
                  ),
                  const SizedBox(height: 12),

                  // 🔹 Responsive Grid
                  LayoutBuilder(builder: (context, constraints) {
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
                        final serviceProduct = products[index];
                        return GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => ProductDetailsPage(service: serviceProduct),
                              ),
                            );
                          },
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
                                  child: CachedNetworkImage(
                                    imageUrl: serviceProduct.imageUrl,
                                    fit: BoxFit.cover,
                                    placeholder: (context, url) => Shimmer.fromColors(
                                      baseColor: Colors.grey[300]!,
                                      highlightColor: Colors.grey[100]!,
                                      child: Container(color: Colors.grey[300]),
                                    ),
                                    errorWidget: (context, url, error) => Image.asset(
                                      'assets/images/fallback_image.webp',
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        serviceProduct.name,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        '₹${serviceProduct.salePrice.toStringAsFixed(0)}',
                                        style: const TextStyle(
                                          color: Colors.green,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        'Duration: ${serviceProduct.duration}',
                                        style: TextStyle(color: Colors.grey[600], fontSize: 12),
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
                  }),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // Shimmer effect for the grid
  Widget _buildShimmerGrid(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Shimmer for top image banner
          Shimmer.fromColors(
            baseColor: Colors.grey[300]!,
            highlightColor: Colors.grey[100]!,
            child: Container(
              width: double.infinity,
              height: 220,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
          const SizedBox(height: 20),
          // Shimmer for title
          Shimmer.fromColors(
            baseColor: Colors.grey[300]!,
            highlightColor: Colors.grey[100]!,
            child: Container(
              width: 200,
              height: 28,
              color: Colors.grey[300],
            ),
          ),
          const SizedBox(height: 6),
          // Shimmer for rating
          Shimmer.fromColors(
            baseColor: Colors.grey[300]!,
            highlightColor: Colors.grey[100]!,
            child: Container(
              width: 100,
              height: 20,
              color: Colors.grey[300],
            ),
          ),
          const SizedBox(height: 12),
          // Shimmer for action button
          Shimmer.fromColors(
            baseColor: Colors.grey[300]!,
            highlightColor: Colors.grey[100]!,
            child: Container(
              width: double.infinity,
              height: 48,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          const SizedBox(height: 24),
          // Shimmer for grid title
          Shimmer.fromColors(
            baseColor: Colors.grey[300]!,
            highlightColor: Colors.grey[100]!,
            child: Container(
              width: 150,
              height: 28,
              color: Colors.grey[300],
            ),
          ),
          const SizedBox(height: 12),
          // Shimmer for grid
          LayoutBuilder(builder: (context, constraints) {
            int crossAxisCount = (constraints.maxWidth / 180).floor();
            if (crossAxisCount < 1) crossAxisCount = 1;
            if (crossAxisCount > 2) crossAxisCount = 2;

            return GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: 4, // Show 4 shimmer placeholders
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: crossAxisCount,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 0.65,
              ),
              itemBuilder: (context, index) {
                return Shimmer.fromColors(
                  baseColor: Colors.grey[300]!,
                  highlightColor: Colors.grey[100]!,
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
                          child: Container(
                            color: Colors.grey[300],
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                width: double.infinity,
                                height: 16,
                                color: Colors.grey[300],
                              ),
                              const SizedBox(height: 4),
                              Container(
                                width: 60,
                                height: 16,
                                color: Colors.grey[300],
                              ),
                              const SizedBox(height: 2),
                              Container(
                                width: 80,
                                height: 14,
                                color: Colors.grey[300],
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
          }),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}