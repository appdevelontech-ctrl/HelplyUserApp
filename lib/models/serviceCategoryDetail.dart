import 'dart:convert';
import 'package:intl/intl.dart';

class CategoryDetailResponse {
  final bool success;
  final MainCategory mainCat;
  final List<Product> products;

  CategoryDetailResponse({
    required this.success,
    required this.mainCat,
    required this.products,
  });

  factory CategoryDetailResponse.fromJson(Map<String, dynamic> json) {
    return CategoryDetailResponse(
      success: json['success'] ?? false,
      mainCat: MainCategory.fromJson(json['MainCat'] ?? {}),
      products: (json['products'] as List<dynamic>?)
          ?.map((e) => Product.fromJson(e))
          .toList() ??
          [],
    );
  }

  CategoryDetailResponse copyWith({
    bool? success,
    MainCategory? mainCat,
    List<Product>? products,
  }) {
    return CategoryDetailResponse(
      success: success ?? this.success,
      mainCat: mainCat ?? this.mainCat,
      products: products ?? this.products,
    );
  }
}

class MainCategory {
  final String id;
  final String title;
  final String slideHead;
  final String slidePara;
  final String image;
  final String slug;
  final String description;
  final String metaTitle;
  final String metaDescription;
  final String metaKeywords;
  final int filter;
  final Specifications specifications;

  MainCategory({
    required this.id,
    required this.title,
    required this.slideHead,
    required this.slidePara,
    required this.image,
    required this.slug,
    required this.description,
    required this.metaTitle,
    required this.metaDescription,
    required this.metaKeywords,
    required this.filter,
    required this.specifications,
  });

  factory MainCategory.fromJson(Map<String, dynamic> json) {
    return MainCategory(
      id: json['_id'] ?? '',
      title: json['title'] ?? '',
      slideHead: json['slide_head'] ?? '',
      slidePara: json['slide_para'] ?? '',
      image: json['image'] ?? '',
      slug: json['slug'] ?? '',
      description: json['description'] ?? '',
      metaTitle: json['metaTitle'] ?? '',
      metaDescription: json['metaDescription'] ?? '',
      metaKeywords: json['metaKeywords'] ?? '',
      filter: json['filter'] ?? 0,
      specifications: Specifications.fromJson(json['specifications'] ?? {}),
    );
  }

  MainCategory copyWith({
    String? id,
    String? title,
    String? slideHead,
    String? slidePara,
    String? image,
    String? slug,
    String? description,
    String? metaTitle,
    String? metaDescription,
    String? metaKeywords,
    int? filter,
    Specifications? specifications,
  }) {
    return MainCategory(
      id: id ?? this.id,
      title: title ?? this.title,
      slideHead: slideHead ?? this.slideHead,
      slidePara: slidePara ?? this.slidePara,
      image: image ?? this.image,
      slug: slug ?? this.slug,
      description: description ?? this.description,
      metaTitle: metaTitle ?? this.metaTitle,
      metaDescription: metaDescription ?? this.metaDescription,
      metaKeywords: metaKeywords ?? this.metaKeywords,
      filter: filter ?? this.filter,
      specifications: specifications ?? this.specifications,
    );
  }
}

class Specifications {
  final List<dynamic> specifications;

  Specifications({required this.specifications});

  factory Specifications.fromJson(Map<String, dynamic> json) {
    return Specifications(
      specifications: json['specifications'] ?? [],
    );
  }

  Specifications copyWith({List<dynamic>? specifications}) {
    return Specifications(
      specifications: specifications ?? this.specifications,
    );
  }
}
class Product {
  final String id;
  final String title;
  final String pImage;
  final List<String> images;
  final String slug;
  final List<String> features;
  final double regularPrice;
  final double salePrice;
  final User userId;
  final List<dynamic> variations;
  final DateTime? selectedDate;
  final DateTime? selectedTime;
  final String selectedDuration;
  final double minPrice; // Added for API compatibility
  final int weight; // Added for API compatibility
  final int gst; // Added for API compatibility
  final int stock; // Added for API compatibility

