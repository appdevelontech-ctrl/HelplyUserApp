import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:google_place/google_place.dart';
import 'package:user_app/main_screen.dart';
import '../controllers/cart_provider.dart';
import '../controllers/socket_controller.dart';
import '../controllers/user_controller.dart';
import '../services/api_services.dart';
import '../models/serviceCategoryDetail.dart';

class CartPage extends StatefulWidget {
  const CartPage({super.key});

  @override
  State<CartPage> createState() => _CartPageState();
}

class _CartPageState extends State<CartPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _pincodeController = TextEditingController();
  final _locationController = TextEditingController();
  final _addressController = TextEditingController();
  String? _selectedState;
  String? _selectedPaymentMethod = 'Cash on Delivery';
  final ApiServices _apiServices = ApiServices();
  late GooglePlace _googlePlace;
  List<AutocompletePrediction> _predictions = [];
  double? _latitude;
  double? _longitude;
  String? _errorMessage;

  final PageController _pageController = PageController();
  int _currentStep = 0;
  bool _isLoading = false;

  final List<String> _states = [
    "Andhra Pradesh", "Arunachal Pradesh", "Assam", "Bihar", "Chhattisgarh", "Goa",
    "Gujarat", "Haryana", "Himachal Pradesh", "Jharkhand", "Karnataka", "Kerala",
    "Madhya Pradesh", "Maharashtra", "Manipur", "Meghalaya", "Mizoram", "Nagaland",
    "Odisha", "Punjab", "Rajasthan", "Sikkim", "Tamil Nadu", "Telangana", "Tripura",
    "Uttar Pradesh", "Uttarakhand", "West Bengal", "Andaman and Nicobar Islands",
    "Chandigarh", "Dadra and Nagar Haveli and Daman and Diu", "Delhi",
    "Jammu and Kashmir", "Ladakh", "Lakshadweep", "Puducherry"
  ];

  @override
  void initState() {
    super.initState();
    _googlePlace = GooglePlace('AIzaSyCcppZWLo75ylSQvsR-bTPZLEFEEec5nrY');
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadUserDetails();
    });
  }

  Future<void> _loadUserDetails() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('userId');
      if (userId == null || userId.isEmpty) throw Exception('Please login first');

      final userController = Provider.of<UserController>(context, listen: false);
      await userController.fetchUserDetails(userId);

      final updatedPrefs = await SharedPreferences.getInstance();
      if (!mounted) return;

      setState(() {
        _nameController.text = updatedPrefs.getString('username') ?? '';
        _phoneController.text = updatedPrefs.getString('phone') ?? '';
        _emailController.text = updatedPrefs.getString('email') ?? '';
        _pincodeController.text = updatedPrefs.getString('pincode') ?? '';
        _addressController.text = updatedPrefs.getString('address') ?? '';
        final state = updatedPrefs.getString('state');
        _selectedState = _states.contains(state) ? state : null;
      });
    } catch (e) {
      _errorMessage = 'Failed to load details';
      EasyLoading.showError(_errorMessage!);
    } finally {
      if (mounted) setState(() => _isLoading = false);
      EasyLoading.dismiss();
    }
  }

  Future<void> _refreshCart() async {
    await EasyLoading.show(status: 'Refreshing cart...');
    try {
      await _loadUserDetails();
      await EasyLoading.showSuccess('Cart refreshed successfully');
    } catch (e) {
      await EasyLoading.showError('Failed to refresh cart: $e');
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _pincodeController.dispose();
    _locationController.dispose();
    _addressController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  void _autoCompleteSearch(String input) {
    if (input.isEmpty) {
      setState(() {
        _predictions.clear();
      });
      return;
    }

    _googlePlace.autocomplete.get(input).then((result) {
      if (result != null && result.predictions != null && mounted) {
        setState(() {
          _predictions = result.predictions!;
        });
      }
    });
  }

  Future<void> _getPlaceDetails(String placeId) async {
    await EasyLoading.show(status: 'Fetching location details...');
    try {
      var result = await _googlePlace.details.get(placeId);
      if (result != null && result.result != null && mounted) {
        setState(() {
          _locationController.text = result.result!.formattedAddress!;
          _latitude = result.result!.geometry!.location!.lat;
          _longitude = result.result!.geometry!.location!.lng;
          _predictions.clear();
          debugPrint("📍 Latitude: $_latitude, Longitude: $_longitude");
        });
        await EasyLoading.dismiss();
      } else {
        throw Exception('Failed to fetch location details');
      }
    } catch (e) {
      await EasyLoading.showError('Failed to fetch location: $e');
      debugPrint('❌ Error fetching place details: $e');
    }
  }

  void _nextStep(CartProvider cartProvider) {
    if (_currentStep == 0) {
      if (cartProvider.cartItems.isEmpty) {
        EasyLoading.showError('Cart is empty. Add items to proceed.');
        return;
      }
      for (var item in cartProvider.cartItems) {
        if (item.selectedDate == null || item.selectedTime == null || item.selectedDuration == null) {
          EasyLoading.showError('All items must have a selected date, time, and duration.');
          return;
        }
      }
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      setState(() => _currentStep++);
    } else if (_currentStep == 1) {
      if (_formKey.currentState!.validate()) {
        if (_latitude == null || _longitude == null) {
          EasyLoading.showError('Please select a valid location from the suggestions.');
          return;
        }
        // Save state to SharedPreferences
        SharedPreferences.getInstance().then((prefs) => prefs.setString('state', _selectedState ?? ''));
        _pageController.nextPage(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
        setState(() => _currentStep++);
      }
    } else if (_currentStep == 2) {
      _confirmPayment();
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      setState(() => _currentStep--);
    }
  }

  Future<void> _confirmPayment() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    await EasyLoading.show(status: 'Processing payment...');
    final cartProvider = Provider.of<CartProvider>(context, listen: false);
    final socketController = Provider.of<SocketController>(context, listen: false);

    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('userId');
      if (userId == null) {
        throw Exception('User ID not found. Please log in.');
      }

      String paymentMode;
      switch (_selectedPaymentMethod) {
        case 'UPI':
          paymentMode = 'UPI';
          break;
        case 'Cash on Delivery':
          paymentMode = 'COD';
          break;
        default:
          paymentMode = 'COD';
      }

      final orderData = {
        'phone': _phoneController.text,
        'pincode': _pincodeController.text,
        'address': _addressController.text,
        'items': cartProvider.cartItems.map((item) => item.toJson()).toList(),
        'status': '1',
        'mode': paymentMode,
        'details': {
          'username': _nameController.text,
          'phone': _phoneController.text,
          'pincode': _pincodeController.text,
          'state': _selectedState,
          'address': _addressController.text,
          'email': _emailController.text,
        },
        'discount': 0,
        'shipping': 0,
        'totalAmount': cartProvider.totalPrice,
        'primary': 'true',
        'payment': 1,
        'username': _nameController.text,
        'email': _emailController.text,
        'location': _locationController.text.isNotEmpty ? _locationController.text : _selectedState ?? '',
        'lat': _latitude,
        'lng': _longitude,
        'userId': userId,
        'state': _selectedState,
        'verified': 1,
      };

      debugPrint('📦 Order Data: ${jsonEncode(orderData)}');

      final result = await _apiServices.createOrder(userId, orderData);

      final newOrder = result['order'];
      if (newOrder != null) {
        final sendmsg = {
          'userId': newOrder['userId']?[0] ?? newOrder['userId'] ?? userId,
          'type': 'book',
          'order': newOrder,
          'orderId': newOrder['orderId'],
        };
        debugPrint('📡 Sending socket message: $sendmsg');
        await socketController.sendOrderNotification(sendmsg);
      } else {
        debugPrint('⚠️ New order data is null, skipping socket notification');
      }
      cartProvider.clearCart();
      await EasyLoading.showSuccess('Order placed successfully!');
      setState(() => _isLoading = false);

      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            title: const Row(
              children: [
                Icon(Icons.check_circle, color: Colors.green, size: 24),
                SizedBox(width: 8),
                Text(
                  'Order Confirmed',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: Colors.green),
                ),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Your order has been placed successfully on ${DateFormat('EEEE, MMMM d, yyyy').format(DateTime.now())} at ${DateFormat('h:mm a').format(DateTime.now())} IST!',
                  style: const TextStyle(fontSize: 16, color: Colors.black87),
                ),
                const SizedBox(height: 10),
                const Text(
                  'Order Status: Created',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.blue),
                ),
                const SizedBox(height: 5),
                Text(
                  result['message'] ?? 'Thank you for your purchase!',
                  style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (context) => const MainScreen()),
                        (route) => false,
                  );
                },
                style: TextButton.styleFrom(
                  foregroundColor: Colors.blue,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: const Text('Back to Home', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      setState(() => _isLoading = false);
      await EasyLoading.showError('Failed to create order: $e');
      debugPrint('❌ Error creating order: $e');
    }
  }

  Widget _buildEmptyCartUI() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.shopping_cart_rounded,
            size: 100,
            color: Colors.blueAccent.withOpacity(0.5),
          ),
          const SizedBox(height: 15),

          const Text(
            "Your cart is empty",
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),

          const SizedBox(height: 8),

          const Text(
            "Add something to checkout!",
            style: TextStyle(
              fontSize: 15,
              color: Colors.black54,
            ),
          ),
        ],
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    final cartProvider = Provider.of<CartProvider>(context);
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    if (_isLoading && _errorMessage == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator(color: Colors.blue)),
      );
    }

    if (_errorMessage != null) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                _errorMessage!,
                style: const TextStyle(fontSize: 16, color: Colors.red),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _loadUserDetails,
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

    if (cartProvider.cartItems.isEmpty) {
      return
        _buildEmptyCartUI();
    }

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _refreshCart,
        color: Colors.blueAccent,
        child: Column(
          children: [
            Padding(
              padding: EdgeInsets.symmetric(vertical: screenHeight * 0.02),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildStepCircle(0, 'Cart'),
                  _buildStepLine(0),
                  _buildStepCircle(1, 'Checkout'),
                  _buildStepLine(1),
                  _buildStepCircle(2, 'Payment'),
                ],
              ),
            ),
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                onPageChanged: (index) {
                  if (mounted) setState(() => _currentStep = index);
                },
                children: [
                  _buildCartStep(cartProvider, screenWidth, screenHeight),
                  _buildCheckoutStep(cartProvider, screenWidth, screenHeight),
                  _buildPaymentStep(cartProvider, screenWidth, screenHeight),
                ],
              ),
            ),
            Container(
              padding: EdgeInsets.all(screenWidth * 0.04),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.2),
                    spreadRadius: 2,
                    blurRadius: 5,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  if (_currentStep > 0)
                    ElevatedButton(
                      onPressed: _isLoading ? null : _previousStep,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.grey,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        minimumSize: Size(screenWidth * 0.3, screenHeight * 0.06),
                      ),
                      child: const Text('Back'),
                    ),
                  Expanded(child: const SizedBox.shrink()),
                  ElevatedButton(
                    onPressed: _isLoading ? null : () => _nextStep(cartProvider),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      minimumSize: Size(screenWidth * 0.3, screenHeight * 0.06),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(color: Colors.white),
                    )
                        : Text(_currentStep == 2 ? 'Pay Now' : 'Next'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStepCircle(int step, String label) {
    return Column(
      children: [
        Container(
          width: 30,
          height: 30,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: _currentStep >= step ? Colors.blue : Colors.grey,
          ),
          child: Center(
            child: Text(
              '${step + 1}',
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    );
  }

  Widget _buildStepLine(int step) {
    return Container(
      width: 60,
      height: 2,
      color: _currentStep > step ? Colors.blue : Colors.grey,
      margin: const EdgeInsets.symmetric(horizontal: 8),
    );
  }

  Widget _buildCartItem(Product item, double screenWidth, double screenHeight) {
    final dateFormat = DateFormat('EEE, d MMM');
    final timeFormat = DateFormat('h:mm a');
    final duration = item.selectedDuration ?? 'Not specified';
    final displayDate = item.selectedDate != null ? dateFormat.format(item.selectedDate!) : 'Date not selected';
    final displayTime = item.selectedTime != null ? timeFormat.format(item.selectedTime!) : 'Time not selected';

    return Card(
      elevation: 4,
      margin: EdgeInsets.only(bottom: screenWidth * 0.03),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: EdgeInsets.all(screenWidth * 0.03),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                item.pImage,
                width: screenWidth * 0.2,
                height: screenWidth * 0.2,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => const Icon(Icons.error),
              ),
            ),
            SizedBox(width: screenWidth * 0.04),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.title,
                    style: TextStyle(fontSize: screenWidth * 0.045, fontWeight: FontWeight.bold, color: Colors.black87),
                  ),
                  SizedBox(height: screenWidth * 0.015),
                  Text('• Date: $displayDate', style: TextStyle(fontSize: screenWidth * 0.035, color: Colors.grey[600])),
                  Text('• Time: $displayTime / $duration', style: TextStyle(fontSize: screenWidth * 0.035, color: Colors.grey[600])),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '₹${item.salePrice.toStringAsFixed(0)}',
                  style: TextStyle(fontSize: screenWidth * 0.045, fontWeight: FontWeight.bold, color: Colors.blue[700]),
                ),
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () async {
                    await EasyLoading.show(status: 'Removing item...');
                    try {
                      Provider.of<CartProvider>(context, listen: false).removeFromCart(item);
                      await EasyLoading.showSuccess('Item removed from cart');
                    } catch (e) {
                      await EasyLoading.showError('Failed to remove item: $e');
                    }
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCartStep(CartProvider cartProvider, double screenWidth, double screenHeight) {
    if (cartProvider.cartItems.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              "Your cart is empty",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey),
            ),
            SizedBox(height: screenHeight * 0.02),
            Text('No cart here', style: TextStyle(fontSize: 14, color: Colors.grey[600])),


          ],
        ),
      );
    }

    return ListView(
      padding: EdgeInsets.all(screenWidth * 0.04),
      children: [
        Text(
          "Your Cart",
          style: TextStyle(fontSize: screenWidth * 0.06, fontWeight: FontWeight.bold, color: Colors.black87),
        ),
        SizedBox(height: screenWidth * 0.03),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: cartProvider.cartItems.length,
          itemBuilder: (context, index) => _buildCartItem(cartProvider.cartItems[index], screenWidth, screenHeight),
        ),
        SizedBox(height: screenWidth * 0.04),
        Card(
          elevation: 4,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: EdgeInsets.all(screenWidth * 0.04),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Total (${cartProvider.cartItems.length} Item${cartProvider.cartItems.length == 1 ? '' : 's'})',
                      style: TextStyle(fontSize: screenWidth * 0.045, fontWeight: FontWeight.bold, color: Colors.black87),
                    ),
                    Text(
                      '₹${cartProvider.totalPrice.toStringAsFixed(0)}',
                      style: TextStyle(fontSize: screenWidth * 0.045, fontWeight: FontWeight.bold, color: Colors.blue[700]),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCheckoutStep(CartProvider cartProvider, double screenWidth, double screenHeight) {
    double fieldSpacing = screenWidth * 0.02;
    double fieldHeight = screenHeight * 0.06;

    if (cartProvider.cartItems.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              "Your cart is empty",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey),
            ),
            SizedBox(height: screenHeight * 0.02),

          ],
        ),
      );
    }

    return SingleChildScrollView(
      padding: EdgeInsets.all(screenWidth * 0.04),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              elevation: 3,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: EdgeInsets.all(screenWidth * 0.04),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Delivery Details",
                      style: TextStyle(fontSize: screenWidth * 0.045, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: fieldSpacing),
                    _buildTextField(
                      controller: _nameController,
                      label: "Full Name",
                      height: fieldHeight,
                      validator: (val) => val!.isEmpty ? "Enter your name" : null,
                    ),
                    SizedBox(height: fieldSpacing),
                    Row(
                      children: [
                        Expanded(
                          child: _buildTextField(
                            controller: _phoneController,
                            label: "Phone No.",
                            keyboardType: TextInputType.phone,
                            height: fieldHeight,
                            validator: (val) => val!.length != 10 ? "Enter a valid phone number" : null,
                          ),
                        ),
                        SizedBox(width: fieldSpacing),
                        Expanded(
                          child: _buildTextField(
                            controller: _emailController,
                            label: "Email",
                            height: fieldHeight,
                            validator: (val) {
                              if (val!.isEmpty) return "Enter email";
                              if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(val)) {
                                return "Enter a valid email";
                              }
                              return null;
                            },
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: fieldSpacing),
                    Row(
                      children: [
                        Expanded(
                          child: _buildTextField(
                            controller: _pincodeController,
                            label: "Pincode",
                            keyboardType: TextInputType.number,
                            height: fieldHeight,
                            validator: (val) => val!.length != 6 ? "Enter a valid pincode" : null,
                          ),
                        ),
                        SizedBox(width: fieldSpacing),
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: _selectedState,
                            isExpanded: true,
                            decoration: _inputDecoration("State"),
                            items: _states.map((state) => DropdownMenuItem(value: state, child: Text(state))).toList(),
                            onChanged: (val) => setState(() => _selectedState = val),
                            validator: (val) => val == null ? "Select a state" : null,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: fieldSpacing),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildTextField(
                          controller: _locationController,
                          label: "Search your location...",
                          height: fieldHeight,
                          suffixIcon: const Icon(Icons.location_on, color: Colors.blue),
                          onChanged: _autoCompleteSearch,
                        ),
                        if (_predictions.isNotEmpty)
                          Container(
                            height: 200,
                            child: ListView.builder(
                              itemCount: _predictions.length,
                              itemBuilder: (context, index) {
                                return ListTile(
                                  title: Text(_predictions[index].description!),
                                  onTap: () => _getPlaceDetails(_predictions[index].placeId!),
                                );
                              },
                            ),
                          ),
                      ],
                    ),
                    SizedBox(height: fieldSpacing),
                    _buildTextField(
                      controller: _addressController,
                      label: "Full Address",
                      maxLines: 3,
                      validator: (val) => val!.isEmpty ? "Enter your address" : null,
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: screenWidth * 0.05),
            Card(
              elevation: 3,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: EdgeInsets.all(screenWidth * 0.04),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Your Order",
                      style: TextStyle(fontSize: screenWidth * 0.045, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: screenWidth * 0.02),
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: cartProvider.cartItems.length,
                      itemBuilder: (context, index) => _buildCartItem(cartProvider.cartItems[index], screenWidth, screenHeight),
                    ),
                    const Divider(),
                    _buildPriceRow("Subtotal:", "₹${cartProvider.totalPrice.toStringAsFixed(0)}"),
                    SizedBox(height: screenWidth * 0.01),
                    _buildPriceRow("Shipping:", "₹0"),
                    const Divider(),
                    _buildPriceRow("Total", "₹${cartProvider.totalPrice.toStringAsFixed(0)}", isBold: true),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentStep(CartProvider cartProvider, double screenWidth, double screenHeight) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(screenWidth * 0.04),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Card(
            elevation: 3,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: EdgeInsets.all(screenWidth * 0.04),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Order Summary',
                    style: TextStyle(fontSize: screenWidth * 0.045, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: screenWidth * 0.02),
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: cartProvider.cartItems.length,
                    itemBuilder: (context, index) => _buildCartItem(cartProvider.cartItems[index], screenWidth, screenHeight),
                  ),
                  const Divider(),
                  _buildPriceRow("Total", "₹${cartProvider.totalPrice.toStringAsFixed(0)}", isBold: true),
                ],
              ),
            ),
          ),
          SizedBox(height: screenWidth * 0.05),
          Card(
            elevation: 3,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: EdgeInsets.all(screenWidth * 0.04),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Payment Method',
                    style: TextStyle(fontSize: screenWidth * 0.045, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: screenWidth * 0.02),
                  RadioListTile<String>(
                    title: const Text('Cash on Delivery'),
                    value: 'Cash on Delivery',
                    groupValue: _selectedPaymentMethod,
                    onChanged: (value) => setState(() => _selectedPaymentMethod = value!),
                    activeColor: Colors.blue,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPriceRow(String label, String value, {bool isBold = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(fontWeight: isBold ? FontWeight.bold : FontWeight.normal, fontSize: MediaQuery.of(context).size.width * 0.04),
        ),
        Text(
          value,
          style: TextStyle(fontWeight: isBold ? FontWeight.bold : FontWeight.normal, fontSize: MediaQuery.of(context).size.width * 0.04),
        ),
      ],
    );
  }

  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.blue, width: 1.5),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    int maxLines = 1,
    double? height,
    String? Function(String?)? validator,
    TextInputType? keyboardType,
    Widget? suffixIcon,
    ValueChanged<String>? onChanged,
  }) {
    return SizedBox(
      height: height,
      child: TextFormField(
        controller: controller,
        validator: validator,
        maxLines: maxLines,
        keyboardType: keyboardType,
        onChanged: onChanged,
        decoration: _inputDecoration(label).copyWith(suffixIcon: suffixIcon),
      ),
    );
  }
}