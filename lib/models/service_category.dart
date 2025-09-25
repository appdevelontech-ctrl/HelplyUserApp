class CategoryResponse {
  final String message;
  final bool success;
  final List<ServiceCategory> categoriesWithProducts;

  CategoryResponse({
    required this.message,
    required this.success,
    required this.categoriesWithProducts,
  });

  factory CategoryResponse.fromJson(Map<String, dynamic> json) {
    return CategoryResponse(
      message: json['message'] ?? '',
      success: json['success'] ?? false,
      categoriesWithProducts: (json['categoriesWithProducts'] as List<dynamic>?)
          ?.map((e) => ServiceCategory.fromJson(e))
          .toList() ??
          [],
    );
  }
}

class ServiceCategory {
  final String id;
  final String title;
  final String image;
  final String slug;

  ServiceCategory({
    required this.id,
    required this.title,
    required this.image,
    required this.slug,
  });

  factory ServiceCategory.fromJson(Map<String, dynamic> json) {
    return ServiceCategory(
      id: json['_id'] ?? '',
      title: json['title'] ?? '',
      image: json['image'] ?? '',
      slug: json['slug'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'title': title,
      'image': image,
      'slug': slug,
    };
  }
}