  Product({
    required this.id,
    required this.title,
    required this.pImage,
    required this.images,
    required this.slug,
    required this.features,
    required this.regularPrice,
    required this.salePrice,
    required this.userId,
    required this.variations,
    this.selectedDate,
    this.selectedTime,
    this.selectedDuration = '30min',
    this.minPrice = 0.0,
    this.weight = 0,
    this.gst = 0,
    this.stock = 0,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['_id'] ?? '',
      title: json['title'] ?? '',
      pImage: json['pImage'] ?? '',
      images: List<String>.from(json['images'] ?? []),
      slug: json['slug'] ?? '',
      features: List<String>.from(json['features'] ?? []),
      regularPrice: (json['regularPrice'] ?? 0).toDouble(),
      salePrice: (json['salePrice'] ?? 0).toDouble(),
      userId: User.fromJson(json['userId'] is String ? jsonDecode(json['userId']) : (json['userId'] ?? {})),
      variations: json['variations'] ?? [],
      selectedDate: json['selectedDate'] != null ? DateTime.tryParse(json['selectedDate']) : null,
      selectedTime: json['selectedTime'] != null ? DateTime.tryParse(json['selectedTime']) : null,
      selectedDuration: json['selectedDuration'] ?? '30min',
      minPrice: (json['minPrice'] ?? 0).toDouble(),
      weight: json['weight'] ?? 0,
      gst: json['gst'] ?? 0,
      stock: json['stock'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'image': pImage, // API uses 'image' instead of 'pImage'
      'regularPrice': regularPrice,
      'salePrice': salePrice,
      'price': salePrice, // API expects 'price' as salePrice
      'color': '',
      'customise': '',
      'TotalQuantity': 1,
      'SelectedSizes': {},
      'weight': weight,
      'gst': gst,
      'stock': stock,
      'pid': id, // API uses 'pid' as product ID
      'date': selectedDate != null ? DateFormat('yyyy-MM-dd').format(selectedDate!) : '',
      'time': selectedTime != null ? DateFormat('h:mm a').format(selectedTime!) : '',
      'hour': selectedDuration, // API expects 'hour' as duration
      'GSTPrice': salePrice, // Assuming GSTPrice is same as salePrice for simplicity
      'NightCharges': 0,
      'fullday': selectedDuration == 'FullDay' ? 1 : 0,
      'minPrice': minPrice,
      'quantity': 1,
    };
  }

  Product copyWith({
    String? id,
    String? title,
    String? pImage,
    List<String>? images,
    String? slug,
    List<String>? features,
    double? regularPrice,
    double? salePrice,
    User? userId,
    List<dynamic>? variations,
    DateTime? selectedDate,
    DateTime? selectedTime,
    String? selectedDuration,
    double? minPrice,
    int? weight,
    int? gst,
    int? stock,
  }) {
    return Product(
      id: id ?? this.id,
      title: title ?? this.title,
      pImage: pImage ?? this.pImage,
      images: images ?? this.images,
      slug: slug ?? this.slug,
      features: features ?? this.features,
      regularPrice: regularPrice ?? this.regularPrice,
      salePrice: salePrice ?? this.salePrice,
      userId: userId ?? this.userId,
      variations: variations ?? this.variations,
      selectedDate: selectedDate ?? this.selectedDate,
      selectedTime: selectedTime ?? this.selectedTime,
      selectedDuration: selectedDuration ?? this.selectedDuration,
      minPrice: minPrice ?? this.minPrice,
      weight: weight ?? this.weight,
      gst: gst ?? this.gst,
      stock: stock ?? this.stock,
    );
  }
}

class ProductDetail {
  final String id;
  final int pId;
  final String title;
  final String description;
  final String pImage;
  final List<String> images;
  final String slug;
  final List<String> features;
  final String metaDescription;
  final String metaTitle;
  final String metaKeywords;
  final double regularPrice;
  final double salePrice;
  final String status;
  final bool type;
  final List<Specification> specifications;
  final List<String> category;
  final String hsn;
  final String sku;
  final User userId;
  final String createdAt;
  final String updatedAt;
  final int gst;
  final int stock;
  final List<dynamic> testimonials;
  final List<dynamic> variantProducts;
  final List<dynamic> variations;
  final int weight;
  final List<dynamic> howItWorks;
  final List<ExtraContent> extraContent;
  final List<String> whatIsExcluded;
  final List<String> whatIsIncluded;
  final double minPrice;
  final int day;

