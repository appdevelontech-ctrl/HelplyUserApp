// controllers/servntroller.dart
import 'package:flutter/material.dart';
import '../models/service_category.dart';

class ServiceCategoryController extends ChangeNotifier {
  ServiceCategory _service;

  ServiceCategoryController({required String title, required String imageUrl})
      : _service = ServiceCategory(title: title, imageUrl: imageUrl);

  ServiceCategory get service => _service;

  void updateService({String? title, String? imageUrl}) {
    if (title != null) _service.title = title;
    if (imageUrl != null) _service.imageUrl = imageUrl;
    notifyListeners();
  }
}