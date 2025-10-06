import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';
import 'package:intl/intl.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import '../controllers/product_detail_controller.dart';
import '../controllers/cart_provider.dart';
import '../main_screen.dart';
import '../models/serviceCategoryDetail.dart';
import 'cartpage.dart';

class ProductDetailsPage extends StatefulWidget {
  final String slug;
  final String name;

  const ProductDetailsPage({super.key, required this.slug, required this.name});

  @override
  State<ProductDetailsPage> createState() => _ProductDetailsPageState();
}

class _ProductDetailsPageState extends State<ProductDetailsPage> {
  @override
  void initState() {
    super.initState();
    // Fetch product details is already handled by ChangeNotifierProvider
  }

  Future<void> _refreshProductDetails(ProductDetailController controller) async {
    await EasyLoading.show(status: 'Refreshing product details...');
    await controller.fetchProductDetails(widget.slug);
    if (controller.errorMessage == null) {
      await EasyLoading.showSuccess('Product details refreshed successfully');
    }
  }

  void _showAddToCartDialog(BuildContext context, ProductDetail product, CartProvider cartProvider) {
    if (cartProvider.cartItems.isNotEmpty) {
      EasyLoading.showError('Already added a product. Please complete that order first.');
      return;
    }

    DateTime now = DateTime.now();
    List<DateTime> dateList = List.generate(11, (i) => now.add(Duration(days: i)));
    DateTime? selectedDate = dateList[0];
    DateTime? selectedTime;
    String selectedDuration = widget.slug == 'multiday-service' ? 'FullDay' : '30min';
    double calculatedPrice = product.salePrice;

    List<DateTime> generateTimesForDate(DateTime date) {
      bool isToday = date.year == now.year && date.month == now.month && date.day == now.day;
      DateTime start = isToday
          ? now.add(Duration(minutes: 30 - (now.minute % 30)))
          : DateTime(date.year, date.month, date.day, 8, 0);
      DateTime end = DateTime(date.year, date.month, date.day, 22, 0);
      if (start.isAfter(end)) {
        start = DateTime(date.year, date.month, date.day, 8, 0);
      }

      List<DateTime> times = [];
      DateTime current = start;
      while (current.isBefore(end) || current.isAtSameMomentAs(end)) {
        times.add(current);
        current = current.add(const Duration(minutes: 30));
      }
      return times;
    }

    int getMinutesFromHour(String hour) {
      if (hour == '30min') return 30;
      return int.parse(hour.substring(0, hour.length - 2)) * 60;
    }

    void updatePrice() {
      if (widget.slug == 'multiday-service') {
        if (selectedDuration == 'FullDay') {
          calculatedPrice = product.salePrice;
        } else {
          int days = int.parse(selectedDuration.replaceAll('days', ''));
          calculatedPrice = product.salePrice * days;
        }
      } else {
        int minutes = getMinutesFromHour(selectedDuration);
        if (minutes <= 30) {
          calculatedPrice = product.salePrice;
        } else {
          calculatedPrice = product.salePrice + (minutes - 30) * product.minPrice;
        }
      }
    }

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Dialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.85,
                  maxWidth: MediaQuery.of(context).size.width * 0.95,
                ),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Choose Date & Time',
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Select Date',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: dateList.map((date) {
                          String dateStr = DateFormat('EEE, d MMM').format(date);
                          return ChoiceChip(
                            label: Text(dateStr),
                            selected: selectedDate == date,
                            onSelected: (bool selected) {
                              setState(() {
                                selectedDate = date;
                                selectedTime = null;
                              });
                            },
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Select Start Time',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 8),
                      if (selectedDate != null)
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: generateTimesForDate(selectedDate!).map((time) {
                            String timeStr = DateFormat('h:mm a').format(time);
                            return ChoiceChip(
                              label: Text(timeStr),
                              selected: selectedTime == time,
                              onSelected: (bool selected) {
                                setState(() {
                                  selectedTime = time;
                                });
                              },
                            );
                          }).toList(),
                        ),
                      const SizedBox(height: 16),
                      if (widget.slug == 'multiday-service')
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Select Service Days',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                            ),
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: ['FullDay', '2days', '3days', '4days', '5days', '6days'].map((day) {
                                return ChoiceChip(
                                  label: Text(day),
                                  selected: selectedDuration == day,
                                  onSelected: (bool selected) {
                                    setState(() {
                                      selectedDuration = day;
                                      updatePrice();
                                    });
                                  },
                                );
                              }).toList(),
                            ),
                          ],
                        )
                      else
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Select Service Hours',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                            ),
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: ['30min', '1Hr', '2Hr', '3Hr', '4Hr', '5Hr', '6Hr'].map((hour) {
                                return ChoiceChip(
                                  label: Text(hour),
                                  selected: selectedDuration == hour,
                                  onSelected: (bool selected) {
                                    setState(() {
                                      selectedDuration = hour;
                                      updatePrice();
                                    });
                                  },
                                );
                              }).toList(),
                            ),
                          ],
                        ),
                      const SizedBox(height: 16),
                      Text(
                        'Approx Price: ₹${calculatedPrice.toStringAsFixed(0)}',
                        style: TextStyle(fontSize: 16, color: Colors.green[800], fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('Cancel'),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton(
                            onPressed: () async {
                              if (selectedDate == null || selectedTime == null || selectedDuration.isEmpty) {
                                EasyLoading.showError('Please select date, time, and duration');
                                return;
                              }

                              final cartProduct = product.toProduct(
                                selectedDate: selectedDate,
                                selectedTime: selectedTime,
                                selectedDuration: selectedDuration,
                                salePrice: calculatedPrice,
                              );

                              try {
                                await EasyLoading.show(status: 'Adding to cart...');
                                await cartProvider.addToCart(cartProduct);
                                await EasyLoading.showSuccess('Product added to cart');
                                if (mounted) {
                                  Navigator.pop(context);
                                }
                              } catch (e) {
                                await EasyLoading.showError('Failed to add to cart: $e');
                              }
                            },
                            child: const Text('Add to Cart'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ProductDetailController()..fetchProductDetails(widget.slug),
      child: Scaffold(
        body: RefreshIndicator(
          onRefresh: () => _refreshProductDetails(context.read<ProductDetailController>()),
          color: Colors.orangeAccent,
          child: Consumer<ProductDetailController>(
            builder: (context, controller, child) {
              if (controller.isLoading) {
                return Scaffold(
                  appBar: _buildAppBar("Loading..."),
                  body: _buildShimmer(context),
                );
              }

              if (controller.errorMessage != null || controller.productDetail == null) {
                return Scaffold(
                  appBar: _buildAppBar(widget.name),
                  body: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          controller.errorMessage ?? 'Failed to load product details',
                          style: const TextStyle(fontSize: 16, color: Colors.red),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () => _refreshProductDetails(controller),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blueAccent,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  ),
                );
              }

              final product = controller.productDetail!;
              final cartProvider = Provider.of<CartProvider>(context, listen: false);

              return Scaffold(
                appBar: _buildAppBar(product.title),
                body: SingleChildScrollView(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: CachedNetworkImage(
                          imageUrl: product.pImage,
                          height: 200,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          placeholder: (context, url) => Shimmer.fromColors(
                            baseColor: Colors.grey[300]!,
                            highlightColor: Colors.grey[100]!,
                            child: Container(height: 200, color: Colors.grey[300]),
                          ),
                          errorWidget: (context, url, error) => Image.asset(
                            'assets/images/fallback_image.webp',
                            height: 200,
                            width: double.infinity,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              product.title,
                              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                            ),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                '₹${product.salePrice.toStringAsFixed(0)}',
                                style: const TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xff004e92),
                                ),
                              ),
                              if (product.regularPrice > product.salePrice)
                                Text(
                                  '₹${product.regularPrice.toStringAsFixed(0)}',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.grey[600],
                                    decoration: TextDecoration.lineThrough,
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        product.metaDescription,
                        style: TextStyle(color: Colors.grey[600], fontSize: 14),
                      ),
                      const SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          ElevatedButton(
                            onPressed: () => _showAddToCartDialog(context, product, cartProvider),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xff004e92),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              elevation: 5,
                              shadowColor: Colors.blue[300],
                              textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.add_shopping_cart, size: 20),
                                SizedBox(width: 8),
                                Text("Add to Cart"),
                              ],
                            ),
                          ),
                          ElevatedButton(
                            onPressed: () => _showAddToCartDialog(context, product, cartProvider),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xff000428),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              elevation: 5,
                              shadowColor: Colors.blue[300],
                              textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.book_online, size: 20),
                                SizedBox(width: 8),
                                Text("Book Now"),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      const Text(
                        "Description",
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 10),
                      Html(
                        data: product.description,
                        style: {
                          "body": Style(fontSize: FontSize(16), color: Colors.grey[800]),
                          "h3": Style(fontSize: FontSize(18), fontWeight: FontWeight.bold, color: Colors.black87),
                          "p": Style(fontSize: FontSize(14), color: Colors.grey[700]),
                          "ul": Style(fontSize: FontSize(14), color: Colors.grey[700]),
                          "li": Style(fontSize: FontSize(14), color: Colors.grey[700]),
                        },
                      ),
                      const SizedBox(height: 20),
                      const Text(
                        "Key Features",
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 10),
                      ...product.features.map(
                            (f) => Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4.0),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(Icons.check_circle, color: Colors.blue, size: 18),
                              const SizedBox(width: 8),
                              Expanded(child: Text(f, style: const TextStyle(fontSize: 16))),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      const Text(
                        "What’s Included",
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 10),
                      ...product.whatIsIncluded.map(
                            (f) => Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4.0),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(Icons.check_circle, color: Colors.blue, size: 18),
                              const SizedBox(width: 8),
                              Expanded(child: Text(f, style: const TextStyle(fontSize: 16))),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      const Text(
                        "What’s Excluded",
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 10),
                      ...product.whatIsExcluded.map(
                            (f) => Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4.0),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(Icons.cancel, color: Colors.red, size: 18),
                              const SizedBox(width: 8),
                              Expanded(child: Text(f, style: const TextStyle(fontSize: 16))),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      const Text(
                        "FAQs",
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 10),
                      ...product.specifications.expand((spec) => spec.labels).map(
                            (faq) => Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                faq.label,
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                faq.value,
                                style: TextStyle(color: Colors.grey[600], fontSize: 14),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildShimmer(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Shimmer.fromColors(
            baseColor: Colors.grey[300]!,
            highlightColor: Colors.grey[100]!,
            child: Container(
              height: 200,
              width: double.infinity,
              decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(12)),
            ),
          ),
          const SizedBox(height: 16),
          Shimmer.fromColors(
            baseColor: Colors.grey[300]!,
            highlightColor: Colors.grey[100]!,
            child: Container(height: 24, width: 200, color: Colors.grey[300]),
          ),
          const SizedBox(height: 8),
          Shimmer.fromColors(
            baseColor: Colors.grey[300]!,
            highlightColor: Colors.grey[100]!,
            child: Container(height: 16, width: 300, color: Colors.grey[300]),
          ),
          const SizedBox(height: 20),
          Shimmer.fromColors(
            baseColor: Colors.grey[300]!,
            highlightColor: Colors.grey[100]!,
            child: Container(height: 40, width: 150, color: Colors.grey[300]),
          ),
        ],
      ),
    );
  }

  AppBar _buildAppBar(String title) {
    return AppBar(
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: Colors.white),
        onPressed: () => Navigator.pop(context),
      ),
      title: Text(
        title,
        style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 20),
      ),
      backgroundColor: Colors.blue[700],
      elevation: 3,
    );
  }
}