  ProductDetail({
    required this.id,
    required this.pId,
    required this.title,
    required this.description,
    required this.pImage,
    required this.images,
    required this.slug,
    required this.features,
    required this.metaDescription,
    required this.metaTitle,
    required this.metaKeywords,
    required this.regularPrice,
    required this.salePrice,
    required this.status,
    required this.type,
    required this.specifications,
    required this.category,
    required this.hsn,
    required this.sku,
    required this.userId,
    required this.createdAt,
    required this.updatedAt,
    required this.gst,
    required this.stock,
    required this.testimonials,
    required this.variantProducts,
    required this.variations,
    required this.weight,
    required this.howItWorks,
    required this.extraContent,
    required this.whatIsExcluded,
    required this.whatIsIncluded,
    required this.minPrice,
    required this.day,
  });

  factory ProductDetail.fromJson(Map<String, dynamic> json) {
    return ProductDetail(
      id: json['_id'] ?? '',
      pId: json['p_id'] ?? 0,
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      pImage: json['pImage'] ?? '',
      images: List<String>.from(json['images'] ?? []),
      slug: json['slug'] ?? '',
      features: List<String>.from(json['features'] ?? []),
      metaDescription: json['metaDescription'] ?? '',
      metaTitle: json['metaTitle'] ?? '',
      metaKeywords: json['metaKeywords'] ?? '',
      regularPrice: (json['regularPrice'] ?? 0).toDouble(),
      salePrice: (json['salePrice'] ?? 0).toDouble(),
      status: json['status'] ?? '',
      type: json['type'] ?? false,
      specifications: (json['specifications']?['specifications'] as List<dynamic>?)
          ?.map((e) => Specification.fromJson(e))
          .toList() ??
          [],
      category: List<String>.from(json['Category'] ?? []),
      hsn: json['hsn'] ?? '',
      sku: json['sku'] ?? '',
      userId: User.fromJson(json['userId'] is String ? jsonDecode(json['userId']) : (json['userId'] ?? {})),
      createdAt: json['createdAt'] ?? '',
      updatedAt: json['updatedAt'] ?? '',
      gst: json['gst'] ?? 0,
      stock: json['stock'] ?? 0,
      testimonials: json['testimonials'] ?? [],
      variantProducts: json['variant_products'] ?? [],
      variations: json['variations'] ?? [],
      weight: json['weight'] ?? 0,
      howItWorks: json['how_it_works'] ?? [],
      extraContent: (json['extra_content'] as List<dynamic>?)
          ?.map((e) => ExtraContent.fromJson(e))
          .toList() ??
          [],
      whatIsExcluded: List<String>.from(json['what_is_excluded'] ?? []),
      whatIsIncluded: List<String>.from(json['what_is_included'] ?? []),
      minPrice: (json['minPrice'] ?? 0).toDouble(),
      day: json['day'] ?? 0,
    );
  }

  ProductDetail copyWith({
    String? id,
    int? pId,
    String? title,
    String? description,
    String? pImage,
    List<String>? images,
    String? slug,
    List<String>? features,
    String? metaDescription,
    String? metaTitle,
    String? metaKeywords,
    double? regularPrice,
    double? salePrice,
    String? status,
    bool? type,
    List<Specification>? specifications,
    List<String>? category,
    String? hsn,
    String? sku,
    User? userId,
    String? createdAt,
    String? updatedAt,
    int? gst,
    int? stock,
    List<dynamic>? testimonials,
    List<dynamic>? variantProducts,
    List<dynamic>? variations,
    int? weight,
    List<dynamic>? howItWorks,
    List<ExtraContent>? extraContent,
    List<String>? whatIsExcluded,
    List<String>? whatIsIncluded,
    double? minPrice,
    int? day,
  }) {
    return ProductDetail(
      id: id ?? this.id,
      pId: pId ?? this.pId,
      title: title ?? this.title,
      description: description ?? this.description,
      pImage: pImage ?? this.pImage,
      images: images ?? this.images,
      slug: slug ?? this.slug,
      features: features ?? this.features,
      metaDescription: metaDescription ?? this.metaDescription,
      metaTitle: metaTitle ?? this.metaTitle,
      metaKeywords: metaKeywords ?? this.metaKeywords,
      regularPrice: regularPrice ?? this.regularPrice,
      salePrice: salePrice ?? this.salePrice,
      status: status ?? this.status,
      type: type ?? this.type,
      specifications: specifications ?? this.specifications,
      category: category ?? this.category,
      hsn: hsn ?? this.hsn,
      sku: sku ?? this.sku,
      userId: userId ?? this.userId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      gst: gst ?? this.gst,
      stock: stock ?? this.stock,
      testimonials: testimonials ?? this.testimonials,
      variantProducts: variantProducts ?? this.variantProducts,
      variations: variations ?? this.variations,
      weight: weight ?? this.weight,
      howItWorks: howItWorks ?? this.howItWorks,
      extraContent: extraContent ?? this.extraContent,
      whatIsExcluded: whatIsExcluded ?? this.whatIsExcluded,
      whatIsIncluded: whatIsIncluded ?? this.whatIsIncluded,
      minPrice: minPrice ?? this.minPrice,
      day: day ?? this.day,
    );
  }

