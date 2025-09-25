import 'package:flutter/material.dart';

import '../models/serviceCategoryDetail.dart';
import '../services/api_services.dart';

class ServiceCategoryDetailController extends ChangeNotifier {
  final ApiServices _apiServices = ApiServices();
  MainCategory? _mainCategory;
  List<Product> _products = [];
  bool _isLoading = true;
  String? _errorMessage;

  MainCategory? get mainCategory => _mainCategory;
  List<Product> get products => _products;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  ServiceCategoryDetailController();

  Future<void> fetchCategoryDetails(String slug, String location) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      final response = await _apiServices.fetchCategoryDetails(slug, location);
      if (response.success) {
        _mainCategory = response.mainCat;
        _products = response.products;
      } else {
        _errorMessage = 'Failed to load category details';
      }

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'Error fetching category details: $e';
      notifyListeners();
      debugPrint(_errorMessage);
    }
  }
}