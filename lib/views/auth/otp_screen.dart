import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pin_code_fields/pin_code_fields.dart';
import '../../controllers/user_controller.dart';

class OtpScreen extends StatefulWidget {
  final String phone;
  const OtpScreen({super.key, required this.phone});

  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen> {
  final _formKey = GlobalKey<FormState>();
  String _otp = "";

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Consumer<UserController>(
      builder: (context, controller, _) {
        return Scaffold(
          body: Stack(
            children: [
              // Background Image
              Positioned.fill(
                child: Image.asset(
                  "assets/images/maid3.jpg",
                  fit: BoxFit.cover,
                ),
              ),

              // Dark Transparent Overlay
              Container(
                color: Colors.black.withOpacity(0.45),
              ),

              // Main Content (Glassmorphism Panel)
              Center(
                child: SingleChildScrollView(
                  padding: EdgeInsets.symmetric(horizontal: size.width * 0.08),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.white.withOpacity(0.3)),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text(
                              "Verify OTP",
                              style: TextStyle(
                                fontSize: 36,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              "Enter the 4-digit OTP sent to\n${widget.phone}",
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.9),
                                fontSize: 16,
                              ),
                            ),

                            SizedBox(height: size.height * 0.03),

                            // OTP Field
                            Form(
                              key: _formKey,
                              child: PinCodeTextField(
                                length: 4,
                                appContext: context,
                                keyboardType: TextInputType.number,
                                autoFocus: true,
                                animationType: AnimationType.fade,
                                cursorColor: Colors.white,
                                textStyle: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                ),
                                pinTheme: PinTheme(
                                  shape: PinCodeFieldShape.box,
                                  borderRadius: BorderRadius.circular(12),
                                  fieldHeight: 55,
                                  fieldWidth: 48,
                                  activeFillColor: Colors.white.withOpacity(0.2),
                                  selectedFillColor: Colors.white.withOpacity(0.25),
                                  inactiveFillColor: Colors.white.withOpacity(0.12),
                                  activeColor: Colors.blueAccent,
                                  selectedColor: Colors.blueAccent,
                                  inactiveColor: Colors.white70,
                                ),
                                onChanged: (value) => _otp = value,
                                onCompleted: (value) {
                                  controller.errorMessage = null;
                                  controller.verifyOtp(value.trim(), context);
                                },
                              ),
                            ),

                            SizedBox(height: size.height * 0.03),

                            controller.isLoading
                                ? const CircularProgressIndicator(color: Colors.blueAccent)
                                : ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blueAccent,
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(15)),
                                padding: EdgeInsets.symmetric(
                                  horizontal: size.width * 0.22,
                                  vertical: size.height * 0.018,
                                ),
                              ),
                              onPressed: () {
                                if (_otp.length == 4) {
                                  controller.errorMessage = null;
                                  controller.verifyOtp(_otp.trim(), context);
                                }
                              },
                              child: const Text(
                                "Verify OTP",
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ),

                            if (controller.errorMessage != null)
                              Padding(
                                padding: const EdgeInsets.only(top: 12),
                                child: Text(
                                  controller.errorMessage!,
                                  style: const TextStyle(
                                      color: Colors.redAccent, fontSize: 14),
                                  textAlign: TextAlign.center,
                                ),
                              ),

                            const SizedBox(height: 10),
                            TextButton(
                              onPressed: () {
                                controller.sendOtpForPasswordUser(widget.phone, context);
                              },
                              child: const Text(
                                "Resend OTP",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  decoration: TextDecoration.underline,
                                ),
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
}
