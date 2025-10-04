import 'package:equatable/equatable.dart';

class UserOrderResponse extends Equatable {
  final bool success;
  final String message;
  final UserOrder userOrder;

  const UserOrderResponse({
    required this.success,
    required this.message,
    required this.userOrder,
  });

  factory UserOrderResponse.fromJson(Map<String, dynamic> json) {
    return UserOrderResponse(
      success: json['success'] ?? false,
      message: json['message'] ?? '',
      userOrder: UserOrder.fromJson(json['userOrder'] ?? {}),
    );
  }

  @override
  List<Object?> get props => [success, message, userOrder];
}

class UserOrder extends Equatable {
  final String id;
  final List<Order> orders;
  final Order? order;

  const UserOrder({
    required this.id,
    this.orders = const [],
    this.order,
  });

  factory UserOrder.fromJson(Map<String, dynamic> json) {
    return UserOrder(
      id: json['_id'] ?? '',
      orders: (json['orders'] as List<dynamic>?)
          ?.map((o) => Order.fromJson(o))
          .toList() ??
          [],
      order: json['order'] != null ? Order.fromJson(json['order']) : null,
    );
  }

  @override
  List<Object?> get props => [id, orders, order];
}

class Order extends Equatable {
  final String id;
  final String mode;
  final double totalAmount;
  final int payment;
  final int status;
  final int orderId;
  final int? otp;
  final DateTime createdAt;
  final String? updatedAt;
  final int v;
  final List<Item> items;
  final String discount;
  final String shipping;
  final List<String> userId;
  final String? primary;
  final int leadStatus;
  final int type;
  final int lead;
  final List<dynamic> category;
  final List<dynamic> cancelId;
  final String agentId;
  final List<UserDetails> details;
  final String? maidName;
  final String? maidPhone;
  final String? maidEmail;
  final double? maidLat;
  final double? maidLng;
  final double? userLat;
  final double? userLng;

  const Order({
    required this.id,
    required this.mode,
    required this.totalAmount,
    required this.payment,
    required this.status,
    required this.orderId,
    this.otp,
    required this.createdAt,
    this.updatedAt,
    required this.v,
    this.items = const [],
    this.discount = '0',
    this.shipping = '0',
    this.userId = const [],
    this.primary,
    this.leadStatus = 0,
    this.type = 0,
    this.lead = 0,
    this.category = const [],
    this.cancelId = const [],
    this.agentId = '',
    this.details = const [],
    this.maidName,
    this.maidPhone,
    this.maidEmail,
    this.maidLat,
    this.maidLng,
    this.userLat,
    this.userLng,
  });

  Order copyWith({
    String? id,
    String? mode,
    double? totalAmount,
    int? payment,
    int? status,
    int? orderId,
    int? otp,
    DateTime? createdAt,
    String? updatedAt,
    int? v,
    List<Item>? items,
    String? discount,
    String? shipping,
    List<String>? userId,
    String? primary,
    int? leadStatus,
    int? type,
    int? lead,
    List<dynamic>? category,
    List<dynamic>? cancelId,
    String? agentId,
    List<UserDetails>? details,
    String? maidName,
    String? maidPhone,
    String? maidEmail,
    double? maidLat,
    double? maidLng,
    double? userLat,
    double? userLng,
  }) {
    return Order(
      id: id ?? this.id,
      mode: mode ?? this.mode,
      totalAmount: totalAmount ?? this.totalAmount,
      payment: payment ?? this.payment,
      status: status ?? this.status,
      orderId: orderId ?? this.orderId,
      otp: otp ?? this.otp,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      v: v ?? this.v,
      items: items ?? this.items,
      discount: discount ?? this.discount,
      shipping: shipping ?? this.shipping,
      userId: userId ?? this.userId,
      primary: primary ?? this.primary,
      leadStatus: leadStatus ?? this.leadStatus,
      type: type ?? this.type,
      lead: lead ?? this.lead,
      category: category ?? this.category,
      cancelId: cancelId ?? this.cancelId,
      agentId: agentId ?? this.agentId,
      details: details ?? this.details,
      maidName: maidName ?? this.maidName,
      maidPhone: maidPhone ?? this.maidPhone,
      maidEmail: maidEmail ?? this.maidEmail,
      maidLat: maidLat ?? this.maidLat,
      maidLng: maidLng ?? this.maidLng,
      userLat: userLat ?? this.userLat,
      userLng: userLng ?? this.userLng,
    );
  }

