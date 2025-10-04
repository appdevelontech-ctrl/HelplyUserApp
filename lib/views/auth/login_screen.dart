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
      duration: const Duration(milliseconds: 1000),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
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
              // Background gradient only, no image
              Container(
                width: double.infinity,
                height: double.infinity,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Color(0xff237bc9), // top color
                      Color(0xff000428), // bottom color
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
              ),

              SafeArea(
                child: Center(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.symmetric(horizontal: size.width * 0.08),
                    child: FadeTransition(
                      opacity: _fadeAnimation,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text(
                            "Welcome Back",
                            style: TextStyle(
                              fontSize: 36,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          SizedBox(height: size.height * 0.02),
                          Form(
                            key: _formKey,
                            child: Column(
                              children: [
                                TextFormField(
                                  controller: _phoneController,
                                  keyboardType: TextInputType.phone,
                                  style: const TextStyle(color: Colors.white),
                                  decoration: InputDecoration(
                                    prefixIcon: Icon(Icons.phone, color: Colors.white.withOpacity(0.8)),
                                    labelText: "Phone Number",
                                    labelStyle: TextStyle(color: Colors.white.withOpacity(0.8)),
                                    filled: true,
                                    fillColor: Colors.white.withOpacity(0.2),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(15),
                                      borderSide: BorderSide.none,
                                    ),
                                  ),
                                  validator: (value) {
                                    if (value == null || value.isEmpty) return 'Enter phone number';
                                    if (!RegExp(r'^\d{10}$').hasMatch(value)) return 'Enter valid 10-digit number';
                                    return null;
                                  },
                                ),
                                if (_showPasswordField && controller.passwordRequired) ...[
                                  SizedBox(height: size.height * 0.02),
                                  TextFormField(
                                    controller: _passwordController,
                                    obscureText: true,
                                    style: const TextStyle(color: Colors.white),
                                    decoration: InputDecoration(
                                      prefixIcon: Icon(Icons.lock, color: Colors.white.withOpacity(0.8)),
                                      labelText: "Password",
                                      labelStyle: TextStyle(color: Colors.white.withOpacity(0.8)),
                                      filled: true,
                                      fillColor: Colors.white.withOpacity(0.2),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(15),
                                        borderSide: BorderSide.none,
                                      ),
                                    ),
                                    validator: (value) => (value == null || value.isEmpty) ? 'Enter password' : null,
                                  ),
                                ],
                              ],
                            ),
                          ),
                          SizedBox(height: size.height * 0.03),
                          controller.isLoading
                              ? const CircularProgressIndicator(color: Colors.orangeAccent)
                              : Column(
                            children: [
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.orangeAccent,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                                  padding: EdgeInsets.symmetric(
                                    horizontal: size.width * 0.15,
                                    vertical: size.height * 0.02,
                                  ),
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
                                      controller.loginWithPhone(_phoneController.text.trim(), context);
                                    }
                                  }
                                },
                                child: Text(
                                  controller.passwordRequired && _showPasswordField
                                      ? "Login with Password"
                                      : "Send OTP",
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                              if (controller.passwordRequired && _showPasswordField) ...[
                                SizedBox(height: size.height * 0.015),
                                TextButton(
                                  onPressed: () {
                                    _passwordController.clear();
                                    setState(() {
                                      _showPasswordField = false;
                                    });
                                    controller.sendOtpForPasswordUser(_phoneController.text.trim(), context);
                                  },
                                  child: const Text(
                                    "Login with OTP instead",
                                    style: TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ],
                            ],
                          ),
                          if (controller.errorMessage != null)
                            Padding(
                              padding: EdgeInsets.only(top: size.height * 0.015),
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
}
