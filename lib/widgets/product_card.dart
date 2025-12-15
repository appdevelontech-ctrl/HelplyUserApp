import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';

import '../models/serviceCategoryDetail.dart';

class ProductCard extends StatelessWidget {
  final Product product;
  final VoidCallback? onTap;

  const ProductCard({
    super.key,
    required this.product,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;

    final bool isSmall = w < 360;
    final bool isTablet = w >= 600;

    final double titleSize = isSmall ? 13 : isTablet ? 17 : 15;
    final double featureSize = isSmall ? 11 : 13;
    final double priceSize = isSmall ? 13 : 15;

    return Material(
      elevation: 4,
      borderRadius: BorderRadius.circular(14),
      color: Colors.white,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            // 🔥 IMAGE (FIXED RATIO)
            AspectRatio(
              aspectRatio: 4 / 3, // 👈 stable on all devices
              child: ClipRRect(
                borderRadius:
                const BorderRadius.vertical(top: Radius.circular(14)),
                child: CachedNetworkImage(
                  imageUrl: product.pImage,
                  fit: BoxFit.cover,
                  placeholder: (_, __) => Shimmer.fromColors(
                    baseColor: Colors.grey.shade300,
                    highlightColor: Colors.grey.shade200,
                    child: Container(color: Colors.grey.shade300),
                  ),
                  errorWidget: (_, __, ___) => Image.asset(
                    'assets/images/fallback_image.webp',
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ),

            // 🔥 CONTENT
            Padding(
              padding: EdgeInsets.all(isSmall ? 8 : 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [

                  // TITLE
                  Text(
                    product.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: titleSize,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),

                  const SizedBox(height: 6),

                  // FEATURES
                  Text(
                    product.features.isNotEmpty
                        ? product.features.join(' • ')
                        : 'No features available',
                    maxLines: isSmall ? 2 : 3,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: featureSize,
                      color: Colors.grey.shade700,
                      height: 1.3,
                    ),
                  ),

                  const SizedBox(height: 10),

                  // PRICE ROW
                  Row(
                    children: [
                      Text(
                        '₹${product.salePrice.toStringAsFixed(0)}',
                        style: TextStyle(
                          fontSize: priceSize,
                          fontWeight: FontWeight.bold,
                          color: Colors.green.shade700,
                        ),
                      ),
                      const SizedBox(width: 6),
                      if (product.regularPrice > product.salePrice)
                        Text(
                          '₹${product.regularPrice.toStringAsFixed(0)}',
                          style: TextStyle(
                            fontSize: priceSize - 2,
                            color: Colors.grey,
                            decoration: TextDecoration.lineThrough,
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
  }
}
