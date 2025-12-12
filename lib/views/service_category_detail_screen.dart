import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_html/flutter_html.dart';
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
      create: (_) => ServiceCategoryDetailController()
        ..fetchCategoryDetails(slug, location),

      child: Consumer<ServiceCategoryDetailController>(
        builder: (context, controller, _) {

          // ---------------- LOADING ----------------
          if (controller.isLoading) {
            return Scaffold(
              backgroundColor: Colors.grey.shade100,
              appBar: _zeptoAppBar(context,"Loading..."),
              body: _buildShimmerGrid(context),
            );
          }

          // ---------------- ERROR ----------------
          if (controller.errorMessage != null ||
              controller.mainCategory == null) {
            return Scaffold(
              backgroundColor: Colors.grey.shade100,
              appBar: _zeptoAppBar(context,"Error"),
              body: Center(
                child: Text(
                  controller.errorMessage ?? "Failed to load data",
                  style: TextStyle(color: Colors.red, fontSize: 16),
                ),
              ),
            );
          }

          // ---------------- SUCCESS ----------------
          final category = controller.mainCategory!;
          final products = controller.products;

          return Scaffold(
            backgroundColor: Colors.grey.shade100,
            appBar: _zeptoAppBar(context,category.title),

            body: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [

                  // 🔥 ZEPTO STYLE BANNER
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black12,
                          blurRadius: 12,
                          offset: Offset(0, 6),
                        )
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(18),
                      child: CachedNetworkImage(
                        imageUrl: category.image,
                        width: double.infinity,
                        height: 220,
                        fit: BoxFit.cover,
                        placeholder: (_, __) => Container(
                          height: 220,
                          color: Colors.grey.shade300,
                        ),
                        errorWidget: (_, __, ___) => Image.asset(
                          'assets/images/fallback_image.webp',
                          height: 220,
                          width: double.infinity,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // 🔥 TITLE (Minimal Like Zepto)
                  Text(
                    category.title,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),

                  const SizedBox(height: 8),

                  // 🔥 DESCRIPTION (Beautiful White Card)
                  Container(
                    padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black12,
                          blurRadius: 8,
                        )
                      ],
                    ),
                    child: Html(
                      data: category.description,
                      style: {
                        "body": Style(
                          fontSize: FontSize(15),
                          color: Colors.grey.shade700,
                          lineHeight: LineHeight(1.5),
                        )
                      },
                    ),
                  ),

                  const SizedBox(height: 20),

                  // 🔥 Safety Guide Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {},
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.black,
                        padding: EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                      ),
                      child: const Text(
                        "Cleaning Standards & Safety Guide",
                        style: TextStyle(color: Colors.white, fontSize: 16),
                      ),
                    ),
                  ),

                  const SizedBox(height: 28),

                  // 🔥 Section Title
                  Text(
                    "All ${category.title} Services",
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),

                  const SizedBox(height: 16),

                  // 🔥 GRID (Zepto Style)
                  LayoutBuilder(
                    builder: (_, constraints) {
                      int count = constraints.maxWidth ~/ 180;
                      if (count < 1) count = 1;
                      if (count > 2) count = 2;

                      return GridView.builder(
                        shrinkWrap: true,
                        physics: NeverScrollableScrollPhysics(),
                        itemCount: products.length,
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: count,
                          crossAxisSpacing: 14,
                          mainAxisSpacing: 14,
                          childAspectRatio: 0.68,
                        ),

                        itemBuilder: (_, i) {
                          final p = products[i];
                          return ProductCard(
                            product: p,
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageBuilder(p.slug, p.title),
                              );
                            },
                          );
                        },
                      );
                    },
                  ),

                  const SizedBox(height: 30),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  /// 🟦 ZEPTO STYLE APPBAR (White + Black Icons)
  AppBar _zeptoAppBar(BuildContext context ,String title) {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 1,
      centerTitle: true,
      leading: IconButton(
        icon: Icon(Icons.arrow_back_ios_new, color: Colors.black87, size: 20),
        onPressed: () {
          Navigator.pop(context);
        },
      ),
      title: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: Colors.black87,
        ),
      ),
    );
  }

  /// 🔵 CLEAN PAGE ROUTE TRANSITION (SLIDE)
  PageRouteBuilder MaterialPageBuilder(String slug, String name) {
    return PageRouteBuilder(
      transitionDuration: Duration(milliseconds: 350),
      pageBuilder: (_, __, ___) =>
          ProductDetailsPage(slug: slug, name: name),
      transitionsBuilder: (_, animation, __, child) {
        final offset =
        Tween(begin: Offset(1, 0), end: Offset.zero).animate(
            CurvedAnimation(parent: animation, curve: Curves.easeOutCubic));
        return SlideTransition(position: offset, child: child);
      },
    );
  }

  /// 🔷 SHIMMER (Zepto Light Grey)
  Widget _buildShimmerGrid(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        children: [
          _shimmerBox(height: 220),
          SizedBox(height: 20),
          _shimmerBox(height: 24, width: 180),
          SizedBox(height: 12),
          _shimmerBox(height: 14, width: 120),
          SizedBox(height: 18),
          _shimmerBox(height: 48),
          SizedBox(height: 20),
          GridView.builder(
            shrinkWrap: true,
            physics: NeverScrollableScrollPhysics(),
            itemCount: 4,
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 14,
              crossAxisSpacing: 14,
              childAspectRatio: 0.7,
            ),
            itemBuilder: (_, __) => _shimmerBox(height: 230),
          ),
        ],
      ),
    );
  }

  Widget _shimmerBox({double height = 200, double? width}) {
    return Shimmer.fromColors(
      baseColor: Colors.grey.shade300,
      highlightColor: Colors.grey.shade200,
      child: Container(
        width: width ?? double.infinity,
        height: height,
        decoration: BoxDecoration(
          color: Colors.grey.shade300,
          borderRadius: BorderRadius.circular(14),
        ),
      ),
    );
  }
}
