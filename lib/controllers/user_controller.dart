import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import '../main_screen.dart';
import '../models/user.dart';
import '../services/api_services.dart';
import '../views/auth/login_screen.dart';
import '../views/auth/otp_screen.dart';

class UserController extends ChangeNotifier {
  AppUser? _user;
  bool _isLoggedIn = false;
  bool _isLoading = false;
  String? _errorMessage;
  String? _hashOtp;
  final ApiServices _apiServices = ApiServices();

  AppUser? get user => _user;
  bool get isLoggedIn => _isLoggedIn;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // Setter for errorMessage
  set errorMessage(String? value) {
    _errorMessage = value;
    notifyListeners();
  }

  Future<void> loginWithPhone(String phone, BuildContext context) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final result = await _apiServices.loginWithOtp(phone);
      print("✅ loginWithOtp result: $result");

      _hashOtp = result['hashotp'];

      if (result['user'] != null) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('userId', result['user']['_id'] ?? '');
        await prefs.setString('phone', result['user']['phone'] ?? '');
        await prefs.setString('hashOtp', _hashOtp ?? '');

        print("💾 User ID saved: ${prefs.getString('userId')}");
        print("💾 Phone saved: ${prefs.getString('phone')}");
        print("💾 Hashed OTP saved: ${prefs.getString('hashOtp')}");
      }

      _isLoading = false;
      notifyListeners();

      print("📌 OTP for testing: ${result['plainOtp']}");

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

      if (userJson['success'] == true) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('isLoggedIn', true);
        final userId = prefs.getString('userId') ?? '';

        if (userId.isNotEmpty) {
          // Fetch user details before navigating
          await fetchUserDetails(userId);
          _isLoggedIn = true;
          _isLoading = false;
          notifyListeners();

          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const MainScreen()),
          );
        } else {
          throw Exception("User ID not found in SharedPreferences");
        }
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

  Future<void> fetchUserDetails(String userId) async {
    try {
      final response = await http.post(
        Uri.parse('${ApiServices.baseUrl}/auth-user'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'id': userId,
        }),
      );

      print('📩 Fetching user details for userId: $userId');
      print('📩 Status: ${response.statusCode}');
      print('📩 Body: ${response.body}');

      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body);
        if (jsonData['success'] == true && jsonData['existingUser'] != null) {
          _user = AppUser.fromJson(jsonData['existingUser']);
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('username', _user!.username ?? '');
          await prefs.setString('email', _user!.email ?? '');
          await prefs.setString('phone', _user!.phone);
          await prefs.setString('address', _user!.address ?? '');
          await prefs.setString('state', _user!.state ?? '');
          await prefs.setString('pincode', _user!.pincode ?? '');
          await prefs.setString('statename', _user!.statename ?? '');
          await prefs.setString('country', _user!.country ?? '');
          await prefs.setString('city', _user!.city ?? '');
          await prefs.setString('about', _user!.about ?? '');
          await prefs.setString('gender', _user!.gender ?? '1');
          await prefs.setString('dob', _user!.dob ?? '');
          print("💾 User details updated in SharedPreferences:");
          print("Username: ${prefs.getString('username')}");
          print("Email: ${prefs.getString('email')}");
          print("Phone: ${prefs.getString('phone')}");
          print("Address: ${prefs.getString('address')}");
          print("State: ${prefs.getString('state')}");
          print("Pincode: ${prefs.getString('pincode')}");
          print("Statename: ${prefs.getString('statename')}");
          print("Country: ${prefs.getString('country')}");
          print("City: ${prefs.getString('city')}");
          print("About: ${prefs.getString('about')}");
          print("Gender: ${prefs.getString('gender')}");
          print("DOB: ${prefs.getString('dob')}");
          notifyListeners();
        } else {
          throw Exception(jsonData['message'] ?? 'Failed to fetch user details');
        }
      } else {
        throw Exception(
            'Failed to fetch user details (Status code: ${response.statusCode})');
      }
    } catch (e) {
      print('❌ Error fetching user details: $e');
      throw Exception('Error fetching user details: $e');
    }
  }

  Future<bool> updateUserDetails({
    required String userId,
    required String username,
    required String phone,
    required String email,
    required String pincode,
    required String address,
    required String state,
    String type = '',
    String password = '',
    String confirmPassword = '',
    String gender = '1',
    String dob = '',
    String statename = '',
    String country = '',
    String city = '',
    String about = '',
    String setEmail = '',
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final url = Uri.parse('${ApiServices.baseUrl}/admin/update-user-details/$userId');
      print('📍 Update API URL: $url');

      final Map<String, dynamic> payload = {
        'type': type,
        'username': username.trim(),
        'phone': phone,
        'email': email,
        'pincode': pincode,
        'Gender': gender,
        'DOB': dob,
        'address': address.trim(),
        'state': state,
        'statename': statename,
        'country': country,
        'city': city,
        'about': about,
        'SetEmail': setEmail.isEmpty ? email : setEmail,
        'promoCode': [],
        'password': password,
        'confirm_password': confirmPassword,
      };

      print('📩 Payload: ${jsonEncode(payload)}');

      final headers = {
        'Content-Type': 'application/json',
      };

      final response = await http.put(
        url,
        headers: headers,
        body: jsonEncode(payload),
      ).timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          throw Exception('Request timed out. Please check your network connection.');
        },
      );

      print('📩 Status: ${response.statusCode}');
      print('📩 Body: ${response.body}');

      if (response.statusCode == 200) {
        try {
          final jsonData = jsonDecode(response.body);
          print('📩 Parsed JSON: $jsonData');

          if (jsonData['success'] == true) {
            _user = AppUser(
              id: userId,
              username: username,
              phone: phone,
              email: email,
              address: address,
              state: state,
              pincode: pincode,
              gender: gender,
              dob: dob,
              statename: statename,
              country: country,
              city: city,
              about: about,
            );

            // Save to SharedPreferences
            try {
              final prefs = await SharedPreferences.getInstance();
              await prefs.setString('username', username);
              await prefs.setString('email', email);
              await prefs.setString('phone', phone);
              await prefs.setString('address', address);
              await prefs.setString('state', state);
              await prefs.setString('pincode', pincode);
              await prefs.setString('statename', statename);
              await prefs.setString('country', country);
              await prefs.setString('city', city);
              await prefs.setString('about', about);
              await prefs.setString('gender', gender);
              await prefs.setString('dob', dob);
              print("💾 User details updated in SharedPreferences ✅");
            } catch (e) {
              print('❌ Error saving to SharedPreferences: $e');
              throw Exception('Failed to save user details locally: $e');
            }

            _isLoading = false;
            notifyListeners();
            return true;
          } else {
            throw Exception(jsonData['message'] ?? 'Failed to update user details');
          }
        } catch (e) {
          throw Exception('Invalid response format: $e');
        }
      } else {
        String errorMessage;
        try {
          final jsonData = jsonDecode(response.body);
          errorMessage = jsonData['message'] ?? 'Failed to update user details (Status code: ${response.statusCode})';
        } catch (e) {
          errorMessage = response.statusCode == 404
              ? 'API endpoint not found. Please check the server configuration.'
              : 'Server error (Status code: ${response.statusCode})';
        }
        throw Exception(errorMessage);
      }
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
      print('❌ Error updating user details: $_errorMessage');
      return false;
    }
  }

  Future<void> checkLoginStatus(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    final isLoggedIn = prefs.getBool('isLoggedIn') ?? false;

    if (isLoggedIn) {
      final userId = prefs.getString('userId') ?? '';
      if (userId.isNotEmpty) {
        await fetchUserDetails(userId);
        _isLoggedIn = true;
        notifyListeners();
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const MainScreen()),
        );
      } else {
        await logout();
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const LoginScreen()),
        );
      }
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
      );
    }
  }

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

  Future<void> deleteAccount(BuildContext context) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('userId') ?? '';

      if (userId.isEmpty) {
        throw Exception('User ID not found');
      }

      final response = await _apiServices.deleteAccount(userId);
      print("✅ deleteAccount response: $response");

      if (response['success'] == true) {
        _isLoading = false;
        notifyListeners();
      } else {
        throw Exception(response['message'] ?? 'Failed to delete account');
      }
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
      print('❌ deleteAccount error: $e');
      throw Exception(_errorMessage);
    }
  }
}