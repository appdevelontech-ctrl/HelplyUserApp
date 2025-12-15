import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shimmer/shimmer.dart';
import 'package:intl/intl.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:http/http.dart' as http;

import 'dart:convert';
import '../controllers/product_detail_controller.dart';
import '../controllers/cart_provider.dart';
import '../main_screen.dart';
import '../models/serviceCategoryDetail.dart';
import '../services/api_services.dart';
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
            _productRatings =
                List<Map<String, dynamic>>.from(data['productRatings']);
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

  Future<void> _refreshProductDetails(
      ProductDetailController controller) async {
    await EasyLoading.show(status: 'Refreshing product details...');
    await controller.fetchProductDetails(widget.slug);
    if (controller.errorMessage == null && controller.productDetail != null) {
      await EasyLoading.showSuccess('Product details refreshed successfully');
      await _fetchProductRatings(controller.productDetail!.id);
    }
  }

  double getResponsiveWidth(BuildContext context) {
    double width = MediaQuery.of(context).size.width;

    if (width <= 480) return width * 0.95; // Mobile
    if (width <= 800) return width * 0.75; // Small Tablet
    if (width <= 1200) return width * 0.55; // Large Tablet
    return width * 0.40; // Web/Desktop
  }

  void _showAddToCartDialog(
      BuildContext context,
      ProductDetail product,
      CartProvider cartProvider,
      ) {
    if (cartProvider.cartItems.isNotEmpty) {
      EasyLoading.showError('Already added a product. Please complete that order first.');
      return;
    }



    final controller = context.read<ProductDetailController>();
    final homeData = controller.homeData;

    int noOfDays = 1;
    if (homeData != null && homeData['noOfDays'] != null) {
      noOfDays = int.tryParse(homeData['noOfDays'].toString()) ?? 1;
    }

    DateTime now = DateTime.now();

    List<DateTime> dateList = List.generate(
      noOfDays,
          (i) => DateTime(now.year, now.month, now.day + i),
    );

    DateTime? selectedDate = dateList.first;


    DateTime? selectedTime;
    String? selectedTimeString;

    String selectedDuration = widget.slug == 'multiday-service' ? 'FullDay' : '30min';

    double calculatedPrice = product.salePrice;

    double nightCharge = 0;
    if (homeData != null && homeData['nightCharges'] != null) {
      nightCharge = double.tryParse(homeData['nightCharges'].toString()) ?? 0;
    }

    DateTime parseTime(String timeStr, DateTime date) {
      timeStr = timeStr.trim();

      if (timeStr.startsWith("24")) {
        return DateTime(date.year, date.month, date.day).add(const Duration(days: 1));
      }

      List<String> parts = timeStr.split(":");
      int hour = int.tryParse(parts[0]) ?? 0;
      int min = parts.length > 1 ? int.tryParse(parts[1]) ?? 0 : 0;

      return DateTime(date.year, date.month, date.day, hour, min);
    }
    DateTime roundToNextSlot(DateTime time, int gapMinutes) {
      int remainder = time.minute % gapMinutes;
      if (remainder == 0) return time;
      return time.add(Duration(minutes: gapMinutes - remainder));
    }

    List<DateTime> generateTimesForDate(DateTime date) {
      if (homeData == null) return [];

      DateTime start =
      parseTime(homeData['startTime'] ?? "10:00:00", date);

      DateTime nightStart =
      parseTime(homeData['startNightTime'] ?? "22:00:00", date);

      DateTime nightEnd =
      parseTime(homeData['endingNightTime'] ?? "24:00:00", date);

      int gap = homeData['timeGap'] ?? 30;
      bool isToday =
          DateTime.now().difference(date).inDays == 0;

      DateTime firstSlot;

      if (isToday) {
        int buffer = homeData['startingHour'] ?? 60;
        DateTime baseTime =
        DateTime.now().add(Duration(minutes: buffer));

        firstSlot = homeData['roundOffTime'] == "Yes"
            ? roundToNextSlot(baseTime, gap)
            : baseTime;
      } else {
        firstSlot = start;
      }

      if (firstSlot.isBefore(start)) firstSlot = start;

      List<DateTime> slots = [];
      DateTime curr = firstSlot;

      // ================= DAY SLOTS =================
      while (curr.isBefore(nightStart)) {
        slots.add(curr);
        curr = curr.add(Duration(minutes: gap));
      }

      // ================= NIGHT SLOTS =================
      if (nightCharge > 0) {
        if (curr.isBefore(nightStart)) {
          curr = nightStart;
        }

        while (curr.isBefore(nightEnd)) {
          slots.add(curr);
          curr = curr.add(Duration(minutes: gap));
        }
      }

      return slots;
    }


    void updatePrice() {
      if (widget.slug == "multiday-service") {
        calculatedPrice = selectedDuration == "FullDay"
            ? product.salePrice
            : product.salePrice * int.parse(selectedDuration.replaceAll("days", ""));
      } else {
        int minutes = selectedDuration == "30min"
            ? 30
            : int.parse(selectedDuration.replaceAll("Hr", "")) * 60;

        calculatedPrice = minutes <= 30
            ? product.salePrice
            : product.salePrice + (minutes - 30) * product.minPrice;
      }

      if (selectedTime != null && selectedTime!.hour >= 22) {
        calculatedPrice += nightCharge;
      }
    }

    showDialog(
      context: context,
      builder: (context) {
        final width = MediaQuery.of(context).size.width;
        final maxDialogWidth = width > 500 ? 500.0 : width * 0.95;



        return StatefulBuilder(
          builder: (context, setState) {
            return Dialog(
              insetPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 20),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Container(
                width: maxDialogWidth,
                constraints: const BoxConstraints(maxHeight: 650),
                padding: const EdgeInsets.all(16),
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title
                      const Text(
                        "Choose Date & Time",
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 16),

                      // DATE
                      const Text("Select Date",
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 8),

                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: dateList.map((d) {
                          return ChoiceChip(
                            label: Text(DateFormat("EEE, d MMM").format(d)),
                            selected: selectedDate == d,
                            selectedColor: Colors.blue,
                            labelStyle: TextStyle(
                                color: selectedDate == d ? Colors.white : Colors.black),
                            onSelected: (_) {
                              setState(() {
                                selectedDate = d;
                                selectedTime = null;
                                selectedTimeString = null;
                              });
                            },
                          );
                        }).toList(),
                      ),

                      const SizedBox(height: 20),

                      // TIME SLOT
                      const Text("Select Start Time",
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 8),

                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: generateTimesForDate(selectedDate!).map((t) {
                          String timeKey = DateFormat('HH:mm').format(t);
                          bool isNight = t.hour >= 22;

                          return ChoiceChip(
                            label: Text(
                              "${DateFormat('h:mm a').format(t)}${isNight ? " (Night + ₹$nightCharge)" : ""}",
                            ),
                            selected: selectedTimeString == timeKey,
                            selectedColor: Colors.blue,
                            backgroundColor: Colors.grey.shade200,
                            labelStyle: TextStyle(
                              color: selectedTimeString == timeKey ? Colors.white : Colors.black,
                              fontWeight: FontWeight.w600,
                            ),
                            onSelected: (_) {
                              setState(() {
                                selectedTime = t;
                                selectedTimeString = timeKey;
                                updatePrice();
                              });
                            },
                          );
                        }).toList(),
                      ),

                      const SizedBox(height: 20),

                      // DURATION
                      const Text("Select Service Duration",
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 8),

                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: (widget.slug == 'multiday-service'
                            ? ["FullDay", "2days", "3days", "4days", "5days", "6days"]
                            : ["30min", "1Hr", "2Hr", "3Hr", "4Hr", "5Hr", "6Hr"])
                            .map((d) {
                          return ChoiceChip(
                            label: Text(d),
                            selected: selectedDuration == d,
                            selectedColor: Colors.orange,
                            labelStyle: TextStyle(
                                color: selectedDuration == d ? Colors.white : Colors.black),
                            onSelected: (_) {
                              setState(() {
                                selectedDuration = d;
                                updatePrice();
                              });
                            },
                          );
                        }).toList(),
                      ),

                      const SizedBox(height: 20),

                      // PRICE
                      Text(
                        "Approx Price: ₹${calculatedPrice.toStringAsFixed(0)}",
                        style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.green.shade800),
                      ),

                      const SizedBox(height: 25),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                            child: const Text("Cancel"),
                            onPressed: () => Navigator.pop(context),
                          ),
                          const SizedBox(width: 12),
                          ElevatedButton(
                            onPressed: () async {
                              if (selectedDate == null || selectedTime == null) {
                                EasyLoading.showError("Please select date & time");
                                return;
                              }

                              final cartItem = product.toProduct(
                                selectedDate: selectedDate,
                                selectedTime: selectedTime,
                                selectedDuration: selectedDuration,
                                salePrice: calculatedPrice,
                              );

                              await EasyLoading.show(status: "Adding...");
                              await cartProvider.addToCart(cartItem);
                              EasyLoading.dismiss();

                              Navigator.pushAndRemoveUntil(
                                context,
                                MaterialPageRoute(builder: (_) => const MainScreen()),
                                    (route) => false,
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue,
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                            ),
                            child: const Text("Add to Cart",style: TextStyle(color: Colors.white),),
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
      child: Builder(
        builder: (context) {
          final size = MediaQuery.of(context).size;
          final isDesktop = size.width > 900;

          return Scaffold(
            backgroundColor: Colors.grey.shade100,

            body: RefreshIndicator(
              color: Colors.orangeAccent,
              onRefresh: () async {
                final controller = context.read<ProductDetailController>();
                return _refreshProductDetails(controller);
              },

              child: Consumer<ProductDetailController>(
                builder: (context, controller, child) {
                  // ------------------- LOADING ----------------------
                  if (controller.isLoading) {
                    return Column(
                      children: [
                        _buildAppBar("Loading..."),
                        Expanded(child: _buildShimmer(context)),
                      ],
                    );
                  }

                  // ------------------- ERROR -------------------------
                  if (controller.errorMessage != null ||
                      controller.productDetail == null) {
                    return Column(
                      children: [
                        _buildAppBar(widget.name),
                        Expanded(
                          child: Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  controller.errorMessage ??
                                      'Failed to load product details',
                                  style: const TextStyle(
                                      fontSize: 16, color: Colors.red),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 16),
                                ElevatedButton(
                                  onPressed: () =>
                                      _refreshProductDetails(controller),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.blueAccent,
                                    shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12)),
                                  ),
                                  child: const Text('Retry'),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    );
                  }

                  // ------------------- SUCCESS -----------------------
                  final product = controller.productDetail!;
                  final cartProvider =
                  Provider.of<CartProvider>(context, listen: false);

                  if (_productRatings.isEmpty) {
                    _fetchProductRatings(product.id);
                  }

                  return Scaffold(
                    appBar: _buildAppBar(product.title),

                    body: Center(
                      child: Container(
                        width: isDesktop ? 650 : size.width,
                        padding: const EdgeInsets.all(16),

                        child: SingleChildScrollView(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [


                              // -------------------------------
                              // PRODUCT IMAGE + PRICE CARD
                              // -------------------------------
                              Container(
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(18),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black12,
                                      blurRadius: 12,
                                      offset: Offset(0, 6),
                                    )
                                  ],
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(18),
                                      child: CachedNetworkImage(
                                        imageUrl: product.pImage,
                                        height: 240,
                                        width: double.infinity,
                                        fit: BoxFit.cover,
                                        placeholder: (c, u) =>
                                            Container(color: Colors.grey.shade300),
                                      ),
                                    ),

                                    Padding(
                                      padding: const EdgeInsets.all(16),
                                      child: Column(
                                        crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            product.title,
                                            style: TextStyle(
                                              fontSize: 22,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),

                                          const SizedBox(height: 8),

                                          Row(
                                            children: [
                                              Text(
                                                "₹${product.salePrice.toStringAsFixed(0)}",
                                                style: const TextStyle(
                                                  fontSize: 28,
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.black,
                                                ),
                                              ),
                                              const SizedBox(width: 8),
                                              if (product.regularPrice >
                                                  product.salePrice)
                                                Text(
                                                  "₹${product.regularPrice.toStringAsFixed(0)}",
                                                  style: const TextStyle(
                                                    fontSize: 16,
                                                    color: Colors.grey,
                                                    decoration: TextDecoration
                                                        .lineThrough,
                                                  ),
                                                ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    )
                                  ],
                                ),
                              ),

                              const SizedBox(height: 22),


                              // -------------------------------
                              // ACTION BUTTONS (ZEPTO STYLE)
                              // -------------------------------
                              Row(
                                children: [
                                  Expanded(
                                    child: ElevatedButton(
                                      onPressed: () {
                                        final controller = context
                                            .read<ProductDetailController>();
                                        if (controller.homeData == null) {
                                          EasyLoading.showError(
                                              "Please wait, fetching available slots...");
                                          return;
                                        }
                                        _showAddToCartDialog(context, product,
                                            cartProvider);
                                      },
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.black,
                                        padding: EdgeInsets.symmetric(
                                            vertical: 14),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                      ),
                                      child: const Text("Add to Cart",
                                          style: TextStyle(fontSize: 16,color: Colors.white)),
                                    ),
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: ElevatedButton(
                                      onPressed: () {
                                        final controller = context
                                            .read<ProductDetailController>();
                                        if (controller.homeData == null) {
                                          EasyLoading.showError(
                                              "Please wait...");
                                          return;
                                        }
                                        _showAddToCartDialog(
                                            context, product, cartProvider);
                                      },
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.green.shade600,
                                        padding: EdgeInsets.symmetric(
                                            vertical: 14),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                      ),
                                      child: const Text("Book Now",
                                          style: TextStyle(fontSize: 16,color: Colors.yellow)),
                                    ),
                                  ),
                                ],
                              ),
                              // -------------------------------
                              // DESCRIPTION CARD
                              // -------------------------------
                              const SizedBox(height: 22),
                              Container(
                                padding: EdgeInsets.all(18),
                                margin: EdgeInsets.only(top: 18),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(18),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black12,
                                      blurRadius: 10,
                                      offset: Offset(0, 5),
                                    )
                                  ],
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text("Description",
                                        style: TextStyle(
                                            fontSize: 20,
                                            fontWeight: FontWeight.bold)),
                                    const SizedBox(height: 12),
                                    Html(
                                      data: product.description,
                                      style: {
                                        "body": Style(
                                          fontSize: FontSize(15),
                                          color: Colors.grey[800],
                                        )
                                      },
                                    ),
                                  ],
                                ),
                              ),



                              const SizedBox(height: 22),


                              // -------------------------------
                              // RATING CARD
                              // -------------------------------
                              Container(
                                padding: EdgeInsets.all(18),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(18),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black12,
                                      blurRadius: 10,
                                    )
                                  ],
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text("Rate This Product",
                                        style: TextStyle(
                                            fontSize: 20,
                                            fontWeight: FontWeight.bold)),

                                    const SizedBox(height: 14),

                                    Slider(
                                      value: _selectedRating,
                                      min: 1,
                                      max: 5,
                                      divisions: 4,
                                      activeColor: Colors.amber,
                                      onChanged: (v) {
                                        setState(() => _selectedRating = v);
                                      },
                                    ),

                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: List.generate(
                                        5,
                                            (i) => Icon(
                                          i < _selectedRating.round()
                                              ? Icons.star
                                              : Icons.star_border,
                                          color: Colors.amber,
                                          size: 26,
                                        ),
                                      ),
                                    ),

                                    const SizedBox(height: 14),

                                    TextFormField(
                                      controller: _commentController,
                                      maxLines: 3,
                                      decoration: InputDecoration(
                                        hintText: "Write a review...",
                                        fillColor: Colors.grey.shade100,
                                        filled: true,
                                        border: OutlineInputBorder(
                                          borderRadius:
                                          BorderRadius.circular(14),
                                          borderSide: BorderSide.none,
                                        ),
                                      ),
                                    ),

                                    const SizedBox(height: 14),

                                    Align(
                                      alignment: Alignment.centerRight,
                                      child: ElevatedButton(
                                        onPressed: () {
                                          if (userId == null) {
                                            EasyLoading.showError(
                                                "⚠ Please login first");
                                            return;
                                          }
                                          _submitRating(userId!, product.id);
                                        },
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.black,
                                          padding: EdgeInsets.symmetric(
                                              horizontal: 20, vertical: 12),
                                          shape: RoundedRectangleBorder(
                                            borderRadius:
                                            BorderRadius.circular(12),
                                          ),
                                        ),
                                        child: const Text("Submit Review",style: TextStyle(color: Colors.white),),
                                      ),
                                    )
                                  ],
                                ),
                              ),

                              const SizedBox(height: 20),


                              // -------------------------------
                              // CUSTOMER REVIEWS LIST
                              // -------------------------------
                              ListView.builder(
                                shrinkWrap: true,
                                physics: NeverScrollableScrollPhysics(),
                                itemCount: _productRatings.length,
                                itemBuilder: (context, index) {
                                  final r = _productRatings[index];

                                  return Container(
                                    margin: EdgeInsets.only(bottom: 14),
                                    padding: EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(18),
                                      boxShadow: [
                                        BoxShadow(
                                            color: Colors.black12,
                                            blurRadius: 8)
                                      ],
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            CircleAvatar(
                                              radius: 20,
                                              backgroundColor:
                                              Colors.grey.shade300,
                                              child: Icon(Icons.person,
                                                  color: Colors.black),
                                            ),
                                            SizedBox(width: 12),
                                            Text(
                                              r['username'] ?? "User",
                                              style: TextStyle(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.bold),
                                            ),
                                          ],
                                        ),

                                        const SizedBox(height: 6),

                                        Row(
                                          children: List.generate(
                                            5,
                                                (i) => Icon(
                                              i < (r['rating'] ?? 0)
                                                  ? Icons.star
                                                  : Icons.star_border,
                                              color: Colors.amber,
                                              size: 20,
                                            ),
                                          ),
                                        ),

                                        const SizedBox(height: 6),

                                        Text(
                                          r['comment'] ?? "",
                                          style: TextStyle(
                                              fontSize: 14,
                                              color: Colors.grey.shade700),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          );
        },
      ),
    );
  }
  AppBar _buildAppBar(String title) {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 1,
      centerTitle: true,
      leading: IconButton(
        icon: Icon(Icons.arrow_back_ios_new, color: Colors.black, size: 20),
        onPressed: () => Navigator.pop(context),
      ),
      title: Text(
        title,
        style: const TextStyle(
          fontWeight: FontWeight.w600,
          color: Colors.black,
          fontSize: 18,
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
              decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(12)),
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


  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }
}
