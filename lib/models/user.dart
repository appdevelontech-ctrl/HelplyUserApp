class AppUser {
  final String id;
  final String? username;
  final String phone;
  final String? email;
  final int? type;
  final int? empType;
  final String? state;
  final String? statename;
  final String? city;
  final String? address;
  final int? verified;
  final String? pincode;
  final String? about;
  final List<String>? department;
  final String? doc1;
  final String? doc2;
  final String? doc3;
  final String? profile;
  final String? pHealthHistory;
  final String? cHealthStatus;
  final List<String>? coverage;
  final int? wallet;
  final int? online;
  final String? country;
  final String? dob;
  final String? gender;

  AppUser({
    required this.id,
    required this.phone,
    this.username,
    this.email,
    this.type,
    this.empType,
    this.state,
    this.statename,
    this.city,
    this.address,
    this.verified,
    this.pincode,
    this.about,
    this.department,
    this.doc1,
    this.doc2,
    this.doc3,
    this.profile,
    this.pHealthHistory,
    this.cHealthStatus,
    this.coverage,
    this.wallet,
    this.online,
    this.country,
    this.dob,
    this.gender,
  });

  factory AppUser.fromJson(Map<String, dynamic> json) {
    return AppUser(
      id: json['_id'] ?? '',
      phone: json['phone'] ?? '',
      username: json['username'],
      email: json['email'],
      type: json['type'] as int?,
      empType: json['empType'] as int?,
      state: json['state'],
      statename: json['statename'],
      city: json['city'],
      address: json['address'],
      verified: json['verified'] as int?,
      pincode: json['pincode'],
      about: json['about'],
      department: (json['department'] as List<dynamic>?)?.cast<String>(),
      doc1: json['Doc1'],
      doc2: json['Doc2'],
      doc3: json['Doc3'],
      profile: json['profile'],
      pHealthHistory: json['pHealthHistory'],
      cHealthStatus: json['cHealthStatus'],
      coverage: (json['coverage'] as List<dynamic>?)?.cast<String>(),
      wallet: json['wallet'] as int?,
      online: json['online'] as int?,
      country: json['country'],
      dob: json['DOB'], // Match payload key casing
      gender: json['Gender'], // Match payload key casing
    );
  }
}