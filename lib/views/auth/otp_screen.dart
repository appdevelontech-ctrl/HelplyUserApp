import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pin_code_fields/pin_code_fields.dart';
import '../../controllers/user_controller.dart';
import '../../services/app_toast.dart';

class OtpScreen extends StatefulWidget {
  final String phone;
  const OtpScreen({super.key, required this.phone});

  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen> {
  final _formKey = GlobalKey<FormState>();
  String _otp = "";
  String? _lastError;

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isSmall = size.width < 360;
    final isTablet = size.width > 600;

    return Consumer<UserController>(
      builder: (context, controller, _) {

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
                  "assets/images/maid3.jpg",
                  fit: BoxFit.cover,
                ),
              ),

              /// 🌫 Dark overlay
              Container(color: Colors.black.withOpacity(0.45)),

              /// 📦 Content
              SafeArea(
                child: Center(
                  child: SingleChildScrollView(
                    keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                    padding: EdgeInsets.symmetric(
                      horizontal: size.width * 0.07,
                      vertical: size.height * 0.04,
                    ),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        maxWidth: isTablet ? 420 : double.infinity,
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(22),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                          child: Container(
                            padding: EdgeInsets.all(isSmall ? 18 : 22),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(22),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.3),
                              ),
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [

                                /// Title
                                Text(
                                  "Verify OTP",
                                  style: TextStyle(
                                    fontSize: isSmall ? 26 : 32,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),

                                const SizedBox(height: 8),

                                /// Subtitle
                                Text(
                                  "Enter the 4-digit OTP sent to\n${widget.phone}",
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.9),
                                    fontSize: isSmall ? 14 : 16,
                                  ),
                                ),

                                SizedBox(height: size.height * 0.03),

                                /// OTP Field
                                Form(
                                  key: _formKey,
                                  child: PinCodeTextField(
                                    length: 4,
                                    appContext: context,
                                    keyboardType: TextInputType.number,
                                    autoFocus: true,
                                    animationType: AnimationType.fade,
                                    cursorColor: Colors.white,
                                    textStyle: TextStyle(
                                      color: Colors.white,
                                      fontSize: isSmall ? 20 : 22,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    pinTheme: PinTheme(
                                      shape: PinCodeFieldShape.box,
                                      borderRadius: BorderRadius.circular(12),
                                      fieldHeight: isSmall ? 48 : 55,
                                      fieldWidth: isSmall ? 42 : 50,
                                      activeFillColor:
                                      Colors.white.withOpacity(0.25),
                                      selectedFillColor:
                                      Colors.white.withOpacity(0.3),
                                      inactiveFillColor:
                                      Colors.white.withOpacity(0.15),
                                      activeColor: Colors.blueAccent,
                                      selectedColor: Colors.blueAccent,
                                      inactiveColor: Colors.white70,
                                    ),
                                    enableActiveFill: true,
                                    onChanged: (value) => _otp = value,
                                    onCompleted: (value) {
                                      controller.verifyOtp(
                                          value.trim(), context);
                                    },
                                  ),
                                ),

                                SizedBox(height: size.height * 0.03),

                                /// Button / Loader
                                controller.isLoading
                                    ? const CircularProgressIndicator(
                                  color: Colors.blueAccent,
                                )
                                    : SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor:
                                      Colors.blueAccent,
                                      padding: EdgeInsets.symmetric(
                                        vertical:
                                        size.height * 0.018,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius:
                                        BorderRadius.circular(16),
                                      ),
                                    ),
                                    onPressed: () {
                                      if (_otp.length != 4) {
                                        AppToast.show(
                                            context, "Enter valid OTP");
                                        return;
                                      }
                                      controller.verifyOtp(
                                          _otp.trim(), context);
                                    },
                                    child: Text(
                                      "Verify OTP",
                                      style: TextStyle(
                                        fontSize:
                                        isSmall ? 16 : 18,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ),

                                const SizedBox(height: 12),

                                /// Resend
                                TextButton(
                                  onPressed: () {
                                    controller.sendOtpForPasswordUser(
                                        widget.phone, context);
                                  },
                                  child: const Text(
                                    "Resend OTP",
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 15,
                                      decoration:
                                      TextDecoration.underline,
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
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
