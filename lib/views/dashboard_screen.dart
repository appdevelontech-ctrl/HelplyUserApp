import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../controllers/home_conroller.dart';
import '../widgets/service_category_card.dart';
import '../widgets/offer_card.dart';


class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<HomeController>(
      builder: (context, controller, _) {
        final currentServices =
            controller.servicesByLocation[controller.selectedLocation] ?? [];

        return RefreshIndicator(
          onRefresh: controller.refreshData,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Hero banner
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: CachedNetworkImage(
                    imageUrl:
                    "https://backend-olxs.onrender.com/uploads/new/image-1758194895880.webp",
                    width: double.infinity,
                    height: 180,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Shimmer.fromColors(
                      baseColor: Colors.grey[300]!,
                      highlightColor: Colors.grey[100]!,
                      child: Container(
                        width: double.infinity,
                        height: 180,
                        color: Colors.grey[300],
                      ),
                    ),
                    errorWidget: (context, url, error) => Image.asset(
                      'assets/images/fallback_image.webp',
                      width: double.infinity,
                      height: 180,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Services by Location
                if (controller.selectedLocation != "Select Location") ...[
                  Text(
                    "All Our House Help Services in ${controller.selectedLocation}",
                    style: Theme.of(context).textTheme.titleLarge,textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: controller.isLoading
                        ? 4
                        : currentServices.length, // 4 placeholders
                    gridDelegate:
                    const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 8,
                      mainAxisSpacing: 8,
                      childAspectRatio: 0.8,
                    ),
                    itemBuilder: (context, i) {
                      if (controller.isLoading) {
                        return Card(
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10)),
                          child: Column(
                            children: [
                              Container(
                                height: 80,
                                width: double.infinity,
                                color: Colors.grey[300],
                              ),
                              Padding(
                                padding: const EdgeInsets.all(4),
                                child: Container(
                                  height: 16,
                                  width: double.infinity,
                                  color: Colors.grey[300],
                                ),
                              ),
                            ],
                          ),
                        );
                      } else {
                        final s = currentServices[i];
                        return ServiceCategoryCard(
                          title: s.title,
                          imageUrl: s.imageUrl,
                        );
                      }
                    },
                  ),
                  const SizedBox(height: 20),
                ],

                // Best Offers
                Text("Best Offers", style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 12),
                SizedBox(
                  height: 240,
                  child: controller.isLoading
                      ? Shimmer.fromColors(
                    baseColor: Colors.grey[300]!,
                    highlightColor: Colors.grey[100]!,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: 4,
                      itemBuilder: (context, i) {
                        return Container(
                          width: 250,
                          margin: const EdgeInsets.only(right: 12),
                          child: Card(
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                            child: Column(
                              crossAxisAlignment:
                              CrossAxisAlignment.start,
                              children: [
                                Container(
                                  height: 130,
                                  width: double.infinity,
                                  color: Colors.grey[300],
                                ),
                                Padding(
                                  padding: const EdgeInsets.all(8),
                                  child: Container(
                                    height: 20,
                                    width: 150,
                                    color: Colors.grey[300],
                                  ),
                                ),
                                Padding(
                                  padding:
                                  const EdgeInsets.symmetric(
                                      horizontal: 8),
                                  child: Container(
                                    height: 15,
                                    width: 100,
                                    color: Colors.grey[300],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  )
                      : ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: controller.bestOffers.length,
                    itemBuilder: (context, i) {
                      final offer = controller.bestOffers[i];
                      return OfferCard(
                        title: offer.title,
                        subtitle: offer.subtitle,
                        imageUrl: offer.imageUrl,
                      );
                    },
                  ),
                ),


                // Footer
                const SizedBox(height: 20),
                Container(
                  color: Colors.blue.shade50,
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              "One Stop for All Household Help",
                              style: TextStyle(
                                  fontSize: 22, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 10),
                            const Text(
                                "Book trusted house help services anytime and anywhere. Reliable and affordable."),
                            const SizedBox(height: 10),
                            ElevatedButton(
                                onPressed: () {}, child: const Text("Book Now")),
                          ],
                        ),
                      ),
                      const SizedBox(width: 20),
                      Expanded(
                        child: CachedNetworkImage(
                          imageUrl:
                          "https://backend-olxs.onrender.com/uploads/new/image-1758104213573.png",
                          fit: BoxFit.contain,
                          placeholder: (context, url) =>
                              Shimmer.fromColors(
                                baseColor: Colors.grey[300]!,
                                highlightColor: Colors.grey[100]!,
                                child: Container(
                                  height: 100,
                                  color: Colors.grey[300],
                                ),
                              ),
                          errorWidget: (context, url, error) =>
                              Image.asset(
                                'assets/images/fallback_image.webp',
                                fit: BoxFit.contain,
                              ),
                        ),
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
  }
}
