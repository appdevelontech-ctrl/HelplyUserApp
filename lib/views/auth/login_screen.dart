import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../controllers/user_controller.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with SingleTickerProviderStateMixin {
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  bool _showPasswordField = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnimation = CurvedAnimation(parent: _animationController, curve: Curves.easeIn);
    _animationController.forward();

    Future.microtask(() async {
      final prefs = await SharedPreferences.getInstance();
      final phone = prefs.getString('phone') ?? '';
      if (phone.isNotEmpty) {
        _phoneController.text = phone;
      }
    });
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _passwordController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Consumer<UserController>(
      builder: (context, controller, _) {
        if (controller.passwordRequired && !_showPasswordField) {
          _showPasswordField = true;
        }

        return Scaffold(
          body: Stack(
            children: [

              /// 🔹 Background full image
              Positioned.fill(
                child: Image.asset(
                  "assets/images/maid2.jpg",
                  fit: BoxFit.cover,
                ),
              ),

              /// 🔹 Dark blur layer for premium effect
              Positioned.fill(
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                  child: Container(color: Colors.black.withOpacity(0.45)),
                ),
              ),

              /// 🔹 UI Content
              SafeArea(
                child: Center(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.symmetric(horizontal: size.width * 0.09),
                    child: FadeTransition(
                      opacity: _fadeAnimation,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [

                          /// 🔹 Title
                          const Text(
                            "Welcome Back 👋",
                            style: TextStyle(
                              fontSize: 34,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),

                          const SizedBox(height: 6),
                          Text(
                            "Login to continue your maid services",
                            style: TextStyle(
                                color: Colors.white.withOpacity(0.8),
                                fontSize: 15),
                            textAlign: TextAlign.center,
                          ),

                          SizedBox(height: size.height * 0.03),

                          /// 🔹 Form Fields
                          Form(
                            key: _formKey,
                            child: Column(
                              children: [
                                _buildInput(
                                  controller: _phoneController,
                                  label: "Phone Number",
                                  icon: Icons.phone,
                                  keyboard: TextInputType.phone,
                                  validator: (value) {
                                    if (value == null || value.isEmpty) return 'Enter phone number';
                                    if (!RegExp(r'^\d{10}$').hasMatch(value)) return 'Enter valid 10-digit number';
                                    return null;
                                  },
                                ),

                                if (_showPasswordField && controller.passwordRequired) ...[
                                  SizedBox(height: size.height * 0.02),
                                  _buildInput(
                                    controller: _passwordController,
                                    label: "Password",
                                    icon: Icons.lock,
                                    isPassword: true,
                                  ),
                                ],
                              ],
                            ),
                          ),

                          SizedBox(height: size.height * 0.04),

                          /// 🔹 Button with logic unchanged
                          controller.isLoading
                              ? const CircularProgressIndicator(color: Colors.blueAccent)
                              : SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blueAccent,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                                padding: const EdgeInsets.symmetric(vertical: 16),
                              ),
                              onPressed: () {
                                if (_formKey.currentState!.validate()) {
                                  controller.errorMessage = null;
                                  if (controller.passwordRequired && _showPasswordField) {
                                    controller.loginWithPassword(
                                      _phoneController.text.trim(),
                                      _passwordController.text.trim(),
                                      context,
                                    );
                                  } else {
                                    controller.loginWithPhone(
                                        _phoneController.text.trim(), context);
                                  }
                                }
                              },
                              child: Text(
                                controller.passwordRequired && _showPasswordField
                                    ? "Login with Password"
                                    : "Send OTP",
                                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                              ),
                            ),
                          ),

                          /// 🔹 OTP toggle button
                          if (controller.passwordRequired && _showPasswordField) ...[
                            const SizedBox(height: 15),
                            TextButton(
                              onPressed: () {
                                _passwordController.clear();
                                setState(() => _showPasswordField = false);
                                controller.sendOtpForPasswordUser(
                                    _phoneController.text.trim(), context);
                              },
                              child: const Text(
                                "Login with OTP instead",
                                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],

                          /// 🔹 Error message
                          if (controller.errorMessage != null)
                            Padding(
                              padding: const EdgeInsets.only(top: 12),
                              child: Text(
                                controller.errorMessage!,
                                style: const TextStyle(color: Colors.redAccent),
                                textAlign: TextAlign.center,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  /// 🔥 Reusable beautiful input field
  Widget _buildInput({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType keyboard = TextInputType.text,
    bool isPassword = false,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      validator: validator,
      obscureText: isPassword,
      keyboardType: keyboard,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        prefixIcon: Icon(icon, color: Colors.white.withOpacity(0.9)),
        labelText: label,
        labelStyle: TextStyle(color: Colors.white.withOpacity(0.9)),
        filled: true,
        fillColor: Colors.white.withOpacity(0.15),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(18), borderSide: BorderSide.none),
      ),
    );
  }
}
