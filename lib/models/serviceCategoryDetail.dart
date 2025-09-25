  import 'dart:convert';

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
  }

  class Specifications {
    final List<dynamic> specifications;

    Specifications({required this.specifications});

    factory Specifications.fromJson(Map<String, dynamic> json) {
      return Specifications(
        specifications: json['specifications'] ?? [],
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
        userId: User.fromJson(json['userId'] ?? {}),
        variations: json['variations'] ?? [],
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
        userId: User.fromJson(json['userId'] ?? {}),
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
  }

  class Specification {
    final String heading;
    final List<Label> labels;

    Specification({
      required this.heading,
      required this.labels,
    });

    factory Specification.fromJson(Map<String, dynamic> json) {
      return Specification(
        heading: json['heading'] ?? '',
        labels: (json['labels'] as List<dynamic>?)
            ?.map((e) => Label.fromJson(e))
            .toList() ??
            [],
      );
    }
  }

  class Label {
    final String label;
    final String value;

    Label({
      required this.label,
      required this.value,
    });

    factory Label.fromJson(Map<String, dynamic> json) {
      return Label(
        label: json['label'] ?? '',
        value: json['value'] ?? '',
      );
    }
  }

  class ExtraContent {
    final List<dynamic> headers;
    final List<dynamic> rows;

    ExtraContent({
      required this.headers,
      required this.rows,
    });

    factory ExtraContent.fromJson(Map<String, dynamic> json) {
      return ExtraContent(
        headers: json['headers'] ?? [],
        rows: json['rows'] ?? [],
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
  }