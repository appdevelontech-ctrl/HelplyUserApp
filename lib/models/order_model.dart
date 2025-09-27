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
      userOrder: UserOrder.fromJson(json['userOrder'] as Map<String, dynamic>),
    );
  }

  @override
  List<Object?> get props => [success, message, userOrder];
}

class UserOrder extends Equatable {
  final String id;
  final List<Order> orders; // For fetchUserOrders
  final Order? order; // For fetchOrderDetails

  const UserOrder({
    required this.id,
    this.orders = const [],
    this.order,
  });

  factory UserOrder.fromJson(Map<String, dynamic> json) {
    return UserOrder(
      id: json['_id'] as String? ?? '',
      orders: (json['orders'] as List<dynamic>?)
          ?.map((orderJson) => Order.fromJson(orderJson as Map<String, dynamic>))
          .toList() ??
          [],
      order: json['items'] != null ? Order.fromJson(json as Map<String, dynamic>) : null,
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
  final List<UserDetails> details; // Add details field

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
    this.details = const [], // Initialize details
  });

  factory Order.fromJson(Map<String, dynamic> json) {
    return Order(
      id: json['_id'] as String? ?? '',
      mode: json['mode'] as String? ?? '',
      totalAmount: (json['totalAmount'] as num?)?.toDouble() ?? 0.0,
      payment: (json['payment'] is String ? int.tryParse(json['payment']) : json['payment']) ?? 0,
      status: (json['status'] is String ? int.tryParse(json['status']) : json['status']) ?? 0,
      orderId: (json['orderId'] is String ? int.tryParse(json['orderId']) : json['orderId']) ?? 0,
      otp: (json['OTP'] is String ? int.tryParse(json['OTP']) : json['OTP']) as int?,
      createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ?? DateTime.now(),
      updatedAt: json['updatedAt'] as String?,
      v: (json['__v'] is String ? int.tryParse(json['__v']) : json['__v']) ?? 0,
      items: (json['items'] as List<dynamic>?)
          ?.map((item) => Item.fromJson(item as Map<String, dynamic>))
          .toList() ??
          [],
      discount: json['discount'] as String? ?? '0',
      shipping: json['shipping'] as String? ?? '0',
      userId: (json['userId'] as List<dynamic>?)?.cast<String>() ?? [],
      primary: json['primary'] as String?,
      leadStatus: (json['leadStatus'] is String ? int.tryParse(json['leadStatus']) : json['leadStatus']) ?? 0,
      type: (json['type'] is String ? int.tryParse(json['type']) : json['type']) ?? 0,
      lead: (json['lead'] is String ? int.tryParse(json['lead']) : json['lead']) ?? 0,
      category: json['category'] as List<dynamic>? ?? [],
      cancelId: json['CancelId'] as List<dynamic>? ?? [],
      agentId: json['agentId'] as String? ?? '',
      details: (json['details'] as List<dynamic>?)
          ?.map((detail) => UserDetails.fromJson(detail as Map<String, dynamic>))
          .toList() ??
          [],
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
      username: json['username'] as String? ?? '',
      phone: json['phone'] as String? ?? '',
      pincode: json['pincode'] as String? ?? '',
      state: json['state'] as String? ?? '',
      address: json['address'] as String? ?? '',
      email: json['email'] as String? ?? '',
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
    return Item(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      image: json['image'] as String? ?? '',
      regularPrice: (json['regularPrice'] is String ? int.tryParse(json['regularPrice']) : json['regularPrice']) ?? 0,
      price: (json['price'] is String ? int.tryParse(json['price']) : json['price']) ?? 0,
      color: json['color'] as String? ?? '',
      customise: json['customise'] as String? ?? '',
      totalQuantity: (json['TotalQuantity'] is String ? int.tryParse(json['TotalQuantity']) : json['TotalQuantity']) ?? 0,
      weight: (json['weight'] is String ? int.tryParse(json['weight']) : json['weight']) ?? 0,
      gst: (json['gst'] is String ? int.tryParse(json['gst']) : json['gst']) ?? 0,
      stock: (json['stock'] is String ? int.tryParse(json['stock']) : json['stock']) ?? 0,
      pid: json['pid'] as String? ?? '',
      quantity: (json['quantity'] is String ? int.tryParse(json['quantity']) : json['quantity']) ?? 0,
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