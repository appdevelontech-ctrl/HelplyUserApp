import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';
import '../models/Service.dart'; // Ensure correct import path

class ServiceCard extends StatelessWidget {
  final Service service;
  final VoidCallback? onTap; // ✅ Add onTap callback


  const ServiceCard({super.key, required this.service,this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 6,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.green[100]!, width: 1),
      ),
      child: InkWell(
        onTap:  onTap,
        borderRadius: BorderRadius.circular(12),
        splashColor: Colors.green.withOpacity(0.3),
        child: LayoutBuilder(
          builder: (cardContext, cardConstraints) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Image section
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                  child: CachedNetworkImage(
                    imageUrl: service.imageUrl ?? '',
                    height: cardConstraints.maxHeight * 0.5,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Shimmer.fromColors(
                      baseColor: Colors.grey[300]!,
                      highlightColor: Colors.grey[100]!,
                      child: Container(
                        height: cardConstraints.maxHeight * 0.5,
                        width: double.infinity,
                        color: Colors.grey[300],
                      ),
                    ),
                    errorWidget: (context, url, error) => Image.asset(
                      'assets/images/fallback_image.webp',
                      height: cardConstraints.maxHeight * 0.5,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                // Content section
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(10.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Name
                        Text(
                          service.name ?? 'Unnamed Product',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: Colors.black87,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 6),
                        // Description with constrained height
                        Flexible(
                          fit: FlexFit.tight,
                          child: Text(
                            service.description ?? 'No description',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[700],
                            ),
                            maxLines: 2, // Reduced to 2 to accommodate price and duration
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(height: 6),
                        // Price in its own Row
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                'Price: ${service.price ?? 'N/A'}',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.green[800],
                                  fontWeight: FontWeight.w600,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        // Duration in a separate Row
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                'Duration: ${service.duration ?? 'N/A'}',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[700],
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
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