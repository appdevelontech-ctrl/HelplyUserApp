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
      orders: (json['orders'] as List?)
          ?.map((e) => Order.fromJson(e))
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
  final bool primary;

  final int leadStatus;
  final int type;
  final int lead;
  final List<dynamic> category;
  final List<dynamic> cancelId;

  final Agent? agent;
  final List<UserDetails> details;

  final double? orderLat;
  final double? orderLng;


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
    this.primary = false,
    this.leadStatus = 0,
    this.type = 0,
    this.lead = 0,
    this.category = const [],
    this.cancelId = const [],
    this.agent,
    this.details = const [],
    this.orderLat,
    this.orderLng,
  });

  // ✅ COPY WITH (FIX FOR YOUR ERROR)
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
    bool? primary,
    int? leadStatus,
    int? type,
    int? lead,
    List<dynamic>? category,
    List<dynamic>? cancelId,
    Agent? agent,
    List<UserDetails>? details,
    double? orderLat,
    double? orderLng,
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
      agent: agent ?? this.agent,
      details: details ?? this.details,
      orderLat: orderLat ?? this.orderLat,
      orderLng: orderLng ?? this.orderLng,
    );
  }
  factory Order.fromJson(Map<String, dynamic> json) {
    double? d(val) => val == null ? null : double.tryParse(val.toString());
    int i(val) => int.tryParse(val.toString()) ?? 0;

    return Order(
      id: json['_id'] ?? '',
      mode: json['mode'] ?? '',
      totalAmount: d(json['totalAmount']) ?? 0,
      payment: i(json['payment']),
      status: i(json['status']),
      orderId: i(json['orderId']),
      otp: json['OTP'] != null ? i(json['OTP']) : null,
      createdAt: DateTime.tryParse(json['createdAt'] ?? '') ?? DateTime.now(),
      updatedAt: json['updatedAt'],
      v: i(json['__v']),
      items: (json['items'] as List?)
          ?.map((e) => Item.fromJson(e))
          .toList() ??
          [],
      discount: json['discount'] ?? '0',
      shipping: json['shipping'] ?? '0',
      userId: (json['userId'] as List?)?.cast<String>() ?? [],
      primary: json['primary'].toString() == 'true',
      leadStatus: i(json['leadStatus']),
      type: i(json['type']),
      lead: i(json['lead']),
      category: json['category'] ?? [],
      cancelId: json['CancelId'] ?? json['cancelId'] ?? [],
      agent: json['agentId'] is Map ? Agent.fromJson(json['agentId']) : null,
      details: (json['details'] as List?)
          ?.map((e) => UserDetails.fromJson(e))
          .toList() ??
          [],
      orderLat: d(json['latitude']),
      orderLng: d(json['longitude']),
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
    agent,
    details,
    orderLat,
    orderLng,
  ];
}


class Agent extends Equatable {
  final String id;
  final String username;
  final String phone;
  final String email;
  final double? latitude;
  final double? longitude;

  const Agent({
    required this.id,
    required this.username,
    required this.phone,
    required this.email,
    this.latitude,
    this.longitude,
  });

  factory Agent.fromJson(Map<String, dynamic> json) {
    double? _d(val) =>
        val == null ? null : double.tryParse(val.toString());

    return Agent(
      id: json['_id'] ?? '',
      username: json['username'] ?? '',
      phone: json['phone'] ?? '',
      email: json['email'] ?? '',
      latitude: _d(json['latitude']),
      longitude: _d(json['longitude']),
    );
  }

  @override
  List<Object?> get props =>
      [id, username, phone, email, latitude, longitude];
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
  List<Object?> get props =>
      [username, phone, pincode, state, address, email];
}

class Item extends Equatable {
  final String id;
  final String title;
  final String image;
  final int regularPrice;
  final int price;
  final int quantity;

  const Item({
    required this.id,
    required this.title,
    required this.image,
    required this.regularPrice,
    required this.price,
    required this.quantity,
  });

  factory Item.fromJson(Map<String, dynamic> json) {
    int i(val) => int.tryParse(val.toString()) ?? 0;

    return Item(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      image: json['image'] ?? '',
      regularPrice: i(json['regularPrice']),
      price: i(json['price']),
      quantity: i(json['quantity']),
    );
  }

  @override
  List<Object?> get props =>
      [id, title, image, regularPrice, price, quantity];
}
