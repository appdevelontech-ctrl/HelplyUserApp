import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';
import 'package:intl/intl.dart';
import '../controllers/product_detail_controller.dart';
import '../controllers/cart_provider.dart';
import '../main_screen.dart';
import '../models/serviceCategoryDetail.dart';
import 'cartpage.dart';

class ProductDetailsPage extends StatelessWidget {
  final String slug;
  final String name;

  const ProductDetailsPage({super.key, required this.slug, required this.name});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ProductDetailController()..fetchProductDetails(slug),
      child: Consumer<ProductDetailController>(
        builder: (context, controller, child) {
          if (controller.isLoading) {
            return Scaffold(
              appBar: _buildAppBar("Loading.."),
              body: _buildShimmer(context),
            );
          }

          if (controller.errorMessage != null ||
              controller.productDetail == null) {
            return Scaffold(
              appBar: AppBar(
                title: Text(name),
                flexibleSpace: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xff004e92), Color(0xff000428)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                ),
                elevation: 2,
              ),
              body: Center(
                child: Text(
                  controller.errorMessage ?? 'Failed to load product details',
                ),
              ),
            );
          }

          final product = controller.productDetail!;
          final cartProvider = Provider.of<CartProvider>(
            context,
            listen: false,
          );

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
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
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
                        onPressed: () {
                          if (cartProvider.cartItems.isNotEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Already added a product. Please complete that order first.',
                                ),
                                duration: Duration(seconds: 2),
                              ),
                            );
                            return;
                          }
                          showDialog(
                            context: context,
                            builder: (BuildContext context) {
                              DateTime now = DateTime.now();
                              List<DateTime> dateList = List.generate(
                                11,
                                (i) => now.add(Duration(days: i)),
                              );
                              DateTime? selectedDate = dateList[0];
                              DateTime? selectedTime;
                              String selectedDuration =
                                  slug == 'multiday-service'
                                  ? 'FullDay'
                                  : '30min';
                              double calculatedPrice = product.salePrice;

                              List<DateTime> generateTimesForDate(
                                DateTime date,
                              ) {
                                bool isToday =
                                    date.year == now.year &&
                                    date.month == now.month &&
                                    date.day == now.day;
                                DateTime start = isToday
                                    ? now.add(
                                        Duration(
                                          minutes: 30 - (now.minute % 30),
                                        ),
                                      )
                                    : DateTime(
                                        date.year,
                                        date.month,
                                        date.day,
                                        8,
                                        0,
                                      );
                                DateTime end = DateTime(
                                  date.year,
                                  date.month,
                                  date.day,
                                  22,
                                  0,
                                );
                                if (start.isAfter(end))
                                  start = DateTime(
                                    date.year,
                                    date.month,
                                    date.day,
                                    8,
                                    0,
                                  );

                                List<DateTime> times = [];
                                DateTime current = start;
                                while (current.isBefore(end) ||
                                    current.isAtSameMomentAs(end)) {
                                  times.add(current);
                                  current = current.add(
                                    const Duration(minutes: 30),
                                  );
                                }
                                return times;
                              }

                              int getMinutesFromHour(String hour) {
                                if (hour == '30min') return 30;
                                return int.parse(
                                      hour.substring(0, hour.length - 2),
                                    ) *
                                    60;
                              }

                              void updatePrice() {
                                if (slug == 'multiday-service') {
                                  if (selectedDuration == 'FullDay') {
                                    calculatedPrice = product.salePrice;
                                  } else {
                                    int days = int.parse(
                                      selectedDuration.replaceAll('days', ''),
                                    );
                                    calculatedPrice = product.salePrice * days;
                                  }
                                } else {
                                  int minutes = getMinutesFromHour(
                                    selectedDuration,
                                  );
                                  if (minutes <= 30) {
                                    calculatedPrice = product.salePrice;
                                  } else {
                                    calculatedPrice =
                                        product.salePrice +
                                        (minutes - 30) * product.minPrice;
                                  }
                                }
                              }

                              return StatefulBuilder(
                                builder: (context, setState) {
                                  return Dialog(
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    insetPadding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 24,
                                    ),
                                    child: ConstrainedBox(
                                      constraints: BoxConstraints(
                                        maxHeight:
                                            MediaQuery.of(context).size.height *
                                            0.85,
                                        maxWidth:
                                            MediaQuery.of(context).size.width *
                                            0.95,
                                      ),
                                      child: SingleChildScrollView(
                                        padding: const EdgeInsets.all(16.0),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            const Text(
                                              'Choose Date & Time',
                                              style: TextStyle(
                                                fontSize: 20,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            const SizedBox(height: 16),
                                            const Text(
                                              'Select Date',
                                              style: TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                            const SizedBox(height: 8),
                                            Wrap(
                                              spacing: 8,
                                              runSpacing: 8,
                                              children: dateList.map((date) {
                                                String dateStr = DateFormat(
                                                  'EEE, d MMM',
                                                ).format(date);
                                                return ChoiceChip(
                                                  label: Text(dateStr),
                                                  selected:
                                                      selectedDate == date,
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
                                              style: TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                            const SizedBox(height: 8),
                                            if (selectedDate != null)
                                              Wrap(
                                                spacing: 8,
                                                runSpacing: 8,
                                                children:
                                                    generateTimesForDate(
                                                      selectedDate!,
                                                    ).map((time) {
                                                      String timeStr =
                                                          DateFormat(
                                                            'h:mm a',
                                                          ).format(time);
                                                      return ChoiceChip(
                                                        label: Text(timeStr),
                                                        selected:
                                                            selectedTime ==
                                                            time,
                                                        onSelected:
                                                            (bool selected) {
                                                              setState(() {
                                                                selectedTime =
                                                                    time;
                                                              });
                                                            },
                                                      );
                                                    }).toList(),
                                              ),
                                            const SizedBox(height: 16),
                                            if (slug == 'multiday-service')
                                              Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  const Text(
                                                    'Select Service Days',
                                                    style: TextStyle(
                                                      fontSize: 16,
                                                      fontWeight:
                                                          FontWeight.w600,
                                                    ),
                                                  ),
                                                  const SizedBox(height: 8),
                                                  Wrap(
                                                    spacing: 8,
                                                    runSpacing: 8,
                                                    children:
                                                        [
                                                          'FullDay',
                                                          '2days',
                                                          '3days',
                                                          '4days',
                                                          '5days',
                                                          '6days',
                                                        ].map((day) {
                                                          return ChoiceChip(
                                                            label: Text(day),
                                                            selected:
                                                                selectedDuration ==
                                                                day,
                                                            onSelected:
                                                                (
                                                                  bool selected,
                                                                ) {
                                                                  setState(() {
                                                                    selectedDuration =
                                                                        day;
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
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  const Text(
                                                    'Select Service Hours',
                                                    style: TextStyle(
                                                      fontSize: 16,
                                                      fontWeight:
                                                          FontWeight.w600,
                                                    ),
                                                  ),
                                                  const SizedBox(height: 8),
                                                  Wrap(
                                                    spacing: 8,
                                                    runSpacing: 8,
                                                    children:
                                                        [
                                                          '30min',
                                                          '1Hr',
                                                          '2Hr',
                                                          '3Hr',
                                                          '4Hr',
                                                          '5Hr',
                                                          '6Hr',
                                                        ].map((hour) {
                                                          return ChoiceChip(
                                                            label: Text(hour),
                                                            selected:
                                                                selectedDuration ==
                                                                hour,
                                                            onSelected:
                                                                (
                                                                  bool selected,
                                                                ) {
                                                                  setState(() {
                                                                    selectedDuration =
                                                                        hour;
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
                                              style: TextStyle(
                                                fontSize: 16,
                                                color: Colors.green[800],
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            const SizedBox(height: 24),
                                            Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.end,
                                              children: [
                                                TextButton(
                                                  onPressed: () =>
                                                      Navigator.pop(context),
                                                  child: const Text('Cancel'),
                                                ),
                                                const SizedBox(width: 8),
                                                ElevatedButton(
                                                  onPressed: () {
                                                    if (selectedDate == null ||
                                                        selectedTime == null ||
                                                        selectedDuration
                                                            .isEmpty)
                                                      return;

                                                    final cartProduct = product
                                                        .toProduct(
                                                          selectedDate:
                                                              selectedDate,
                                                          selectedTime:
                                                              selectedTime,
                                                          selectedDuration:
                                                              selectedDuration,
                                                          salePrice:
                                                              calculatedPrice,
                                                        );

                                                    cartProvider
                                                        .addToCart(cartProduct)
                                                        .then((_) {
                                                          Navigator.pop(
                                                            context,
                                                          );
                                                          ScaffoldMessenger.of(
                                                            context,
                                                          ).showSnackBar(
                                                            const SnackBar(
                                                              content: Text(
                                                                'Product added to cart',
                                                              ),
                                                              duration:
                                                                  Duration(
                                                                    seconds: 2,
                                                                  ),
                                                            ),
                                                          );
                                                        });
                                                  },
                                                  child: const Text(
                                                    'Add to Cart',
                                                  ),
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
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xff004e92),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 14,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 5,
                          shadowColor: Colors.blue[300],
                          textStyle: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: const [
                            Icon(Icons.add_shopping_cart, size: 20),
                            SizedBox(width: 8),
                            Text("Add to Cart"),
                          ],
                        ),
                      ),
                      ElevatedButton(
                        onPressed: () {
                          if (cartProvider.cartItems.isNotEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Already added a product. Please complete that order first.',
                                ),
                                duration: Duration(seconds: 2),
                              ),
                            );
                            return;
                          }
                          showDialog(
                            context: context,
                            builder: (BuildContext context) {
                              DateTime now = DateTime.now();
                              List<DateTime> dateList = List.generate(
                                11,
                                    (i) => now.add(Duration(days: i)),
                              );
                              DateTime? selectedDate = dateList[0];
                              DateTime? selectedTime;
                              String selectedDuration =
                              slug == 'multiday-service'
                                  ? 'FullDay'
                                  : '30min';
                              double calculatedPrice = product.salePrice;

                              List<DateTime> generateTimesForDate(
                                  DateTime date,
                                  ) {
                                bool isToday =
                                    date.year == now.year &&
                                        date.month == now.month &&
                                        date.day == now.day;
                                DateTime start = isToday
                                    ? now.add(
                                  Duration(
                                    minutes: 30 - (now.minute % 30),
                                  ),
                                )
                                    : DateTime(
                                  date.year,
                                  date.month,
                                  date.day,
                                  8,
                                  0,
                                );
                                DateTime end = DateTime(
                                  date.year,
                                  date.month,
                                  date.day,
                                  22,
                                  0,
                                );
                                if (start.isAfter(end))
                                  start = DateTime(
                                    date.year,
                                    date.month,
                                    date.day,
                                    8,
                                    0,
                                  );

                                List<DateTime> times = [];
                                DateTime current = start;
                                while (current.isBefore(end) ||
                                    current.isAtSameMomentAs(end)) {
                                  times.add(current);
                                  current = current.add(
                                    const Duration(minutes: 30),
                                  );
                                }
                                return times;
                              }

                              int getMinutesFromHour(String hour) {
                                if (hour == '30min') return 30;
                                return int.parse(
                                  hour.substring(0, hour.length - 2),
                                ) *
                                    60;
                              }

                              void updatePrice() {
                                if (slug == 'multiday-service') {
                                  if (selectedDuration == 'FullDay') {
                                    calculatedPrice = product.salePrice;
                                  } else {
                                    int days = int.parse(
                                      selectedDuration.replaceAll('days', ''),
                                    );
                                    calculatedPrice = product.salePrice * days;
                                  }
                                } else {
                                  int minutes = getMinutesFromHour(
                                    selectedDuration,
                                  );
                                  if (minutes <= 30) {
                                    calculatedPrice = product.salePrice;
                                  } else {
                                    calculatedPrice =
                                        product.salePrice +
                                            (minutes - 30) * product.minPrice;
                                  }
                                }
                              }

                              return StatefulBuilder(
                                builder: (context, setState) {
                                  return Dialog(
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    insetPadding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 24,
                                    ),
                                    child: ConstrainedBox(
                                      constraints: BoxConstraints(
                                        maxHeight:
                                        MediaQuery.of(context).size.height *
                                            0.85,
                                        maxWidth:
                                        MediaQuery.of(context).size.width *
                                            0.95,
                                      ),
                                      child: SingleChildScrollView(
                                        padding: const EdgeInsets.all(16.0),
                                        child: Column(
                                          crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                          children: [
                                            const Text(
                                              'Choose Date & Time',
                                              style: TextStyle(
                                                fontSize: 20,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            const SizedBox(height: 16),
                                            const Text(
                                              'Select Date',
                                              style: TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                            const SizedBox(height: 8),
                                            Wrap(
                                              spacing: 8,
                                              runSpacing: 8,
                                              children: dateList.map((date) {
                                                String dateStr = DateFormat(
                                                  'EEE, d MMM',
                                                ).format(date);
                                                return ChoiceChip(
                                                  label: Text(dateStr),
                                                  selected:
                                                  selectedDate == date,
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
                                              style: TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                            const SizedBox(height: 8),
                                            if (selectedDate != null)
                                              Wrap(
                                                spacing: 8,
                                                runSpacing: 8,
                                                children:
                                                generateTimesForDate(
                                                  selectedDate!,
                                                ).map((time) {
                                                  String timeStr =
                                                  DateFormat(
                                                    'h:mm a',
                                                  ).format(time);
                                                  return ChoiceChip(
                                                    label: Text(timeStr),
                                                    selected:
                                                    selectedTime ==
                                                        time,
                                                    onSelected:
                                                        (bool selected) {
                                                      setState(() {
                                                        selectedTime =
                                                            time;
                                                      });
                                                    },
                                                  );
                                                }).toList(),
                                              ),
                                            const SizedBox(height: 16),
                                            if (slug == 'multiday-service')
                                              Column(
                                                crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                                children: [
                                                  const Text(
                                                    'Select Service Days',
                                                    style: TextStyle(
                                                      fontSize: 16,
                                                      fontWeight:
                                                      FontWeight.w600,
                                                    ),
                                                  ),
                                                  const SizedBox(height: 8),
                                                  Wrap(
                                                    spacing: 8,
                                                    runSpacing: 8,
                                                    children:
                                                    [
                                                      'FullDay',
                                                      '2days',
                                                      '3days',
                                                      '4days',
                                                      '5days',
                                                      '6days',
                                                    ].map((day) {
                                                      return ChoiceChip(
                                                        label: Text(day),
                                                        selected:
                                                        selectedDuration ==
                                                            day,
                                                        onSelected:
                                                            (
                                                            bool selected,
                                                            ) {
                                                          setState(() {
                                                            selectedDuration =
                                                                day;
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
                                                crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                                children: [
                                                  const Text(
                                                    'Select Service Hours',
                                                    style: TextStyle(
                                                      fontSize: 16,
                                                      fontWeight:
                                                      FontWeight.w600,
                                                    ),
                                                  ),
                                                  const SizedBox(height: 8),
                                                  Wrap(
                                                    spacing: 8,
                                                    runSpacing: 8,
                                                    children:
                                                    [
                                                      '30min',
                                                      '1Hr',
                                                      '2Hr',
                                                      '3Hr',
                                                      '4Hr',
                                                      '5Hr',
                                                      '6Hr',
                                                    ].map((hour) {
                                                      return ChoiceChip(
                                                        label: Text(hour),
                                                        selected:
                                                        selectedDuration ==
                                                            hour,
                                                        onSelected:
                                                            (
                                                            bool selected,
                                                            ) {
                                                          setState(() {
                                                            selectedDuration =
                                                                hour;
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
                                              style: TextStyle(
                                                fontSize: 16,
                                                color: Colors.green[800],
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            const SizedBox(height: 24),
                                            Row(
                                              mainAxisAlignment:
                                              MainAxisAlignment.end,
                                              children: [
                                                TextButton(
                                                  onPressed: () =>
                                                      Navigator.pop(context),
                                                  child: const Text('Cancel'),
                                                ),
                                                const SizedBox(width: 8),
                                                ElevatedButton(
                                                  onPressed: () {
                                                    if (selectedDate == null ||
                                                        selectedTime == null ||
                                                        selectedDuration
                                                            .isEmpty)
                                                      return;

                                                    final cartProduct = product
                                                        .toProduct(
                                                      selectedDate:
                                                      selectedDate,
                                                      selectedTime:
                                                      selectedTime,
                                                      selectedDuration:
                                                      selectedDuration,
                                                      salePrice:
                                                      calculatedPrice,
                                                    );

                                                    cartProvider
                                                        .addToCart(cartProduct)
                                                        .then((_) {
                                                      Navigator.pop(
                                                        context,
                                                      );
                                                      ScaffoldMessenger.of(
                                                        context,
                                                      ).showSnackBar(
                                                        const SnackBar(
                                                          content: Text(
                                                            'Product added to cart',
                                                          ),
                                                          duration:
                                                          Duration(
                                                            seconds: 2,
                                                          ),
                                                        ),
                                                      );
                                                    });
                                                  },
                                                  child: const Text(
                                                    'Add to Cart',
                                                  ),
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
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xff000428),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 14,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 5,
                          shadowColor: Colors.blue[300],
                          textStyle: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: const [
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
                      "body": Style(
                        fontSize: FontSize(16),
                        color: Colors.grey[800],
                      ),
                      "h3": Style(
                        fontSize: FontSize(18),
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                      "p": Style(
                        fontSize: FontSize(14),
                        color: Colors.grey[700],
                      ),
                      "ul": Style(
                        fontSize: FontSize(14),
                        color: Colors.grey[700],
                      ),
                      "li": Style(
                        fontSize: FontSize(14),
                        color: Colors.grey[700],
                      ),
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
                          const Icon(
                            Icons.check_circle,
                            color: Colors.blue,
                            size: 18,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              f,
                              style: const TextStyle(fontSize: 16),
                            ),
                          ),
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
                          const Icon(
                            Icons.check_circle,
                            color: Colors.blue,
                            size: 18,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              f,
                              style: const TextStyle(fontSize: 16),
                            ),
                          ),
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
                          Expanded(
                            child: Text(
                              f,
                              style: const TextStyle(fontSize: 16),
                            ),
                          ),
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
                  ...product.specifications
                      .expand((spec) => spec.labels)
                      .map(
                        (faq) => Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                faq.label,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                faq.value,
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 14,
                                ),
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
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Shimmer.fromColors(
            baseColor: Colors.grey[300]!,
            highlightColor: Colors.grey[100]!,
            child: Container(height: 24, width: 200, color: Colors.grey[300]),
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
}
