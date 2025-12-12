import 'package:flutter/foundation.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

import '../models/serviceCategoryDetail.dart';
import '../services/api_services.dart';

class ProductDetailController extends ChangeNotifier {
  final ApiServices _apiServices = ApiServices();

  ProductDetail? _productDetail;
  bool _isLoading = false;
  String? _errorMessage;
  bool _isDisposed = false;

  /// ⭐ HOME SETTINGS (startTime, endTime, timeGap)
  Map<String, dynamic>? homeData;

  ProductDetail? get productDetail => _productDetail;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  /// ⭐ Empty Constructor
  ProductDetailController();

  // =====================================================
  //  FETCH PRODUCT DETAILS + HOME DATA
  // =====================================================
  Future<void> fetchProductDetails(String slug) async {
    if (_isDisposed) return;

    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      EasyLoading.show(status: 'Loading product details...');

      /// ----------------------------
      /// FETCH PRODUCT DETAILS
      /// ----------------------------
      _productDetail = await _apiServices.fetchProductDetails(slug);

      /// ⭐ VERY IMPORTANT:
      /// Fetch Home Slot Settings IMMEDIATELY
      await fetchHomeData();

      _isLoading = false;
      notifyListeners();

      EasyLoading.dismiss();
    } catch (e) {
      _isLoading = false;
      _errorMessage = "Error fetching product details: $e";
      notifyListeners();

      EasyLoading.showError(_errorMessage ?? "Something went wrong");
      debugPrint(_errorMessage);
    }
  }

  // =====================================================
  //  FETCH HOME SLOT SETTINGS
  // =====================================================
  Future<void> fetchHomeData() async {
    try {
      final response = await http.get(
        Uri.parse("https://backend-olxs.onrender.com/home-data"),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        /// ⭐ STORE homeData (startTime, endTime, timeGap)
        homeData = data["homeData"];

        notifyListeners();
      } else {
        print("Failed to fetch home settings: ${response.statusCode}");
      }
    } catch (e) {
      print("Error fetching home settings: $e");
    }
  }

  // =====================================================
  //  CLEANUP
  // =====================================================
  @override
  void dispose() {
    _isDisposed = true;
    super.dispose();
  }
}
