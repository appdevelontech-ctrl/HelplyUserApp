
class AppUser {
  final String id;
  final String phone;
  final String? name;
  final String? email;

  AppUser({
    required this.id,
    required this.phone,
    this.name,
    this.email,
  });

  factory AppUser.fromJson(Map<String, dynamic> json) {
    return AppUser(
      id: json['_id'] ?? '',
      phone: json['phone'] ?? '',
      name: json['name'],
      email: json['email'],
    );
  }
}