import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../controllers/user_controller.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/app_toast.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {

  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  bool _showPasswordField = false;
  String? _lastError;

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );

    _fadeAnimation =
        CurvedAnimation(parent: _animationController, curve: Curves.easeInOut);

    _animationController.forward();

    Future.microtask(() async {
      final prefs = await SharedPreferences.getInstance();
      _phoneController.text = prefs.getString('phone') ?? '';
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

    final isSmall = size.width < 360;
    final isTablet = size.width >= 600;

    return Consumer<UserController>(
      builder: (context, controller, _) {

        /// 🔐 Password field toggle (safe)
        if (controller.passwordRequired && !_showPasswordField) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              setState(() => _showPasswordField = true);
            }
          });
        }

        /// 🔔 Error toast (no repeat)
        if (controller.errorMessage != null &&
            controller.errorMessage != _lastError) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            AppToast.show(context, controller.errorMessage!);
            _lastError = controller.errorMessage;
            controller.errorMessage = null;
          });
        }

        return Scaffold(
          resizeToAvoidBottomInset: true,
          body: Stack(
            children: [

              /// 🌄 Background
              Positioned.fill(
                child: Image.asset(
                  "assets/images/maid2.jpg",
                  fit: BoxFit.cover,
                ),
              ),

              /// 🌫 Blur overlay
              Positioned.fill(
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
                  child: Container(
                    color: Colors.black.withOpacity(0.45),
                  ),
                ),
              ),

              /// 📦 Content
              SafeArea(
                child: Center(
                  child: SingleChildScrollView(
                    keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                    padding: EdgeInsets.symmetric(
                      horizontal: size.width * 0.08,
                      vertical: size.height * 0.04,
                    ),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        maxWidth: isTablet ? 420 : double.infinity,
                      ),
                      child: FadeTransition(
                        opacity: _fadeAnimation,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [

                            /// Title
                            Text(
                              "Welcome Back 👋",
                              style: TextStyle(
                                fontSize: isSmall ? 26 : 32,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),

                            const SizedBox(height: 6),

                            Text(
                              "Login to continue your maid services",
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.85),
                                fontSize: isSmall ? 13 : 15,
                              ),
                            ),

                            SizedBox(height: size.height * 0.035),

                            /// Form
                            Form(
                              key: _formKey,
                              child: Column(
                                children: [
                                  _buildInput(
                                    controller: _phoneController,
                                    label: "Phone Number",
                                    icon: Icons.phone,
                                    keyboard: TextInputType.phone,
                                    validator: (v) {
                                      if (v == null || v.isEmpty) {
                                        AppToast.show(context, "Enter phone number");
                                        return '';
                                      }
                                      if (!RegExp(r'^\d{10}$').hasMatch(v)) {
                                        AppToast.show(
                                            context, "Enter valid 10-digit number");
                                        return '';
                                      }
                                      return null;
                                    },
                                  ),

                                  if (_showPasswordField) ...[
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

                            /// Button
                            controller.isLoading
                                ? const CircularProgressIndicator(
                              color: Colors.blueAccent,
                            )
                                : SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.blueAccent,
                                  padding: EdgeInsets.symmetric(
                                    vertical: isSmall ? 14 : 16,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius:
                                    BorderRadius.circular(18),
                                  ),
                                ),
                                onPressed: () {
                                  if (_formKey.currentState!.validate()) {
                                    if (_showPasswordField) {
                                      controller.loginWithPassword(
                                        _phoneController.text.trim(),
                                        _passwordController.text.trim(),
                                        context,
                                      );
                                    } else {
                                      controller.loginWithPhone(
                                        _phoneController.text.trim(),
                                        context,
                                      );
                                    }
                                  }
                                },
                                child: Text(
                                  _showPasswordField
                                      ? "Login with Password"
                                      : "Send OTP",
                                  style: TextStyle(
                                    fontSize: isSmall ? 16 : 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),

                            if (_showPasswordField)
                              TextButton(
                                onPressed: () {
                                  _passwordController.clear();
                                  setState(() => _showPasswordField = false);
                                  controller.sendOtpForPasswordUser(
                                    _phoneController.text.trim(),
                                    context,
                                  );
                                },
                                child: const Text(
                                  "Login with OTP instead",
                                  style: TextStyle(color: Colors.white),
                                ),
                              ),
                          ],
                        ),
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

  /// 🔹 Input Field
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
        prefixIcon: Icon(icon, color: Colors.white),
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white),
        filled: true,
        fillColor: Colors.white.withOpacity(0.15),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}
