import 'package:flutter/material.dart';
import 'package:user_app/models/service_category.dart';
import '../models/offer.dart';
import '../services/api_services.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class HomeController extends ChangeNotifier {
  final ApiServices _apiServices = ApiServices();

  String _selectedLocation = "Select Location";
  bool _isLoading = false;
  bool _isSliderLoading = false;
  Map<String, List<ServiceCategory>> _servicesByLocation = {};

  // Cached slider image URL
  String _sliderImage = "";

  String get selectedLocation => _selectedLocation;
  bool get isLoading => _isLoading;
  bool get isSliderLoading => _isSliderLoading;
  Map<String, List<ServiceCategory>> get servicesByLocation => _servicesByLocation;
  String get sliderImage => _sliderImage;

  final List<Offer> bestOffers = [
    Offer(
      title: "Help Service",
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
    // Initial data load
    fetchHomeLayoutData();
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

  Future<void> fetchHomeLayoutData() async {
    // Skip fetching if slider image is already cached
    if (_sliderImage.isNotEmpty) {
      debugPrint("Using cached slider image: $_sliderImage");
      return;
    }

    try {
      _isSliderLoading = true;
      notifyListeners();

      final response = await http.get(
        Uri.parse("https://backend-olxs.onrender.com/home-layout-data"),
      ).timeout(const Duration(seconds: 10), onTimeout: () {
        debugPrint("API request timed out");
        return http.Response('Timeout', 408);
      });

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        debugPrint("Home layout data: $data");

        if (data is Map<String, dynamic> && data.containsKey('homeLayout')) {
          final homeLayout = data['homeLayout'];
          _sliderImage = homeLayout['slider_img'] ?? "";
          debugPrint("Slider image URL cached: $_sliderImage");
        } else {
          debugPrint("Invalid data format: $data");
        }
      } else {
        debugPrint("Failed to load home layout data: ${response.statusCode}");
      }
    } catch (e) {
      debugPrint("Error fetching home layout data: $e");
    } finally {
      _isSliderLoading = false;
      notifyListeners();
    }
  }

  Future<void> refreshData() async {
    // Refresh both services and slider data
    // Force fetch slider image even if cached, to allow refreshing
    _sliderImage = ""; // Clear cache to force refresh
    await fetchHomeLayoutData();
    if (_selectedLocation != "Select Location") {
      await fetchServicesByLocation(_selectedLocation);
    }
  }
}