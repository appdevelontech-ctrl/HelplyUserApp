import 'package:flutter/material.dart';
import '../models/Service.dart';

class ServiceController extends ChangeNotifier {
  late List<Service> _products;

  ServiceController() {
    _initializeProducts();
  }

  List<Service> get products => _products;

  void _initializeProducts() {
    try {
      _products = [
        Service(
          name: 'Quick & Efficient',
          description: 'Basic cleaning completed in minimal time.',
          price: '₹150',
          duration: '30 mins',
          imageUrl: 'https://backend-olxs.onrender.com/uploads/new/image-1756571559212.jpg', // Realistic placeholder
          regularPrice: 200.0,
          salePrice: 150.0,
        ),
        Service(
          name: 'Hygienic Cleaning',
          description: 'Pot, sink, tiles, and more cleaned hygienically.',
          price: '₹200',
          duration: '45 mins',
          imageUrl: 'https://backend-olxs.onrender.com/uploads/new/image-1756571559212.jpg',
          regularPrice: 250.0,
          salePrice: 200.0,
        ),
        Service(
          name: 'Deep Clean',
          description: 'Detailed cleaning including mirrors and exhaust fan.',
          price: '₹250',
          duration: '60 mins',
          imageUrl: 'https://backend-olxs.onrender.com/uploads/new/image-1756571559212.jpg',
          regularPrice: 300.0,
          salePrice: 250.0,
        ),
        Service(
          name: 'Premium Service',
          description: 'Trained helper, reliable and affordable.',
          price: '₹300',
          duration: '75 mins',
          imageUrl: 'https://backend-olxs.onrender.com/uploads/new/image-1756571559212.jpg',
          regularPrice: 350.0,
          salePrice: 300.0,
        ),
      ];
    } catch (e) {
      _products = [];
      debugPrint('Error initializing products: $e');
    }
  }

  // Method to add or update a product
  void addOrUpdateProduct(Service product) {
    final index = _products.indexWhere((p) => p.name == product.name);
    if (index != -1) {
      _products[index] = product;
    } else {
      _products.add(product);
    }
    notifyListeners();
  }
}