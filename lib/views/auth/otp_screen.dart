import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../controllers/user_controller.dart';

class OtpScreen extends StatefulWidget {
  final String phone;
  const OtpScreen({super.key, required this.phone});

  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen>
    with SingleTickerProviderStateMixin {
  final _otpController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

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
  }

  @override
  void dispose() {
    _otpController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final padding = size.width * 0.06;

    return Consumer<UserController>(
      builder: (context, controller, _) {
        return Scaffold(
          body: Container(
            width: double.infinity,
            height: double.infinity,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xff004e92), Color(0xff000428)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: SafeArea(
              child: Center(
                child: SingleChildScrollView(
                  padding: EdgeInsets.symmetric(horizontal: padding, vertical: size.height * 0.05),
                  child: FadeTransition(
                    opacity: _fadeAnimation,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          "Verify OTP",
                          style: TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                              color: Colors.white),
                        ),
                        SizedBox(height: size.height * 0.01),
                        Text(
                          "Enter the OTP sent to ${widget.phone}",
                          style: TextStyle(
                              fontSize: 16,
                              color: Colors.white.withOpacity(0.8)),
                          textAlign: TextAlign.center,
                        ),
                        SizedBox(height: size.height * 0.04),
                        Form(
                          key: _formKey,
                          child: TextFormField(
                            controller: _otpController,
                            keyboardType: TextInputType.number,
                            style: const TextStyle(color: Colors.white),
                            decoration: InputDecoration(
                              prefixIcon: Icon(Icons.lock,
                                  color: Colors.white.withOpacity(0.8)),
                              labelText: "OTP",
                              labelStyle:
                              TextStyle(color: Colors.white.withOpacity(0.8)),
                              filled: true,
                              fillColor: Colors.white.withOpacity(0.1),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide.none,
                              ),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter the OTP';
                              }
                              if (!RegExp(r'^\d{4}$').hasMatch(value)) {
                                return 'Please enter a valid 4-digit OTP';
                              }
                              return null;
                            },
                          ),
                        ),
                        SizedBox(height: size.height * 0.03),
                        controller.isLoading
                            ? const CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.orangeAccent),
                        )
                            : ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.orangeAccent,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                            padding: EdgeInsets.symmetric(
                                horizontal: size.width * 0.1,
                                vertical: size.height * 0.015),
                          ),
                          onPressed: () {
                            if (_formKey.currentState!.validate()) {
                              controller.verifyOtp(
                                  _otpController.text.trim(), context);
                            }
                          },
                          child: const Text(
                            "Verify OTP",
                            style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.white),
                          ),
                        ),
                        if (controller.errorMessage != null) ...[
                          SizedBox(height: size.height * 0.015),
                          Text(
                            controller.errorMessage!,
                            style: const TextStyle(color: Colors.redAccent),
                          )
                        ],
                        SizedBox(height: size.height * 0.02),
                        TextButton(
                          onPressed: () {
                            controller.loginWithPhone(widget.phone, context);
                          },
                          child: Text(
                            "Resend OTP",
                            style: TextStyle(
                                color: Colors.white.withOpacity(0.8),
                                fontSize: 14),
                          ),
                        )
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
