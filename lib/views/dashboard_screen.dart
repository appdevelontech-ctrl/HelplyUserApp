  import 'package:flutter/material.dart';
  import 'package:provider/provider.dart';
  import 'package:shimmer/shimmer.dart';
  import 'package:cached_network_image/cached_network_image.dart';

  import '../controllers/home_conroller.dart';
  import '../widgets/service_category.dart';
  import '../widgets/offer_card.dart';
  import '../widgets/hover_effect.dart';
  import 'service_category_detail_screen.dart';

  class DashboardScreen extends StatefulWidget {
    const DashboardScreen({super.key});

    @override
    State<DashboardScreen> createState() => _DashboardScreenState();
  }

  class _DashboardScreenState extends State<DashboardScreen> with SingleTickerProviderStateMixin {
    bool _showSuggestion = true;
    AnimationController? _animationController;
    Animation<double>? _fadeAnimation;

    @override
    void initState() {
      super.initState();
      _animationController = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 500),
      );
      _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(parent: _animationController!, curve: Curves.easeInOut),
      );

      WidgetsBinding.instance.addPostFrameCallback((_) {
        final controller = Provider.of<HomeController>(context, listen: false);
        if (controller.selectedLocation == "Select Location" && _showSuggestion) {
          _animationController?.forward();
          Future.delayed(const Duration(seconds: 5), () {
            if (mounted) {
              setState(() {
                _showSuggestion = false;
              });
              _animationController?.reverse();
            }
          });
        }
      });
    }

    @override
    void dispose() {
      _animationController?.dispose();
      super.dispose();
    }

    @override
    Widget build(BuildContext context) {
      return Consumer<HomeController>(
        builder: (context, controller, _) {
          final currentServices = controller.servicesByLocation[controller.selectedLocation] ?? [];

          return Stack(
            children: [
              RefreshIndicator(
                onRefresh: controller.refreshData,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Stack(
                          children: [
                            CachedNetworkImage(
                              imageUrl:
                              "https://backend-olxs.onrender.com/uploads/new/image-1758194895880.webp",
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
                            Container(
                              height: 200,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [Colors.black.withOpacity(0.5), Colors.transparent],
                                  begin: Alignment.bottomCenter,
                                  end: Alignment.topCenter,
                                ),
                              ),
                            ),
                            Positioned(
                              left: 20,
                              bottom: 20,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "Find Trusted Help",
                                    style: Theme.of(context).textTheme.headlineSmall!.copyWith(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.orangeAccent,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                    ),
                                    onPressed: () {},
                                    child: const Text("Explore Now"),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      if (controller.selectedLocation != "Select Location") ...[
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.home_repair_service, color: Colors.blueAccent, size: 22),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: RichText(
                                    text: TextSpan(
                                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 16,
                                        color: Colors.black87,
                                      ),
                                      children: [
                                        const TextSpan(text: "All Our House Help Services in "),
                                        TextSpan(
                                          text: controller.selectedLocation,
                                          style: const TextStyle(
                                            color: Colors.blueAccent,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            GridView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: controller.isLoading ? 4 : currentServices.length,
                              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2,
                                crossAxisSpacing: 12,
                                mainAxisSpacing: 12,
                                childAspectRatio: 0.85,
                              ),
                              itemBuilder: (context, i) {
                                if (controller.isLoading) {
                                  return Card(
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Shimmer.fromColors(
                                      baseColor: Colors.grey[300]!,
                                      highlightColor: Colors.grey[100]!,
                                      child: Column(
                                        children: [
                                          Container(
                                            height: 100,
                                            width: double.infinity,
                                            color: Colors.grey[300],
                                          ),
                                          const SizedBox(height: 8),
                                          Container(
                                            height: 14,
                                            width: 80,
                                            color: Colors.grey[300],
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                } else {
                                  final s = currentServices[i];
                                  return ServiceCategoryCard(
                                    title: s.title,
                                    imageUrl: s.image,
                                    slug: s.slug,
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => ServiceCategoryDetailScreen(
                                            slug: s.slug,
                                            location: controller.selectedLocation,
                                          ),
                                        ),
                                      );
                                    },
                                  );
                                }
                              },
                            ),
                            const SizedBox(height: 20),
                          ],
                        ),
                      ],
                      Text(
                        "Best Offers",
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        height: 250,
                        child: controller.isLoading
                            ? Shimmer.fromColors(
                          baseColor: Colors.grey[300]!,
                          highlightColor: Colors.grey[100]!,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: 4,
                            itemBuilder: (context, i) {
                              return Container(
                                width: 240,
                                margin: const EdgeInsets.only(right: 12),
                                decoration: BoxDecoration(
                                  color: Colors.grey[300],
                                  borderRadius: BorderRadius.circular(12),
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
                            return Container(
                              margin: const EdgeInsets.only(right: 12),
                              child: HoverEffect(
                                child: OfferCard(
                                  title: offer.title,
                                  subtitle: offer.subtitle,
                                  imageUrl: offer.imageUrl,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 30),
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Colors.blue.shade400, Colors.blue.shade600],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(16),
                        ),
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
                                      fontSize: 22,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  const Text(
                                    "Book trusted house help services anytime and anywhere. Reliable and affordable.",
                                    style: TextStyle(color: Colors.white70),
                                  ),
                                  const SizedBox(height: 12),
                                  ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.orangeAccent,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                    ),
                                    onPressed: () {},
                                    child: const Text("Book Now"),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 20),
                            Expanded(
                              child: CachedNetworkImage(
                                imageUrl:
                                "https://backend-olxs.onrender.com/uploads/new/image-1758104213573.png",
                                fit: BoxFit.contain,
                                placeholder: (context, url) => Shimmer.fromColors(
                                  baseColor: Colors.grey[300]!,
                                  highlightColor: Colors.grey[100]!,
                                  child: Container(height: 100),
                                ),
                                errorWidget: (context, url, error) => Image.asset(
                                  'assets/images/fallback_image.webp',
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (_showSuggestion && controller.selectedLocation == "Select Location")
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: FadeTransition(
                    opacity: _fadeAnimation!,
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          _showSuggestion = false;
                        });
                        _animationController?.reverse();
                      },
                      child: Container(
                        margin: const EdgeInsets.all(12),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: Colors.blueAccent.withOpacity(0.9),
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: const [
                            BoxShadow(
                              color: Colors.black26,
                              blurRadius: 8,
                              offset: Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.location_on, color: Colors.white, size: 20),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                "Please select a location from the top bar to view services",
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.close, color: Colors.white, size: 20),
                              onPressed: () {
                                setState(() {
                                  _showSuggestion = false;
                                });
                                _animationController?.reverse();
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          );
        },
      );
    }
  }