import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';
import 'package:provider/provider.dart';
import 'package:user_app/views/service_details_page.dart';

import '../controllers/ServiceController.dart';
import '../controllers/service_category_controller.dart';
import '../models/Service.dart';
import '../widgets/service_card.dart';


class ServiceCategoryDetailScreen extends StatelessWidget {
  final String title;
  final String imageUrl;

  const ServiceCategoryDetailScreen({super.key, required this.title, required this.imageUrl});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ServiceCategoryController(title: title, imageUrl: imageUrl)),
        ChangeNotifierProvider(create: (_) => ServiceController()),
      ],
      child: Consumer2<ServiceCategoryController, ServiceController>(
        builder: (context, serviceCategoryController, serviceController, child) {
          final service = serviceCategoryController.service;
          final products = serviceController.products.map((product) {
            return Service(
              name: '${service.title} - ${product.name}',
              description: product.description,
              price: product.price,
              duration: product.duration,
              imageUrl: service.imageUrl ?? product.imageUrl,
              regularPrice: double.tryParse(product.price.replaceAll('₹', '')) ?? 0.0,
              salePrice: (double.tryParse(product.price.replaceAll('₹', '')) ?? 0.0) * 0.7, // 30% discount
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
                style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
              ),
              backgroundColor: Colors.green[100],
              elevation: 4,
            ),
            body: LayoutBuilder(
              builder: (context, constraints) {
                int crossAxisCount = (constraints.maxWidth / 180).floor();
                if (crossAxisCount < 1) crossAxisCount = 1;
                if (crossAxisCount > 2) crossAxisCount = 2;

                return SingleChildScrollView(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          decoration: BoxDecoration(
                            boxShadow: [
                              BoxShadow(
                                color: Colors.green.withOpacity(0.3),
                                spreadRadius: 2,
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: CachedNetworkImage(
                            imageUrl: service.imageUrl,
                            width: double.infinity,
                            height: 200,
                            fit: BoxFit.cover,
                            placeholder: (context, url) => Shimmer.fromColors(
                              baseColor: Colors.grey[300]!,
                              highlightColor: Colors.grey[100]!,
                              child: Container(
                                width: double.infinity,
                                height: 200,
                                color: Colors.grey[300],
                              ),
                            ),
                            errorWidget: (context, url, error) => Image.asset(
                              'assets/images/fallback_image.webp',
                              width: double.infinity,
                              height: 200,
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        service.title,
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Colors.green[800],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '⭐ 4.8 (89% bookings)', // Static for now
                        style: TextStyle(color: Colors.grey[600], fontSize: 16),
                      ),
                      const SizedBox(height: 8),
                      OutlinedButton(
                        onPressed: () {},
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: Colors.green[700]!),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        child: const Text(
                          'Cleaning Standards & Safety Guide',
                          style: TextStyle(color: Colors.green),
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'All ${service.title} Services',
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Colors.green[800],
                        ),
                      ),
                      const SizedBox(height: 12),
                      GridView.builder(
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
                          if (index >= 0 && index < products.length) {
                            final serviceProduct = products[index];
                            return ServiceCard(
                              service: serviceProduct,
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => ServiceDetailPage(service: serviceProduct),
                                  ),
                                );
                              },
                            );
                          }
                          return const SizedBox.shrink();
                        },
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}