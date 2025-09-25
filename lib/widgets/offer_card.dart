import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';

class OfferCard extends StatefulWidget {
  final String title;
  final String subtitle;
  final String imageUrl;

  const OfferCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.imageUrl,
  });

  @override
  State<OfferCard> createState() => _OfferCardState();
}

class _OfferCardState extends State<OfferCard> {
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovering = true),
      onExit: (_) => setState(() => _hovering = false),
      child: AnimatedScale(
        duration: const Duration(milliseconds: 200),
        scale: _hovering ? 1.05 : 1.0,
        child: Container(
          width: 250,
          margin: const EdgeInsets.only(right: 12),
          child: Card(
            elevation: _hovering ? 10 : 4,
            shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            clipBehavior: Clip.antiAlias,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Image with zoom effect
                Stack(
                  children: [
                    CachedNetworkImage(
                      imageUrl: widget.imageUrl,
                      height: 140,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Shimmer.fromColors(
                        baseColor: Colors.grey[300]!,
                        highlightColor: Colors.grey[100]!,
                        child: Container(
                          height: 140,
                          width: double.infinity,
                          color: Colors.grey[300],
                        ),
                      ),
                      errorWidget: (context, url, error) => Image.asset(
                        'assets/images/fallback_image.webp',
                        height: 140,
                        width: double.infinity,
                        fit: BoxFit.cover,
                      ),
                    ),
                    Container(
                      height: 140,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.black.withOpacity(0.4),
                            Colors.transparent
                          ],
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                        ),
                      ),
                    ),
                  ],
                ),

                // Content
                Padding(
                  padding: const EdgeInsets.all(8),
                  child: Text(
                    widget.title,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Text(
                    widget.subtitle,
                    style: const TextStyle(fontSize: 13, color: Colors.grey),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
