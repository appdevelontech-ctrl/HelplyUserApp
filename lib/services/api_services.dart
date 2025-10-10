import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/location.dart';
import '../models/order_model.dart';
import '../models/serviceCategoryDetail.dart';
import '../models/service_category.dart';


  


class ApiServices {
  static final String baseUrl = 'https://backend-olxs.onrender.com';

  Future<LocationResponse> fetchLocations() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/get-all-zones-only'));
      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body);
        return LocationResponse.fromJson(jsonData);
      } else {
        throw Exception(
            'Failed to load locations (Status code: ${response.statusCode})');
      }
    } catch (e) {
      throw Exception('Error fetching locations: $e');
    }
  }

  Future<List<ServiceCategory>> fetchCategoriesByLocation(
      String location) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/get-catgeory-product?location=$location'),
      );

      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body);
        if (jsonData['success'] == true &&
            jsonData['categoriesWithProducts'] != null) {
          return (jsonData['categoriesWithProducts'] as List<dynamic>)
              .map((e) => ServiceCategory.fromJson(e))
              .toList();
        } else {
          return [];
        }
      } else {
        throw Exception(
            'Failed to load categories (Status code: ${response.statusCode})');
      }
    } catch (e) {
      throw Exception('Error fetching categories: $e');
    }
  }

  Future<CategoryDetailResponse> fetchCategoryDetails(
      String slug, String location) async {
    try {
      final response = await http.get(
        Uri.parse(
            '$baseUrl/all/category-slug/$slug?filter=&price&page=1&perPage=100&location=$location'),
      );
      print('Response is : ${response.body}');

      if (response.statusCode == 200) {
        return CategoryDetailResponse.fromJson(jsonDecode(response.body));
      } else {
        throw Exception(
            'Failed to load category details: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching category details: $e');
    }
  }

  Future<ProductDetail> fetchProductDetails(String slug) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/user-product-slug/$slug'),
      );
      print("Response is : ${response.body}");

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        if (json['success'] == true) {
          return ProductDetail.fromJson(json['Product']);
        } else {
          throw Exception('Failed to load product details: ${json['message']}');
        }
      } else {
        throw Exception(
            'Failed to load product details: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching product details: $e');
    }
  }

  Future<List<Order>> fetchUserOrders() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('userId');

      print('📩 Fetching orders for userId: $userId');
      if (userId == null) {
        print('❌ Error: User ID not found in SharedPreferences');
        throw Exception('User ID not found in SharedPreferences');
      }

      final url = Uri.parse('$baseUrl/user-orders/$userId');
      print('📡 API Request URL: $url');

      final response = await http.get(url);

      print('📋 Response Status Code: ${response.statusCode}');
      print('📄 Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print('✅ Parsed JSON Data: $data');

        final userOrderResponse = UserOrderResponse.fromJson(data);
        print(
            '📦 Orders Fetched: ${userOrderResponse.userOrder.orders.length} orders');

        return userOrderResponse.userOrder.orders.reversed.toList();
      } else {
        print('❌ Failed to fetch orders (Status code: ${response.statusCode})');
        throw Exception(
            'Failed to fetch orders (Status code: ${response.statusCode})');
      }
    } catch (e) {
      print('❌ Error fetching orders: $e');
      throw Exception('Error fetching orders: $e');
    }
  }

  Future<Order> fetchOrderDetails(String userId, String orderId) async {
    try {
      print('📩 Fetching order details for userId: $userId, orderId: $orderId');

      final url = Uri.parse('$baseUrl/user-orders-view/$userId/$orderId');
      print('📡 API Request URL: $url');

      final response = await http.get(url);

      print('📋 Response Status Code: ${response.statusCode}');
      print('📄 Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print('✅ Parsed JSON Data: $data');

        if (data['success'] == true && data['userOrder'] != null) {
          final userOrderResponse = UserOrderResponse.fromJson(data);
          print('📦 Order Details Fetched: Order _id $orderId');
          Order? order = userOrderResponse.userOrder.order;
          if (order == null) {
// Fallback: Parse order directly from userOrder JSON (backend returns order fields directly)
            final userOrderJson = data['userOrder'] as Map<String, dynamic>;
            order = Order.fromJson(userOrderJson);
          }
          if (order.id.isEmpty) {
            throw Exception(
                'Failed to fetch order details: Invalid order data in response');
          }
          return order;
        } else {
          throw Exception(
              'Failed to fetch order details: ${data['message'] ?? 'Unknown error'}');
        }
      } else {
        print(
            '❌ Failed to fetch order details (Status code: ${response.statusCode})');
        throw Exception(
            'Failed to fetch order details (Status code: ${response.statusCode})');
      }
    } catch (e) {
      print('❌ Error fetching order details: $e');
      throw Exception('Error fetching order details: $e');
    }
  }

  Future<Map<String, dynamic>> createOrder(
      String userId, Map<String, dynamic> orderData) async {
    try {
      final url = Uri.parse('$baseUrl/create-order/$userId');
      print('📩 Creating order for userId: $userId');
      print('📩 Payload: $orderData');

      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(orderData),
      );

      print('📋 Response Status Code: ${response.statusCode}');
      print('📄 Response Body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final jsonData = jsonDecode(response.body);
        if (jsonData['success'] == true) {
          return {
            'success': true,
            'message': jsonData['message'] ?? 'Order created successfully',
            'order':
                jsonData['newOrder'], // Fixed: Use 'newOrder' from response
          };
        } else {
          throw Exception(jsonData['message'] ?? 'Failed to create order');
        }
      } else {
        throw Exception(
            'Failed to create order (Status code: ${response.statusCode})');
      }
    } catch (e) {
      print('❌ Error creating order: $e');
      throw Exception('Error creating order: $e');
    }
  }

  Future<Map<String, dynamic>> createPaymentOrder(
      Map<String, dynamic> payload) async {
    final url = Uri.parse('$baseUrl/order-payment');
    final response = await http.post(url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(payload));

    print('Order Payment Response: ${response.body}');

    if (response.statusCode == 200 || response.statusCode == 201) {
      final jsonData = jsonDecode(response.body);
      return jsonData;
    } else {
      return {
        'success': false,
        'message':
            'Failed to create payment order (Status code: ${response.statusCode})'
      };
    }
  }

  Future<Map<String, dynamic>> verifyPayment({
    required String razorpayOrderId,
    required String razorpayPaymentId,
    required String razorpaySignature,
  }) async {
    final url = Uri.parse('$baseUrl/order-payment-verification');
    final payload = {
      'razorpay_order_id': razorpayOrderId,
      'razorpay_payment_id': razorpayPaymentId,
      'razorpay_signature': razorpaySignature,
    };

    final response = await http.post(url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(payload));

    print("Verify Response Status: ${response.statusCode}");
    print("Verify Response Body: ${response.body}");

    if (response.statusCode == 200) {
      final jsonData = jsonDecode(response.body);
      if (jsonData['success'] == true) {
        return {
          'success': true,
          'message': jsonData['message'] ?? 'Payment verified successfully'
        };
      } else {
        return {
          'success': false,
          'message': jsonData['message'] ?? 'Verification failed'
        };
      }
    } else {
      return {
        'success': false,
        'message':
            'Failed to verify payment (Status code: ${response.statusCode})'
      };
    }
  }

  Future<Map<String, dynamic>> fetchPrivacyPolicy() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/admin/get-page/689c77097fa4afbd4d286457'),
      );

      print('📩 Fetching Privacy Policy');
      print('📩 Status: ${response.statusCode}');
      print('📩 Body: ${response.body}');

      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body);
        if (jsonData['success'] == true && jsonData['Mpage'] != null) {
          return {
            'success': true,
            'title': jsonData['Mpage']['title'],
            'description': jsonData['Mpage']['description'],
          };
        } else {
          throw Exception(
              'Failed to load privacy policy: ${jsonData['message'] ?? 'Unknown error'}');
        }
      } else {
        throw Exception(
            'Failed to load privacy policy (Status code: ${response.statusCode})');
      }
    } catch (e) {
      print('❌ Error fetching privacy policy: $e');
      throw Exception('Error fetching privacy policy: $e');
    }
  }

  Future<Map<String, dynamic>> deleteAccount(String userId) async {
    final response = await http.put(
      Uri.parse('$baseUrl/admin/update-user/$userId'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'status': '0'}),
    );

    print('📩 Deleting Account');
    print('📩 Status: ${response.statusCode}');
    print('📩 Body: ${response.body}');

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception(
          'Failed to delete account (Status code: ${response.statusCode})');
    }
  }

  Future<Map<String, dynamic>> getUser(String userId, {String? token}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final storedToken = token ?? prefs.getString('token') ?? '';

      final headers = {
        'Content-Type': 'application/json',
      };
      if (storedToken.isNotEmpty) {
        headers['Authorization'] = 'Bearer $storedToken';
      }

      final response = await http.post(
        Uri.parse('$baseUrl/auth-user'),
        headers: headers,
        body: jsonEncode({'id': userId}),
      );

      print('📩 getUser request for userId: $userId');
      print('📩 Status: ${response.statusCode}');
      print('📩 Body: ${response.body}');

      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body);
        if (jsonData['success'] == true && jsonData['existingUser'] != null) {
          return {
            'success': true,
            'user': jsonData['existingUser'],
            'message':
                jsonData['message'] ?? 'User details fetched successfully',
          };
        } else {
          throw Exception(
              jsonData['message'] ?? 'Failed to fetch user details');
        }
      } else {
        throw Exception(
            'Failed to fetch user details (Status code: ${response.statusCode})');
      }
    } catch (e) {
      print('❌ getUser error: $e');
      throw Exception('Error fetching user details: $e');
    }
  }

  Future<Map<String, dynamic>> loginWithOtp(String phone,
      {bool retry = false}) async {
    try {
      final url = '$baseUrl/signup-login-otp/';
      final response = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'phone': phone,
          'Gtoken': 'sddwdwdwdd',
          'password': '',
        }),
      );

      print('📩 signup-login-otp request with $phone');
      print('📩 Status: ${response.statusCode}');
      print('📩 Body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final jsonData = jsonDecode(response.body);

        if (jsonData['success'] == true) {
          print('✅ loginWithOtp result: $jsonData');
          print('💡 Plain OTP (newotp): ${jsonData['newotp']}');

          return {
            'success': true,
            'hashotp': jsonData['otp'],
            'plainOtp': jsonData['newotp'],
            'message': jsonData['message'],
            'newUser': jsonData['newUser'] ?? false,
            'user': jsonData['existingUser'],
            'passwordRequired': jsonData['password'] ?? false,
            'token': jsonData['token'],
          };
        } else {
          throw Exception(jsonData['message'] ?? 'Failed to send OTP');
        }
      } else {
        final jsonData = jsonDecode(response.body);
        throw Exception(jsonData['message'] ??
            'Failed to send OTP (Status code: ${response.statusCode})');
      }
    } catch (e) {
      print('❌ loginWithOtp error: $e');
      throw Exception('$e'); // Ensure the full error message is passed
    }
  }

  Future<Map<String, dynamic>> loginWithPassword(
      String phone, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/login-with-pass'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'phone': phone,
          'Gtoken': 'sddwdwdwdd',
          'password': password,
        }),
      );

      print('📩 login-with-pass request with $phone');
      print('📩 Status: ${response.statusCode}');
      print('📩 Body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final jsonData = jsonDecode(response.body);

        if (jsonData['success'] == true) {
          print('✅ loginWithPassword result: $jsonData');
          return {
            'success': true,
            'message': jsonData['message'] ?? 'Login successful',
            'user': jsonData['existingUser'],
            'token': jsonData['token'],
          };
        } else {
          throw Exception(jsonData['message'] ?? 'Invalid credentials');
        }
      } else {
        throw Exception(
            'Failed to login with password (Status code: ${response.statusCode})');
      }
    } catch (e) {
      print('❌ loginWithPassword error: $e');
      throw Exception('Error logging in with password: $e');
    }
  }

  Future<Map<String, dynamic>> verifyOtp(String otp, String hashOtp) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/login-verify-otp/'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'OTP': otp,
          'HASHOTP': hashOtp,
        }),
      );

      print('📩 verify-otp request');
      print('📩 Status: ${response.statusCode}');
      print('📩 Body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final jsonData = jsonDecode(response.body);
        if (jsonData['success'] == true || jsonData['sucesss'] == true) {
          return {
            'success': true,
            'message': jsonData['message'] ?? 'OTP verified',
            'user': jsonData['user'],
          };
        } else {
          throw Exception(jsonData['message'] ?? 'Invalid OTP');
        }
      } else {
        throw Exception(
            'Failed to verify OTP (Status code: ${response.statusCode})');
      }
    } catch (e) {
      print('❌ verifyOtp error: $e');
      throw Exception('Error verifying OTP: $e');
    }
  }

  Future<Map<String, dynamic>> signupNewUser(
      String phone, String gToken) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/signup-new-user/'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'phone': phone,
          'Gtoken': gToken,
          'password': '',
        }),
      );

      print('📩 signup-new-user request with $phone');
      print('📩 Status: ${response.statusCode}');
      print('📩 Body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final jsonData = jsonDecode(response.body);
        if (jsonData['success'] == true) {
          return {
            'success': true,
            'userId': jsonData['existingUser']?['_id']?.toString(),
            'phone': jsonData['existingUser']?['phone']?.toString(),
            'message': jsonData['message'] ?? 'User signed up successfully',
            'token': jsonData['token'],
            'otp': jsonData['otp'],
            'newotp': jsonData['newotp'],
          };
        } else {
          throw Exception(jsonData['message'] ?? 'Failed to sign up user');
        }
      } else {
        throw Exception(
            'Failed to sign up user (Status code: ${response.statusCode})');
      }
    } catch (e) {
      print('❌ signupNewUser error: $e');
      throw Exception('Error signing up user: $e');
    }
  }

  Future<Map<String, dynamic>> sendOtpForPasswordUser(String phone) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/login-with-otp/'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'phone': phone,
          'password': '',
        }),
      );

      print('📩 login-with-otp request with $phone');
      print('📩 Status: ${response.statusCode}');
      print('📩 Body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final jsonData = jsonDecode(response.body);

        if (jsonData['success'] == true) {
          print('✅ sendOtpForPasswordUser result: $jsonData');
          print('💡 Plain OTP (newotp): ${jsonData['newotp']}');
          return {
            'success': true,
            'hashotp': jsonData['otp'],
            'plainOtp': jsonData['newotp'],
            'message': jsonData['message'],
            'user': jsonData['existingUser'],
            'token': jsonData['token'],
            'type': jsonData['type'],
          };
        } else {
          throw Exception(jsonData['message'] ?? 'Failed to send OTP');
        }
      } else {
        throw Exception(
            'Failed to send OTP (Status code: ${response.statusCode})');
      }
    } catch (e) {
      print('❌ sendOtpForPasswordUser error: $e');
      throw Exception('Error sending OTP: $e');
    }
  }
}