  Product toProduct({
    DateTime? selectedDate,
    DateTime? selectedTime,
    String? selectedDuration,
    double? salePrice,
  }) {
    return Product(
      id: id,
      title: title,
      pImage: pImage,
      images: images,
      slug: slug,
      features: features,
      regularPrice: regularPrice,
      salePrice: salePrice ?? this.salePrice,
      userId: userId,
      variations: variations,
      selectedDate: selectedDate,
      selectedTime: selectedTime,
      selectedDuration: selectedDuration ?? '30min',
    );
  }
}

class Specification {
  final String heading;
  final List<Label> labels;

  Specification({required this.heading, required this.labels});

  factory Specification.fromJson(Map<String, dynamic> json) {
    return Specification(
      heading: json['heading'] ?? '',
      labels: (json['labels'] as List<dynamic>?)
          ?.map((e) => Label.fromJson(e))
          .toList() ??
          [],
    );
  }

  Specification copyWith({String? heading, List<Label>? labels}) {
    return Specification(
      heading: heading ?? this.heading,
      labels: labels ?? this.labels,
    );
  }
}

class Label {
  final String label;
  final String value;

  Label({required this.label, required this.value});

  factory Label.fromJson(Map<String, dynamic> json) {
    return Label(
      label: json['label'] ?? '',
      value: json['value'] ?? '',
    );
  }

  Label copyWith({String? label, String? value}) {
    return Label(
      label: label ?? this.label,
      value: value ?? this.value,
    );
  }
}

class ExtraContent {
  final List<dynamic> headers;
  final List<dynamic> rows;

  ExtraContent({required this.headers, required this.rows});

  factory ExtraContent.fromJson(Map<String, dynamic> json) {
    return ExtraContent(
      headers: json['headers'] ?? [],
      rows: json['rows'] ?? [],
    );
  }

  ExtraContent copyWith({List<dynamic>? headers, List<dynamic>? rows}) {
    return ExtraContent(
      headers: headers ?? this.headers,
      rows: rows ?? this.rows,
    );
  }
}

class User {
  final String id;
  final String username;
  final String phone;
  final String email;
  final List<String> coverage;
  final String createdAt;
  final String address;

  User({
    required this.id,
    required this.username,
    required this.phone,
    required this.email,
    required this.coverage,
    required this.createdAt,
    required this.address,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['_id'] ?? '',
      username: json['username'] ?? '',
      phone: json['phone'] ?? '',
      email: json['email'] ?? '',
      coverage: List<String>.from(json['coverage'] ?? []),
      createdAt: json['createdAt'] ?? '',
      address: json['address'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'username': username,
      'phone': phone,
      'email': email,
      'coverage': coverage,
      'createdAt': createdAt,
      'address': address,
    };
  }

  User copyWith({
    String? id,
    String? username,
    String? phone,
    String? email,
    List<String>? coverage,
    String? createdAt,
    String? address,
  }) {
    return User(
      id: id ?? this.id,
      username: username ?? this.username,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      coverage: coverage ?? this.coverage,
      createdAt: createdAt ?? this.createdAt,
      address: address ?? this.address,
    );
  }
}