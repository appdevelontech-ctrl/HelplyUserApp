import 'package:flutter/material.dart';
import 'package:user_app/models/ProductDetail.dart';
import '../models/serviceCategoryDetail.dart';

class ServiceCategoryDetailController extends ChangeNotifier {
  List<Servicecategorydetail> _servicecategorydetail = []; // Initialize with empty list
  bool _isLoading = true; // Loading state

  ServiceCategoryDetailController() {
    _initializeProducts();
  }

  List<Servicecategorydetail> get servicecategorydetail => _servicecategorydetail;
  bool get isLoading => _isLoading;

  Future<void> _initializeProducts() async {
    try {
      // Simulate network delay
      await Future.delayed(const Duration(seconds: 2)); // Replace with actual API call
      _servicecategorydetail = [
        Servicecategorydetail(
          name: 'Quick & Efficient',
          description: 'Basic cleaning completed in minimal time.',
          price: '150',
          duration: '30 mins',
          imageUrl: 'https://backend-olxs.onrender.com/uploads/new/image-1756571559212.jpg',
          regularPrice: 200.0,
          salePrice: 150.0,
        ),
        Servicecategorydetail(
          name: 'Hygienic Cleaning',
          description: 'Pot, sink, tiles, and more cleaned hygienically.',
          price: '200',
          duration: '45 mins',
          imageUrl: 'https://backend-olxs.onrender.com/uploads/new/image-1756571559212.jpg',
          regularPrice: 250.0,
          salePrice: 200.0,
        ),
        Servicecategorydetail(
          name: 'Deep Clean',
          description: 'Detailed cleaning including mirrors and exhaust fan.',
          price: '250',
          duration: '60 mins',
          imageUrl: 'https://backend-olxs.onrender.com/uploads/new/image-1756571559212.jpg',
          regularPrice: 300.0,
          salePrice: 250.0,
        ),
        Servicecategorydetail(
          name: 'Premium Service',
          description: 'Trained helper, reliable and affordable.',
          price: '300',
          duration: '75 mins',
          imageUrl: 'https://backend-olxs.onrender.com/uploads/new/image-1756571559212.jpg',
          regularPrice: 350.0,
          salePrice: 300.0,
        ),
      ];
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _servicecategorydetail = [];
      _isLoading = false;
      debugPrint('Error initializing products: $e');
      notifyListeners();
    }
  }

  void addOrUpdateProduct(Servicecategorydetail servicecategorydetail) {
    final index = _servicecategorydetail.indexWhere((p) => p.name == servicecategorydetail.name);
    if (index != -1) {
      _servicecategorydetail[index] = servicecategorydetail;
    } else {
      _servicecategorydetail.add(servicecategorydetail);
    }
    notifyListeners();
  }
}