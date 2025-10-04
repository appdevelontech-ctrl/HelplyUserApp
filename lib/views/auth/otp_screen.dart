import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../controllers/user_controller.dart';
import 'package:pin_code_fields/pin_code_fields.dart'; // Add dependency in pubspec.yaml

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
              // Background gradient only, no image
              Container(
                width: double.infinity,
                height: double.infinity,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Color(0xff3f87c5), // top color
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
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          "Verify OTP",
                          style: TextStyle(
                            fontSize: 36,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        SizedBox(height: size.height * 0.02),
                        Text(
                          "Enter the 4-digit OTP sent to ${widget.phone}",
                          style: TextStyle(color: Colors.white.withOpacity(0.85), fontSize: 16),
                          textAlign: TextAlign.center,
                        ),
                        SizedBox(height: size.height * 0.03),
                        Form(
                          key: _formKey,
                          child: PinCodeTextField(
                            length: 4, // changed to 4 digits
                            appContext: context,
                            keyboardType: TextInputType.number,
                            autoFocus: true,
                            animationType: AnimationType.fade,
                            cursorColor: Colors.white,
                            textStyle: const TextStyle(color: Colors.white, fontSize: 20),
                            pinTheme: PinTheme(
                              shape: PinCodeFieldShape.box,
                              borderRadius: BorderRadius.circular(10),
                              fieldHeight: 55,
                              fieldWidth: 45,
                              activeFillColor: Colors.orangeAccent.withOpacity(0.2),
                              selectedFillColor: Colors.orangeAccent.withOpacity(0.3),
                              inactiveFillColor: Colors.white.withOpacity(0.1),
                              activeColor: Colors.orangeAccent,
                              selectedColor: Colors.orangeAccent,
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
                            ? const CircularProgressIndicator(color: Colors.orangeAccent)
                            : ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.orangeAccent,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                            padding: EdgeInsets.symmetric(
                              horizontal: size.width * 0.2,
                              vertical: size.height * 0.02,
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
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
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
            ],
          ),
        );
      },
    );
  }
}
