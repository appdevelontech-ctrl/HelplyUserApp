import 'package:flutter/material.dart';
import '../services/api_services.dart';


class LocationController extends ChangeNotifier {
  final ApiServices _apiServices = ApiServices();
  List<String> _locations = ["Select Location"];
  bool _isLoading = false;

  List<String> get locations => _locations;
  bool get isLoading => _isLoading;

  LocationController() {
    fetchLocations();
  }

  Future<void> fetchLocations() async {
    try {
      _isLoading = true;
      notifyListeners();
      final response = await _apiServices.fetchLocations();
      if (response.success) {
        _locations = ["Select Location", ...response.uniqueLocations];
      }
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      debugPrint('Error fetching locations: $e');
    }
  }
}