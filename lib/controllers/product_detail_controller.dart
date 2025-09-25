import 'package:flutter/material.dart';

import '../models/serviceCategoryDetail.dart';
import '../services/api_services.dart';

class ProductDetailController extends ChangeNotifier {
  final ApiServices _apiServices = ApiServices();
  ProductDetail? _productDetail;
  bool _isLoading = true;
  String? _errorMessage;

  ProductDetail? get productDetail => _productDetail;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  ProductDetailController();

  Future<void> fetchProductDetails(String slug) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      _productDetail = await _apiServices.fetchProductDetails(slug);

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'Error fetching product details: $e';
      notifyListeners();
      debugPrint(_errorMessage);
    }
  }
}