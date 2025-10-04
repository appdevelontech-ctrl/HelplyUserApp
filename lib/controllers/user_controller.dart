import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import '../main_screen.dart';
import 'package:image_picker/image_picker.dart';
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
  bool _isNewUser = false; // New flag to track if user is new
  String? _phone; // Store phone number for signup
  String? _gToken; // Store Gtoken for signup
  bool _passwordRequired = false;
  final ApiServices _apiServices = ApiServices();

  AppUser? get user => _user;
  bool get isLoggedIn => _isLoggedIn;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get passwordRequired => _passwordRequired;

  set errorMessage(String? value) {
    _errorMessage = value;
    notifyListeners();
  }
  Future<void> loginWithPhone(String phone, BuildContext context) async {
    _isLoading = true;
    _errorMessage = null;
    _passwordRequired = false;
    _isNewUser = false;
    _hashOtp = null;
    notifyListeners();

    try {
      final result = await _apiServices.loginWithOtp(phone);
      print("✅ loginWithOtp result: $result");

      _phone = phone;
      _hashOtp = result['hashotp'];
      _isNewUser = result['newUser'] ?? false;
      _gToken = 'sddwdwdwdd';
      _passwordRequired = result['passwordRequired'] ?? false;

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('phone', phone);
      await prefs.setBool('isNewUser', _isNewUser);
      await prefs.setBool('passwordRequired', _passwordRequired);

      if (result['user'] != null) {
        await prefs.setString('userId', result['user']['_id'] ?? '');
        print("💾 User ID saved: ${prefs.getString('userId')}");
      }

      if (_hashOtp != null) {
        await prefs.setString('hashOtp', _hashOtp!);
        print("💾 Hashed OTP saved: ${prefs.getString('hashOtp')}");
        _isLoading = false;
        notifyListeners();

        print("📌 OTP for testing: ${result['plainOtp']}");
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => OtpScreen(phone: phone)),
        );
      } else if (_passwordRequired) {
        _isLoading = false;
        notifyListeners();
      } else {
        throw Exception('No OTP received. Please try again or contact support.');
      }
    } catch (e) {
      _isLoading = false;
      // Extract the clean API message
      String errorMsg = e.toString();
      // Remove all "Exception: " prefixes iteratively
      while (errorMsg.startsWith('Exception: ')) {
        errorMsg = errorMsg.replaceFirst('Exception: ', '');
      }
      _errorMessage = errorMsg; // Set the clean message
      // Clear SharedPreferences to prevent login with stale data
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
      _isLoggedIn = false;
      notifyListeners();
      print('❌ loginWithPhone error: $e');
    }
  }
  Future<void> sendOtpForPasswordUser(String phone, BuildContext context) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final result = await _apiServices.sendOtpForPasswordUser(phone);
      print("✅ sendOtpForPasswordUser result: $result");

      _phone = phone;
      _hashOtp = result['hashotp'];
      _gToken = result['token'] ?? 'sddwdwdwdd';

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('phone', phone);
      await prefs.setString('hashOtp', _hashOtp!);
      if (result['user'] != null) {
        await prefs.setString('userId', result['user']['_id'] ?? '');
        print("💾 User ID saved: ${prefs.getString('userId')}");
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
      print('❌ sendOtpForPasswordUser error: $e');
    }
  }
  Future<void> loginWithPassword(String phone, String password, BuildContext context) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final result = await _apiServices.loginWithPassword(phone, password);
      print("✅ loginWithPassword result: $result");

      if (result['success'] == true && result['user'] != null) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('userId', result['user']['_id'] ?? '');
        await prefs.setString('phone', phone);
        await prefs.setString('token', result['token'] ?? '');
        await prefs.setBool('isLoggedIn', true);

        await fetchUserDetails(result['user']['_id']);
        _isLoggedIn = true;
        _isLoading = false;
        notifyListeners();

        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const MainScreen()),
              (Route<dynamic> route) => false, // removes all previous routes
        );

      } else {
        throw Exception(result['message'] ?? 'Invalid credentials');
      }
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
      print('❌ loginWithPassword error: $e');
    }
  }
  Future<void> verifyOtp(String otp, BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    _hashOtp ??= prefs.getString('hashOtp');
    _isNewUser = prefs.getBool('isNewUser') ?? false;
    _phone ??= prefs.getString('phone');

    if (_hashOtp == null || _phone == null) {
      _isLoading = false;
      _errorMessage = 'OTP or phone number not found. Please resend OTP.';
      notifyListeners();
      return;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final verifyResult = await _apiServices.verifyOtp(otp, _hashOtp!);
      print("✅ verifyOtp response: $verifyResult");

      if (verifyResult['success'] == true) {
        final userId = prefs.getString('userId') ?? '';

        if (_isNewUser) {
          final signupResult = await _apiServices.signupNewUser(_phone!, _gToken!);
          print("✅ signupNewUser response: $signupResult");

          if (signupResult['success'] == true) {
            final newUserId = signupResult['userId'];
            final newPhone = signupResult['phone'];
            if (newUserId == null || newPhone == null) {
              throw Exception('User ID or phone number missing in signup response');
            }
            await prefs.setString('userId', newUserId);
            await prefs.setString('phone', newPhone);
            await prefs.setBool('isLoggedIn', true);

            await fetchUserDetails(newUserId);
            _isLoggedIn = true;
            _isLoading = false;
            notifyListeners();

            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (context) => const MainScreen()),
                  (Route<dynamic> route) => false, // removes all previous routes
            );

          } else {
            throw Exception(signupResult['message'] ?? 'Failed to sign up user');
          }
        } else {
          if (userId.isNotEmpty) {
            await fetchUserDetails(userId);
            await prefs.setBool('isLoggedIn', true);
            _isLoggedIn = true;
            _isLoading = false;
            notifyListeners();

            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const MainScreen()),
            );
          } else {
            throw Exception('User ID not found in SharedPreferences');
          }
        }
      } else {
        throw Exception(verifyResult['message'] ?? 'Invalid OTP');
      }
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
      print('❌ verifyOtp error: $e');
    }
  }
  Future<void> fetchUserDetails(String userId) async {
    try {
      final response = await _apiServices.getUser(userId);
      print('📩 Fetching user details for userId: $userId');
      print('📩 Body: ${response['body'] ?? 'No response body'}');

      if (response['success'] == true && response['user'] != null) {
        _user = AppUser.fromJson(response['user']);
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('username', _user!.username ?? '');
        await prefs.setString('email', _user!.email ?? '');
        await prefs.setString('phone', _user!.phone ?? '');
        await prefs.setString('address', _user!.address ?? '');
        await prefs.setString('state', _user!.state ?? '');
        await prefs.setString('pincode', _user!.pincode ?? '');
        await prefs.setString('statename', _user!.statename ?? '');
        await prefs.setString('country', _user!.country ?? '');
        await prefs.setString('city', _user!.city ?? '');
        await prefs.setString('about', _user!.about ?? '');
        await prefs.setString('gender', _user!.gender ?? '1');
        await prefs.setString('dob', _user!.dob ?? '');
        await prefs.setString('doc1', _user!.doc1 ?? '');
        await prefs.setString('doc2', _user!.doc2 ?? '');
        await prefs.setString('doc3', _user!.doc3 ?? '');
        await prefs.setString('pHealthHistory', _user!.pHealthHistory ?? '');
        await prefs.setString('cHealthStatus', _user!.cHealthStatus ?? '');
        await prefs.setStringList('department', _user!.department ?? []);
        await prefs.setStringList('coverage', _user!.coverage ?? []);
        await prefs.setInt('empType', _user!.empType ?? 0);
        await prefs.setInt('verified', _user!.verified ?? 0);
        await prefs.setInt('wallet', _user!.wallet ?? 0);
        await prefs.setInt('online', _user!.online ?? 0);
        notifyListeners();
      } else {
        throw Exception(response['message'] ?? 'Failed to fetch user details');
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
    int? empType,
    int? verified,
    List<String>? department,
    String? doc1,
    String? doc2,
    String? doc3,
    XFile? profileImage,
    String? pHealthHistory,
    String? cHealthStatus,
    List<String>? coverage,
    int? wallet,
    int? online,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final String? finalDoc1 = profileImage?.path ?? doc1 ?? _user?.doc1;

      final url = Uri.parse('${ApiServices.baseUrl}/admin/update-user-details/$userId');
      print('📍 Update API URL: $url');

      final Map<String, dynamic> payload = {
        'type': type.isNotEmpty ? int.tryParse(type) : _user?.type,
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
        'empType': empType ?? _user?.empType,
        'verified': verified ?? _user?.verified,
        'department': department ?? _user?.department,
        'Doc1': finalDoc1,
        'Doc2': doc2 ?? _user?.doc2,
        'Doc3': doc3 ?? _user?.doc3,
        'pHealthHistory': pHealthHistory ?? _user?.pHealthHistory,
        'cHealthStatus': cHealthStatus ?? _user?.cHealthStatus,
        'coverage': coverage ?? _user?.coverage,
        'wallet': wallet ?? _user?.wallet,
        'online': online ?? _user?.online,
      };

      print('📩 Payload: ${jsonEncode(payload)}');

      final headers = {
        'Content-Type': 'application/json',
      };
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token') ?? '';
      if (token.isNotEmpty) {
        headers['Authorization'] = 'Bearer $token';
      }

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
              type: int.tryParse(type) ?? _user?.type,
              empType: empType ?? _user?.empType,
              verified: verified ?? _user?.verified,
              department: department ?? _user?.department,
              doc1: finalDoc1,
              doc2: doc2 ?? _user?.doc2,
              doc3: doc3 ?? _user?.doc3,
              pHealthHistory: pHealthHistory ?? _user?.pHealthHistory,
              cHealthStatus: cHealthStatus ?? _user?.cHealthStatus,
              coverage: coverage ?? _user?.coverage,
              wallet: wallet ?? _user?.wallet,
              online: online ?? _user?.online,
            );

            // Save to SharedPreferences
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
            await prefs.setString('doc1', finalDoc1 ?? '');
            await prefs.setString('doc2', doc2 ?? _user?.doc2 ?? '');
            await prefs.setString('doc3', doc3 ?? _user?.doc3 ?? '');
            await prefs.setString('pHealthHistory', pHealthHistory ?? _user?.pHealthHistory ?? '');
            await prefs.setString('cHealthStatus', cHealthStatus ?? _user?.cHealthStatus ?? '');
            await prefs.setStringList('department', department ?? _user?.department ?? []);
            await prefs.setStringList('coverage', coverage ?? _user?.coverage ?? []);
            await prefs.setString('type', type);
            await prefs.setInt('empType', empType ?? _user?.empType ?? 0);
            await prefs.setInt('verified', verified ?? _user?.verified ?? 0);
            await prefs.setInt('wallet', wallet ?? _user?.wallet ?? 0);
            await prefs.setInt('online', online ?? _user?.online ?? 0);
            print("💾 User details updated in SharedPreferences ✅");

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
        try {
          await fetchUserDetails(userId);
          _isLoggedIn = true;
          notifyListeners();
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const MainScreen()),
          );
        } catch (e) {
          _errorMessage = 'Failed to load user details. Please log in again.';
          await logout();
          notifyListeners();
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const LoginScreen()),
          );
        }
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

    final currentUserId = prefs.getString('userId');

    // ✅ Get current user's maid_info
    final maidInfo = prefs.getString('maid_info_$currentUserId');

    // Clear everything else
    await prefs.clear();
    print("💾 SharedPreferences cleared.");

    // ✅ Restore only this user’s maid_info
    if (maidInfo != null && maidInfo.isNotEmpty && currentUserId != null) {
      await prefs.setString('maid_info_$currentUserId', maidInfo);
      print("💾 maid_info preserved for userId: $currentUserId ✅");
    }

    _user = null;
    _isLoggedIn = false;
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
        await logout();
        _isLoading = false;
        notifyListeners();
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const LoginScreen()),
        );
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