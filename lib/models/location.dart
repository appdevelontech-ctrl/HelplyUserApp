class LocationResponse {
  final bool success;
  final List<String> uniqueLocations;

  LocationResponse({required this.success, required this.uniqueLocations});

  factory LocationResponse.fromJson(Map<String, dynamic> json) {
    return LocationResponse(
      success: json['success'] ?? false,
      uniqueLocations: List<String>.from(json['uniqueLocations'] ?? []),
    );
  }
}