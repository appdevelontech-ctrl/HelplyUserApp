import 'package:flutter/material.dart';

class AddAddressPage extends StatefulWidget {
  const AddAddressPage({super.key});

  @override
  State<AddAddressPage> createState() => _AddAddressPageState();
}

class _AddAddressPageState extends State<AddAddressPage> {
  bool isHomeSelected = true;

  final TextEditingController flatController = TextEditingController();
  final TextEditingController floorController = TextEditingController();
  final TextEditingController apartmentController = TextEditingController();
  final TextEditingController landmarkController = TextEditingController();
  final TextEditingController phoneController =
  TextEditingController(text: '+91 8802377021');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text("Add address details"),
        leading: IconButton(
          icon: Image.asset(
            'assets/icons/back.png',
            width: 24,
            height: 24,
          ),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0.5,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Address details",
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text("Save address as",
                style: TextStyle(color: Colors.grey.shade600)),
            const SizedBox(height: 12),

            // Toggle buttons
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                      isHomeSelected ? Colors.green : Colors.grey.shade200,
                      foregroundColor:
                      isHomeSelected ? Colors.white : Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                    ),
                    onPressed: () {
                      setState(() => isHomeSelected = true);
                    },
                    child: const Text("Home"),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                      !isHomeSelected ? Colors.green : Colors.grey.shade200,
                      foregroundColor:
                      !isHomeSelected ? Colors.white : Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                    ),
                    onPressed: () {
                      setState(() => isHomeSelected = false);
                    },
                    child: const Text("Other"),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // TextFields
            _buildTextField("Flat/House no.*", flatController),
            const SizedBox(height: 12),
            _buildTextField("Floor (Optional)", floorController),
            const SizedBox(height: 12),
            _buildTextField("Apartment / Building name*", apartmentController),
            const SizedBox(height: 12),
            _buildTextField("Nearby Landmark (Optional)", landmarkController),

            const SizedBox(height: 16),
            // Current area card
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Area/Sector/Locality*",
                      style:
                      TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          "Block C, Sector 56, Gurugram, Haryana, India, 122011",
                          style: TextStyle(
                              fontSize: 13, color: Colors.grey.shade700),
                        ),
                      ),
                      TextButton(
                        onPressed: () {},
                        child: const Text("Change"),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),
            Text("Receiver details",
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text("Our professional will reach out to you on this number.",
                style: TextStyle(color: Colors.grey.shade600)),
            const SizedBox(height: 12),
            _buildTextField("Receiver's phone number*", phoneController,
                keyboardType: TextInputType.phone),

            const SizedBox(height: 30),
          ],
        ),
      ),

      // Bottom button
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          onPressed: () {
            // Save address logic
          },
          child: const Text("Save address",
              style: TextStyle(fontSize: 16, color: Colors.white)),
        ),
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller,
      {TextInputType keyboardType = TextInputType.text}) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        contentPadding:
        const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        filled: true,
        fillColor: Colors.white,
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.green),
        ),
      ),
    );
  }
}
