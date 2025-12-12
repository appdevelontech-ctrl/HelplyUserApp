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
  String _sliderImage = "";
  List<Offer> _bestOffers = []; // Dynamic best offers list

  String get selectedLocation => _selectedLocation;
  bool get isLoading => _isLoading;
  bool get isSliderLoading => _isSliderLoading;
  Map<String, List<ServiceCategory>> get servicesByLocation => _servicesByLocation;
  String get sliderImage => _sliderImage;
  List<Offer> get bestOffers => _bestOffers; // Getter for best offers

  HomeController() {
    fetchHomeLayoutData();
    print("images is : $sliderImage");
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
          _sliderImage = homeLayout['top_bar'] ?? "";
          print("Slider image is: $sliderImage");

          // Populate bestOffers from latest_product_banner
          if (homeLayout['latest_product_banner'] != null) {
            _bestOffers = (homeLayout['latest_product_banner'] as List<dynamic>)
                .map((item) => Offer(
              title: item['imageTITInput'] ?? '',
              subtitle: item['imageParaInput'] ?? '',
              imageUrl: item['imageInput'] ?? '',
              url: item['imageUrlInput'] ?? '#', // Optional: store URL
            ))
                .toList();
          }
          debugPrint("Slider image URL cached: $_sliderImage");
          debugPrint("Best offers loaded: ${_bestOffers.length}");
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
    _sliderImage = "";
    _bestOffers = []; // Clear best offers to force refresh
    await fetchHomeLayoutData();
    if (_selectedLocation != "Select Location") {
      await fetchServicesByLocation(_selectedLocation);
    }
  }
}