  factory Order.fromJson(Map<String, dynamic> json) {
    double? parseDouble(dynamic val) {
      if (val == null) return null;
      if (val is double) return val;
      if (val is int) return val.toDouble();
      if (val is String) return double.tryParse(val);
      return null;
    }

    int? parseInt(dynamic val) {
      if (val == null) return null;
      if (val is int) return val;
      if (val is String) return int.tryParse(val);
      if (val is double) return val.toInt();
      return null;
    }

    return Order(
      id: json['_id'] ?? '',
      mode: json['mode'] ?? '',
      totalAmount: parseDouble(json['totalAmount']) ?? 0.0,
      payment: parseInt(json['payment']) ?? 0,
      status: parseInt(json['status']) ?? 0,
      orderId: parseInt(json['orderId']) ?? 0,
      otp: parseInt(json['OTP']),
      createdAt: DateTime.tryParse(json['createdAt'] ?? '') ?? DateTime.now(),
      updatedAt: json['updatedAt'],
      v: parseInt(json['__v']) ?? 0,
      items: (json['items'] as List<dynamic>?)
          ?.map((i) => Item.fromJson(i))
          .toList() ??
          [],
      discount: json['discount'] ?? '0',
      shipping: json['shipping'] ?? '0',
      userId: (json['userId'] as List<dynamic>?)?.cast<String>() ?? [],
      primary: json['primary'],
      leadStatus: parseInt(json['leadStatus']) ?? 0,
      type: parseInt(json['type']) ?? 0,
      lead: parseInt(json['lead']) ?? 0,
      category: json['category'] ?? [],
      cancelId: json['CancelId'] ?? [],
      agentId: json['agentId'] ?? '',
      details: (json['details'] as List<dynamic>?)
          ?.map((d) => UserDetails.fromJson(d))
          .toList() ??
          [],
      maidName: json['maidName'],
      maidPhone: json['maidPhone'],
      maidEmail: json['maidEmail'],
      maidLat: parseDouble(json['maidLat']),
      maidLng: parseDouble(json['maidLng']),
      userLat: parseDouble(json['userLat']),
      userLng: parseDouble(json['userLng']),
    );
  }

  @override
  List<Object?> get props => [
    id,
    mode,
    totalAmount,
    payment,
    status,
    orderId,
    otp,
    createdAt,
    updatedAt,
    v,
    items,
    discount,
    shipping,
    userId,
    primary,
    leadStatus,
    type,
    lead,
    category,
    cancelId,
    agentId,
    details,
    maidName,
    maidPhone,
    maidEmail,
    maidLat,
    maidLng,
    userLat,
    userLng,
  ];
}

class UserDetails extends Equatable {
  final String username;
  final String phone;
  final String pincode;
  final String state;
  final String address;
  final String email;

  const UserDetails({
    required this.username,
    required this.phone,
    required this.pincode,
    required this.state,
    required this.address,
    required this.email,
  });

  factory UserDetails.fromJson(Map<String, dynamic> json) {
    return UserDetails(
      username: json['username'] ?? '',
      phone: json['phone'] ?? '',
      pincode: json['pincode'] ?? '',
      state: json['state'] ?? '',
      address: json['address'] ?? '',
      email: json['email'] ?? '',
    );
  }

  @override
  List<Object?> get props => [username, phone, pincode, state, address, email];
}

class Item extends Equatable {
  final String id;
  final String title;
  final String image;
  final int regularPrice;
  final int price;
  final String color;
  final String customise;
  final int totalQuantity;
  final int weight;
  final int gst;
  final int stock;
  final String pid;
  final int quantity;

  const Item({
    required this.id,
    required this.title,
    required this.image,
    required this.regularPrice,
    required this.price,
    required this.color,
    required this.customise,
    required this.totalQuantity,
    required this.weight,
    required this.gst,
    required this.stock,
    required this.pid,
    required this.quantity,
  });

  factory Item.fromJson(Map<String, dynamic> json) {
    int parseInt(dynamic val) {
      if (val == null) return 0;
      if (val is int) return val;
      if (val is double) return val.toInt();
      if (val is String) return int.tryParse(val) ?? 0;
      return 0;
    }

    return Item(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      image: json['image'] ?? '',
      regularPrice: parseInt(json['regularPrice']),
      price: parseInt(json['price']),
      color: json['color'] ?? '',
      customise: json['customise'] ?? '',
      totalQuantity: parseInt(json['TotalQuantity']),
      weight: parseInt(json['weight']),
      gst: parseInt(json['gst']),
      stock: parseInt(json['stock']),
      pid: json['pid'] ?? '',
      quantity: parseInt(json['quantity']),
    );
  }

  @override
  List<Object?> get props => [
    id,
    title,
    image,
    regularPrice,
    price,
    color,
    customise,
    totalQuantity,
    weight,
    gst,
    stock,
    pid,
    quantity,
  ];
}
