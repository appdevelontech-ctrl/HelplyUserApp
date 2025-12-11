import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';

class ServiceCategoryCard extends StatelessWidget {
  final String title;
  final String imageUrl;
  final String slug;
  final VoidCallback? onTap;

  const ServiceCategoryCard({
    super.key,
    required this.title,
    required this.imageUrl,
    required this.slug,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    // Get screen width for responsiveness
    final screenWidth = MediaQuery.of(context).size.width;

    // Responsive text and padding sizes
    final double titleFontSize = screenWidth < 400
        ? 12
        : screenWidth < 600
        ? 14
        : 16;

    final double exploreFontSize = screenWidth < 400
        ? 10
        : screenWidth < 600
        ? 12
        : 14;

    final double imageHeightFactor = screenWidth < 400
        ? 0.65
        : screenWidth < 600
        ? 0.7
        : 0.75;

    final double paddingValue = screenWidth < 400 ? 6 : 10;

    return LayoutBuilder(
      builder: (context, constraints) {
        return InkWell(
          onTap: onTap ?? () => debugPrint('Tapped on $title with slug: $slug'),
          child: Card(
            elevation: 4,
            shadowColor: Colors.black26,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                /// ✅ Responsive Image
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                  child: CachedNetworkImage(
                    imageUrl: imageUrl,
                    height: constraints.maxWidth * imageHeightFactor,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Shimmer.fromColors(
                      baseColor: Colors.grey[300]!,
                      highlightColor: Colors.grey[100]!,
                      child: Container(
                        height: constraints.maxWidth * imageHeightFactor,
                        width: double.infinity,
                        color: Colors.grey[300],
                      ),
                    ),
                    errorWidget: (context, url, error) => Image.asset(
                      'assets/images/fallback_image.webp',
                      height: constraints.maxWidth * imageHeightFactor,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),

                SizedBox(height: paddingValue),

                /// ✅ Responsive Title
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: paddingValue),
                  child: Text(
                    title,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: titleFontSize,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),

                const Spacer(),

                /// ✅ Responsive Explore Button
                Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: EdgeInsets.symmetric(
                    horizontal: paddingValue + 4,
                    vertical: screenWidth < 400 ? 3 : 5,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.blueAccent.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    "Explore",
                    style: TextStyle(
                      fontSize: exploreFontSize,
                      color: Colors.blueAccent,
                      fontWeight: FontWeight.bold,
                    ),
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
