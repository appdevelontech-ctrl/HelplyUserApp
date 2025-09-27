import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_maps_place_picker_mb/google_maps_place_picker.dart';

import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;



import '../controllers/cart_provider.dart';
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
  String _selectedPaymentMethod = 'Credit Card';
  double? _latitude;
  double? _longitude;
  final ApiServices _apiServices = ApiServices();

  final PageController _pageController = PageController();
  int _currentStep = 0;
  bool _isLoading = false;

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

  Future<void> _pickLocation() async {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PlacePicker(
          apiKey: 'AIzaSyCcppZWLo75ylSQvsR-bTPZLEFEEec5nrY',
          onPlacePicked: (PickResult result) {
            setState(() {
              _locationController.text = result.formattedAddress ?? '';
              _latitude = result.geometry?.location.lat;
              _longitude = result.geometry?.location.lng;
            });
            Navigator.pop(context);
          },
          initialPosition: const LatLng(28.6139, 77.2090), // Delhi
          useCurrentLocation: true,
          selectInitialPosition: true,
        ),
      ),
    );
  }

  Future<void> _fetchCurrentLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Location services are disabled.')),
        );
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Location permissions are denied.')),
          );
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Location permissions are permanently denied.')),
        );
        return;
      }

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      setState(() {
        _latitude = position.latitude;
        _longitude = position.longitude;
        _locationController.text = 'Current Location';
      });

      final response = await http.get(
        Uri.parse(
          'https://maps.googleapis.com/maps/api/geocode/json?latlng=${position.latitude},${position.longitude}&key=YOUR_GOOGLE_MAPS_API_KEY',
        ),
      );

      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body);
        if (jsonData['status'] == 'OK') {
          setState(() {
            _locationController.text = jsonData['results'][0]['formatted_address'] ?? 'Current Location';
          });
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to get current location: $e')),
      );
    }
  }

  void _nextStep(CartProvider cartProvider) {
    if (_currentStep == 0) {
      if (cartProvider.cartItems.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Cart is empty. Add items to proceed.')),
        );
        return;
      }
      _pageController.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
      setState(() => _currentStep++);
    } else if (_currentStep == 1) {
      if (_formKey.currentState!.validate()) {
        if (_latitude == null || _longitude == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Please select a location.')),
          );
          return;
        }
        _pageController.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
        setState(() => _currentStep++);
      }
    } else if (_currentStep == 2) {
      _confirmPayment();
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      _pageController.previousPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
      setState(() => _currentStep--);
    }
  }

  Future<void> _confirmPayment() async {
    setState(() => _isLoading = true);
    final cartProvider = Provider.of<CartProvider>(context, listen: false);

    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('userId');
      if (userId == null) throw Exception('User ID not found. Please log in.');

      String paymentMode;
      switch (_selectedPaymentMethod) {
        case 'Credit Card':
          paymentMode = 'CARD';
          break;
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
          'latitude': _latitude,
          'longitude': _longitude,
        },
        'discount': 0,
        'shipping': 0,
        'totalAmount': cartProvider.totalPrice,
        'primary': 'true',
        'payment': 1,
        'username': _nameController.text,
        'email': _emailController.text,
        'location': _locationController.text.isNotEmpty ? _locationController.text : _selectedState,
        'userId': userId,
        'state': _selectedState,
        'verified': 1,
      };

      final result = await _apiServices.createOrder(userId, orderData);

      cartProvider.clearCart();
      setState(() => _isLoading = false);

      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Order Confirmed'),
          content: Text(result['message'] ?? 'Your order has been placed successfully!'),
          actions: [
            TextButton(
              onPressed: () => Navigator.popUntil(context, (route) => route.isFirst),
              child: const Text('Back to Home'),
            ),
          ],
        ),
      );
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to create order: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final cartProvider = Provider.of<CartProvider>(context);
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(65),
        child: AppBar(
          elevation: 0,
          flexibleSpace: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xff004e92), Color(0xff000428)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
          title: const Text('Order Process', style: TextStyle(color: Colors.white)),
        ),
      ),
      body: Column(
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
              onPageChanged: (index) => setState(() => _currentStep = index),
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
                    onPressed: _previousStep,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      minimumSize: Size(screenWidth * 0.3, screenHeight * 0.06),
                    ),
                    child: const Text('Back'),
                  ),
                Expanded(child: SizedBox.shrink()),
                ElevatedButton(
                  onPressed: _isLoading ? null : () => _nextStep(cartProvider),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    minimumSize: Size(screenWidth * 0.3, screenHeight * 0.06),
                  ),
                  child: _isLoading
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white))
                      : Text(_currentStep == 2 ? 'Pay Now' : 'Next'),
                ),
              ],
            ),
          ),
        ],
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
            child: Text('${step + 1}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
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
    final duration = item.selectedDuration;

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
                  Text(item.title, style: TextStyle(fontSize: screenWidth * 0.045, fontWeight: FontWeight.bold, color: Colors.black87)),
                  SizedBox(height: screenWidth * 0.015),
                  Text('• Date: ${dateFormat.format(item.selectedDate!)}', style: TextStyle(fontSize: screenWidth * 0.035, color: Colors.grey[600])),
                  Text('• Time: ${timeFormat.format(item.selectedTime!)} / ${duration}', style: TextStyle(fontSize: screenWidth * 0.035, color: Colors.grey[600])),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text('₹${item.salePrice.toStringAsFixed(0)}', style: TextStyle(fontSize: screenWidth * 0.045, fontWeight: FontWeight.bold, color: Colors.blue[700])),
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () => Provider.of<CartProvider>(context, listen: false).removeFromCart(item),
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
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text('Continue Shopping'),
            ),
          ],
        ),
      );
    }

    return ListView(
      padding: EdgeInsets.all(screenWidth * 0.04),
      children: [
        Text(
          "Your Cart",
          style: TextStyle(
            fontSize: screenWidth * 0.06,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        SizedBox(height: screenWidth * 0.03),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: cartProvider.cartItems.length,
          itemBuilder: (context, index) => _buildCartItem(
            cartProvider.cartItems[index],
            screenWidth,
            screenHeight,
          ),
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
                      style: TextStyle(
                        fontSize: screenWidth * 0.045,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    Text(
                      '₹${cartProvider.totalPrice.toStringAsFixed(0)}',
                      style: TextStyle(
                        fontSize: screenWidth * 0.045,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue[700],
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
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text('Continue Shopping'),
            ),
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
            // Address Section
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
                      style: TextStyle(
                        fontSize: screenWidth * 0.045,
                        fontWeight: FontWeight.bold,
                      ),
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
                            items: [
                              "Andhra Pradesh",
                              "Arunachal Pradesh",
                              "Assam",
                              "Bihar",
                              "Chhattisgarh",
                              "Goa",
                              "Gujarat",
                              "Haryana",
                              "Himachal Pradesh",
                              "Jharkhand",
                              "Karnataka",
                              "Kerala",
                              "Madhya Pradesh",
                              "Maharashtra",
                              "Manipur",
                              "Meghalaya",
                              "Mizoram",
                              "Nagaland",
                              "Odisha",
                              "Punjab",
                              "Rajasthan",
                              "Sikkim",
                              "Tamil Nadu",
                              "Telangana",
                              "Tripura",
                              "Uttar Pradesh",
                              "Uttarakhand",
                              "West Bengal",
                              "Andaman and Nicobar Islands",
                              "Chandigarh",
                              "Dadra and Nagar Haveli and Daman and Diu",
                              "Delhi",
                              "Jammu and Kashmir",
                              "Ladakh",
                              "Lakshadweep",
                              "Puducherry"
                            ].map((state) => DropdownMenuItem(value: state, child: Text(state))).toList(),
                            onChanged: (val) => setState(() => _selectedState = val),
                            validator: (val) => val == null ? "Select a state" : null,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: fieldSpacing),
                    Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: _pickLocation,
                            child: AbsorbPointer(
                              child: _buildTextField(
                                controller: _locationController,
                                label: "Search your location...",
                                height: fieldHeight,
                                suffixIcon: const Icon(Icons.location_on, color: Colors.blue),
                                validator: (val) => val!.isEmpty ? "Select a location" : null,
                              ),
                            ),
                          ),
                        ),
                        SizedBox(width: fieldSpacing),
                        IconButton(
                          icon: const Icon(Icons.my_location, color: Colors.blue),
                          onPressed: _fetchCurrentLocation,
                          tooltip: 'Use Current Location',
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
            // Product Section
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
                      style: TextStyle(
                        fontSize: screenWidth * 0.045,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: fieldSpacing),
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: cartProvider.cartItems.length,
                      itemBuilder: (context, index) => _buildCartItem(
                        cartProvider.cartItems[index],
                        screenWidth,
                        screenHeight,
                      ),
                    ),
                    const Divider(),
                    _buildPriceRow(
                      "Subtotal:",
                      "₹${cartProvider.totalPrice.toStringAsFixed(0)}",
                    ),
                    SizedBox(height: fieldSpacing / 2),
                    _buildPriceRow("Shipping:", "₹0"),
                    const Divider(),
                    _buildPriceRow(
                      "Total",
                      "₹${cartProvider.totalPrice.toStringAsFixed(0)}",
                      isBold: true,
                    ),
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
                    style: TextStyle(
                      fontSize: screenWidth * 0.045,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: screenWidth * 0.02),
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: cartProvider.cartItems.length,
                    itemBuilder: (context, index) => _buildCartItem(
                      cartProvider.cartItems[index],
                      screenWidth,
                      screenHeight,
                    ),
                  ),
                  const Divider(),
                  _buildPriceRow(
                    "Total",
                    "₹${cartProvider.totalPrice.toStringAsFixed(0)}",
                    isBold: true,
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
                    'Payment Method',
                    style: TextStyle(
                      fontSize: screenWidth * 0.045,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: screenWidth * 0.02),
                  RadioListTile<String>(
                    title: const Text('Credit Card'),
                    value: 'Credit Card',
                    groupValue: _selectedPaymentMethod,
                    onChanged: (value) => setState(() => _selectedPaymentMethod = value!),
                    activeColor: Colors.blue,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  RadioListTile<String>(
                    title: const Text('UPI'),
                    value: 'UPI',
                    groupValue: _selectedPaymentMethod,
                    onChanged: (value) => setState(() => _selectedPaymentMethod = value!),
                    activeColor: Colors.blue,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
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
          style: TextStyle(
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            fontSize: MediaQuery.of(context).size.width * 0.04,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            fontSize: MediaQuery.of(context).size.width * 0.04,
          ),
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
  }) {
    return SizedBox(
      height: height,
      child: TextFormField(
        controller: controller,
        validator: validator,
        maxLines: maxLines,
        keyboardType: keyboardType,
        decoration: _inputDecoration(label).copyWith(suffixIcon: suffixIcon),
      ),
    );
  }
}