import 'dart:convert';
import 'package:http/http.dart' as http;

import '../models/location.dart';
import '../models/serviceCategoryDetail.dart';
import '../models/service_category.dart';

class ApiServices {
  final String baseUrl = 'https://backend-olxs.onrender.com';

  // Fetch unique locations
  Future<LocationResponse> fetchLocations() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/get-all-zones-only'));
      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body);
        return LocationResponse.fromJson(jsonData);
      } else {
        throw Exception('Failed to load locations (Status code: ${response.statusCode})');
      }
    } catch (e) {
      throw Exception('Error fetching locations: $e');
    }
  }

  // Fetch categories by location
  Future<List<ServiceCategory>> fetchCategoriesByLocation(String location) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/get-catgeory-product?location=$location'),
      );

      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body);
        if (jsonData['success'] == true && jsonData['categoriesWithProducts'] != null) {
          return (jsonData['categoriesWithProducts'] as List<dynamic>)
              .map((e) => ServiceCategory.fromJson(e))
              .toList();
        } else {
          return []; // Return empty list if API returns success=false or no data
        }
      } else {
        throw Exception('Failed to load categories (Status code: ${response.statusCode})');
      }
    } catch (e) {
      throw Exception('Error fetching categories: $e');
    }
  }



  Future<CategoryDetailResponse> fetchCategoryDetails(String slug, String location) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/all/category-slug/$slug?filter=&price&page=1&perPage=100&location=$location'),
      );

      if (response.statusCode == 200) {
        return CategoryDetailResponse.fromJson(jsonDecode(response.body));
      } else {
        throw Exception('Failed to load category details: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching category details: $e');
    }
  }


  Future<ProductDetail> fetchProductDetails(String slug) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/user-product-slug/$slug'),
      );

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        if (json['success'] == true) {
          return ProductDetail.fromJson(json['Product']);
        } else {
          throw Exception('Failed to load product details: ${json['message']}');
        }
      } else {
        throw Exception('Failed to load product details: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching product details: $e');
    }
  }

}
