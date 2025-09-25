  import 'package:flutter/material.dart';
  import 'package:user_app/models/service_category.dart';
  import '../models/offer.dart';
  import '../services/api_services.dart';

  class HomeController extends ChangeNotifier {
    final ApiServices _apiServices = ApiServices();
    String _selectedLocation = "Select Location";
    bool _isLoading = false;
    Map<String, List<ServiceCategory>> _servicesByLocation = {};

    String get selectedLocation => _selectedLocation;
    bool get isLoading => _isLoading;
    Map<String, List<ServiceCategory>> get servicesByLocation => _servicesByLocation;

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
      // Initial data loading can be handled by calling refreshData()
    }

    void setLocation(String location) async {
      _selectedLocation = location;
      notifyListeners();
      if (location != "Select Location") {
        await fetchServicesByLocation(location);
      } else {
        _servicesByLocation.clear();
        notifyListeners();
      }
    }

    Future<void> fetchServicesByLocation(String location) async {
      try {
        _isLoading = true;
        notifyListeners();

        // ApiServices now returns List<ServiceCategory>
        final List<ServiceCategory> categories = await _apiServices.fetchCategoriesByLocation(location);
        _servicesByLocation[location] = categories;

        _isLoading = false;
        notifyListeners();
      } catch (e) {
        _isLoading = false;
        notifyListeners();
        debugPrint('Error fetching services: $e');
      }
    }

    Future<void> refreshData() async {
      if (_selectedLocation != "Select Location") {
        await fetchServicesByLocation(_selectedLocation);
      }
    }
  }
