import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../controllers/home_conroller.dart';
import 'service_category_detail_screen.dart';

// ----------------------------------------------------------
// HOVER EXTENSION (for animation)
// ----------------------------------------------------------
extension HoverScale on Widget {
  Widget hover() {
    return TweenAnimationBuilder(
      tween: Tween<double>(begin: 1, end: 1),
      duration: const Duration(milliseconds: 200),
      builder: (context, value, child) =>
          Transform.scale(scale: value, child: child),
      child: this,
    );
  }
}

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen>
    with SingleTickerProviderStateMixin {
  bool _showSuggestion = true;
  AnimationController? _animationController;
  Animation<double>? _fadeAnimation;

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _animationController!,
      curve: Curves.easeInOut,
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final controller =
      Provider.of<HomeController>(context, listen: false);

      if (controller.selectedLocation == "Select Location") {
        _animationController?.forward();

        Future.delayed(const Duration(seconds: 3), () {
          if (!mounted) return;
          setState(() => _showSuggestion = false);
          _animationController?.reverse();
        });
      }
    });
  }

  @override
  void dispose() {
    _animationController?.dispose();
    super.dispose();
  }
  Widget fastImage(
      String url, {
        double? height,
        double? width,
        BoxFit fit = BoxFit.cover,
        BorderRadius? borderRadius,
      }) {
    return ClipRRect(
      borderRadius: borderRadius ?? BorderRadius.zero, // 👈 important
      child: CachedNetworkImage(
        imageUrl: url,
        height: height,
        width: width,
        fit: fit,

        // 👇 YE LINES PURPLE / EDGE ISSUE FIX KARTI HAIN
        fadeInDuration: Duration.zero,
        fadeOutDuration: Duration.zero,


        memCacheHeight: 650,
        memCacheWidth: 650,

        placeholder: (_, __) => Container(
          height: height,
          width: width,
          color: Colors.grey.shade200, // ❌ white mat rakho
        ),

        errorWidget: (_, __, ___) => Container(
          height: height,
          width: width,
          color: Colors.grey.shade200,
          alignment: Alignment.center,
          child: const Icon(Icons.broken_image, color: Colors.grey),
        ),
      ),
    );
  }


  // ----------------------------------------------------------
  // UI START
  // ----------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    return Consumer<HomeController>(
      builder: (context, controller, _) {
        final currentServices =
            controller.servicesByLocation[controller.selectedLocation] ?? [];

        return Stack(
          children: [
            RefreshIndicator(
              onRefresh: controller.refreshData,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ----------------------------------------------------------
                    // HERO BANNER (Zepto Style)
                    // ----------------------------------------------------------
                    Container(
                      height: 220,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(22),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.15),
                            blurRadius: 20,
                            spreadRadius: 1,
                            offset: Offset(0, 8),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(22),
                        child: fastImage(
                          controller.sliderImage,
                          height: 220,
                          width: double.infinity,
                          fit: BoxFit.fill,
                        ),
                      ),
                    )
,

                    const SizedBox(height: 22),

                    if (controller.selectedLocation != "Select Location") ...[
                      Text(
                        "House Help Services in ${controller.selectedLocation}",
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),

                      const SizedBox(height: 14),

                      // ----------------------------------------------------------
                      // CATEGORY GRID (Zepto Style)
                      // ----------------------------------------------------------
                      GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount:
                        controller.isLoading ? 4 : currentServices.length,
                        gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 16,
                          childAspectRatio: 0.78,
                        ),
                        itemBuilder: (context, i) {
                          if (controller.isLoading) return _shimmerCard();

                          final service = currentServices[i];

                          return GestureDetector(
                            onTap: () {
                              Navigator.push(
                                  context,
                                  PageRouteBuilder(
                                    transitionDuration: Duration(milliseconds: 350),
                                    pageBuilder: (_, __, ___) => ServiceCategoryDetailScreen(slug: service.slug, location: controller.selectedLocation),
                                    transitionsBuilder: (_, animation, __, child) {
                                      final offset = Tween(begin: Offset(1, 0), end: Offset.zero)
                                          .animate(CurvedAnimation(parent: animation, curve: Curves.easeOutCubic));
                                      return SlideTransition(position: offset, child: child);
                                    },
                                  ));
                            },
                            child: serviceCard(
                              title: service.title,
                              imageUrl: service.image,
                            ).hover(),
                          );

                        },
                      ),

                      const SizedBox(height: 26),
                    ],

                    // ----------------------------------------------------------
                    // BEST OFFERS (Horizontal Slider)
                    // ----------------------------------------------------------
                    const Text(
                      "Best Offers",
                      style:
                      TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),

                    SizedBox(
                      height: 250,
                      child: controller.isSliderLoading
                          ? _offerShimmer()
                          : ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: controller.bestOffers.length,
                        separatorBuilder: (_, __) =>
                        const SizedBox(width: 14),
                        itemBuilder: (context, i) {
                          final offer = controller.bestOffers[i];

                          return GestureDetector(
                            onTap: () {
                              if (offer.url != null &&
                                  offer.url != "#") {
                                final slug =
                                    offer.url!.split("/").last;

                                Navigator.push(
                                    context,
                                    PageRouteBuilder(
                                      transitionDuration: Duration(milliseconds: 350),
                                      pageBuilder: (_, __, ___) => ServiceCategoryDetailScreen(slug:slug, location: controller.selectedLocation),
                                      transitionsBuilder: (_, animation, __, child) {
                                        final offset = Tween(begin: Offset(1, 0), end: Offset.zero)
                                            .animate(CurvedAnimation(parent: animation, curve: Curves.easeOutCubic));
                                        return SlideTransition(position: offset, child: child);
                                      },
                                    ));
                              }
                            },
                            child: Container(
                              width: 260,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(18),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.10),
                                    blurRadius: 15,
                                    offset: const Offset(0, 6),
                                  ),
                                ],
                                image: DecorationImage(
                                  image: CachedNetworkImageProvider(
                                      offer.imageUrl),
                                  fit: BoxFit.cover,
                                ),
                              ),
                              child: Container(
                                alignment: Alignment.bottomLeft,
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  borderRadius:
                                  BorderRadius.circular(18),
                                  gradient: LinearGradient(
                                    colors: [
                                      Colors.black.withOpacity(0.7),
                                      Colors.transparent
                                    ],
                                    begin: Alignment.bottomCenter,
                                    end: Alignment.topCenter,
                                  ),
                                ),
                                child: Text(
                                  offer.title,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ).hover(),
                          );
                        },
                      ),
                    ),

                    const SizedBox(height: 30),
                    homeHeroCard(context)

                  ],
                ),
              ),
            ),

            // ----------------------------------------------------------
            // LOCATION SUGGESTION
            // ----------------------------------------------------------
            if (_showSuggestion &&
                controller.selectedLocation == "Select Location")
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: FadeTransition(
                  opacity: _fadeAnimation!,
                  child: Container(
                    margin: const EdgeInsets.all(12),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blueAccent,
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: const [
                        BoxShadow(
                          color: Colors.black38,
                          blurRadius: 10,
                        )
                      ],
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.location_on,
                            color: Colors.white, size: 20),
                        const SizedBox(width: 10),
                        const Expanded(
                          child: Text(
                            "Please select a location to view services",
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        GestureDetector(
                          onTap: () {
                            setState(() => _showSuggestion = false);
                            _animationController?.reverse();
                          },
                          child: const Icon(Icons.close,
                              color: Colors.white, size: 20),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }




  Widget homeHeroCard(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final w = size.width;

    final bool isSmall = w < 360;
    final bool isTablet = w >= 600;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: w * 0.05,
        vertical: w * 0.055,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.blue.shade500,
            Colors.blue.shade700,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.shade700.withOpacity(0.35),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),

      child: LayoutBuilder(
        builder: (_, constraints) {
          final isNarrow = constraints.maxWidth < 500;

          return Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [

              /// 🔥 TEXT SECTION
              Expanded(
                flex: isNarrow ? 3 : 4,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "One Stop for All\nHousehold Help",
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: isSmall
                            ? 18
                            : isTablet
                            ? 26
                            : 22,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        height: 1.25,
                        letterSpacing: 0.3,
                      ),
                    ),

                    SizedBox(height: w * 0.025),

                    Text(
                      "Book trusted home services anytime, anywhere.\nFast, reliable and affordable professionals.",
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: isSmall ? 13 : 15,
                        color: Colors.white.withOpacity(0.9),
                        height: 1.45,
                      ),
                    ),
                  ],
                ),
              ),

              SizedBox(width: w * 0.04),

              /// 🔥 IMAGE SECTION (ROUNDED + REDUCED)
              Expanded(
                flex: isNarrow ? 2 : 3,
                child: Padding(
                  padding: EdgeInsets.all(w * 0.02),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(w * 0.06), // 👈 smooth radius
                    child: AspectRatio(
                      aspectRatio: 1,
                      child: CachedNetworkImage(
                        imageUrl:
                        "https://backend-olxs.onrender.com/uploads/new/image-1758104213573.png",
                        fit: BoxFit.contain,
                        placeholder: (_, __) => Shimmer.fromColors(
                          baseColor: Colors.white.withOpacity(0.2),
                          highlightColor: Colors.white.withOpacity(0.35),
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius:
                              BorderRadius.circular(w * 0.06), // 👈 match radius
                            ),
                          ),
                        ),
                        errorWidget: (_, __, ___) => Image.asset(
                          'assets/images/fallback_image.webp',
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                  ),
                ),
              ),


            ],
          );
        },
      ),
    );
  }


  Widget serviceCard({
    required String title,
    required String imageUrl,
  }) {
    return LayoutBuilder(
      builder: (context, constraints) {
        double cardWidth = constraints.maxWidth == double.infinity
            ? 150
            : constraints.maxWidth;

        return Container(
          width: cardWidth,
          height: cardWidth * 1.1, // responsive height
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: Colors.black26,
                blurRadius: 8,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: Stack(
              children: [
                // ---------------- BACKGROUND IMAGE ----------------
                Positioned.fill(
                  child: CachedNetworkImage(
                    imageUrl: imageUrl,
                    fit: BoxFit.cover,
                    placeholder: (c, s) => Container(color: Colors.grey.shade200),
                    errorWidget: (c, s, e) =>
                    const Center(child: Icon(Icons.error, size: 40)),
                  ),
                ),

                // ---------------- GRADIENT OVERLAY ----------------
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withOpacity(0.55),
                        ],
                      ),
                    ),
                  ),
                ),

                // ---------------- CENTER BOTTOM TEXT ----------------
                Positioned(
                  bottom: MediaQuery.of(context).size.width < 360 ? 8 : 12,
                  left: 8,
                  right: 8,
                  child: Center(
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final width = MediaQuery.of(context).size.width;

                        final double fontSize =
                        width < 360 ? 12 : width < 600 ? 14 : 16;

                        final int maxLines =
                        width < 360 ? 2 : 3;

                        return Text(
                          title,
                          textAlign: TextAlign.center,
                          maxLines: maxLines,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: fontSize,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.2,
                            height: 1.2,
                            shadows: const [
                              Shadow(
                                blurRadius: 6,
                                color: Colors.black54,
                              ),
                            ],
                          ),
                        );
                      },
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





  // ----------------------------------------------------------
  // SHIMMER WIDGETS
  // ----------------------------------------------------------
  Widget _shimmerCard() {
    return Shimmer.fromColors(
      baseColor: Colors.grey.shade300,
      highlightColor: Colors.grey.shade100,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.grey.shade300,
          borderRadius: BorderRadius.circular(18),
        ),
      ),
    );
  }

  Widget _offerShimmer() {
    return ListView.builder(
      scrollDirection: Axis.horizontal,
      itemCount: 3,
      itemBuilder: (_, __) => Container(
        width: 260,
        margin: const EdgeInsets.only(right: 14),
        decoration: BoxDecoration(
          color: Colors.grey.shade300,
          borderRadius: BorderRadius.circular(18),
        ),
      ),
    );
  }
}
