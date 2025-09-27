import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/location.dart';
import '../models/order_model.dart';
import '../models/serviceCategoryDetail.dart';
import '../models/service_category.dart';
import '../models/user.dart';

class ApiServices {
  final String baseUrl = 'https://backend-olxs.onrender.com';

  Future<LocationResponse> fetchLocations() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/get-all-zones-only'));
      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body);
        return LocationResponse.fromJson(jsonData);
      } else {
        throw Exception('Failed to load locations (Status code: ${response.statusCode})');
      }
    } catch (e) {
      throw Exception('Error fetching locations: $e');
    }
  }

  Future<List<ServiceCategory>> fetchCategoriesByLocation(String location) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/get-catgeory-product?location=$location'),
      );

      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body);
        if (jsonData['success'] == true && jsonData['categoriesWithProducts'] != null) {
          return (jsonData['categoriesWithProducts'] as List<dynamic>)
              .map((e) => ServiceCategory.fromJson(e))
              .toList();
        } else {
          return [];
        }
      } else {
        throw Exception('Failed to load categories (Status code: ${response.statusCode})');
      }
    } catch (e) {
      throw Exception('Error fetching categories: $e');
    }
  }

  Future<CategoryDetailResponse> fetchCategoryDetails(String slug, String location) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/all/category-slug/$slug?filter=&price&page=1&perPage=100&location=$location'),
      );

      if (response.statusCode == 200) {
        return CategoryDetailResponse.fromJson(jsonDecode(response.body));
      } else {
        throw Exception('Failed to load category details: ${response.statusCode}');
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

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        if (json['success'] == true) {
          return ProductDetail.fromJson(json['Product']);
        } else {
          throw Exception('Failed to load product details: ${json['message']}');
        }
      } else {
        throw Exception('Failed to load product details: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching product details: $e');
    }
  }

  Future<Map<String, dynamic>> loginWithOtp(String phone) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/login-with-otp/'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'phone': phone, 'password': ''}),
      );

      print('📩 login-with-otp request with $phone');
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
            'token': jsonData['token'],
            'user': jsonData['existingUser'],
          };
        } else {
          throw Exception(jsonData['message'] ?? 'Failed to send OTP');
        }
      } else {
        throw Exception('Failed to send OTP (Status code: ${response.statusCode})');
      }
    } catch (e) {
      print('❌ loginWithPhone error: $e');
      throw Exception('Error sending OTP: $e');
    }
  }

  Future<Map<String, dynamic>> verifyOtp(String enteredOtp, String hashOtp) async {
    try {
      print('📲 verifyOtp() called with otp: $enteredOtp & hashOtp: $hashOtp');

      final response = await http.post(
        Uri.parse('$baseUrl/login-verify-otp'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'OTP': enteredOtp, 'HASHOTP': hashOtp}),
      );

      print('📩 verify-otp raw body: ${response.body}');

      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body);

        if (jsonData['success'] == true) {
          return {
            'success': true,
            'user': jsonData['user'],
          };
        } else {
          throw Exception(jsonData['message'] ?? 'Invalid OTP');
        }
      } else {
        throw Exception('Failed to verify OTP (Status code: ${response.statusCode})');
      }
    } catch (e) {
      print('❌ verifyOtp error: $e');
      throw Exception('Error verifying OTP: $e');
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
        print('📦 Orders Fetched: ${userOrderResponse.userOrder.orders.length} orders');

        return userOrderResponse.userOrder.orders.reversed.toList();
      } else {
        print('❌ Failed to fetch orders (Status code: ${response.statusCode})');
        throw Exception('Failed to fetch orders (Status code: ${response.statusCode})');
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
          return userOrderResponse.userOrder.order!;
        } else {
          throw Exception('Failed to fetch order details: ${data['message'] ?? 'Unknown error'}');
        }
      } else {
        print('❌ Failed to fetch order details (Status code: ${response.statusCode})');
        throw Exception('Failed to fetch order details (Status code: ${response.statusCode})');
      }
    } catch (e) {
      print('❌ Error fetching order details: $e');
      throw Exception('Error fetching order details: $e');
    }
  }

  Future<Map<String, dynamic>> createOrder(String userId, Map<String, dynamic> orderData) async {
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
            'order': jsonData['order'],
          };
        } else {
          throw Exception(jsonData['message'] ?? 'Failed to create order');
        }
      } else {
        throw Exception('Failed to create order (Status code: ${response.statusCode})');
      }
    } catch (e) {
      print('❌ Error creating order: $e');
      throw Exception('Error creating order: $e');
    }
  }

}