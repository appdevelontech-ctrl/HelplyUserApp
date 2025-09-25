import 'package:flutter/material.dart';
import '../models/service_category.dart';

class ServiceCategoryController extends ChangeNotifier {
  ServiceCategory _servicecategory;
  bool _isLoading = true; // Add loading state

  ServiceCategoryController({required String title, required String imageUrl})
      : _servicecategory = ServiceCategory(title: title, imageUrl: imageUrl) {
    _initializeService();
  }

  ServiceCategory get servicecategory => _servicecategory;
  bool get isLoading => _isLoading; // Getter for loading state

  Future<void> _initializeService() async {
    try {
      // Simulate async data fetching (replace with actual API call if needed)
      await Future.delayed(const Duration(seconds: 1));
      // Optionally update _service with fetched data if needed
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      debugPrint('Error initializing service category: $e');
      notifyListeners();
    }
  }

  void updateService({String? title, String? imageUrl}) {
    if (title != null) _servicecategory.title = title;
    if (imageUrl != null) _servicecategory.imageUrl = imageUrl;
    notifyListeners();
  }
}