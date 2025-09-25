import 'package:flutter/material.dart';
import 'package:user_app/models/service_category.dart';


class ServiceCategoryController extends ChangeNotifier {
  ServiceCategory? _category;
  bool _isLoading = false;

  ServiceCategory? get category => _category;
  bool get isLoading => _isLoading;

  ServiceCategoryController({ServiceCategory? initialCategory}) {
    if (initialCategory != null) {
      _category = initialCategory;
      _isLoading = false;
      notifyListeners();
    }
  }

  void setCategory(ServiceCategory category) {
    _category = category;
    _isLoading = false;
    notifyListeners();
  }
}