import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../controllers/cart_provider.dart';
import 'payment_page.dart';

class CheckoutPage extends StatefulWidget {
  const CheckoutPage({super.key});

  @override
  _CheckoutPageState createState() => _CheckoutPageState();
}

class _CheckoutPageState extends State<CheckoutPage> {
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _pincodeController = TextEditingController();
  final _locationController = TextEditingController();
  final _addressController = TextEditingController();

  String? _selectedState;

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _pincodeController.dispose();
    _locationController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  void _placeOrder(BuildContext context) {
    if (_formKey.currentState!.validate()) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const PaymentPage()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final cartProvider = Provider.of<CartProvider>(context);
    final screenWidth = MediaQuery.of(context).size.width;

    double fieldSpacing = screenWidth * 0.02; // responsive spacing
    double fieldHeight = screenWidth * 0.12; // responsive height

    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(65),
        child: AppBar(
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
            'Checkout',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.white,
              fontSize: 20,
            ),
          ),
          flexibleSpace: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xff004e92), Color(0xff000428)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(4.0),
            child: LinearProgressIndicator(
              value: 2 / 3,
              backgroundColor: Colors.white.withOpacity(0.3),
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          ),
          elevation: 3,
        ),
      ),
      body: SafeArea(
        child: cartProvider.cartItems.isEmpty
            ? const Center(
          child: Text(
            'Your cart is empty',
            style: TextStyle(fontSize: 18),
          ),
        )
            : SingleChildScrollView(
          padding: EdgeInsets.all(screenWidth * 0.04),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                /// ---------------- Address Section ----------------
                Card(
                  elevation: 3,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                  child: Padding(
                    padding: EdgeInsets.all(screenWidth * 0.04),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Delivery Details",
                          style: TextStyle(
                              fontSize: screenWidth * 0.045,
                              fontWeight: FontWeight.bold),
                        ),
                        SizedBox(height: fieldSpacing),

                        _buildTextField(
                          controller: _nameController,
                          label: "Full Name",
                          height: fieldHeight,
                          validator: (val) =>
                          val!.isEmpty ? "Enter your name" : null,
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
                                validator: (val) => val!.isEmpty
                                    ? "Enter phone number"
                                    : null,
                              ),
                            ),
                            SizedBox(width: fieldSpacing),
                            Expanded(
                              child: _buildTextField(
                                controller: _emailController,
                                label: "Email",
                                height: fieldHeight,
                                validator: (val) =>
                                val!.isEmpty ? "Enter email" : null,
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
                                ]
                                    .map((state) => DropdownMenuItem(
                                  value: state,
                                  child: Text(state),
                                ))
                                    .toList(),
                                onChanged: (val) {
                                  setState(() {
                                    _selectedState = val;
                                  });
                                },
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: fieldSpacing),

                        _buildTextField(
                          controller: _locationController,
                          label: "Search your location...",
                          height: fieldHeight,
                          suffixIcon: const Icon(Icons.location_on,
                              color: Colors.blue),
                        ),
                        SizedBox(height: fieldSpacing),

                        _buildTextField(
                          controller: _addressController,
                          label: "Full Address",
                          maxLines: 3,
                        ),
                      ],
                    ),
                  ),
                ),

                SizedBox(height: screenWidth * 0.05),

                /// ---------------- Product Section ----------------
                Card(
                  elevation: 3,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                  child: Padding(
                    padding: EdgeInsets.all(screenWidth * 0.04),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Your Order",
                          style: TextStyle(
                              fontSize: screenWidth * 0.045,
                              fontWeight: FontWeight.bold),
                        ),
                        SizedBox(height: fieldSpacing),

                        ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: cartProvider.cartItems.length,
                          itemBuilder: (context, index) {
                            final item = cartProvider.cartItems[index];
                            return Card(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              margin: EdgeInsets.symmetric(
                                  vertical: fieldSpacing / 2),
                              child: ListTile(
                                leading: ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Image.network(item.pImage,
                                      width: screenWidth * 0.12,
                                      fit: BoxFit.cover),
                                ),
                                title: Text(item.title,
                                    style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: screenWidth * 0.04)),
                                subtitle: Text(
                                  "₹${item.salePrice}  |  Qty: 1\n${DateFormat('EEE, d MMM').format(item.selectedDate ?? DateTime.now())}",
                                  style: TextStyle(
                                      fontSize: screenWidth * 0.035),
                                ),
                                trailing: Text(
                                  "₹${(item.salePrice * 1).toStringAsFixed(0)}",
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: screenWidth * 0.04),
                                ),
                              ),
                            );
                          },
                        ),
                        const Divider(),
                        _buildPriceRow(
                            "Subtotal:",
                            "₹${cartProvider.totalPrice.toStringAsFixed(0)}"),
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

                SizedBox(height: screenWidth * 0.05),

                /// Promo code
                TextFormField(
                  decoration: InputDecoration(
                    labelText: "Promo code",
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    suffixIcon: TextButton(
                      onPressed: () {},
                      child: const Text("Apply",
                          style: TextStyle(color: Colors.blue)),
                    ),
                  ),
                ),

                SizedBox(height: screenWidth * 0.06),

                /// ---------------- Checkout Button ----------------
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => _placeOrder(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blueAccent,
                      foregroundColor: Colors.white,
                      minimumSize: Size(double.infinity, fieldHeight),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      elevation: 3,
                    ),
                    child: Text(
                      "Proceed to Payment",
                      style: TextStyle(fontSize: screenWidth * 0.045),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
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

  Widget _buildPriceRow(String label, String value, {bool isBold = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: TextStyle(
                fontWeight: isBold ? FontWeight.bold : FontWeight.normal)),
        Text(
          value,
          style: TextStyle(
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal),
        ),
      ],
    );
  }
}