import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shimmer/shimmer.dart';
import 'package:intl/intl.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:http/http.dart' as http;
import 'package:user_app/services/api_services.dart';
import 'dart:convert';
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
  final _formKey = GlobalKey<FormState>();
  double _selectedRating = 1.0; // Changed to double for slider
  final TextEditingController _commentController = TextEditingController();
  List<Map<String, dynamic>> _productRatings = [];
  String? userId;

  Future<void> getUserId() async {
    final prefs = await SharedPreferences.getInstance();
    userId = prefs.getString("userId");
    print("USERID IS : $userId");
  }


  @override
  void initState() {
    super.initState();
    getUserId();

  }


  Future<void> _fetchProductRatings(String productId) async {
    try {
      final response = await http.get(
        Uri.parse('${ApiServices.baseUrl}/view-product-rating/$productId'),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success']) {
          setState(() {
            _productRatings = List<Map<String, dynamic>>.from(data['productRatings']);
          });
        }
      } else {
        await EasyLoading.showError('Failed to fetch ratings');
      }
    } catch (e) {
      await EasyLoading.showError('Error fetching ratings: $e');
    }
  }

  Future<void> _submitRating(String userId, String productId) async {
    if (!_formKey.currentState!.validate()) return;

    try {
      await EasyLoading.show(status: 'Submitting rating...');
      final response = await http.post(
        Uri.parse('${ApiServices.baseUrl}/add-rating'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'rating': _selectedRating.round(), // Convert to integer for API
          'comment': _commentController.text,
          'userId': userId,
          'productId': productId,
        }),
      );

      print("Response is: ${response.body}");

      if (response.statusCode == 200) {
        await EasyLoading.showSuccess('Rating submitted successfully');
        _commentController.clear();
        setState(() {
          _selectedRating = 1.0;
        });
        await _fetchProductRatings(productId);
      } else {
        await EasyLoading.showError('Failed to submit rating');
      }
    } catch (e) {
      await EasyLoading.showError('Error submitting rating: $e');
    }
  }

  Future<void> _refreshProductDetails(ProductDetailController controller) async {
    await EasyLoading.show(status: 'Refreshing product details...');
    await controller.fetchProductDetails(widget.slug);
    if (controller.errorMessage == null && controller.productDetail != null) {
      await EasyLoading.showSuccess('Product details refreshed successfully');
      await _fetchProductRatings(controller.productDetail!.id);
    }
  }

  double getResponsiveWidth(BuildContext context) {
    double width = MediaQuery.of(context).size.width;

    if (width <= 480) return width * 0.95;         // Mobile
    if (width <= 800) return width * 0.75;         // Small Tablet
    if (width <= 1200) return width * 0.55;        // Large Tablet
    return width * 0.40;                           // Web/Desktop
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
            EasyLoading.showError('Please select date, time & duration');
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

            EasyLoading.dismiss(); // remove loader

            if (!mounted) return;

            // show success toast message
            EasyLoading.showToast(
            'Added to cart successfully!',
            toastPosition: EasyLoadingToastPosition.bottom,
            duration: const Duration(seconds: 2),
            );

            // Close ALL previous routes & open MainScreen with Cart Tab
            Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (_) => const MainScreen()),
            (route) => false,
            );

            } catch (e) {
            await EasyLoading.showError('Failed to add to cart: $e');
            }
            }
,
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

              // Fetch ratings after product details are loaded
              if (_productRatings.isEmpty) {
                _fetchProductRatings(product.id);
              }

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
                      Card(
                        elevation: 4,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                "Rate This Product",
                                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 16),
                              Form(
                                key: _formKey,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Your Rating',
                                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                                    ),
                                    const SizedBox(height: 8),
                                    Slider(
                                      value: _selectedRating,
                                      min: 1.0,
                                      max: 5.0,
                                      divisions: 4,
                                      label: _selectedRating.round().toString(),
                                      onChanged: (value) {
                                        setState(() {
                                          _selectedRating = value;
                                        });
                                      },
                                      activeColor: Colors.amber,
                                      inactiveColor: Colors.grey[300],
                                    ),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: List.generate(5, (index) {
                                        return Icon(
                                          index < _selectedRating.round() ? Icons.star : Icons.star_border,
                                          color: Colors.amber,
                                          size: 24,
                                        );
                                      }),
                                    ),
                                    const SizedBox(height: 16),
                                    const Text(
                                      'Your Comment',
                                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                                    ),
                                    const SizedBox(height: 8),
                                    TextFormField(
                                      controller: _commentController,
                                      maxLines: 3,
                                      decoration: InputDecoration(
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        hintText: 'Write your review here...',
                                      ),
                                      validator: (value) {
                                        if (value == null || value.isEmpty) {
                                          return 'Please enter a comment';
                                        }
                                        return null;
                                      },
                                    ),
                                    const SizedBox(height: 16),
                                    Align(
                                      alignment: Alignment.centerRight,
                                      child: ElevatedButton(
              onPressed: () {
              if (userId == null) {
              EasyLoading.showError("⚠ Please login first");
              return;
              }
              _submitRating(userId!, product.id);
              },
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.blue[700],
                                          foregroundColor: Colors.white,
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                        ),
                                        child: const Text('Submit Rating'),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      ListView.builder(
                        shrinkWrap: true,
                        physics: NeverScrollableScrollPhysics(),
                        itemCount: _productRatings.length,
                        itemBuilder: (context, index) {
                          final rating = _productRatings[index];

                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8.0),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                CircleAvatar(
                                  radius: 20,
                                  backgroundColor: Colors.grey[300],
                                  child: Icon(Icons.person, color: Colors.grey[600], size: 20),
                                ),
                                const SizedBox(width: 12),

                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [

                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            rating['username'] ?? "Unknown User",
                                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                          ),

                                          Text(
                                            rating['createdAt'] != null
                                                ? DateFormat('d MMM yyyy')
                                                .format(DateTime.parse(rating['createdAt']))
                                                : "Just now",
                                            style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                                          ),
                                        ],
                                      ),

                                      const SizedBox(height: 4),

                                      Row(
                                        children: List.generate(5, (i) {
                                          return Icon(
                                            i < (rating['rating'] ?? 0)
                                                ? Icons.star
                                                : Icons.star_border,
                                            color: Colors.amber,
                                            size: 20,
                                          );
                                        }),
                                      ),

                                      const SizedBox(height: 4),

                                      Text(
                                        rating['comment'] ?? "No comment provided.",
                                        style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      )

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
      leading: Builder(
        builder: (context) => IconButton(
          icon: Image.asset(
            'assets/icons/back.png',
            width: 24,
            height: 24,
            color: Colors.white,
          ),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      title: Text(
        title,
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          color: Colors.white,
          fontSize: 20,
        ),
      ),
      backgroundColor: Colors.blue[700],
      elevation: 3,
    );
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }
}