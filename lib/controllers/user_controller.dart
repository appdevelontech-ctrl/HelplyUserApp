import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:user_app/views/auth/login_screen.dart';
import '../main_screen.dart';
import '../models/user.dart';
import '../services/api_services.dart';
import '../views/auth/otp_screen.dart';

class UserController extends ChangeNotifier {
  AppUser? _user;
  bool _isLoggedIn = false;
  bool _isLoading = false;
  String? _errorMessage;
  String? _hashOtp; // hashed OTP from server
  final ApiServices _apiServices = ApiServices();

  AppUser? get user => _user;
  bool get isLoggedIn => _isLoggedIn;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;



  Future<void> loginWithPhone(String phone, BuildContext context) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final result = await _apiServices.loginWithOtp(phone);
      print("✅ loginWithOtp result: $result");

      // Save hashed OTP internally
      _hashOtp = result['hashotp'];

      // Save existingUser details in SharedPreferences
      if (result['user'] != null) {
        final prefs = await SharedPreferences.getInstance();
        final existingUser = result['user']; // from existingUser key

        await prefs.setString('userId', existingUser['_id'] ?? '');
        await prefs.setString('phone', existingUser['phone'] ?? '');
        await prefs.setString('name', existingUser['username'] ?? '');
        await prefs.setString('email', existingUser['email'] ?? '');
        await prefs.setString('hashOtp', _hashOtp ?? '');

        // ✅ Print to console to verify
        print("💾 User details saved in SharedPreferences:");
        print("User ID: ${prefs.getString('userId')}");
        print("Phone: ${prefs.getString('phone')}");
        print("Name: ${prefs.getString('name')}");
        print("Email: ${prefs.getString('email')}");
        print("Hashed OTP: ${prefs.getString('hashOtp')}");
      }

      _isLoading = false;
      notifyListeners();

      // Print plain OTP in console for testing
      print("📌 OTP for testing: ${result['plainOtp']}");

      // Navigate to OTP screen
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => OtpScreen(phone: phone)),
      );
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
      print('❌ loginWithPhone error: $e');
    }
  }



  Future<void> verifyOtp(String otp, BuildContext context) async {
    if (_hashOtp == null) {
      final prefs = await SharedPreferences.getInstance();
      _hashOtp = prefs.getString('hashOtp');
    }

    if (_hashOtp == null) {
      _errorMessage = "OTP not generated. Please resend OTP.";
      notifyListeners();
      return;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final userJson = await _apiServices.verifyOtp(otp, _hashOtp!);
      print("✅ verifyOtp response: $userJson");

      // Success without user details
      if (userJson['success'] == true) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('isLoggedIn', true);

        // Only save user info if available
        if (userJson['user'] != null) {
          final existingUser = userJson['user'];
          _user = AppUser(
            id: existingUser['_id'] ?? '',
            phone: existingUser['phone'] ?? '',
            name: existingUser['username'] ?? '',
            email: existingUser['email'] ?? '',
          );
          await prefs.setString('userId', _user!.id);
          await prefs.setString('phone', _user!.phone);
          await prefs.setString('name', _user!.name ?? '');
          await prefs.setString('email', _user!.email ?? '');
        }

        _isLoggedIn = true;
        _isLoading = false;
        notifyListeners();

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const MainScreen()),
        );
      } else {
        throw Exception(userJson['message'] ?? "Invalid OTP");
      }
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
      print("❌ verifyOtp error: $e");
    }
  }

  // Check login status
  Future<void> checkLoginStatus(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    final isLoggedIn = prefs.getBool('isLoggedIn') ?? false;

    if (isLoggedIn) {
      final userId = prefs.getString('userId') ?? '';
      final phone = prefs.getString('phone') ?? '';
      final name = prefs.getString('name') ?? '';
      final email = prefs.getString('email') ?? '';

      _user = AppUser(id: userId, phone: phone, name: name, email: email);
      _isLoggedIn = true;
      notifyListeners();

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const MainScreen()),
      );
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
      );
    }
  }

  // Logout
  Future<void> logout() async {
    print("🚪 Logging out user...");
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    print("💾 SharedPreferences cleared.");

    _user = null;
    _isLoggedIn = false;
    _hashOtp = null;
    notifyListeners();
  }
}
