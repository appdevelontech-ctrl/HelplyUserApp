import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';

import '../models/serviceCategoryDetail.dart';

class ProductCard extends StatelessWidget {
  final Product product;
  final VoidCallback? onTap;

  const ProductCard({super.key, required this.product, this.onTap});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    // 🔹 Responsive breakpoints
    final bool isSmall = screenWidth < 360;
    final bool isTablet = screenWidth >= 600;

    final double titleSize = isSmall ? 14 : isTablet ? 18 : 16;
    final double featureSize = isSmall ? 12 : 14;
    final double priceSize = isSmall ? 13 : 15;

    return Card(
      elevation: 6,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.green[100]!, width: 1),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        splashColor: Colors.green.withOpacity(0.3),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final imageHeight = constraints.maxHeight * (isTablet ? 0.55 : 0.5);

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ---------------- IMAGE ----------------
                ClipRRect(
                  borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(12)),
                  child: CachedNetworkImage(
                    imageUrl: product.pImage,
                    height: imageHeight,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    placeholder: (_, __) => Shimmer.fromColors(
                      baseColor: Colors.grey[300]!,
                      highlightColor: Colors.grey[100]!,
                      child: Container(
                        height: imageHeight,
                        width: double.infinity,
                        color: Colors.grey[300],
                      ),
                    ),
                    errorWidget: (_, __, ___) => Image.asset(
                      'assets/images/fallback_image.webp',
                      height: imageHeight,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),

                // ---------------- CONTENT ----------------
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.all(isSmall ? 8 : 10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // TITLE
                        Text(
                          product.title,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: titleSize,
                            color: Colors.black87,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),

                        const SizedBox(height: 6),

                        // FEATURES
                        Expanded(
                          child: Text(
                            product.features.isNotEmpty
                                ? product.features.join(' ')
                                : 'No features available',
                            style: TextStyle(
                              fontSize: featureSize,
                              color: Colors.grey[700],
                            ),
                            maxLines: isSmall ? 2 : 3,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),

                        const SizedBox(height: 6),

                        // PRICE
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                '₹${product.salePrice.toStringAsFixed(0)}',
                                style: TextStyle(
                                  fontSize: priceSize,
                                  color: Colors.green[800],
                                  fontWeight: FontWeight.w600,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (product.regularPrice > product.salePrice)
                              Padding(
                                padding: const EdgeInsets.only(left: 4),
                                child: Text(
                                  '₹${product.regularPrice.toStringAsFixed(0)}',
                                  style: TextStyle(
                                    fontSize: priceSize - 2,
                                    color: Colors.grey[600],
                                    decoration: TextDecoration.lineThrough,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
