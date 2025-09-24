import 'package:flutter/material.dart';
import '../models/offer.dart';
import '../models/service_category.dart';



class HomeController extends ChangeNotifier {
  String _selectedLocation = "Select Location";
  bool _isLoading = true;

  String get selectedLocation => _selectedLocation;
  bool get isLoading => _isLoading;



  // Services by location
  final Map<String, List<ServiceCategory>> servicesByLocation = {
    "New Delhi": [
      ServiceCategory(
        title: "Maid Service",
        imageUrl: "https://backend-olxs.onrender.com/uploads/new/image-1756571877671.jpg",
      ),
      ServiceCategory(
        title: "Cook Service",
        imageUrl: "https://backend-olxs.onrender.com/uploads/new/image-1756571237015.jpg",
      ),
      ServiceCategory(
        title: "Baby Care",
        imageUrl: "https://backend-olxs.onrender.com/uploads/new/image-1756571237015.jpg",
      ),
      ServiceCategory(
        title: "Senior Care",
        imageUrl: "https://backend-olxs.onrender.com/uploads/new/image-1756571237015.jpg",
      ),
    ],
    "Mumbai": [
      ServiceCategory(
        title: "Chef",
        imageUrl: "https://backend-olxs.onrender.com/uploads/new/image-1756572185144.jpg",
      ),
      ServiceCategory(
        title: "Driver",
        imageUrl: "https://backend-olxs.onrender.com/uploads/new/image-1756572185144.jpg",
      ),
      ServiceCategory(
        title: "Cleaner",
        imageUrl: "https://backend-olxs.onrender.com/uploads/new/image-1756572185144.jpg",
      ),
      ServiceCategory(
        title: "Security",
        imageUrl: "https://backend-olxs.onrender.com/uploads/new/image-1756572185144.jpg",
      ),
    ],
    "Bangalore": [
      ServiceCategory(
        title: "Daily Maid",
        imageUrl: "https://backend-olxs.onrender.com/uploads/new/image-1756571417814.jpg",
      ),
      ServiceCategory(
        title: "Full-time Nanny",
        imageUrl: "https://backend-olxs.onrender.com/uploads/new/image-1756571417814.jpg",
      ),
      ServiceCategory(
        title: "Cook",
        imageUrl: "https://backend-olxs.onrender.com/uploads/new/image-1756571417814.jpg",
      ),
      ServiceCategory(
        title: "Housekeeping",
        imageUrl: "https://backend-olxs.onrender.com/uploads/new/image-1756571417814.jpg",
      ),
    ],
  };

  // Best Offers
  final List<Offer> bestOffers = [
    Offer(
      title: "Maid Help Service",
      subtitle: "Daily help for household tasks",
      imageUrl: "https://backend-olxs.onrender.com/uploads/new/image-1756536070057.webp",
    ),
    Offer(
      title: "Plant Care Services",
      subtitle: "Taking care of your plants",
      imageUrl: "https://backend-olxs.onrender.com/uploads/new/image-1756570965324.jpg",
    ),
    Offer(
      title: "Cooking Services",
      subtitle: "Professional cooks at your home",
      imageUrl: "https://backend-olxs.onrender.com/uploads/new/image-1754476230460.webp",
    ),
    Offer(
      title: "Bathroom Cleaning",
      subtitle: "Deep cleaning made easy",
      imageUrl: "https://backend-olxs.onrender.com/uploads/new/image-1754476157254.webp",
    ),
  ];


  HomeController() {
    // Simulate initial data loading
    Future.delayed(const Duration(seconds: 2), () {
      _isLoading = false;
      notifyListeners();
    });
  }

  void setLocation(String location) {
    _selectedLocation = location;
    notifyListeners();
  }

  Future<void> refreshData() async {
    _isLoading = true;
    notifyListeners();
    await Future.delayed(const Duration(seconds: 2)); // Simulate network delay
    _isLoading = false;
    notifyListeners();
  }
}